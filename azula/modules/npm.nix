{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    git
    openssl
    zlib
    readline
    libyaml
    autoconf
    bison
    pkg-config
    python3
    (pkgs.writeShellScriptBin "python" ''
      exec ${pkgs.python3}/bin/python3 "$@"
    '')
    gcc
    gnumake
    gnupg
  ];

  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc
      zlib
      openssl
      libyaml
      readline
      gmp
      libxcrypt

      glib
      nspr
      nss
      dbus
      expat
      libdrm

      libX11
      libXcomposite
      libXcursor
      libXdamage
      libXext
      libXfixes
      libXi
      libXrandr
      libXrender
      libXtst
      libxcb

      alsa-lib
      at-spi2-atk
      at-spi2-core
      atk
      cairo
      cups
      pango
      gdk-pixbuf
      gtk3
      libxkbcommon
      fontconfig
      freetype

      mesa
      libgbm
    ];
  };

}
