# default recipe to display help information
default:
  @just --list

# Create a new hardened service config from template
new SERVICE:
  #!/usr/bin/env bash
  set -euo pipefail
  target="services/{{SERVICE}}.nix"
  if [ -f "$target" ]; then
    echo "error: $target already exists" >&2
    exit 1
  fi
  sed "s/SERVICE_NAME/{{SERVICE}}/g" service_template.nix > "$target"
  echo "Created $target — edit it to relax restrictions as needed for {{SERVICE}}"

# Run flake checks
check:
  nix flake check --show-trace

# Format all nix files
fmt:
  nix fmt

# List all hardened services
list:
  @ls services/*.nix | sed 's|services/||;s|\.nix||'
