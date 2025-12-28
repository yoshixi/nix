{ config, pkgs, lib, ... }:
with builtins;
{
  home.username = "yoshiki";
  home.homeDirectory = lib.mkForce "/Users/yoshiki";

  home.stateVersion = "25.05";

  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    # runtime
    go nodejs_24

    # shells
    neovim tmux fzf git ghq gh lazygit
    
    # desktop apps
    vscode
    
    # background
    tailscale

    #AI tools
    codex github-copilot-cli
  ];

  programs.git = {
    enable = true;
    userName = "yoshixi";
    userEmail = "yoshixi.dev@gmail.com";
    delta = {
      enable = true;
      options = {
        line-numbers = true;
        navigate = true;
        side-by-side = true;
      };
    };
    extraConfig = {
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
    ignores = [
      "*~"
      "*.swp"
      ".DS_Store"
      ".direnv"
    ];
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
      export PATH="$HOME/.local/bin:$PATH
    '';

    loginExtra = ''
      . ${./zsh/search.zsh}
    '';

    shellAliases = {
      # general
      vim = "nvim";
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
      # docker
      dkilla = "docker kill $(docker ps -q)";
      # tmux wrappers
      t      = "tmux";

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

   programs.tmux = {
    enable = true;


    extraConfig = ''
      source ${./.tmux.conf}
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
