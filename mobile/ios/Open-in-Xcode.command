#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
if ! xcode-select -p >/dev/null 2>&1; then
  echo "Install Xcode and open it once to complete setup."; exit 1
fi
if command -v python3 >/dev/null; then
  python3 generate_project.py
  python3 enable_ui_tests.py
fi
open TeamUnstoppable.xcodeproj
