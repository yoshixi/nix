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
  ];
}
