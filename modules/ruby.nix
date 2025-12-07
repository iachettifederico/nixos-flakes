{ config, pkgs, lib, ruby-packages, ... }:

{
  # Install direnv and nix-direnv for automatic environment loading
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # Install bundix globally for converting Gemfile.lock to gemset.nix
  environment.systemPackages = with pkgs; [
    bundix
    direnv
  ];

  # Make Ruby packages available via overlay so direnv can find them
  nixpkgs.overlays = [
    (final: prev: ruby-packages)
  ];
}
