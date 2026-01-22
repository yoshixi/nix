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
  services.aerospace = {
    enable = true;
    settings = {
      after-startup-command = [];

      enable-normalization-flatten-containers = false;
      enable-normalization-opposite-orientation-for-nested-containers = true;

      accordion-padding = 10;
      default-root-container-layout = "tiles";
      default-root-container-orientation = "auto";

      key-mapping.preset = "qwerty";

      on-focused-monitor-changed = [ "move-mouse monitor-lazy-center" ];

      gaps = {
        inner = { horizontal = 5; vertical = 5; };
        outer = { left = 5; bottom = 5; top = 5; right = 5; };
      };

      on-window-detected = [
        # Floating apps
        { "if".app-id = "com.apple.systempreferences"; run = "layout floating"; }
        { "if".app-id = "com.1password.1password"; run = "layout floating"; }
        { "if".app-id = "com.spotify.client"; run = "layout floating"; }
        { "if".app-id = "com.github.Electron"; run = "layout floating"; }
        { "if".app-id = "com.electron.aqua-voice"; run = "layout floating"; }
        { "if".app-id = "com.shuchu.app"; run = "layout floating"; }
        # Workspace 2: Tiles - Ghostty terminal
        { "if".app-id = "com.mitchellh.ghostty"; run = [ "move-node-to-workspace 2" "layout tiling" ]; }

        # Workspace 3: Tiles - Slack
        { "if".app-id = "com.tinyspeck.slackmacgap"; run = [ "move-node-to-workspace 3" "layout tiling" ]; }

        # Workspace 5: Google Meet (Chrome with Meet in title) - Accordion
        { "if".app-id = "com.google.Chrome"; "if".window-title-regex-substring = "Meet"; check-further-callbacks = false; run = [ "move-node-to-workspace 5" "layout accordion horizontal" ]; }

        # Workspace 5: Chrome on workspace 5 should be floating
        { "if".app-id = "com.google.Chrome"; "if".workspace = "5"; check-further-callbacks = false; run = "layout floating"; }
      ];

      mode.main.binding = {
        # Window navigation (vim-style)
        alt-h = "focus left";
        alt-j = "focus down";
        alt-k = "focus up";
        alt-l = "focus right";

        # Move windows
        alt-shift-h = "move left";
        alt-shift-j = "move down";
        alt-shift-k = "move up";
        alt-shift-l = "move right";

        # Workspace navigation
        alt-1 = "workspace 1";
        alt-2 = "workspace 2";
        alt-3 = "workspace 3";
        alt-4 = "workspace 4";
        alt-5 = "workspace 5";
        alt-6 = "workspace 6";
        alt-7 = "workspace 7";
        alt-8 = "workspace 8";
        alt-9 = "workspace 9";

        # Move window to workspace
        alt-shift-1 = "move-node-to-workspace 1";
        alt-shift-2 = "move-node-to-workspace 2";
        alt-shift-3 = "move-node-to-workspace 3";
        alt-shift-4 = "move-node-to-workspace 4";
        alt-shift-5 = "move-node-to-workspace 5";
        alt-shift-6 = "move-node-to-workspace 6";
        alt-shift-7 = "move-node-to-workspace 7";
        alt-shift-8 = "move-node-to-workspace 8";
        alt-shift-9 = "move-node-to-workspace 9";

        # Layout commands
        alt-slash = "layout tiles horizontal vertical";
        alt-comma = "layout accordion horizontal vertical";
        alt-f = "fullscreen";

        # Join commands (use join-with instead of split when normalizations are enabled)
        alt-minus = "resize smart -50";
        alt-equal = "resize smart +50";

        # Resize
        alt-shift-minus = "resize smart -100";
        alt-shift-equal = "resize smart +100";

        # Service mode
        alt-shift-semicolon = "mode service";

        # Grid layout for current workspace
        alt-shift-g = "exec-and-forget ${aerospace-grid}/bin/aerospace-grid";
      };

      mode.service.binding = {
        esc = [ "reload-config" "mode main" ];
        r = [ "flatten-workspace-tree" "mode main" ];
        f = [ "layout floating tiling" "mode main" ];
        backspace = [ "close-all-windows-but-current" "mode main" ];
        alt-shift-h = "join-with left";
        alt-shift-j = "join-with down";
        alt-shift-k = "join-with up";
        alt-shift-l = "join-with right";
      };

      workspace-to-monitor-force-assignment = {
        "1" = [ "secondary" "main" ];
        "2" = [ "secondary" "main" ];
        "3" = [ "secondary" "main" ];
        "4" = [ "secondary" "main" ];
        "5" = [ "secondary" "main" ];
        "6" = [ "main" "secondary" ];
        "7" = [ "main" "secondary" ];
        "8" = [ "main" "secondary" ];
        "9" = [ "main" "secondary" ];
      };
    };
  };

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
  # Homebrew Casks - macOS Apps
  # ===================
  homebrew = {
    enable = true;
    casks = [
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
