{ lib, buildNpmPackage, fetchurl }:

let
  version = "5.0.12";

  # Upstream (https://github.com/yoshiko-pg/difit) ships dist/ prebuilt in
  # its npm tarball, but the tarball has no lockfile and its own
  # package.json pulls in its whole pnpm monorepo (React, mermaid, vite, …)
  # needed only to build the browser bundle that's already prebuilt here.
  # ./package.json + ./package-lock.json instead pin just the runtime deps
  # difit's published dist/ actually imports: commander, express, open,
  # simple-git, @parcel/watcher (checked directly against dist/cli/*.js and
  # dist/server/*.js — the last is a dynamic import, used for live-reload
  # and optional: dist degrades to "no file watching" without it).
  dist = fetchurl {
    url = "https://registry.npmjs.org/difit/-/difit-${version}.tgz";
    hash = "sha256-6zye65ZbaTh26njrNidE4GdsLlbElgMvozzQFMOVYlA=";
  };
in
buildNpmPackage {
  pname = "difit";
  inherit version;

  src = ./.;
  npmDepsHash = "sha256-vTfUP++LocDE+/JHs+/g68LUjgR8cfyX6E4Mc6vhoRI=";

  # No build step of our own; postPatch below drops in the real prebuilt
  # dist/ before npm's install phase wires up the "bin" wrapper for it.
  dontNpmBuild = true;
  postPatch = ''
    tar -xzf ${dist} --strip-components=1 -C . package/dist
  '';

  meta = {
    description = "Lightweight CLI that shows Git diffs in a GitHub-like Files changed view";
    homepage = "https://github.com/yoshiko-pg/difit";
    license = lib.licenses.mit;
    mainProgram = "difit";
  };
}
