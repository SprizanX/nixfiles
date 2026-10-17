{ lib, ... }:

{
  den.aspects.gpu = {
    settings = {
      # TODO: pull from facter report
      amd = lib.mkEnableOption "AMD GPU support";

      nvidia = {
        enable = lib.mkEnableOption "NVIDIA GPU support";
        prime = lib.mkEnableOption "NVIDIA Prime support";

        open = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = ''
            Use the open kernel modules. Requires Turing (RTX 20xx) or newer.
          '';
        };

        nvidiaSettings = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Install the nvidia-settings GUI.";
        };

        powerManagement = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = ''
            Preserve video memory across suspend. May cause issues on some setups,
            so it is opt-in rather than tied to nvidia.enable.
          '';
        };

        driverBranch = lib.mkOption {
          type = lib.types.str;
          default = "production";
          example = "latest";
          description = "Which boot.kernelPackages.nvidiaPackages branch to use.";
        };
      };

      cuda = lib.mkEnableOption ''
        CUDA support. Off by default because it rebuilds a very large part of
        nixpkgs; opt in only when something actually needs it.
      '';
    };

    nixos =
      {
        host,
        config,
        pkgs,
        lib,
        ...
      }:
      let
        cfg = host.settings.gpu;
        hasGPU = config.gpu.hasGPU;
      in
      {
        options.gpu.hasGPU = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Whether the system has a GPU (useful for disabling the module via specialisation)";
        };

        config = lib.mkIf (hasGPU && (cfg.amd || cfg.nvidia.enable)) {
          # ensure only one of amd or nvidia is enabled
          assertions = [
            {
              assertion = !(cfg.amd && cfg.nvidia.enable);
              message = "Only one of AMD or NVIDIA can be enabled.";
            }
          ];

          environment.systemPackages = [
            pkgs.clinfo # OpenCL info tool
          ]
          ++ lib.optionals cfg.amd (with pkgs; [ amdgpu_top ])
          ++ lib.optionals cfg.nvidia.enable (with pkgs; [ nvtopPackages.full ]);

          boot.initrd.kernelModules =
            (lib.optional cfg.amd "amdgpu") ++ (lib.optional cfg.nvidia.enable "nvidia");

          # nvidia-drm.fbdev is required for a working Wayland session on current drivers
          boot.kernelParams = lib.optionals cfg.nvidia.enable [ "nvidia-drm.fbdev=1" ];

          # TODO: check if we need this?
          services.xserver.videoDrivers =
            (lib.optional cfg.amd "amdgpu") ++ (lib.optional cfg.nvidia.enable "nvidia");

          hardware.graphics = {
            enable = true;
            enable32Bit = true;
            extraPackages = lib.optionals cfg.amd [ pkgs.rocmPackages.clr.icd ];
          };

          hardware.amdgpu.opencl.enable = cfg.amd;

          # from https://nixos.wiki/wiki/Nvidia
          hardware.nvidia = lib.mkIf cfg.nvidia.enable {
            inherit (cfg.nvidia) open;

            nvidiaSettings = cfg.nvidia.nvidiaSettings;
            package = config.boot.kernelPackages.nvidiaPackages.${cfg.nvidia.driverBranch};

            modesetting.enable = true;
            powerManagement.enable = cfg.nvidia.powerManagement;

            # finegrained power management only makes sense for laptop PRIME offload
            powerManagement.finegrained = cfg.nvidia.prime;

            prime = lib.mkIf cfg.nvidia.prime {
              # TODO: get the actual values
              # intelBusId = "PCI:0:2:0";
              # nvidiaBusId = "PCI:14:0:0";

              offload = {
                enable = true;
                enableOffloadCmd = true;
              };
            };
          };

          nixpkgs.config.rocmSupport = cfg.amd;

          # Deliberately NOT `cfg.nvidia.enable`: CUDA is opt-in so that adding a
          # GPU does not silently trigger a nixpkgs-wide rebuild.
          nixpkgs.config.cudaSupport = cfg.cuda;
        };
      };

  };
}
