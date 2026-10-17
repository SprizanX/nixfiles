# Agent Guidelines

## Project Information
This is a NixOS flake with a configuration for one desktop, custom package definitions, and custom modules.

The flake is following the dendritic pattern, using [denful/den](https://github.com/denful/den) as a framework.

Every feature includes all of the necessary config, including both the home-manager and nixos modules configuration in the same aspect. The features are either included by the hosts directly, or by a parent aspect that encompasses its concern.

The two main aspects are `base` and `workstation`. The `base` aspect is for things that are shared across all hosts, and the `workstation` aspect is for things that are specific to the workstations - hosts that have a display & are expected to have the tools used on a daily basis. New aspects should be intentional about what they do and where they are imported.

### Hosts
- `sprizan`: the desktop and primary workstation (workstation)

### Users
- `sans`: the only user, and `base.settings.primaryUser`

## Important Directories
- `modules/`: everything nixos-related goes here, one file per concern.
- `lib/`: custom functions and utilities used across the flake.
- `packages/`: custom packages, exposed to modules as `self'.packages.*`.

# Tools
You have access to a few tools to help with nixos development. The `nil` language server, `nixfmt` for formatting, `nix-prefetch-scripts` to pre-compute fetcher hashes, and `statix` for ensuring best practices. Use them as necessary.

Use the internet for reference, with `wiki.nixos.org` as a resource for the nixos ecosystem.

## Code Style
- Idiomatic Nix: use inherit for hyphenated identifiers in scope, not quoted assignment
- Idiomatic Nix: use lib.optional lib.optionals lib.optionalAttrs for basic conditionals
- Idiomatic Nix: avoid with - prefer inherit to bring names into scope. with obscures where bindings come from and breaks tooling.
- Use functions available in the nixpkgs lib instead of writing your own helpers where possible
- Commenting: comments should describe why not what, code should be self documenting as to what
- Minimal changes: fix the bug, don't refactor surroundings
- This project is using flake-file to manage inputs, so inputs are defined in `flake-file.inputs`, and are written to `flake.nix` by `nix run .#write-flake`. To use a new input, add it to `flake-file.inputs`, run `nix run .#write-flake`, and then add the code that depends on it - otherwise the evaluations will fail.

## Rules
- To validate changes, use `nix eval` to find the specific output path you want to test.
- Never modify `flake.nix` directly, it is managed by `flake-file`
- Stage files with `git add -N <file>` before testing changes, otherwise nix will ignore them
- Use explicit file paths when using `git` command, never use `git add .` or `git commit -a`
- There is no secrets manager in this repository, and none should be added back. Machine-local secrets belong in plain files outside the nix store.
- Host-specific values go in `den.hosts.x86_64-linux.<host>.settings`, and every option set there must be declared by an aspect that the host includes.
- If you need clarification on any preference or decision, ask for input

## Hardware Notes
- ryzen 5 5600 with no integrated gpu, so there is no prime/offload configuration anywhere
- the nvidia driver uses the open kernel modules: `nvidia-drm.fbdev=1` and `hardware.nvidia.modesetting` are required for wayland
- `nixpkgs.config.cudaSupport` is deliberately controlled by `gpu.nvidia.cuda` and not by `gpu.nvidia.enable`, so that enabling the gpu does not trigger a nixpkgs-wide cuda rebuild
- windows keeps its own 200mb esp. never declare a partition table for the nvme, and never reformat the windows esp
