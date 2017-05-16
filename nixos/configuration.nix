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
      efiPartition = 2;	       # 250 MB
    };
  };
  boot.cleanTmpDir = true;

  networking.hostName = "dax"; # Define your hostname.
  networking.networkmanager.enable = true;

  # Select internationalisation properties.
  i18n = {
    consoleFont = "Lat2-Terminus16";
    consoleKeyMap = "de";
    defaultLocale = "de_DE.UTF-8";
  };

  # Set your time zone.
  time.timeZone = "Europe/Berlin";

  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [
    autojump
    bc
    beancount
    chromium
    ctags
    dmenu
    dropbox
    encfs
    evince
    file
    firefox
    gimp
    git
    glxinfo
    gnome3.gedit
    htop
    i3
    keepassx
    lftp
    lm_sensors
    mplayer
    nix-prefetch-git
    nix-repl
    patchelf
    spotify
    unzip
    vanilla-dmz       # style neutral scalable cursor theme
    vimHugeX
    wget
    xorg.xkbcomp
    xorg.xvinfo
  ];

  # Enable bash completion.
  programs.bash.enableCompletion = true;

  # Tweak sudo.
  security.sudo.wheelNeedsPassword = false;
  #security.sudo.extraConfig =
  #  ''

  #    # Ask for root password and remember it for a while.
  #    Defaults rootpw
  #    Defaults timestamp_timeout=360
  #  '';


  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  networking.firewall.enable = false;

  # Enable CUPS to print documents.
  services.printing = {
    enable = true;
    drivers = [ pkgs.hplip ];
  };

  # Enable the X11 windowing system.
  services.xserver = {
    enable = true;
    videoDrivers = [ "nvidia" ];
    layout = "de";
    xkbModel = "pc105";
    screenSection =
      ''
        Option "metamodes" "1920x1080_144 +0+0"
      '';
    displayManager.slim.enable = true;
    desktopManager.xfce = {
      enable = true;
      noDesktop = true;
      enableXfwm = false;
      extraSessionCommands = "i3";
    };
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.extraUsers.jan = {
    isNormalUser = true;
    uid = 1000;
    extraGroups = [ "wheel" "networkmanager" ];
  };

  # The NixOS release to be compatible with for stateful data such as databases.
  system.stateVersion = "17.03";
}
