{ pkgs, lib, ... }:

{
  imports = [ ./common.nix ];

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/fb4b727a-c33a-479b-bba6-292f3faf5795";
      fsType = "ext4";
    };

    "/boot" = {
      device = "/dev/disk/by-uuid/AB65-FB79";
      fsType = "vfat";
    };
  };

  swapDevices = [
    { device = "/dev/disk/by-uuid/7331a140-5df1-4c9c-b4b0-68ef45db89d8"; }
  ];

  boot = {
    initrd = {
      availableKernelModules = [
        "nvme"
        "sd_mod"
        "thunderbolt"
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
      '';
    };

    kernelModules = [ "kvm-amd" ];
  };

  # Do not rely on BIOS for latest microcode.
  hardware.cpu.amd.updateMicrocode = true;

  networking = {
    hostName = "sulu";

    wg-quick.interfaces = {
      wg0.address = [ "10.10.0.2/32" ];
      wg1.address = [ "192.168.0.8/32" ];
    };
  };

  programs.steam = {
    enable = true;
    extraCompatPackages = with pkgs; [ proton-ge-bin ];
  };

  services = {
    #openssh.enable = true;
    fprintd.enable = true;
    fwupd.enable = true;
  };

  systemd.services = {
    wireguard-mtu-workaround = let
      wireguard-mtu-workaround-script = pkgs.writeShellScript "wireguard-mtu-workaround" ''
        echo 1400 > /sys/class/net/wg0/mtu
      '';
    in {
      description = "lower mtu for wireguard interface as a workaround for ssh connection problems";
      after = [ "multi-user.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${wireguard-mtu-workaround-script}";
        User = "root";
      };
    };
  };

  system.stateVersion = "23.11";

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
