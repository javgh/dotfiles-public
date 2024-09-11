# Use cfdisk to prepare a GUID partition table (GPT) on the disk:
#   Partition 1: 300M, EFI System, /boot, bootable, mkfs.fat -F 32 -n UEFI1 / UEFI2
#   Partition 2: xG, Linux RAID, integritysetup format, mdadm, mkfs.ext4 -L linux-root
#     pick a round number to make replacing the disk in the RAID array easier
#   Partition 3: remaining free space, Linux swap, mkswap -L swap1 / swap2
# See doc/raid+integrity for RAID details.

{ lib, ... }:

{
  imports = [ ./common.nix ];

  hardware.enableRedistributableFirmware = true;
  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usbhid" "usb_storage" "sd_mod" "sr_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/7d557d88-7bec-4cbe-8665-82968c79ec7b";
      fsType = "ext4";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/4836-5686";
      fsType = "vfat";
      options = [ "nofail" ];   # not a hard requirement for system startup
    };

  fileSystems."/boot-fallback" =
    { device = "/dev/disk/by-uuid/4447-E87C";
      fsType = "vfat";
      options = [ "nofail" ];   # not a hard requirement for system startup
    };

  swapDevices =
    [ { device = "/dev/disk/by-uuid/53dd1d7d-fceb-430b-9845-c52e5919abd0"; options = [ "nofail" ]; }
      { device = "/dev/disk/by-uuid/31305f5f-04a6-43e4-aba8-56dcedd6173a"; options = [ "nofail" ]; }
    ];  # swap should also not be a hard requirement for system startup

  nix.settings.max-jobs = lib.mkDefault 4;
  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
}
