{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    mise
    git

    # build deps for compiling Ruby via mise
    openssl
    zlib
    readline
    libyaml
    autoconf
    bison
    pkg-config
  ];

  environment.variables.MISE_DATA_DIR = "/home/fedex/.local/share/mise";

  environment.interactiveShellInit = ''
    if [ -x "${pkgs.mise}/bin/mise" ]; then
      eval "$(${pkgs.mise}/bin/mise activate posix)"
    fi
  '';

  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc  # glibc, libstdc++, etc
      zlib
      openssl
      libyaml
      readline
      gmp
      libxcrypt
    ];
  };
}
