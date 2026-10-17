set shell := ["bash", "-euo", "pipefail", "-c"]

export NIXPKGS_ALLOW_UNFREE := "1"

[metadata("ci")]
ci: flake-check host-dry-build

flake-check:
    nix flake check --impure --print-build-logs

host-eval:
    nix eval .#nixosConfigurations.sprizan.config.system.build.toplevel.drvPath

host-dry-build:
    nix build .#nixosConfigurations.sprizan.config.system.build.toplevel --no-link --print-build-logs
