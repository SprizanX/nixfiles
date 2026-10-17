{ den, inputs, ... }:

{
  den.aspects.bar = {
    includes = [
      den.aspects.noctalia-plugins
      den.aspects.idle-inhibit
    ];

    nixos =
      {
        host,
        pkgs,
        lib,
        ...
      }:
      {
        imports = [ inputs.noctalia.nixosModules.default ];

        # to make noctalia’s wifi, bluetooth, power-profile, and battery features available
        # TODO: enable gnome evolution data server for calendar support
        programs.noctalia.enable = true;
        programs.noctalia.recommendedServices.enable = true;
      };

    homeManager =
      {
        inputs',
        config,
        host,
        pkgs,
        lib,
        ...
      }:
      {
        imports = [ inputs.noctalia.homeModules.default ];

        home.packages =
          with pkgs;
          [
            fastfetch # for system information
          ]
          ++ lib.optionals host.settings.workstation.isLaptop (
            with pkgs;
            [
              ddcutil # brightness controls
            ]
          );

        programs.noctalia = {
          enable = true;

          package = inputs'.noctalia.packages.default;

          systemd.enable = true;

          settings = lib.recursiveUpdate (builtins.fromTOML (builtins.readFile ./noctalia-config.toml)) {
            shell = {
              avatar_path = "${config.home.homeDirectory}/.face";
              screenshot.directory = "${config.xdg.userDirs.pictures}/Screenshots";
            };

            wallpaper.directory = "${config.xdg.userDirs.pictures}/Wallpaper";

            # macos-style dock for the running apps, in addition to the bar
            dock = {
              enabled = true;
              position = "bottom";
              icon_size = 42;
              magnification = true;
              magnification_scale = 1.45;
              active_scale = 1.0;
              show_running = true;
              show_dots = true;
              auto_hide = false;
              reserve_space = true;
              radius = 18;
              launcher_position = "start";
            };
          };
        };
      };
  };

  # allow exporting noctalia config to a file
  perSystem =
    { pkgs, lib, ... }:
    {
      apps.write-noctalia = {
        type = "app";
        program = pkgs.writeShellApplication {
          name = "write-noctalia";
          runtimeInputs = with pkgs; [
            inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default
          ];
          text = ''
            noctalia config export > ~/nixfiles/modules/features/workstation/bar/noctalia-config.toml
          '';
        };
        meta.description = "Export noctalia config to a file";
      };
    };

  flake-file.inputs.noctalia.url = "github:noctalia-dev/noctalia/cachix";

  flake-file.nixConfig = {
    extra-substituters = [ "https://noctalia.cachix.org" ];
    extra-trusted-public-keys = [
      "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
    ];
  };
}
