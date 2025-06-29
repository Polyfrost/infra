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

## TODO List

- [x] Basic NixOS setup
- [x] Nspawn container tooling
- [x] Postgres
- [x] Plausible
- [x] Reposilite
- [x] Ursa minor
- [x] v0 backend & v1 backend
  - [x] Add a nix flake to each
- [x] Caddy
- [ ] Polyfrost main website (https://polyfrost.org)
- [ ] Monitoring
  - [x] Node exporter + https://grafana.com/grafana/dashboards/1860
  - [ ] Better dashboard/metrics for ursa-minor
  - [ ] postgres_exporter + dashboard
  - [ ] VictoriaLogs
    - [ ]
      [Journald](https://search.nixos.org/options?channel=25.05&show=services.journald.upload.settings&from=0&size=50&sort=relevance&type=packages&query=journal-upload)
    - [ ] Caddy request logs
- [ ] Resolve all TODOs if necessary
