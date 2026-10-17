# Session Handoff

## Goal

Prepare and improve the `sprizan` NixOS repository and configuration before
installation. The current phase is the operating system and repository itself;
defer interactive Hermes setup, Telegram, voice workflows, and computer-use
integration until the OS is installed and verified.

## Current State

- Repository: `C:\Users\Sans\Documents\Проект по умолчанию\nixfiles`
- Branch: `sprizan/host-setup`, based on `cf9ec88` at the time this note was
  written. Check Git status and history at the start of each session.
- Host and user: `sprizan` / `sans`
- Target: MSI A520M-A PRO, Ryzen 5 5600, RTX 3080, 32 GB DDR4; Windows 11 and
  NixOS will dual boot from the same NVMe drive.
- Development currently happens on Windows without Nix. No evaluation, build,
  installation, or physical hardware test has yet been completed.
- Root and NixOS EFI UUIDs in `modules/hosts/sprizan/filesystem.nix` are
  placeholders. Obtain the real values from the target disk before installation.

## Agreed Constraints

- Preserve existing user changes. Inspect `git status` and diffs before editing;
  do not discard, stage, or commit unrelated work.
- Do not edit generated `flake.nix` by hand. Change `flake-file.inputs` near the
  owning code and regenerate with `nix run .#write-flake` on a Nix system.
- Never partition the full NVMe declaratively or alter the Windows EFI
  partition. NixOS uses a separate EFI partition.
- Do not add sops, age, or any secrets manager.
- Do not run activation, `sudo`, disk operations, or other system-wide/destructive
  commands without explicit authorization.
- Credit `redxtech/nixfiles` as the repository's upstream source; describe the
  present configuration and decisions in the owner's voice rather than
  presenting inherited material as wholly original.
- State clearly in project-facing documentation that this configuration is
  based on https://github.com/redxtech/nixfiles.
- This phase covers OS and repository files. Defer configuring or connecting
  Hermes integrations until a later phase.

## Next Work

1. Review the current working tree and the OS-specific diffs without overwriting
   existing changes.
2. On the target or NixOS installer, inspect disks and record the actual UUIDs;
   update only the NixOS root and dedicated EFI entries.
3. Regenerate the flake with `nix run .#write-flake`, then run `nix fmt`.
4. Evaluate `nixosConfigurations.sprizan`, run `nix flake check` where practical,
   and build the system without activating it. Resolve errors before installation.
5. Install and verify boot, NVIDIA, network, audio, displays, and desktop on the
   physical machine. Revisit settings that were necessarily guessed before boot.
6. Replace the temporary `initialPassword = "nixos"` with a password hash, then
   remove `initialPassword` after the first successful boot.
7. After the OS is stable, proceed to the separately agreed Hermes hardening,
   backup/recovery, Telegram, Russian voice, and computer-use work.

## Repository Map

- `modules/hosts/sprizan/`: host, filesystem, and hardware-specific values
- `modules/users/sans/`: user account and Home Manager entry point
- `modules/features/base/`: common system and CLI setup
- `modules/features/workstation/`: desktop, applications, audio, and gaming
- `modules/features/gpu.nix`: NVIDIA settings and GPU feature options
- `modules/features/ai/hermes/`: current service/module work; defer integration
  until the OS phase is complete
- `docs/`: repository documentation and research; verify old notes still apply

## Useful Checks

```sh
nix run .#write-flake
nix fmt
nix eval .#nixosConfigurations.sprizan.config.system.build.toplevel.drvPath
nix build .#nixosConfigurations.sprizan.config.system.build.toplevel
nix flake check
```

Do not run `nh os switch` or otherwise activate a generation until the user has
reviewed the candidate build and explicitly requested installation or switching.
