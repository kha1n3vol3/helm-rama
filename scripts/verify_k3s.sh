#!/usr/bin/env bash
set -euo pipefail

# verify_k3s.sh - Check that k3s is installed and optional version requirement
# Usage: ./verify_k3s.sh [REQUIRED_VERSION]

# Determine required version prefix if provided
REQUIRED_VERSION="${1:-}"

if ! command -v k3s >/dev/null 2>&1; then
  echo "Error: k3s is not installed. Please install k3s before proceeding." >&2
  exit 1
fi

INSTALLED_VERSION=$(k3s --version | awk '{print $2}')
echo "Detected k3s version: ${INSTALLED_VERSION}"

if [[ -n "$REQUIRED_VERSION" && "$INSTALLED_VERSION" != "$REQUIRED_VERSION"* ]]; then
  echo "Error: k3s version mismatch. Required prefix: ${REQUIRED_VERSION}." >&2
  exit 1
fi

echo "k3s verification passed."