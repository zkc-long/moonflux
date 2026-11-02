#!/usr/bin/env bash
set -euo pipefail

VERSION="${MOONFLUX_VERSION:-0.1.2}"
SMOKE_DIR="$(mktemp -d)"

cd "$SMOKE_DIR"
moon new . --name package_smoke --user smoke
moon add "zkc-long/moonflux@$VERSION"

cat > moon.pkg <<'EOF'
import {
  "zkc-long/moonflux" @moonflux,
} for "test"
EOF

cat > package_smoke_test.mbt <<'EOF'
test "installed MoonFlux package encodes and parses" {
  let point = @moonflux.new_point("smoke")
    .add_field("value", @moonflux.IntValue(1L))
  match @moonflux.encode_point(point) {
    Ok(line) => {
      assert_eq(line, "smoke value=1i")
      match @moonflux.parse_line(line) {
        Ok(parsed) => assert_eq(parsed.measurement, "smoke")
        Err(_) => assert_eq(false, true)
      }
    }
    Err(_) => assert_eq(false, true)
  }
}
EOF

moon check --deny-warn
moon test
echo "MoonFlux package smoke test passed for $VERSION at $SMOKE_DIR"
