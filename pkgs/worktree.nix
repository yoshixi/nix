{ pkgs }:

pkgs.writeShellApplication {
  name = "worktree";
  runtimeInputs = with pkgs; [ git tmux ];
  text = builtins.readFile ./worktree.sh;
}
