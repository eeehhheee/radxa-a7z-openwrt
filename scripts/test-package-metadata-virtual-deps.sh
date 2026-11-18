#!/bin/sh
set -eu

OPENWRT_DIR="${1:?Usage: $0 OPENWRT_DIR}"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT HUP INT TERM

cat > "${TMP_DIR}/packageinfo" <<'EOF'
Source-Makefile: package/test/provider/Makefile

Package: foo-default
Depends:
Provides: foo
Default-Variant: 1
Category: Test
Title: Default foo provider
Description: default
@@

Package: foo-self
Depends: +foo
Provides: foo
Category: Test
Title: Self-dependent foo provider
Description: self
@@

Package: foo-other
Depends:
Provides: foo
Category: Test
Title: Other foo provider
Description: other
@@
EOF

"${OPENWRT_DIR}/scripts/package-metadata.pl" config "${TMP_DIR}/packageinfo" > "${TMP_DIR}/config.in"

if grep -Fn 'PACKAGE_foo-self<PACKAGE_foo-self' "${TMP_DIR}/config.in"; then
  echo "package-metadata.pl emitted a recursive self-dependency" >&2
  exit 1
fi

grep -Fq 'select PACKAGE_foo-default' "${TMP_DIR}/config.in"
grep -Fq 'select PACKAGE_foo-default if PACKAGE_foo-other<PACKAGE_foo-self' "${TMP_DIR}/config.in"
printf '%s\n' 'package-metadata.pl virtual dependency test: ok'
