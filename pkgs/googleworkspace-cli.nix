{ lib, stdenv, fetchurl }:

let
  version = "0.22.5";

  sources = {
    "aarch64-darwin" = {
      url = "https://github.com/googleworkspace/cli/releases/download/v${version}/google-workspace-cli-aarch64-apple-darwin.tar.gz";
      hash = "sha256-HSqf/VvJssLEtIYw2vCC+tE9nlfXQZiKLCSO7VYvfaw=";
    };
    "x86_64-darwin" = {
      url = "https://github.com/googleworkspace/cli/releases/download/v${version}/google-workspace-cli-x86_64-apple-darwin.tar.gz";
      hash = lib.fakeHash; # replace after first build on x86_64
    };
    "x86_64-linux" = {
      url = "https://github.com/googleworkspace/cli/releases/download/v${version}/google-workspace-cli-x86_64-unknown-linux-gnu.tar.gz";
      hash = lib.fakeHash; # replace after first build on linux
    };
    "aarch64-linux" = {
      url = "https://github.com/googleworkspace/cli/releases/download/v${version}/google-workspace-cli-aarch64-unknown-linux-gnu.tar.gz";
      hash = lib.fakeHash; # replace after first build on linux
    };
  };

  src = sources.${stdenv.hostPlatform.system}
    or (throw "Unsupported platform: ${stdenv.hostPlatform.system}");

in
stdenv.mkDerivation {
  pname = "googleworkspace-cli";
  inherit version;

  src = fetchurl {
    inherit (src) url hash;
  };

  sourceRoot = ".";

  installPhase = ''
    install -Dm755 gws $out/bin/gws
  '';

  meta = with lib; {
    description = "Google Workspace CLI — dynamic command surface from Discovery Service";
    homepage = "https://github.com/googleworkspace/cli";
    license = licenses.asl20;
    mainProgram = "gws";
  };
}
