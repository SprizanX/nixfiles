{
  den.aspects.mcp = {
    homeManager =
      {
        self',
        config,
        pkgs,
        lib,
        ...
      }:
      {
        programs.mcp = {
          enable = true;

          # servers to consider adding:
          # - context7 (https://github.com/upstash/context7)
          # - thunderbird (https://github.com/TKasperczyk/thunderbird-mcp)

          servers = {
            codebase-memory.command = lib.getExe self'.packages.codebase-memory-mcp;
            nixos.command = lib.getExe pkgs.mcp-nixos;
            super-productivity.command = lib.getExe self'.packages.super-productivity-mcp;
          };
        };

        # native pi needs its own config path
        home.file = lib.mkIf config.programs.pi-coding-agent.enable {
          "${config.programs.pi-coding-agent.configDir}/mcp.json".source =
            (pkgs.formats.json { }).generate "pi-mcp.json"
              {
                mcpServers = lib.mapAttrs (
                  _: server:
                  lib.hm.mcp.transformMcpServer {
                    inherit server;
                    extraTransforms = [ lib.hm.mcp.addType ];
                    mkFileRef = path: "!${lib.getExe' pkgs.coreutils "cat"} ${lib.escapeShellArg path}";
                  }
                ) config.programs.mcp.servers;
              };
        };

        home.packages = [
          self'.packages.codebase-memory-mcp
          self'.packages.super-productivity-mcp
        ];
      };
  };
}
