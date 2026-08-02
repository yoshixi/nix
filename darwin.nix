{ config, pkgs, lib, ... }:
let
  aerospace-grid = pkgs.writeShellScriptBin "aerospace-grid" ''
    # Arrange windows in current workspace into a grid layout
    workspace=$(aerospace list-workspaces --focused)

    # Get window count
    count=$(aerospace list-windows --workspace "$workspace" | wc -l | tr -d ' ')

    if [ "$count" -lt 2 ]; then
      exit 0
    fi

    # Flatten and set horizontal layout
    aerospace flatten-workspace-tree --workspace "$workspace"
    sleep 0.2
    aerospace layout tiles horizontal
    sleep 0.2

    # Calculate rows per column: ceil(sqrt(count))
    rows=$(awk "BEGIN {r=int(sqrt($count)+0.99); if(r<2) r=2; print r}")
    cols=$(( (count + rows - 1) / rows ))

    # Use spatial navigation instead of window IDs
    # Start from leftmost window (focus left until we can't anymore)
    for ((j = 0; j < count; j++)); do
      aerospace focus left 2>/dev/null || true
    done
    sleep 0.1

    # Track position in grid
    pos=0

    for ((i = 1; i < count; i++)); do
      # Move focus to next window on the right
      aerospace focus right 2>/dev/null || true
      sleep 0.1

      pos=$((pos + 1))

      # If this is not the first window in a column, join with left
      if (( pos % rows != 0 )); then
        aerospace join-with left 2>/dev/null || true
        sleep 0.1
      fi
    done

    # Balance sizes
    sleep 0.2
    aerospace balance-sizes
  '';

  # Appends the newly focused window to ~/.cache/aerospace-focus-history
  # (most-recent last), deduping and capping length. Wired into AeroSpace's
  # `on-focus-changed` hook (see home.nix) so `a app mv` can pick the
  # most-recently-focused window when an app has several open.
  aerospace-track-focus = pkgs.writeShellScriptBin "aerospace-track-focus" ''
    set -euo pipefail

    window_id="''${AEROSPACE_WINDOW_ID:-}"
    [ -z "$window_id" ] && exit 0

    history_file="$HOME/.cache/aerospace-focus-history"
    mkdir -p "$(dirname "$history_file")"

    tmp="$history_file.tmp.$$"
    { grep -vx "$window_id" "$history_file" 2>/dev/null || true; echo "$window_id"; } \
      | tail -n 300 > "$tmp"
    mv "$tmp" "$history_file"
  '';

  # AeroSpace helper CLI:
  #   a mv <workspace>            move the focused window to <workspace>
  #   a app mv <app> <workspace>  move the window matching <app> to <workspace>
  #   a app ls                    list open windows
  # `<app>` matches as a case-insensitive substring against both
  # app-bundle-id and app-name, so "notion", "cal", or "cron" all find
  # Notion Calendar without needing the exact display name or bundle id.
  a = pkgs.writeShellScriptBin "a" ''
    set -euo pipefail

    list_format=$'%{window-id}\t%{app-bundle-id}\t%{app-name}'

    usage() {
      cat >&2 <<'USAGE'
    Usage:
      a mv <workspace>             Move the focused window to <workspace>
      a app mv <app> <workspace>   Move the window matching <app> to <workspace>
      a app ls                     List open windows: window-id, app-bundle-id, app-name
    USAGE
      exit 1
    }

    cmd="''${1:-}"
    [ $# -gt 0 ] && shift

    case "$cmd" in
      mv)
        # Invoked from a terminal or Raycast, so the focused window is
        # always the invoker itself. Hop to whatever was focused right
        # before it (via AeroSpace's own focus history), then move that
        # window and follow it to the target workspace.
        workspace="''${1:-}"
        if [ -z "$workspace" ]; then
          usage
        fi

        origin_id=$(aerospace list-windows --focused --format "%{window-id}" 2>/dev/null) || origin_id=""
        if [ -z "$origin_id" ]; then
          echo "a: no focused window" >&2
          exit 1
        fi

        # Can fail (e.g. "Prev window has been closed") when AeroSpace has no
        # valid previous-focus pointer; treated as "nothing to move" below
        # rather than aborting the script.
        aerospace focus-back-and-forth >/dev/null 2>&1 || true

        target_id=$(aerospace list-windows --focused --format "%{window-id}" 2>/dev/null) || target_id="$origin_id"

        if [ "$target_id" = "$origin_id" ]; then
          echo "a: no previous window to move" >&2
          exit 1
        fi

        aerospace move-node-to-workspace --focus-follows-window --window-id "$target_id" "$workspace"
        ;;

      app)
        sub="''${1:-}"
        [ $# -gt 0 ] && shift

        case "$sub" in
          mv)
            query="''${1:-}"
            workspace="''${2:-}"
            if [ -z "$query" ] || [ -z "$workspace" ]; then
              usage
            fi
            query_lc=$(printf '%s' "$query" | tr '[:upper:]' '[:lower:]')

            matches=$(aerospace list-windows --all --format "$list_format" \
              | awk -F'\t' -v q="$query_lc" '{ n = tolower($2 "\t" $3); if (index(n, q) > 0) print }')

            if [ -z "$matches" ]; then
              echo "a: no window matching '$query'" >&2
              exit 1
            fi

            count=$(printf '%s\n' "$matches" | wc -l | tr -d ' ')
            if [ "$count" -gt 1 ]; then
              # Several windows match: pick whichever was focused most
              # recently, per ~/.cache/aerospace-focus-history (populated by
              # aerospace-track-focus via the on-focus-changed hook).
              match_ids=$(printf '%s\n' "$matches" | cut -f1)
              history_file="$HOME/.cache/aerospace-focus-history"
              window_id=""

              if [ -f "$history_file" ]; then
                mapfile -t hist < "$history_file"
                for ((i = ''${#hist[@]} - 1; i >= 0; i--)); do
                  id="''${hist[i]}"
                  if printf '%s\n' "$match_ids" | grep -qx "$id"; then
                    window_id="$id"
                    break
                  fi
                done
              fi

              if [ -z "$window_id" ]; then
                echo "a: multiple windows match '$query', none in focus history:" >&2
                printf '%s\n' "$matches" >&2
                exit 1
              fi
            else
              window_id=$(printf '%s' "$matches" | cut -f1)
            fi

            aerospace move-node-to-workspace --focus-follows-window --window-id "$window_id" "$workspace"
            ;;

          ls)
            aerospace list-windows --all --format "$list_format"
            ;;

          *) usage ;;
        esac
        ;;

      *) usage ;;
    esac
  '';
in
{
  # ===================
  # AeroSpace - Tiling Window Manager
  # ===================
  # Installed via the Homebrew cask (see `casks` below) instead of the
  # nix-darwin `services.aerospace` module, so the app lives at the stable
  # path /Applications/AeroSpace.app. This keeps macOS Accessibility / Input
  # Monitoring (TCC) grants valid across updates — the nix-store path changes
  # on every version bump and would otherwise invalidate those permissions.
  # The app registers its own login item via `start-at-login = true`, and its
  # config is managed declaratively at ~/.aerospace.toml (see home.nix).

  # ===================
  # JankyBorders - Window Border Highlighting
  # ===================
  services.jankyborders = {
    enable = true;
    active_color = "0xffe1e3e4";
    inactive_color = "0xff494d64";
    width = 5.0;
    hidpi = true;
    style = "round";
  };

  # ===================
  # SketchyBar - Custom Menu Bar
  # ===================
  services.sketchybar = {
    enable = true;
  };

  # ===================
  # Homebrew - Taps, Brews, and Casks
  # ===================
  homebrew = {
    enable = true;
    brews = [
      "reattach-to-user-namespace"
      "awscli-local"
      "googleworkspace-cli"
    ];
    casks = [
      "aerospace"
      "copilot-cli"
      "alt-tab"
      "codex"
    ];
  };

  # ===================
  # System Packages
  # ===================
  environment.systemPackages = [
    aerospace-grid
    aerospace-track-focus
    a
  ];
}
