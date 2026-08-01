{ config, pkgs, lib, username, homeDirectory, ... }:
with builtins;
{
  imports = [
    # AI agent context (~/.claude/CLAUDE.md, ~/.cursor/rules) generated from ai/
    ./ai.nix
  ];

  home.username = username;
  home.homeDirectory = lib.mkForce homeDirectory;

  home.stateVersion = "25.05";

  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    # runtime
    go nodejs_24
    python3
    docker

    # shells
    tmux fzf git ghq gh lazygit lazydocker

    # log viewer (https://lnav.org)
    lnav

    # desktop apps
    google-cloud-sdk
    (callPackage ./pkgs/googleworkspace-cli.nix {})

    # background
    tailscale

    # SQL client
    usql

    # 1Password CLI
    _1password-cli

    process-compose

    cloudflared

    # agent multiplexer (https://herdr.dev), via herdr flake overlay
    herdr
  ];

  programs.git = {
    enable = true;
    ignores = [
      "*~"
      "*.swp"
      ".DS_Store"
      ".direnv"
    ];
    settings = {
      user = {
        name = "yoshixi";
        email = "yoshixi.dev@gmail.com";
      };
      advice = {
        skippedCherryPicks = false;
      };
      color = {
        ui = "auto";
      };
      init = {
        defaultBranch = "main";
      };
      merge = {
        conflictStyle = "diff3";
        ff = false;
      };
      pull = {
        ff = "only";
      };
      push = {
        default = "current";
      };
      rebase = {
        autosquash = true;
        autostash = true;
        stat = true;
      };
      rerere = {
        enabled = true;
      };
      core = {
        editor = "vim";
      };
    };
  };

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      line-numbers = true;
      navigate = true;
      side-by-side = true;
    };
  };

  programs.vscode = {
    enable = true;
    package = pkgs.vscode; 
    profiles.default = {
      extensions = with pkgs.vscode-extensions; [
        dracula-theme.theme-dracula
        vscodevim.vim
        yzhang.markdown-all-in-one
        bbenoist.nix
     ];
    };
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;        # compinit
    autosuggestion.enable = true;   # zsh-autosuggestions
    syntaxHighlighting.enable = true;

    history = {
      path = "${config.home.homeDirectory}/.zsh_history";
      size = 10000;
      save = 100000;
      extended = true;      # EXTENDED_HISTORY
      ignoreDups = true;    # hist_ignore_dups
      share = true;         # share_history
      saveNoDups = true;
      findNoDups = true;
      ignoreAllDups = true;
    };



    # Plugins (Home-Manager will source these in order)
    zplug = {
      enable = true;
      plugins = [
        { name = "sindresorhus/pure"; tags = [ use:pure.zsh from:github as:theme ];}
        { name = "zsh-users/zsh-syntax-highlighting"; }
        { name = "b4b4r07/enhancd"; tags = [ use:init.sh ]; }
      ];
    };

        # setopt / keybindings that were in your .zshrc
    initContent = lib.mkOrder 550''
      setopt nobeep notify auto_menu auto_pushd auto_cd interactivecomments nonomatch
      setopt hist_no_store hist_expand
      bindkey -v
      bindkey '^P' history-beginning-search-backward
      bindkey '^N' history-beginning-search-forward
      # needs the "zaw" plugin below
      bindkey '^h' zaw-history

      # Prompt: pure (matches your setup + zstyles)
      fpath+=(${pkgs.pure-prompt}/share/zsh/site-functions)
      autoload -U promptinit; promptinit
      prompt pure
      PURE_CMD_MAX_EXEC_TIME=10
      zstyle :prompt:pure:path color white
      zstyle ':prompt:pure:prompt:*' color cyan
      zstyle :prompt:pure:git:stash show yes

      # completion menu behavior
      zstyle ':completion:*:default' menu select=1

      # npm global package place
      export PATH="$HOME/.npm-global/bin:$PATH"
      export PATH="$HOME/.local/bin:$PATH"

      # go install destination ($GOPATH/bin) - appended so the nix-managed
      # `go` toolchain always wins over anything in here.
      export PATH="$PATH:$HOME/go/bin"

      . ${./pkgs/worktree.zsh}
      . ${./zsh/secureinput.zsh}
      # Allows running adb from anywhere; requires Android Studio to be installed
      export PATH="$PATH:$HOME/Library/Android/sdk/platform-tools"
    '';

    loginExtra = ''
      . ${./zsh/search.zsh}
    '';

    shellAliases = {
      # general
      # macOS kills the nix-wrapped `code` binary (Killed: 9) because the Electron
      # executable is unsigned when installed via nix. Use the signed CLI from the
      # app bundle directly to bypass the nix wrapper.
      code   = "'/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code'";
      chrome = "open -a 'Google Chrome'";
      sshadd = "ssh-add ~/.ssh/id_rsa";
      ll = "ls -l";
      l  = "ls -al";
      rm = "rm -i";
      sz = "source ~/.zshrc";

      # git
      gb   = "git branch";
      gs   = "git status --short --branch";
      gc   = "git checkout";
      gcp  = "git branch | peco | xargs git checkout";
      gcb  = "git checkout -b";
      gcm  = "git commit -m";
      acm  = "aicommits";
      gd   = "git diff --patience";
      gdn  = "git diff --name-only";
      gl   = "git log --graph --decorate --oneline";
      gphc = "git symbolic-ref --short HEAD| xargs -Icurrent_branch git push heroku-st current_branch:master";
      gpo  = "git symbolic-ref --short HEAD| xargs git push origin";
      gpof = "git symbolic-ref --short HEAD| xargs git push origin --force-with-lease";
      gbdm = ''git branch --merged | grep -Ev "(^\*|master|main|dev)" | xargs git branch -d'';
      cm   = ''cat ~/.gitcommitmessage_sample | peco | xargs -I {} echo  "'{}'"'';
      # history helpers
      hpp  = "history 1| peco | pbcopy";
      hp   = "history 1| peco";
      hisg = "history | grep";
      # dotfiles/nvim shortcuts (adjust paths if you want)
      vz   = "nvim ${config.home.homeDirectory}/.config/nvim/init.lua";
      vv   = "nvim ${config.home.homeDirectory}/.config/nvim";
      # shared AI agent context (see ai.nix) — read-only in $HOME, edit here
      va   = "nvim /etc/nix-darwin/ai/AGENTS.md";
      # docker
      dkilla = "docker kill $(docker ps -q)";
      # tmux wrappers
      t      = "tmux";
      # herdr wrapper
      h      = "herdr";

      # ruby helpers
      be   = "bundle exec";
      rubo   = ''git diff --name-only --diff-filter=AM | grep '\.rb$' | xargs rubocop'';
      ruboa  = ''git diff --name-only --diff-filter=AM | grep '\.rb$' | xargs rubocop -a'';
      "rails-ruboa" =
        ''git diff --name-only --staged | grep '\.rb$' | grep -v 'db/schema.rb' | xargs bundle exec rubocop -a --force-exclusion'';
      grspec = ''git diff --name-only --staged | grep '\_spec.rb$' | xargs -t bundle exec rspec'';
      # GAS
      nclasp = "npx clasp";
      # YAML check
      ymlc = ''ruby -ryaml -e "p YAML.load(STDIN.read)" <'';
      # ghq helpers
      ghqb = "hub browse $(ghq list -p | grep github.com | peco | cut -d '/' -f 2,3)";
      g  = "cd $(ghq list -p | fzf)";
    };
  };

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    withRuby = false;
    withPython3 = false;
    initLua = builtins.readFile ./nvim/init.lua;
  };

  # Manage nvim lua config files from this repo.
  # lazy.nvim still handles plugin downloads at runtime.
  # lazy-lock.json and lazyvim.json are intentionally NOT managed here
  # (they are auto-updated by LazyVim).
  home.file = {
    # herdr — use the default ctrl+b prefix
    ".config/herdr/config.toml".source =
      (pkgs.formats.toml { }).generate "herdr-config.toml" {
        onboarding = false;
        keys.prefix = "ctrl+b";
        # Workspace navigation: enter workspace mode with prefix+w, then step
        # through workspaces with bare n/p (no prefix) — n=next(down),
        # p=previous(up). These are navigate-mode local keys, active only
        # while that mode is open. Enter switches, esc closes.
        # (switch_workspace = prefix+shift+1..9 also jumps by number.)
        keys.navigate_workspace_down = "n";
        keys.navigate_workspace_up = "p";
        # Swap the focused pane with its neighbor (mirrors focus_pane h/j/k/l,
        # with shift). No herdr default — unbound out of the box.
        keys.swap_pane_left = "prefix+shift+h";
        keys.swap_pane_down = "prefix+shift+j";
        keys.swap_pane_up = "prefix+shift+k";
        keys.swap_pane_right = "prefix+shift+l";
        # Split the focused pane horizontally on prefix+s (default is
        # prefix+minus). Moves settings off prefix+s onto prefix+shift+s.
        keys.split_horizontal = "prefix+s";
        keys.settings = "prefix+shift+s";
        # Close tab on prefix+shift+x (herdr default); close the whole workspace
        # on prefix+shift+q (default is prefix+shift+d). In workspace mode via
        # prefix+w, bare shift+x closes the tab and shift+q closes the workspace.
        keys.close_tab = "prefix+shift+x";
        keys.close_workspace = "prefix+shift+q";
        # Restore recent pane scrollback across a full server restart / logout.
        # Off by default because saved output can contain secrets/tokens.
        experimental.pane_history = true;
      };

    # AeroSpace tiling WM config. Installed as a Homebrew cask (see darwin.nix)
    # for a stable app path so Accessibility / Input Monitoring grants survive
    # updates. `start-at-login = true` makes the app register its own login
    # item (replacing the old nix-darwin launchd agent).
    ".aerospace.toml".source =
      (pkgs.formats.toml { }).generate "aerospace.toml" {
        start-at-login = true;

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

          # Move chrome to workspace 1 as default and go to the workspace1
          { "if".app-id = "com.google.Chrome"; run = [ "move-node-to-workspace 1" "layout tiling" "workspace 1" ]; }
        ];

        mode.main.binding = {
          # Window navigation (vim-style)
          alt-h = "focus left";
          alt-j = "focus down";
          alt-k = "focus up";
          alt-l = "focus right";
          alt-t = [ "layout tiles horizontal vertical"];

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
        };

        mode.service.binding = {
          esc = [ "reload-config" "mode main" ];
          r = [ "flatten-workspace-tree" "mode main" ];
          f = [ "layout floating tiling" "mode main" ];
          g = "exec-and-forget /run/current-system/sw/bin/aerospace-grid";
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
          "6" = [ "secondary" "main" ];
          "7" = [ "secondary" "main" ];
          "8" = [ "main" "secondary" ];
          "9" = [ "main" "secondary" ];
        };
      };

    # Ghostty terminal. Disable auto-secure-input: Ghostty's heuristic turns on
    # macOS Secure Input when it thinks a password is being typed (e.g. sudo),
    # which holds a system-wide keyboard lock that blocks AeroSpace's global
    # hotkeys. See https://ghostty.org/docs/config/reference#macos-auto-secure-input
    ".config/ghostty/config".text = ''
      macos-auto-secure-input = false
    '';

    ".config/nvim/lua/config/lazy.lua".source           = ./nvim/lua/config/lazy.lua;
    ".config/nvim/lua/config/keymaps.lua".source        = ./nvim/lua/config/keymaps.lua;
    ".config/nvim/lua/config/options.lua".source        = ./nvim/lua/config/options.lua;
    ".config/nvim/lua/config/autocmds.lua".source       = ./nvim/lua/config/autocmds.lua;
    ".config/nvim/lua/plugins/neotree.lua".source       = ./nvim/lua/plugins/neotree.lua;
    ".config/nvim/lua/plugins/curl-runner.lua".source   = ./nvim/lua/plugins/curl-runner.lua;
    ".config/nvim/lua/plugins/copilot.lua".source       = ./nvim/lua/plugins/copilot.lua;
  };

  programs.tmux = {
    enable = true;
    # shell = "${pkgs.zsh}/bin/zsh";


    extraConfig = ''
      source ${./.tmux.conf}

      # the workaround for macOS default shell issue with nix and tmux. https://github.com/nix-community/home-manager/issues/5952#issuecomment-2409056750
      set -gu default-command
      set -g default-shell "$SHELL"

      unbind-key -T prefix C-r
      set -g command-alias[0] restore='run-shell "${pkgs.tmuxPlugins.resurrect}/share/tmux-plugins/resurrect/scripts/restore.sh"'
    '';
    baseIndex = 1;
    clock24 = true;
    escapeTime = 1;
    historyLimit = 5000;
    keyMode = "vi";
    newSession = false;
    prefix = "C-t";
    terminal = "screen-256color";
    plugins = with pkgs.tmuxPlugins; [
      # sensible
      yank
      resurrect
      continuum
      # add others from pkgs.tmuxPlugins
    ];
  };

}
