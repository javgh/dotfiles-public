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
    };

    swraid.mdadmConf = ''
      DEVICE /dev/mapper/nvme0n1p2+integrity
      DEVICE /dev/mapper/nvme1n1p2+integrity
    '';

    tmp = {
      useTmpfs = true;
      tmpfsSize = "75%";
      cleanOnBoot = true;
    };

    kernelModules = [ "nct6775" ];  # found via 'sensors-detect'; see also 'sensors'
    supportedFilesystems = [ "cifs" ];

    # activate to build aarch64 targets; see https://nixos.wiki/wiki/NixOS_on_ARM
    #binfmt.emulatedSystems = [ "aarch64-linux" ];
  };

  hardware = {
    # Do not rely on BIOS for latest microcode.
    # Check with spectre-meltdown-checker.
    cpu.intel.updateMicrocode = true;

    pulseaudio = {
      enable = true;
      package = pkgs.pulseaudioFull;
    };

    sane = {
      enable = true;
      extraBackends = [ pkgs.hplipWithPlugin ];
    };

    bluetooth.enable = true;
    rtl-sdr.enable = true;

    opengl = {
      setLdLibraryPath = true;   # needed for CUDA
      driSupport32Bit = true;    # needed for docker.enableNvidia
    };
  };

  networking = {
    hostName = "dax";
    firewall.enable = false;
    networkmanager.enable = true;
    extraHosts = builtins.readFile /home/jan/.hosts;

    wg-quick.interfaces = {
      wg0 = {
        autostart = true;
        address = [ "10.10.0.1/32" ];
        privateKeyFile = "/home/jan/.wireguard/intranet/private_key";
        peers = import /home/jan/.wireguard/intranet/peers.nix;
        # template for peers.nix:
        # [
        #   {
        #     endpoint = "...:51820";
        #     publicKey = "...";
        #     allowedIPs = [ "10.10.0.0/24" ];
        #     persistentKeepalive = 25;
        #   }
        # ]
      };

      wg1 = {
        autostart = false;
        address = [ "192.168.0.5/32" ];
        privateKeyFile = "/home/jan/.wireguard/olegeno/private_key";
        peers = [
          {
            endpoint = "195.201.27.235:51820";
            publicKey = "+iE+VPhY1dDASMj6c5nzQO4NvvVpMPAEuxYmPX54ewk=";
            allowedIPs = [
              "192.168.0.0/24"
              "192.168.2.0/24"
              "192.168.1.196/32"
              "192.168.3.0/24"
            ];
          }
        ];
      };
    };
  };

  i18n = {
    defaultLocale = "de_DE.UTF-8";
  };

  console = {
    font = "Lat2-Terminus16";
    keyMap = "de-latin1";
  };

  fonts = {
    enableDefaultPackages = true;
    packages = with pkgs; [
      corefonts
      liberation_ttf
      noto-fonts
    ];
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
    pulseaudio = true;
  };

  environment = {
    homeBinInPath = true;

    systemPackages = with pkgs; [
      aichat
      anki
      aria
      asciinema
      bc
      beancount
      binutils
      blender
      blueman
      borgbackup
      brave
      cadaver
      charles
      chromium
      croc
      cryptsetup
      ctags
      cudaPackages.cudatoolkit
      cudaPackages.cudnn
      delve
      dmenu
      dmidecode
      dnsutils
      dos2unix
      drawio
      dropbox
      electrum
      emacs
      encfs
      enscript
      evince
      fava
      feh
      file
      firefox
      geeqie
      getmail6
      gimp
      git
      glxinfo
      gnome.gedit
      gnumake
      gnumeric
      go
      go-ethereum
      golangci-lint
      golint
      gpodder
      gqrx
      graphviz
      hexchat
      htop
      httplz
      i3status
      imagemagick
      inkscape
      inotify-tools
      jetbrains.idea-community
      jetbrains.jdk
      jq
      keepassxc
      kicad
      kiwix
      leiningen
      lftp
      librecad
      libreoffice
      lm_sensors
      monero
      mplayer
      mpv
      msmtp
      mutt
      nbd
      ncdu
      nextcloud-client
      nix-prefetch-git
      nodejs
      nodePackages.node2nix
      nodePackages.stylelint
      offlineimap
      openssl
      par2cmdline
      pasystray
      patchelf
      pavucontrol
      pdftk
      pshs
      qemu
      redshift
      remind
      rlwrap
      rtl-sdr
      ruby
      screen
      shellcheck
      signal-desktop
      simple-scan
      smartmontools
      solc
      solvespace
      spotify
      termite
      texlive.combined.scheme-full
      tor
      tor-browser-bundle-bin
      unzip
      vanilla-dmz       # style neutral scalable cursor theme
      vlc
      w3m
      wget
      whois
      wineWowPackages.full    # wow = "Windows on Windows"
      woof
      xorg.xkbcomp
      xorg.xvinfo
      youtube-dl
      zbar
      (python3.withPackages(ps: [
          ps.beancount
          ps.flake8
          ps.google-api-python-client
          ps.jedi
          ps.matplotlib
          ps.nltk
          ps.pandas
          ps.pep8
          ps.pyflakes
          ps.pylint
          ps.qrcode
          ps.requests
          ps.scikitlearn
        ]))
    ];
  };

  programs = {
    vim = {
      package = pkgs.vim-full.customize {
        name = "vim";
        vimrcConfig = {
          customRC = ''
            source ~/.vimrc
          '';
          packages.myPackages = with pkgs.vimPlugins; {
            start = [
              command-t
              jedi-vim
              supertab
              syntastic
              taglist-vim
              vimagit
              vim-beancount
              vim-dispatch
              vim-fireplace
              vim-gitgutter
              vim-go
              vim-javascript
              vim-latex-live-preview
              vim-projectionist
              vim-salve
              vim-solidity
              vim-surround
            ];
          };
        };
      };
      defaultEditor = true;
    };

    bash = {
      enableCompletion = true;
      vteIntegration = true;
    };

    fzf = {
      keybindings = true;
      fuzzyCompletion = true;
    };

    autojump.enable = true;

    ssh.startAgent = true;

    gnupg.agent.enable = true;

    fuse.userAllowOther = true;

    adb.enable = true;

    _1password-gui.enable = true;
  };

  services = {
    openssh = {
      enable = true;
      settings.PasswordAuthentication = false;
    };

    printing = {
      enable = true;
      drivers = [ pkgs.hplipWithPlugin ];
    };

    avahi = {   # to help find scanner
      enable = true;
      nssmdns = true;
    };

    xserver = {
      enable = true;
      videoDrivers = [ "nvidia" ];
      layout = "de";
      xkbModel = "pc105";
      screenSection =
        ''
          # generated with nvidia-settings; also set configuration via xfce4-display-settings
          Option "nvidiaXineramaInfoOrder" "DFP-3"
          Option "metamodes" "DP-2: 1920x1080_144 +1280+0, DP-0: nvidia-auto-select +0+0, DP-4: nvidia-auto-select +3200+0"
        '';
      displayManager.autoLogin = {
        enable = true;
        user = "jan";
      };
      desktopManager.xfce = {
        enable = true;
        noDesktop = true;
        enableXfwm = false;
      };
      windowManager.i3.enable = true;
    };

    postgresql = {
      enable = true;
      package = pkgs.postgresql_15;
      initialScript = pkgs.writeText "initialScript.sql" ''
        CREATE USER jan;
        CREATE DATABASE playground WITH OWNER jan;
      '';
    };

    #influxdb2.enable = true;

    #grafana = {
    #  enable = true;
    #  settings.server = {
    #    http_addr = "127.0.0.1";
    #    http_port = 3000;
    #  };
    #};

    timesyncd.enable = true;
    acpid.enable = true;
    blueman.enable = true;
    keybase.enable = false;
  };

  virtualisation = {
    virtualbox.host.enable = true;
    docker = {
      enable = true;
      enableNvidia = true;
    };
  };

  users.extraUsers.jan = {  # set password with 'passwd'
    isNormalUser = true;
    uid = 1000;
    extraGroups = [ "wheel" "networkmanager" "cdrom" "lp" "scanner" "vboxusers" "audio" "docker" "adbusers" "dialout" "plugdev" ];
  };

  systemd.shutdown = let
    unloadNvidiaModules = pkgs.writeShellScript "unload-nvidia-modules.shutdown" ''
      # Nvidia kernel modules currently cause this message to appear on shutdown:
      # "Failed to unmount /oldroot/sys: Device or resource busy"
      # This script unloads the Nvidia kernel modules before shutdown
      # to allow for a clean unmount.
      # It might not be needed in the future. To test:
      # Disable the script and check with 'systemctl halt'.

      ${pkgs.kmod}/bin/rmmod nvidia_uvm nvidia_drm nvidia_modeset nvidia
    '';
  in {
    "unload-nvidia-modules.shutdown" = unloadNvidiaModules;
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
