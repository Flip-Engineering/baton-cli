#!/bin/sh
# p05: child-process supervision through the audit-era 222-line C family
# (extracted from canonical source commit bdc234c3), built with the
# actual pinned toolchain on Linux.
set -u
BEND=/run/baton2-native-homelab/retained/baton2-compiler-741-20261015/postrelease-751-761-20261015-9/toolchain-home/bin/bend
export BEND_NO_TELEMETRY=1
export CC=/usr/bin/clang-19
cd "$(dirname "$0")"
rm -rf work out && mkdir -p work out
echo "== --check-only"
$BEND driver.bend --check-only; echo "exit=$?"
echo "== emit + link"
$BEND driver.bend -o out/driver.c && $CC -O1 -pthread out/driver.c -o out/driver || exit 1
echo "== native run (cwd=work)"
cd work && ../out/driver; echo "exit=$?"
