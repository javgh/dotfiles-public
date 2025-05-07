{ pkgs, ... }:

{
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot";
      };
    };

    tmp = {
      useTmpfs = true;
      tmpfsSize = "75%";
      cleanOnBoot = true;
    };
  };

  hardware = {
    enableRedistributableFirmware = true;

    pulseaudio = {
      enable = true;
      package = pkgs.pulseaudioFull;
    };

    bluetooth.enable = true;
    rtl-sdr.enable = true;
  };

  networking = {
    firewall.enable = false;
    networkmanager.enable = true;

    wg-quick.interfaces = {
      wg0 = {
        autostart = true;
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
              "192.168.4.0/24"
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
      comfortaa
      ubuntu_font_family
    ];
  };

  time.timeZone = "Europe/Berlin";

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
      beancount-language-server
      binutils
      blender
      blueman
      borgbackup
      brave
      cadaver
      charles
      chromium
      clang-tools
      clojure-lsp
      croc
      cryptsetup
      ctags
      delve
      dmenu
      dmidecode
      dnsutils
      dos2unix
      drawio
      dropbox
      efibootmgr
      electrum
      emacs
      encfs
      enscript
      evince
      fava
      feh
      file
      firefox
      gcc
      gedit
      geeqie
      getmail6
      gimp
      git
      glxinfo
      gnumake
      gnumeric
      go
      go-ethereum
      golangci-lint
      golint
      gopls
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
      jdt-language-server
      jetbrains.idea-community
      jetbrains.jdk
      jq
      keepassxc
      kicad
      kiwix
      krita
      leiningen
      lftp
      librecad
      libreoffice
      lm_sensors
      lua-language-server
      monero-cli
      mplayer
      mpv
      msmtp
      mutt
      nbd
      ncdu
      nextcloud-client
      nftables
      nixd
      nix-prefetch-git
      nmap
      nodejs
      nodePackages.node2nix
      nodePackages.stylelint
      nvtopPackages.full
      offlineimap
      openssl
      par2cmdline
      pasystray
      patchelf
      pavucontrol
      pdftk
      pshs
      pv
      pyright
      qemu
      redshift
      remind
      ripgrep
      rlwrap
      rtl-sdr
      ruby
      ruff
      ruff-lsp
      scrcpy
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
      visidata
      vlc
      w3m
      wget
      whois
      wineWowPackages.full    # wow = "Windows on Windows"
      wireshark
      woof
      xclip
      xorg.xev
      xorg.xkbcomp
      xorg.xvinfo
      yarn
      yt-dlp
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
          ps.pynvim
          ps.pyxdg
          ps.qrcode
          ps.requests
          ps.scikitlearn
          ps.seaborn
        ]))
    ];
  };

  programs = {
    neovim = {
      enable = true;
      configure = {
        customRC = ''
          luafile ~/.config/nvim/init.lua
        '';
        packages.myPackages = with pkgs.vimPlugins; {
          start = [ lazy-nvim ];
        };
      };
      defaultEditor = true;
      viAlias = true;
      vimAlias = true;
    };

    bash = {
      completion.enable = true;
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
    printing = {
      enable = true;
      drivers = [ pkgs.hplipWithPlugin ];
    };

    avahi = {   # to help find scanner
      enable = true;
      nssmdns4 = true;
    };

    xserver = {
      enable = true;
      xkb = {
        layout = "de";
        model = "pc105";
      };
      desktopManager.xfce = {
        enable = true;
        noDesktop = true;
        enableXfwm = false;
      };
      windowManager.i3.enable = true;
    };

    displayManager.autoLogin = {
      enable = true;
      user = "jan";
    };

    timesyncd.enable = true;
    acpid.enable = true;
    blueman.enable = true;
    pipewire.enable = false;
  };

  virtualisation = {
    virtualbox.host.enable = true;
    docker.enable = true;
  };

  users.extraUsers.jan = {  # set password with 'passwd'
    isNormalUser = true;
    uid = 1000;
    extraGroups = [
      "adbusers"
      "audio"
      "cdrom"
      "dialout"
      "docker"
      "lp"
      "networkmanager"
      "plugdev"
      "scanner"
      "vboxusers"
      "wheel"
    ];
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
}
