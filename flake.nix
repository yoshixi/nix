{
  description = "Example nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
    # Optional: Declarative tap management
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
    nikitabobko-tap = {
      url = "github:nikitabobko/homebrew-tap"; # for AeroSpace
      flake = false;
    };
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, home-manager, nix-homebrew, homebrew-core, homebrew-cask, nikitabobko-tap }:

  let
    username = builtins.getEnv "USER"; 
    homedir = builtins.getEnv "HOME";
    system = "aarch64-darwin"; 
    configuration = { pkgs, ... }: {
      # List packages installed in system profile. To search by name, run:
      # $ nix-env -qaP | grep wget
      environment.systemPackages = [ 
        pkgs.vim
        pkgs.devenv
        pkgs.ripgrep # for vim telesope's file search
      ];

      # Necessary for using flakes on this system.
      nix.settings.experimental-features = "nix-command flakes";

      # Enable alternative shell support in nix-darwin.
      # programs.fish.enable = true;

      # Set Git commit hash for darwin-version.
      system.configurationRevision = self.rev or self.dirtyRev or null;

      # Used for backwards compatibility, please read the changelog before changing.
      # $ darwin-rebuild changelog
      system.stateVersion = 6;

      # The platform the configuration will be used on.
      nixpkgs.hostPlatform = "aarch64-darwin";

      # to install vscode
      nixpkgs.config.allowUnfree = true;
    };

  in
  {
    # Build darwin flake using:
    # $ darwin-rebuild build --flake .#Yoshikis-Mac-mini
    darwinConfigurations."Yoshikis-Mac-mini" = nix-darwin.lib.darwinSystem {
      modules =
      [ configuration
        ./darwin.nix
        home-manager.darwinModules.home-manager
        {
          system.primaryUser = "yoshiki";
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users."yoshiki" = import ./home.nix;
          home-manager.extraSpecialArgs = {
            username = "yoshiki";
            homeDirectory = "/Users/yoshiki";
          };
        }
        nix-homebrew.darwinModules.nix-homebrew
        {
          nix-homebrew = {
            # Install Homebrew under the default prefix
            enable = true;

            # Apple Silicon Only: Also install Homebrew under the default Intel prefix for Rosetta 2
            enableRosetta = false;

            # User owning the Homebrew prefix
            user = "yoshiki";

            # Optional: Declarative tap management
            taps = {
              "homebrew/homebrew-core" = homebrew-core;
              "homebrew/homebrew-cask" = homebrew-cask;
              "nikitabobko/homebrew-tap" = nikitabobko-tap;
            };
            mutableTaps = false;
          };
        }
      ];
    };
    darwinConfigurations."Yoshikis-MacBook-Pro" = nix-darwin.lib.darwinSystem {
      modules =
      [ configuration
        ./darwin.nix
        home-manager.darwinModules.home-manager
        {
          system.primaryUser = "yoshikimasubuchi";
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users."yoshikimasubuchi" = import ./home.nix;
          home-manager.extraSpecialArgs = {
            username = "yoshikimasubuchi";
            homeDirectory = "/Users/yoshikimasubuchi";
          };
        }
      ];
    };
  };
}
