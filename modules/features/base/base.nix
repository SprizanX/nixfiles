{ den, lib, ... }:

{
  den.aspects.base = {
    settings = {
      hasDisplay = lib.mkEnableOption "Whether the host has a display";

      primaryUser = lib.mkOption {
        type = lib.types.str;
        default = "sans";
        description = "Primary user for permissions and defaults.";
      };

      tz = lib.mkOption {
        type = lib.types.str;
        default = "Europe/Moscow";
        description = "The timezone of the machine.";
      };

      fs = {
        btrfs = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable btrfs support.";
        };

        zfs = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable zfs support.";
        };
      };

      dockerDNS = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "DNS servers to use for docker";
      };

      dockerStorageDriver = lib.mkOption {
        type = lib.types.enum [
          "btrfs"
          "overlay2"
        ];
        default = "overlay2";
        description = "Docker storage driver for the filesystem backing /var/lib/docker.";
      };

      useZen = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Use the zen kernel.";
      };

      useCachy = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Use the cachix nixos module.";
      };
    };

    includes = [
      den.aspects.boot
      den.aspects.bluetooth
      den.aspects.cli
      den.aspects.memory
      den.aspects.networking
      den.aspects.nix-config
      den.aspects.root
      den.aspects.security
      den.aspects.style
      den.aspects.virtualisation
      den.aspects.virtualisation._.containers

      den.aspects.ssh
    ];

    nixos =
      {
        inputs',
        host,
        pkgs,
        ...
      }:
      let
        cfg = host.settings.base;
      in
      {
        time.timeZone = lib.mkDefault cfg.tz;

        # nixos-native user management
        services.userborn.enable = true;

        boot.kernelPackages =
          let
            kernel =
              if cfg.useCachy then
                inputs'.chaotic.legacyPackages.linuxPackages_cachyos
              else if cfg.useZen then
                pkgs.linuxPackages_zen
              else
                pkgs.linuxPackages;
          in
          kernel;

        # defaults
        hardware.enableRedistributableFirmware = lib.mkDefault true;
        services.dbus.implementation = "broker";
        services.zfs.autoScrub.enable = lib.mkDefault cfg.fs.zfs;
        services.geoclue2.enable = lib.mkDefault true;
        services.gvfs.enable = lib.mkDefault true;
        services.irqbalance.enable = lib.mkDefault true;
        services.zfs.autoSnapshot.enable = lib.mkDefault cfg.fs.zfs;
        i18n.defaultLocale = "en_US.UTF-8";
        i18n.extraLocales = [
          "en_US.UTF-8/UTF-8"
          "ru_RU.UTF-8/UTF-8"
        ];

        # docker changes
        virtualisation.docker = {
          # fix	dns
          daemon.settings = {
            dns = lib.mkIf (builtins.length cfg.dockerDNS > 0) cfg.dockerDNS;
            metrics-addr = "0.0.0.0:9323";
          };

          storageDriver = cfg.dockerStorageDriver;
        };

        # for interacting with qmk keyboards + etc
        users.groups.plugdev = { };

        environment.systemPackages =
          with pkgs;
          [
            lm_sensors
            man-pages
            man-pages-posix
            powertop
          ]
          ++ lib.optionals cfg.fs.btrfs [ btrfs-progs ];

        # fix shutdown taking a long time
        # https://gist.github.com/worldofpeace/27fcdcb111ddf58ba1227bf63501a5fe
        # TODO: do we need this?
        # systemd.settings.Manager = {
        #   DefaultTimeoutStopSec = "10s";
        #   DefaultTimeoutStartSec = "10s";
        # };
      };

    homeManager = {
      home.language.base = "en_US.UTF-8";

      systemd.user.startServices = "sd-switch";

      # install home-manager docs
      manual = {
        html.enable = true;
        json.enable = lib.mkDefault true;
      };
    };
  };
}
