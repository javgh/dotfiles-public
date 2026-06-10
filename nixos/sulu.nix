# Use cfdisk to prepare a GUID partition table (GPT) on the disk:
#   /dev/nvme0n1p1       2048     616447     614400   300M EFI-System
#   /dev/nvme0n1p2     616448 1814652927 1814036480   865G Linux RAID
#   /dev/nvme0n1p3 1814652928 3628689407 1814036480   865G Linux RAID
#   /dev/nvme0n1p4 3628689408 3907028991  278339584 132,7G Linux Swap
# See doc/raid+integrity for RAID details.
# Use cryptsetup {luksFormat,luksDump} to configure and check encryption.
{ pkgs, lib, utils, ... }:

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
    { device = "/dev/disk/by-uuid/af0a91b3-40a5-42fb-a7cb-404e2cfb0f5e"; options = [ "nofail" ]; }
  ];  # swap should not be a hard requirement for system startup

  boot = {
    initrd = {
      availableKernelModules = [
        "nvme"
        "sd_mod"
        "thunderbolt"
        "usb_storage"
        "xhci_pci"
      ] ++ [
        "aes"
        "cbc"
        "crc32c"
        "dm_crypt"
        "dm_integrity"
        "dm_mod"
        "encrypted_keys"
        "hmac"
        "rng"
        "sha256"
        "trusted"
      ];

      systemd =
        let
          pre-raid-integritysetup-script = pkgs.writeShellScript "pre-raid-integritysetup" ''
            integritysetup open /dev/nvme0n1p2 nvme0n1p2+integrity
            integritysetup open /dev/nvme0n1p3 nvme0n1p3+integrity
          '';
          nvme0n1p2-device = "${utils.escapeSystemdPath "/dev/nvme0n1p2"}.device";
          nvme0n1p3-device = "${utils.escapeSystemdPath "/dev/nvme0n1p3"}.device";
         in {
           initrdBin = [ pkgs.cryptsetup ];
           storePaths = [ pre-raid-integritysetup-script ];
           services = {
             pre-raid-integritysetup = {
               description = "pre-raid-integritysetup";
               requires = [ nvme0n1p2-device nvme0n1p3-device ];
               after = [ nvme0n1p2-device nvme0n1p3-device ];
               before = [ "cryptsetup-pre.target" "shutdown.target" ];
               wants = [ "cryptsetup-pre.target" ];
               wantedBy = [ "initrd.target" ];
               conflicts = [ "shutdown.target" ];
               unitConfig.DefaultDependencies = false;  # avoid surprise ordering in initrd
                                                        # shutdown.target added as per 'man 7 systemd.special'
               serviceConfig = {
                 Type = "oneshot";
                 RemainAfterExit = true;
                 WorkingDirectory="/";
                 ExecStart = "${pre-raid-integritysetup-script}";
               };
             };
           };
         };

      luks.devices = {
        mirrored_decrypted = {
          device = "/dev/md/mirrored";
        };

        nvme0n1p4_decrypted = {
          device = "/dev/nvme0n1p4";
        };
      };
    };

    swraid = {
      enable = true;
      mdadmConf = ''
        PROGRAM /bin/true
        DEVICE /dev/mapper/nvme0n1p2+integrity
        DEVICE /dev/mapper/nvme0n1p3+integrity
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
    libinput.touchpad.tapping = false;  # too many accidental clicks

    influxdb2.enable = false;
    grafana = {
      enable = false;
      settings.server = {
        http_addr = "127.0.0.1";
        http_port = 3000;
      };
    };
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
