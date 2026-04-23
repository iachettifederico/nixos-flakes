# sudo nixos-rebuild switch --impure --flake  "/home/fedex/nixos-flakes-toph#toph"

{ config, pkgs, emacs-with-grammars, pkgs-master, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      /etc/nixos/hardware-configuration.nix
    ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Use latest kernel.
  # boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.hostName = "toph";
  networking.networkmanager.enable = true;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  time.timeZone = "America/Argentina/Cordoba";

  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "es_AR.UTF-8";
    LC_IDENTIFICATION = "es_AR.UTF-8";
    LC_MEASUREMENT = "es_AR.UTF-8";
    LC_MONETARY = "es_AR.UTF-8";
    LC_NAME = "es_AR.UTF-8";
    LC_NUMERIC = "es_AR.UTF-8";
    LC_PAPER = "es_AR.UTF-8";
    LC_TELEPHONE = "es_AR.UTF-8";
    LC_TIME = "es_AR.UTF-8";
  };

  services.xserver = {
    enable = true;
    displayManager.lightdm.enable = true; # or greetd, sddm, etc.
    windowManager.i3.enable = true;
  };

  services.xserver.xkb = {
    layout = "us";
    variant = "intl";
  };

  # 3D stack
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # Tell X/Wayland to use NVIDIA
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    open = true;                # 570 series supports the open kernel module
    modesetting.enable = true;
    powerManagement.enable = false;
    nvidiaSettings = true;      # gives you the nvidia-settings GUI
  };

  environment.sessionVariables = {
    PATH = "$HOME/bin:$PATH";
    XCURSOR_THEME = "Adwaita";
    # XCURSOR_SIZE = "24";  # Optional: sets cursor size (common values: 16, 24, 32, 48)
  };

  # Configure console keymap
  console.keyMap = "us-acentos";

  fonts = {
    enableDefaultPackages = true;
    fontconfig.enable = true;

    packages = with pkgs; [
      font-awesome
      inconsolata
      # jetbrains-mono
      source-code-pro
      nerd-fonts.fira-code
    ];

    # Optional but nice: default monospace fonts
    fontconfig.defaultFonts.monospace = [
      # "JetBrains Mono"
      "Source Code Pro"
      "Inconsolata"
    ];
  };

  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.groups.fedex = {
    gid = 1000;
  };

  users.users.fedex = {
    isNormalUser = true;
    description = "Federico Martín Iachetti";
    uid = 1000;
    group = "fedex";  # primary group
    extraGroups = [
      "docker"
      "libvirtd"
      "networkmanager"
      "wheel"
      "users"
    ];
    shell = pkgs.zsh;
    packages = with pkgs; [];
  };

  # Enable automatic login for the user.
  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = "fedex";

  programs.firefox.enable = true;
  programs.zsh.enable = true;

  programs.npm.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [

    # jetbrains-mono

    arandr
    audacity
    bat
    brave
    claude-code
    davinci-resolve
    difftastic
    discord
    docker
    docker-compose
    dunst
    emacs-with-grammars
    entr
    evince
    feh
    ferdium
    ffmpeg
    firefox-devedition
    flameshot
    foliate
    font-awesome
    ghostty
    git
    git-lfs
    github-cli
    gnome-calculator
    gnumake
    godot
    hledger
    hledger-interest
    hledger-ui
    hledger-web
    inconsolata
    jdk21
    jellyfin
    jellyfin-ffmpeg
    jellyfin-media-player
    jellyfin-web
    jq
    kitty
    lazydocker
    ledger
    libnotify
    mc
    mermaid-cli
    nvtopPackages.nvidia
    nemo
    obs-studio
    ollama-cuda
    pkgs-master.opencode
    pandoc
    pavucontrol
    python3Packages.weasyprint
    remmina
    ripgrep
    rofi
    silver-searcher
    slack
    source-code-pro
    tealdeer
    telegram-desktop
    terminator
    tilda
    transmission_4-gtk
    tree
    unzip
    vim
    virtiofsd
    vlc
    xclip
    xhost
    xmodmap

    # Kalkomey
    awscli2
    openvpn
    vault

    config.hardware.nvidia.package
  ];

  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    libyaml
  ];

  virtualisation.docker.rootless = {
    enable = true;
    setSocketVariable = true;

    daemon.settings = {
      # Force sane DNS servers inside containers, often fixes build-time resolution issues.
      dns = [ "1.1.1.1" "8.8.8.8" ];

      experimental = true;
      features = {
        buildkit = true;
      };
    };
  };

  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;
  boot.kernel.sysctl."net.ipv6.ip_forward" = 1;

  security.sudo.extraRules = [
    {
      groups = [ "wheel" ];
      commands = [ { command = "ALL"; options = [ "NOPASSWD" ]; } ];
    }
  ];

  # services.sunshine = {
  #   enable = true;
  #   autoStart = true;
  #   capSysAdmin = true;
  #   openFirewall = true;
  # };

  # Enable the unfree 1Password packages
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (pkgs.lib.getName pkg) [
    "1password-gui"
    "1password"
  ];
  # Alternatively, you could also just allow all unfree packages
  # nixpkgs.config.allowUnfree = true;

  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    # Certain features, including CLI integration and system authentication support,
    # require enabling PolKit integration on some desktop environments (e.g. Plasma).
    polkitPolicyOwners = [ "fedex" ];
  };

  # Ollama AI service (accessible from VMs via virbr0 bridge)
  services.ollama = {
    enable = true;
    package = pkgs.ollama-cuda;
    host = "0.0.0.0";  # Listen on all interfaces including VM bridge
    port = 11434;
    openFirewall = false;  # Don't open to external network
    environmentVariables = {
      OLLAMA_HOST = "0.0.0.0";
      OLLAMA_ORIGINS = "*";
    };
  };

  services.jellyfin = {
    enable = true;
    openFirewall = true;
    user = "fedex";
  };

  services.syncthing = {
    enable = true;
    user = "fedex";
    dataDir = "/home/fedex/.local/share/syncthing";
    configDir = "/home/fedex/.config/syncthing";
    openDefaultPorts = true;
  };

  security.acme = {
    acceptTerms = true;
    defaults.email = "fiachetti@omashu.com";
  };

  services.qdrant = {
    enable = true;
    settings = {
      service = {
        host = "127.0.0.1";
        http_port = 6333;
        grpc_port = 6334;
      };
      storage = {
        storage_path = "/var/lib/qdrant/storage";
      };
    };
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?

}
