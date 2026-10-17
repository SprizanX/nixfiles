{ ... }:

# The windows install on this machine owns its own 200mb efi system partition and
# must not be touched. Create a separate 1gb esp for nixos and fill in the uuids
# below after partitioning; `lsblk -o NAME,SIZE,FSTYPE,UUID` lists them.
#
# partitioning recipe, run from the nixos installer (device is /dev/nvme0n1):
#
#   sgdisk --new=0:0:+1G --typecode=0:EF00 --change-name=0:NIXOS-ESP /dev/nvme0n1
#   mkfs.fat -F 32 -n NIXOS-ESP /dev/nvme0n1p<new esp>
#   sgdisk --new=0:0:0   --typecode=0:8300 --change-name=0:NIXOS-ROOT /dev/nvme0n1
#   mkfs.btrfs -L nixos /dev/nvme0n1p<new root>
#
# btrfs subvolumes are optional, the config only needs / and /boot and a swapfile
{
  den.aspects.sprizan-fs.nixos = {
    fileSystems = {
      "/" = {
        # TODO: replace with the real uuid of the nixos root partition
        device = "/dev/disk/by-uuid/00000000-0000-0000-0000-000000000001";
        fsType = "btrfs";
        options = [
          "compress=zstd"
          "noatime"
        ];
      };

      "/boot" = {
        # TODO: replace with the real uuid of the nixos esp
        device = "/dev/disk/by-uuid/0000-0000";
        fsType = "vfat";
        options = [
          "fmask=0077"
          "dmask=0077"
        ];
      };
    };

    # no swapfile here: memory.nix enables zramSwap, and btrfs swapfiles need
    # `chattr +C` to work, which nixos does not do for you
  };
}
