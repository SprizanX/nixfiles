{
  perSystem =
    {
      inputs',
      self',
      pkgs,
      ...
    }:
    {
      devShells.default = pkgs.mkShell {
        packages = with pkgs; [
          git
          neovim
          nix

          # secrets
          age
          bitwarden-cli
          bws

          # nix specific tooling
          nil
          nixd
          nixfmt
          nix-prefetch-scripts
          statix
          just

          # ci
          omnix

          # ai tooling
          mcp-nixos
          inputs'.llm-agents.packages.apm
          inputs'.llm-agents.packages.skills
        ];

        shellHook = ''
          alias ls="eza --group-directories-first"
          alias la="ls -la"
          alias l="ls -l"
          alias nrs="nh os switch"
          alias tu="nix run github:redxtech/tu"
        '';
      };
    };
}
