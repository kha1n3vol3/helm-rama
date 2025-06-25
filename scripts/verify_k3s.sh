#!/usr/bin/env bash
set -euo pipefail

# verify_k3s.sh - Check that k3s is installed and enforce a version requirement
# Usage: ./scripts/verify_k3s.sh [LEGACY_REQUIRED_PREFIX]
# Without an argument, defaults to the current k3s version.

if ! command -v k3s >/dev/null 2>&1; then
  echo "Error: k3s is not installed. Please install k3s before proceeding." >&2
  exit 1
fi

# Determine the installed k3s version
INSTALLED_VERSION=$(k3s --version | awk '{print $2}')
echo "Detected k3s version: ${INSTALLED_VERSION}"

# Determine required version prefix (default to current version if none provided)
REQUIRED_VERSION="${1:-$INSTALLED_VERSION}"
echo "Using required version prefix: ${REQUIRED_VERSION}"

if [[ "$INSTALLED_VERSION" != "$REQUIRED_VERSION"* ]]; then
  echo "Error: k3s version mismatch. Required prefix: ${REQUIRED_VERSION}." >&2
  exit 1
fi

echo "k3s verification passed."