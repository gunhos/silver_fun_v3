#!/usr/bin/env bash
# Build a release AAB for Play Store internal testing.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

flutter clean
flutter pub get
flutter build appbundle --release "$@"
