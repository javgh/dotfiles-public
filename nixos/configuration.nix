# Use cfdisk to prepare a GUID partition table (GPT) on the disk:
#   Partition 1: 300M, EFI System, /boot, bootable, mkfs.fat -F 32 -n UEFI1 / UEFI2
#   Partition 2: xG, Linux RAID, integritysetup format, mdadm, mkfs.ext4 -L linux-root
#     pick a round number to make replacing the disk in the RAID array easier
#   Partition 3: remaining free space, Linux swap, mkswap -L swap1 / swap2
# See doc/raid+integrity for RAID details.

{ config, pkgs, ... }:

{
  #nix.nixPath = [
  #  "/home/jan/repos" "nixos-config=/etc/nixos/configuration.nix"
  #];

  imports = [ /etc/nixos/hardware-configuration.nix ];

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot";
      };
    };

    initrd = {
      availableKernelModules = [ "dm_integrity" ];
      extraUtilsCommands = ''
        copy_bin_and_libs ${pkgs.cryptsetup}/bin/integritysetup
      '';
      postDeviceCommands = ''
        integritysetup open /dev/nvme0n1p2 nvme0n1p2+integrity
        integritysetup open /dev/nvme1n1p2 nvme1n1p2+integrity
        mdadm --stop --scan  # start with a clean slate
        mdadm --assemble --scan --run
      '';
      mdadmConf = ''
        DEVICE /dev/mapper/nvme0n1p2+integrity
        DEVICE /dev/mapper/nvme1n1p2+integrity
      '';
    };

    supportedFilesystems = [ "cifs" ];
    cleanTmpDir = true;
  };

  hardware = {
    # Do not rely on BIOS for latest microcode.
    # Check with spectre-meltdown-checker.
    cpu.intel.updateMicrocode = true;

    pulseaudio.enable = true;

    sane = {
      enable = true;
      extraBackends = [ pkgs.hplipWithPlugin ];
    };

    bluetooth.enable = true;
  };

  networking = {
    hostName = "dax";
    firewall.enable = false;
    networkmanager.enable = true;
    extraHosts = builtins.readFile "/home/jan/.hosts";
  };

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

  nixpkgs.config = {
    allowUnfree = true;
    #chromium.enablePepperFlash = true;
    pulseaudio = true;
    packageOverrides = _pkgs: {   # take the set of all packages and
                                  # return a set of modified packages
      vimHugeX = _pkgs.vimHugeX.override { python = _pkgs.python3; };
    };
  };

  environment.systemPackages = with pkgs; [
    anki
    aria
    asciinema
    autojump
    bc
    beancount
    binutils
    blueman
    borgbackup
    chromium
    cryptsetup
    ctags
    curlftpfs
    delve
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
    go
    go-ethereum
    golangci-lint
    gpodder
    graphviz
    hexchat
    htop
    i3
    i3status
    imagemagick
    inkscape
    inotify-tools
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
    mpv
    msmtp
    mutt
    nbd
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
    qemu
    redshift
    remind
    rlwrap
    ruby
    screen
    signal-desktop
    simplenote
    simple-scan
    smartmontools
    solc
    spotify
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
    vimPlugins.vim-go
    vimPlugins.vim-javascript
    vlc
    w3m
    wget
    whois
    xorg.xkbcomp
    xorg.xvinfo
    youtube-dl
    zbar
    (python3.withPackages(ps: [
        ps.beancount
        ps.flake8
        ps.google_api_python_client
        ps.jedi
        ps.matplotlib
        ps.nltk
        ps.pep8
        ps.pyflakes
        ps.pylint
        ps.requests
        ps.scikitlearn
      ]))
  ];

  programs = {
    bash = {
      enableCompletion = true;
      interactiveShellInit = ''
        export VTE_NG_PATH="${pkgs.gnome3.vte-ng}"
        export AUTOJUMP_PATH="${pkgs.autojump}"
      '';
    };

    ssh = {
      startAgent = true;
      agentTimeout = "2h";
    };
  };

  services = {
    #openssh.enable = true;

    printing = {
      enable = true;
      drivers = [ pkgs.hplipWithPlugin ];
    };

    xserver = {
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

    autofs = {
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

    ntp.enable = true;
  };

  virtualisation = {
    #virtualbox.host.enable = true;
    #docker.enable = true;
  };

  users.extraUsers.jan = {  # set password with 'passwd'
    isNormalUser = true;
    uid = 1000;
    extraGroups = [ "wheel" "networkmanager" "cdrom" "lp" "scanner" "vboxusers" "audio" "docker" ];
  };

  security.sudo = {
    #wheelNeedsPassword = false;
    extraConfig =
      ''

        # Ask for root password and remember it for a while.
        Defaults rootpw
        Defaults timestamp_timeout=360
      '';
  };

  system = {
    stateVersion = "19.03";

    activationScripts.sync-boot-fallback = ''
      echo "syncing /boot and /boot-fallback..."
      ${pkgs.rsync}/bin/rsync -a --delete /boot/ /boot-fallback
    '';
  };
}
