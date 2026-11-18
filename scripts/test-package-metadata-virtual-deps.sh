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

Package: bar-self-default
Depends: +bar
Provides: bar
Default-Variant: 1
Category: Test
Title: Default bar provider which depends on bar
Description: default self provider
@@

Package: bar-other
Depends:
Provides: bar
Category: Test
Title: Other bar provider
Description: alternate
@@

Package: baz-self
Depends: baz
Provides: baz
Default-Variant: 1
Category: Test
Title: Default baz provider which depends on baz
Description: default self provider
@@

Package: baz-other
Depends:
Provides: baz
Category: Test
Title: Other baz provider
Description: alternate
@@

Package: lua-default
Depends: @!riscv64
Provides: lua-virtual
Default-Variant: 1
Category: Test
Title: Restricted default Lua provider
Description: default is unavailable on riscv64
@@

Package: lua-alt
Depends:
Provides: lua-virtual
Category: Test
Title: Alternative Lua provider
Description: available on riscv64
@@

Package: dnsdist-test
Depends: +lua-virtual
Category: Test
Title: Virtual Lua consumer
Description: verify provider arbitration never reemits own rank
@@
EOF

"${OPENWRT_DIR}/scripts/package-metadata.pl" config "${TMP_DIR}/packageinfo" > "${TMP_DIR}/config.in"

if grep -Fn 'PACKAGE_foo-self<PACKAGE_foo-self' "${TMP_DIR}/config.in"; then
  echo "package-metadata.pl emitted a recursive self-dependency" >&2
  exit 1
fi

grep -Fq 'select PACKAGE_foo-default' "${TMP_DIR}/config.in"
grep -Fq 'select PACKAGE_foo-default if PACKAGE_foo-other<PACKAGE_foo-self' "${TMP_DIR}/config.in"
grep -Fq 'select PACKAGE_bar-other' "${TMP_DIR}/config.in"
if grep -Fq 'select PACKAGE_bar-self-default' "${TMP_DIR}/config.in"; then
  echo "package-metadata.pl selected a virtual package consumer as its own provider" >&2
  exit 1
fi
grep -Fq 'depends on PACKAGE_baz-other' "${TMP_DIR}/config.in"
if grep -Fq 'PACKAGE_baz-self<PACKAGE_baz-self' "${TMP_DIR}/config.in"; then
  echo "package-metadata.pl emitted a recursive non-select dependency" >&2
  exit 1
fi
# A selected provider's architecture gate must not inherit the rank of an
# alternative provider (PACKAGE_lua-alt<PACKAGE_dnsdist-test), or the
# consumer gains a recursive depends-on edge in Kconfig. The rank belongs
# only on the select, while the propagated gate can negate the alternative.
grep -Fq 'select PACKAGE_lua-default if PACKAGE_lua-alt<PACKAGE_dnsdist-test' "${TMP_DIR}/config.in"
grep -Fq 'depends on !(!PACKAGE_lua-alt) || !riscv64' "${TMP_DIR}/config.in"
if grep -E 'depends on .*<PACKAGE_dnsdist-test' "${TMP_DIR}/config.in"; then
  echo "package-metadata.pl propagated consumer rank into dependency" >&2
  exit 1
fi
printf '%s\n' 'package-metadata.pl virtual dependency test: ok'
