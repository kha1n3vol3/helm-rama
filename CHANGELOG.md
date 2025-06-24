# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Changed
- Bump Helm chart version to 0.6.0
- Updated helpers/Dockerfile base image to Ubuntu 24.10 (ARM64)
- Modified default image repository to ARM64 variant (`rama-arm64`)
- Added `nodeSelector` support for ARM64 architecture
- Introduced k3s verification script (`scripts/verify_k3s.sh`)
- Updated README with Pi5/Ubuntu24.10 deployment instructions and k3s checks

### Added
- `scripts/verify_k3s.sh`: script to verify k3s installation and optional version requirement
- `CHANGELOG.md` to track project changes
- `plan.md` outlining refactoring plan