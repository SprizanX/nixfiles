# my nixOS flake

this repository contains the nixOS and home-manager configuration for my desktop.

## what is included

- a nixOS and home-manager configuration for one host, `sprizan`:
  - msi a520m-a pro, ryzen 5 5600, rtx 3080 (open kernel modules), 32gb ddr4
  - three monitors: 2560x1440@180 (primary), 1920x1080, 1080x1920 (rotated)
  - dual boot with windows 11. windows keeps its own 200mb esp, nixos has a
    separate 1gb esp, and windows is booted from the firmware boot menu (f11)
- feature-based configuration through [den](https://github.com/denful/den) aspects
  - `base` provides shared system and user configuration.
  - `workstation` adds the graphical desktop, applications, audio, gaming, and related services.
- custom packages, modules, scripts, and nix library functions

the workstation configuration uses niri, noctalia, fish, neovim, kitty, and firefox nightly.

## structure

- `modules/features`: shared, workstation, gpu, and AI aspects
- `modules/hosts`: host definitions and file-system configuration
- `modules/users`: user aspects and user-specific configuration
- `packages`: custom flake packages
- `lib`: nix functions used by the configuration

`flake-file` generates `flake.nix` from declarations next to the modules that use them. `import-tree` loads the modules and packages.

## secrets

there is no secrets manager here. sops-nix and age were removed because every
secret was encrypted to a yubikey that does not exist any more.

the one exception is hermes, which reads an optional plain environment file from
`~/.hermes/hermes.env`. create it with mode `0600` and rebuild, and the service
picks it up.

## common commands

the flake's devShell provides the repository tools and the `nrs` rebuild alias.

```fish
# rebuild the current host
nrs

# rebuild a named host
nh os switch .#sprizan

# format the repository
nix fmt

# regenerate flake.nix after a flake-file declaration changes
nix run .#write-flake

# regenerate noctalia's config after making changes via the ui
nix run .#write-noctalia
```
