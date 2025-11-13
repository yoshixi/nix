# nix

## Installation

### Darwin


### Preset up

Need to install [nix-darwin](https://github.com/nix-darwin/nix-darwin)

```sh

# Allow to use nix flakes
$ mkdir -p ~/.config/nix && \
$ echo "experimental-features = nix-command flakes" > ~/.config/nix/nix.conf 

# Install nix-darwin
$ sudo mkdir -p /etc/nix-darwin
$ sudo chown $(id -nu):$(id -ng) /etc/nix-darwin
$ git clone https://github.com/yoshixi/nix /etc/nix-darwin
$ cd /etc/nix-darwin

$ sudo nix flake init -t nix-darwin/master
$ sudo nix --extra-experimental-features 'nix-command flakes' run nix-darwin/nix-darwin-25.05#darwin-rebuild -- switch

# Apply config
$ sudo darwin-rebuild switch
```

### Apply your updates

Once you have made changes to your configuration, apply them with:

```sh
sudo darwin-rebuild switch
```

## Note

- Need to run `prefix` + `I` to install tmux packages.