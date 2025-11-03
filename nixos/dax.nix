# Use cfdisk to prepare a GUID partition table (GPT) on the disk:
#   Partition 1: 300M, EFI System, /boot, bootable, mkfs.fat -F 32 -n UEFI1 / UEFI2
#   Partition 2: 1800G, Linux RAID, integritysetup format, mdadm, mkfs.ext4 -L linux-root
#     pick a round number to make replacing the disk in the RAID array easier
#   Partition 3: remaining free space, Linux swap, mkswap -L swap1 / swap2
# See doc/raid+integrity for RAID details.

{ pkgs, ... }:

{
  imports = [ ./common.nix ];

  nix.settings.max-jobs = 4;

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/7d557d88-7bec-4cbe-8665-82968c79ec7b";
      fsType = "ext4";
    };

    "/boot" = {
      device = "/dev/disk/by-uuid/A356-582E";
      fsType = "vfat";
      options = [ "nofail" ];   # not a hard requirement for system startup
    };

    "/boot-fallback" = {
      device = "/dev/disk/by-uuid/0D30-00C2";
      fsType = "vfat";
      options = [ "nofail" ];   # not a hard requirement for system startup
    };
  };

  swapDevices = [
    { device = "/dev/disk/by-uuid/bfab7c28-95dc-4f66-90b6-3ee1fafa1b70"; options = [ "nofail" ]; }
    { device = "/dev/disk/by-uuid/701936ff-c4f2-496f-b1ab-3703a89ca847"; options = [ "nofail" ]; }
  ];  # swap should also not be a hard requirement for system startup

  boot = {
    initrd = {
      availableKernelModules = [
        "ahci"
        "nvme"
        "sd_mod"
        "sr_mod"
        "thunderbolt"
        "usbhid"
        "usb_storage"
        "xhci_pci"
      ] ++ [
        "dm_integrity"
      ];

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

    kernelModules = [
      "kvm-amd"
      #"nct6775"     # found via 'sensors-detect'; see also 'sensors'
    ];

    supportedFilesystems = [ "cifs" ];

    # activate to build aarch64 targets; see https://nixos.wiki/wiki/NixOS_on_ARM
    #binfmt.emulatedSystems = [ "aarch64-linux" ];
  };

  hardware = {
    # Do not rely on BIOS for latest microcode.
    # Check with spectre-meltdown-checker.
    cpu.amd.updateMicrocode = true;

    sane = {
      enable = true;
      extraBackends = [ pkgs.hplipWithPlugin ];
    };

    nvidia.open = true;
  };

  networking = {
    hostName = "dax";
    extraHosts = builtins.readFile /home/jan/.hosts;

    wg-quick.interfaces = {
      wg0.address = [ "10.10.0.1/32" ];
      wg1.address = [ "192.168.0.5/32" ];
    };
  };

  programs.steam = {
    enable = true;
    extraCompatPackages = with pkgs; [ proton-ge-bin ];
  };

  services = {
    openssh = {
      enable = true;
      settings.PasswordAuthentication = false;
    };

    xserver = {
      videoDrivers = [ "nvidia" ];
      screenSection =
        ''
          # generated with nvidia-settings; also set configuration via xfce4-display-settings
          Option "nvidiaXineramaInfoOrder" "DFP-3"
          Option "metamodes" "DP-2: 1920x1080_144 +1280+0, DP-0: nvidia-auto-select +0+0, DP-4: nvidia-auto-select +3200+0"
        '';
    };

    postgresql = {
      enable = true;
      package = pkgs.postgresql_15;
      initialScript = pkgs.writeText "initialScript.sql" ''
        CREATE USER jan;
        CREATE DATABASE playground WITH OWNER jan;
      '';
    };

    influxdb2.enable = true;

    #grafana = {
    #  enable = true;
    #  settings.server = {
    #    http_addr = "127.0.0.1";
    #    http_port = 3000;
    #  };
    #};
  };

  system = {
    stateVersion = "19.03";

    activationScripts.sync-boot-fallback = ''
      echo "syncing /boot and /boot-fallback..."
      ${pkgs.rsync}/bin/rsync -a --delete /boot/ /boot-fallback
    '';
  };
}
