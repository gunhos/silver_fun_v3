#!/usr/bin/env bash
# Build a release AAB for Play Store internal testing.
#
# Always regenerates lib/core/config/google_auth_config.dart from the current
# android/app/google-services.json first, so the Web client ID baked into the
# binary always matches the active Firebase project. Switching projects is just
# `flutterfire configure && scripts/build_release_aab.sh`.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

python3 scripts/generate_google_auth_config.py
flutter clean
flutter pub get
flutter build appbundle --release "$@"
