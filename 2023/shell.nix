{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  # rustup
  RUST_SRC_PATH = "${pkgs.rust.packages.stable.rustPlatform.rustLibSrc}";

  packages = with pkgs; [ bashInteractive rustc rustfmt rust-analyzer cargo clippy vscode openssl.dev pkg-config gfortran ];
}
