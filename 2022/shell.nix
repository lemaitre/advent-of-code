{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
   packages = with pkgs; [ zig valgrind ];
}

