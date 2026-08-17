{ pkgs, ... }:

let
  my-i3 = pkgs.i3.overrideAttrs (oldAttrs: {
    version = "4.25-25-g9be3249a";
    src = pkgs.fetchFromGitHub {
      owner = "i3";
      repo = "i3";
      rev = "9be3249a";  # need version that includes this commit
      hash = "sha256-1oQg5vaAeUPmpGpvHnTNUYabE+xi6VF2//70mmMzVv8=";
    };
    postPatch = ''
      patchShebangs .
    '';
  });
in {
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
    enableAllFirmware = true;
    bluetooth.enable = true;
    rtl-sdr.enable = true;
  };

  networking = {
    firewall.enable = false;
    networkmanager = {
      enable = true;
      plugins = [
        pkgs.networkmanager-openvpn
      ];
    };

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
      ubuntu-classic
    ];
  };

  time.timeZone = "Europe/Berlin";

  nixpkgs.config = {
    allowUnfree = true;
    permittedInsecurePackages = [ "python3.12-ecdsa-0.19.1" ];
  };

  environment = {
    homeBinInPath = true;

    systemPackages = with pkgs; [
      alacritty
      android-tools
      anki
      anydesk
      asciinema
      bc
      beancount
      beancount-language-server
      beanquery
      binutils
      blender
      blueman
      borgbackup
      brave
      cadaver
      cargo
      cargo-outdated
      charles
      clang-tools
      clippy
      clojure-lsp
      croc
      cryptsetup
      ctags
      delve
      dmenu
      dmidecode
      dmtx-utils
      dnsutils
      dos2unix
      dracut
      drawio
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
      gnumake
      gnumeric
      go
      go-ethereum
      golangci-lint
      golint
      google-chrome
      gopls
      gpodder
      gqrx
      graphviz
      hexchat
      htop
      #httplz
      i3status
      imagemagick
      inkscape
      inotify-tools
      jdt-language-server
      jetbrains.jdk
      jq
      keepassxc
      kicad
      kiwix
      krita
      lean4
      leiningen
      lftp
      libnotify
      librecad
      libreoffice
      linuxPackages.cpupower
      lm_sensors
      lua-language-server
      mesa-demos
      monero-cli
      mplayer
      mpv
      msmtp
      mutt
      nbd
      ncdu
      nethack
      nettools
      nextcloud-client
      nftables
      nixd
      nix-prefetch-git
      nmap
      nodejs
      nvtopPackages.full
      offlineimap
      openssl
      par2cmdline
      pasystray
      patchelf
      pavucontrol
      pdftk
      poppler-utils
      pshs
      pv
      pyright
      qemu
      syncthingtray
      redshift
      remind
      ripgrep
      rlwrap
      rtl-sdr
      ruby
      ruff
      rust-analyzer
      rustc
      rustfmt
      scrcpy
      screen
      shellcheck
      signal-desktop
      simple-scan
      smartmontools
      solc
      solvespace
      spotify
      syncthing
      texlive.combined.scheme-full
      tor
      tor-browser
      typescript
      typescript-language-server
      unzip
      vanilla-dmz       # style neutral scalable cursor theme
      visidata
      vlc
      vscode-langservers-extracted
      w3m
      webpack-cli
      wget
      whois
      wineWow64Packages.full    # wow = "Windows on Windows"
      wireshark
      xclip
      xev
      xkbcomp
      xvinfo
      yarn
      yt-dlp
      zbar
      (python3.withPackages(ps: [
          ps.beancount
          ps.beanquery
          ps.dbus-next
          ps.flake8
          ps.google-api-python-client
          ps.jedi
          ps.jupytext
          ps.kokoro
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
          ps.scikit-learn
          ps.seaborn
          ps.spacy-models.en_core_web_sm    # for kokoro
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

    fzf = {
      keybindings = true;
      fuzzyCompletion = true;
    };

    bash.completion.enable = true;

    autojump.enable = true;

    ssh.startAgent = true;

    gnupg.agent.enable = true;

    fuse.userAllowOther = true;

    _1password-gui.enable = true;
  };

  services = {
    pipewire = {
      enable = true;
      audio.enable = true;
      pulse.enable = true;

      alsa = {
        enable = true;
        support32Bit = true;
      };
    };

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
      windowManager.i3 = {
        enable = true;
        package = my-i3;
      };
    };

    displayManager.autoLogin = {
      enable = true;
      user = "jan";
    };

    gnome.gcr-ssh-agent.enable = false;

    timesyncd.enable = true;
    acpid.enable = true;
    blueman.enable = true;
  };

  virtualisation = {
    virtualbox.host.enable = true;
    docker.enable = true;
  };

  users.extraUsers.jan = {  # set password with 'passwd'
    isNormalUser = true;
    uid = 1000;
    extraGroups = [
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

  security = {
    sudo = {
      #wheelNeedsPassword = false;
      extraConfig =
        ''

          # Ask for root password and remember it for a while.
          Defaults rootpw
          Defaults timestamp_timeout=360
        '';
    };

    rtkit.enable = true;     # allow realtime priority for PulseAudio/PipeWire
  };
}
