{ config, pkgs, lib, ... }:
{
  # ===================
  # AeroSpace - Tiling Window Manager
  # ===================
  services.aerospace = {
    enable = true;
    settings = {
      after-startup-command = [];

      enable-normalization-flatten-containers = true;
      enable-normalization-opposite-orientation-for-nested-containers = true;

      accordion-padding = 30;
      default-root-container-layout = "tiles";
      default-root-container-orientation = "auto";

      key-mapping.preset = "qwerty";

      on-focused-monitor-changed = [ "move-mouse monitor-lazy-center" ];

      gaps = {
        inner = { horizontal = 5; vertical = 5; };
        outer = { left = 5; bottom = 5; top = 5; right = 5; };
      };

      on-window-detected = [
        { "if".app-id = "com.apple.systempreferences"; run = "layout floating"; }
        { "if".app-id = "com.1password.1password"; run = "layout floating"; }
        { "if".app-name-regex-substring = "Meet"; run = "layout floating"; }
        { "if".app-id = "com.spotify.client"; run = "layout floating"; }
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
}
