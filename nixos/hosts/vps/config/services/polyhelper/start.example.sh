#!/usr/bin/env -S nix shell nixpkgs#bun --command bash

set -exuo pipefail

cd ./PolyHelper

echo "Running bun install..."
bun install --frozen-lockfile

echo "Starting program..."
bun ./src/index.ts
