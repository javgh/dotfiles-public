# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  nix.nixPath = [
    "/home/jan/repos" "nixos-config=/etc/nixos/configuration.nix"
  ];

  imports =
    [ # Include the results of the hardware scan.
      /etc/nixos/hardware-configuration.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi = {
    canTouchEfiVariables = true;
    efibootmgr = {
      efiDisk = "/dev/nvme0n1";
      efiPartition = 2;        # 250 MB
    };
  };

  boot.supportedFilesystems = [ "cifs" ];
  boot.cleanTmpDir = true;

  # Do not rely on BIOS for latest microcode
  hardware.cpu.intel.updateMicrocode = true;

  networking = {
    hostName = "dax";
    firewall.enable = false;
    networkmanager.enable = true;
    extraHosts = builtins.readFile "/home/jan/.hosts";
  };

  # Select internationalisation properties.
  i18n = {
    consoleFont = "Lat2-Terminus16";
    consoleKeyMap = "de";
    defaultLocale = "de_DE.UTF-8";
  };

  time = {
    timeZone = "Europe/Berlin";
    hardwareClockInLocalTime = true;
  };

  sound = {
    enable = true;
    mediaKeys.enable = true;
  };

  hardware.pulseaudio.enable = true;

  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  nixpkgs.config = {
    allowUnfree = true;
    chromium.enablePepperFlash = true;
    pulseaudio = true;
    packageOverrides = _pkgs: {   # take the set of all packages and
                                  # return a set of modified packages
      vimHugeX = _pkgs.vimHugeX.override { python = _pkgs.python3; };
    };
  };

  environment.systemPackages = with pkgs; [
    anki
    aria
    autojump
    bc
    beancount
    binutils
    blueman
    borgbackup
    chromium
    ctags
    curlftpfs
    dmenu
    dnsutils
    dos2unix
    dropbox
    emacs
    encfs
    enscript
    evince
    fava
    feh
    file
    firefox
    geeqie
    getmail
    gimp
    git
    glxinfo
    gnome3.gedit
    gnumake
    gnumeric
    gnupg
    #go-ethereum
    gpodder
    hexchat
    htop
    i2p
    i3
    i3status
    imagemagick
    inkscape
    jetbrains.idea-community
    jetbrains.jdk
    jq
    keepassx
    leiningen
    lftp
    libreoffice
    lm_sensors
    monero
    mplayer
    msmtp
    mutt
    nix-prefetch-git
    nodejs
    nodePackages.node2nix
    offlineimap
    openssl
    par2cmdline
    pasystray
    patchelf
    pavucontrol
    pshs
    rdiff-backup
    redshift
    rlwrap
    screen
    signal-desktop
    simplenote
    simple-scan
    smplayer
    solc
    spotify
    tarsnap
    termite
    texlive.combined.scheme-full
    tor
    torbrowser
    unzip
    vanilla-dmz       # style neutral scalable cursor theme
    vimHugeX
    vimPlugins.command-t
    vimPlugins.gitgutter
    vimPlugins.latex-live-preview
    vimPlugins.Supertab
    vimPlugins.surround
    vimPlugins.Syntastic
    vimPlugins.taglist
    vimPlugins.vim-javascript
    vlc
    w3m
    wget
    whois
    xorg.xkbcomp
    xorg.xvinfo
    zbar
    (python3.withPackages(ps: [
        ps.beancount
        ps.flake8
        ps.google_api_python_client
        ps.jedi
        ps.nltk
        ps.pep8
        ps.pyflakes
        #ps.pylint
        ps.requests
        ps.scikitlearn
      ]))
  ];

  programs.bash = {
    enableCompletion = true;
    interactiveShellInit = ''
      export VTE_NG_PATH="${pkgs.gnome3.vte-ng}"
      export AUTOJUMP_PATH="${pkgs.autojump}"
    '';
  };

  # Start OpenSSH agent.
  programs.ssh = {
    startAgent = true;
    agentTimeout = "2h";
  };

  # Tweak sudo.
  #security.sudo.wheelNeedsPassword = false;
  security.sudo.extraConfig =
    ''

      # Ask for root password and remember it for a while.
      Defaults rootpw
      Defaults timestamp_timeout=360
    '';


  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Enable CUPS to print documents.
  services.printing = {
    enable = true;
    drivers = [ pkgs.hplipWithPlugin ];
  };

  # Enable the X11 windowing system.
  services.xserver = {
    enable = true;
    videoDrivers = [ "nvidia" ];
    layout = "de";
    xkbModel = "pc105";
    screenSection =
      ''
        # generated with nvidia-settings
        Option "nvidiaXineramaInfoOrder" "DFP-6"
        Option "metamodes" "DP-2: nvidia-auto-select +0+0, DP-4: 1920x1080_144 +1280+0, DP-0: nvidia-auto-select +3200+0"
      '';
    displayManager.slim.enable = true;
    desktopManager.xfce = {
      enable = true;
      noDesktop = true;
      enableXfwm = false;
      extraSessionCommands = "i3";
    };
  };

  # Enable autofs.
  services.autofs = {
    enable = true;
    debug = false;
    timeout = 60;
    autoMaster =
      let
        sharecenter = pkgs.writeText "sharecenter" ''
          # vers=1.0 needed to force use of old SMB1 protocol
          sharecenter  -fstype=cifs,vers=1.0,nodev,nosuid,async,uid=jan,gid=users,credentials=/home/jan/.cifsrc,iocharset=iso8859-1    ://192.168.1.7/Volume_1
        '';
        data = pkgs.writeText "data" ''
          # requires /root/.netrc
          data  -fstype=fuse,allow_other    :/run/current-system/sw/bin/curlftpfs\#192.168.1.7
        '';
      in ''
        /var/autofs/cifs  ${sharecenter}  --timeout=60
        /var/autofs/ftp   ${data}         --timeout=60
      '';
  };

  # wait for https://github.com/NixOS/nixpkgs/issues/38627
  #services.ntp.enable = true;

  # Enable SANE for scanning.
  hardware.sane = {
    enable = true;
    extraBackends = [ pkgs.hplipWithPlugin ];
  };

  hardware.bluetooth.enable = true;

  # Enable VirtualBox.
  #virtualisation.virtualbox.host.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.extraUsers.jan = {
    isNormalUser = true;
    uid = 1000;
    extraGroups = [ "wheel" "networkmanager" "cdrom" "lp" "scanner" "vboxusers" "audio" ];
  };

  # The NixOS release to be compatible with for stateful data such as databases.
  system.stateVersion = "17.03";
}
