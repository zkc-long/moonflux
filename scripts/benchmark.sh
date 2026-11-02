#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
moon update
moon run --target native bench
