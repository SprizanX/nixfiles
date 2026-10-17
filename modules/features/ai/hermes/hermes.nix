{ self, ... }:

{
  den.aspects.hermes = {
    nixos = { ... }: {
      # enable accessibility service for hermes computer_use skill
      services.gnome.at-spi2-core.enable = true;
      systemd.user.services.at-spi-dbus-bus.wantedBy = [ "graphical-session.target" ];
    };

    homeManager =
      {
        self',
        inputs',
        config,
        pkgs,
        lib,
        ...
      }:
      let
        llmAgentsPackages = inputs'.llm-agents.packages;
        selfPackages = self'.packages;
        hermesPythonPackages = config.services.hermes-agent.package.python.pkgs;

        # API keys live outside the nix store. Create the file and it gets picked
        # up on the next rebuild; until then hermes starts without it.
        hermesEnvFile = "${config.home.homeDirectory}/.hermes/hermes.env";

        honchoSource = pkgs.fetchFromGitHub {
          owner = "plastic-labs";
          repo = "honcho";
          rev = "f014a64306bac21f233f51a8e5cddf94a704f62d";
          hash = "sha256-zZhrst/o66Yo9Z1iHMQkBxtrDLn5haC2uh5nSMcBz8I=";
        };
        honchoPlugin = pkgs.runCommand "honcho-1.0.0" { } ''
          ln -s ${honchoSource}/hermes-plugin-honcho "$out"
        '';
        honchoSdk = hermesPythonPackages.buildPythonPackage {
          pname = "honcho-ai";
          version = "2.5.0";
          src = "${honchoSource}/sdks/python";
          pyproject = true;
          build-system = [
            hermesPythonPackages.setuptools
            hermesPythonPackages.wheel
          ];
          # the sealed hermes venv owns these distributions at compatible locked versions
          buildInputs = [
            hermesPythonPackages.httpx
            hermesPythonPackages.pydantic
          ];
          pythonImportsCheck = [ "honcho" ];
        };
      in
      {
        imports = [ self.homeManagerModules.hermes ];

        services.hermes-agent = {
          enable = true;
          workingDirectory = "${config.home.homeDirectory}/Documents/personal";
          extraArgs = [
            "run"
            "--replace"
            "--external-supervisor"
          ];

          dashboard.enable = true;
          gateway.port = 8642;

          documents."AGENTS.md" = ../agents/AGENTS.md;

          managedSettings = {
            plugins.enabled = [
              "hermes-lcm"
              "rtk-rewrite"
            ];

            mcp_servers = {
              codebase-memory.command = lib.getExe self'.packages.codebase-memory-mcp;
              nixos.command = lib.getExe pkgs.mcp-nixos;
              super-productivity.command = lib.getExe self'.packages.super-productivity-mcp;
            };
          };

          inherit (lib.optional (builtins.pathExists hermesEnvFile) hermesEnvFile) { };
          environmentFiles = lib.optional (builtins.pathExists hermesEnvFile) hermesEnvFile;
          environment.CUA_DRIVER_RS_ENABLE_WAYLAND = "1";

          extraPackages = [
            pkgs.defuddle
            pkgs.ffmpeg-full
            pkgs.jq
            pkgs.mcp-nixos
            pkgs.obsidian
            selfPackages.codebase-memory-mcp
            selfPackages.cua-driver
            selfPackages.cyber-mux
            selfPackages.docker-axi
            selfPackages.gh-axi
            selfPackages.gws-axi
            selfPackages.kubernetes-axi
            selfPackages.mcp-remote
            selfPackages.super-productivity-mcp
            selfPackages.workspace-mcp
            llmAgentsPackages.rtk
          ];

          extraLibraries = [ pkgs.portaudio ];

          extraPlugins = [
            (pkgs.fetchFromGitHub {
              owner = "stephenschoettler";
              repo = "hermes-lcm";
              rev = "v0.20.0";
              hash = "sha256-yJ1Nn+su7YbKd+cgVOizXChzLbKHqTprSprF1p9/HYk=";
            })
            honchoPlugin
          ];

          extraPythonPackages = [
            honchoSdk
            (
              let
                pname = "rtk-hermes";
                version = "1.2.3";
              in
              hermesPythonPackages.buildPythonPackage {
                inherit pname version;
                src = pkgs.fetchFromGitHub {
                  owner = "ogallotti";
                  repo = pname;
                  rev = "v${version}";
                  hash = "sha256-7YRW6PODrCapfYLFn3DvgHAEME//RGC48GQt+s9ot0s=";
                };
                format = "pyproject";
                build-system = [ hermesPythonPackages.setuptools ];
              }
            )
          ];

          extraDependencyGroups = [
            "messaging"
            "edge-tts"
            "exa"
            "voice"
            "tts-premium"
          ];
        };

        home.packages = [ config.services.hermes-agent.desktopPackage ];

        home.file.".hermes/dashboard-themes/clean-webui.yaml" = {
          force = true;
          source = "${
            pkgs.fetchFromGitHub {
              owner = "fplanque";
              repo = "hermes-agent-dashboard-theme-clean";
              rev = "e7d58098f3a3ffc6866e59f4f054fa64c09913e0";
              hash = "sha256-DDBws/rdcwCaUJ2TeGIuaDR0EaDrI0qGs7LhYxHAd9A=";
            }
          }/clean-webui.yaml";
        };
      };
  };

  flake-file.inputs.hermes-agent = {
    url = "github:NousResearch/hermes-agent";
    inputs.nixpkgs.follows = "nixpkgs";
  };
}
