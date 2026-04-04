#!/usr/bin/env bash
set -euo pipefail

# Provisions seo-optimizer project configs into the Argus clone.
# Copies from the canonical local copy (lucidforecast/company/seo-optimizer).
# Run once after cloning, or whenever configs change.

ARGUS_DIR="$(cd "$(dirname "$0")/.." && pwd)"
REPO_LOCAL="$ARGUS_DIR/repos/seo-optimizer"
SOURCE="/home/antoine-header/Projects/lucidforecast/company/seo-optimizer/projects"

if [[ ! -d "$REPO_LOCAL" ]]; then
    echo "ERROR: Clone not found at $REPO_LOCAL. Run a task first to trigger clone." >&2
    exit 1
fi

if [[ ! -d "$SOURCE" ]]; then
    echo "ERROR: Source configs not found at $SOURCE" >&2
    exit 1
fi

for project_dir in "$SOURCE"/*/; do
    project_name="$(basename "$project_dir")"
    target="$REPO_LOCAL/projects/$project_name"

    echo "Provisioning $project_name..."
    mkdir -p "$target/config"

    # Copy config (credentials + any other yaml)
    cp -r "$project_dir/config/"* "$target/config/" 2>/dev/null || true

    # Copy data directory structure (but not large data files)
    mkdir -p "$target/data" 2>/dev/null || true
done

echo "Done. Provisioned configs for: $(ls "$SOURCE" | tr '\n' ' ')"
