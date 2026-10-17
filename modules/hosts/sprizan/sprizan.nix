{
  den,
  self,
  inputs,
  ...
}:

{
  den.hosts.x86_64-linux.sprizan = {
    users.sans = { };

    settings = {
      base = {
        hasDisplay = true;
        fs.btrfs = true;
        useCachy = false;
      };

      gpu.nvidia = {
        enable = true;
        open = true;
        driverBranch = "production";
        powerManagement = false;
      };

      # verify the connector names after the first boot with `niri msg outputs`
      # and fix the names/positions/rates here if they differ
      monitors = {
        enable = true;
        monitors = [
          {
            name = "DP-1";
            primary = true;
            width = 2560;
            height = 1440;
            rate = 180.;
            x = 0;
            y = 0;
            workspaces = [
              {
                name = "shell";
                number = 1;
              }
              {
                name = "www";
                number = 2;
              }
              {
                name = "chat";
                number = 3;
              }
              {
                name = "files";
                number = 4;
              }
              {
                name = "five";
                number = 5;
              }
              {
                name = "six";
                number = 6;
              }
            ];
          }
          {
            name = "HDMI-A-1";
            width = 1920;
            height = 1080;
            rate = 60.;
            x = 2560;
            y = 0;
            workspaces = [
              {
                name = "music";
                number = 7;
              }
              {
                name = "r-www";
                number = 8;
              }
              {
                name = "video";
                number = 9;
              }
            ];
          }
          {
            name = "DP-2";
            width = 1080;
            height = 1920;
            rate = 60.;
            x = -1080;
            y = 0;
            workspaces = [
              {
                name = "vertical";
                number = 10;
              }
              {
                name = "eleven";
                number = 11;
              }
            ];
          }
        ];
      };

      audio.devices = [
        {
          name = "Scarlett 2i2";
          matches = "alsa_output.usb-Focusrite_Scarlett_2i2_USB-00.*";
        }
        # {
        #   name = "JBL Tune 770NC";
        #   type = "bluetooth";
        #   matches = "bluez_output.<MAC with : replaced by _>.*";
        # }
      ];
    };
  };

  den.aspects.sprizan = {
    includes = [
      den.aspects.sprizan-fs
      den.aspects.workstation

      den.aspects.gpu
      den.aspects.hermes
    ];

    nixos =
      { ... }:
      {
        imports = with inputs.nixos-hardware.nixosModules; [
          common-cpu-amd
          common-gpu-nvidia
          common-pc-ssd
        ];

        networking.hostId = "0d1e7a53";

        # extra boot entry that skips the nvidia driver entirely, in case a driver
        # update breaks the graphical session
        specialisation.nvidia-less.configuration.gpu.hasGPU = false;

        system.stateVersion = "25.05";

        # ryzen 5 5600: no integrated gpu, so no amdgpu/prime config anywhere
        boot.kernelModules = [ "kvm-amd" ];
        boot.initrd.availableKernelModules = [
          "nvme"
          "xhci_pci"
          "ahci"
          "usb_storage"
          "usbhid"
          "sd_mod"
        ];

        # windows keeps its own 200mb esp and is booted from the firmware boot
        # menu (F11); systemd-boot only manages the nixos esp.
        # https://github.com/nix-community/home-manager/issues/6364#issuecomment-2965010115
        home-manager.useUserPackages = true;
      };

    homeManager =
      { pkgs, ... }:
      {
        home.packages = with pkgs; [
          audacity # audio editor
          ente-desktop # photos app
          kdePackages.okular # ebook, pdf, comic, etc. reader
        ];
      };
  };

  flake-file.inputs.nixos-hardware.url = "github:nixos/nixos-hardware";
}
