# Project Refactoring Plan

## Goal
Refactor the Rama Helm chart to support deployment on Ubuntu 24.10 running on Raspberry Pi5 (ARM64) with an existing k3s cluster. Ensure proper configuration, image variants, and version checks for k3s.

## Action Items
1. Update helpers/Dockerfile base image to Ubuntu 24.10 for ARM64.
2. Modify default image repository in values.yaml to use the ARM64 variant (rama-arm64).
3. Introduce a nodeSelector value for ARM64 and inject it into StatefulSet templates for conductor and supervisor.
4. Create a verification script to check k3s installation and optional version requirement prior to deployment.
5. Update README.md with Pi5/Ubuntu24.10-specific instructions, nodeSelector guidance, and k3s verification steps.
6. Bump the Helm chart version in Chart.yaml to 0.6.0 to reflect the refactoring.
7. Add a CHANGELOG.md to track changes under an "Unreleased" heading.
8. Commit each logical change with descriptive commit messages and keep this plan under version control.

## Timeline
- Draft plan (this file)
- Implement and commit changes iteratively
- Push all commits once complete