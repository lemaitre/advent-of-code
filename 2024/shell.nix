{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  packages = with pkgs; [
    bashInteractive
    python3
    python3Packages.click
    python3Packages.numpy
    vscode
  ];
}
