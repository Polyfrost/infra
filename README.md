# Polyfrost infrastructure

This repository contains the code for all of the Polyfrost infrastructure (primarily our VPS,
hosting maven and the such).

## Project setup

Our VPS is managed using NixOS. The entrypoints for NixOS configurations are located at
`nixos/hosts/CONFIGURATION/default.nix`. In addition to base NixOS, we also use `sops-nix` for
secrets provisioning, `nixos-anywhere` and `disko` for VPS setup, and `nixos-facter` for hardware
configuration.

All NixOS configurations are exported via Nix Flake with outputs for nixos-rebuild and colmena.

This project also contains a nix-direnv configuration which provides the binaries for packages and
utilities needed to work on this repository. In addition, treefmt-nix is setup for code formatting,
so just use `nix fmt` to format all code.

A `Justfile` is also provided, which can simplify a lot of common tasks, run `just` to have all the
tasks listed.

## Storage

The VPS has two block devices, both described in `nixos/hosts/vps/disk-configuration.nix`:

- `main` - the root volume
- `volume` - a Network Attached Storage Volume

To move a container's state onto the volume, add its `persistentDirs` key to the `onVolume` list in
`nixos/hosts/vps/disk-configuration.nix`. Since the containers module bind mounts
`/var/lib/containers-persistent/<name>` into the container, nothing requires changes (only changes
is where the directory physically exists).
