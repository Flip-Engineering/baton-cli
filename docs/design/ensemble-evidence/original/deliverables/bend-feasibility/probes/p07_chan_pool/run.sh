#!/bin/sh
# p07: completion-order join through Base Chan/IO.fork.
set -u
BEND=/run/baton2-native-homelab/retained/baton2-compiler-741-20261015/postrelease-751-761-20261015-9/toolchain-home/bin/bend
export BEND_NO_TELEMETRY=1
cd "$(dirname "$0")"
echo "== --check-only"
$BEND pool.bend --check-only; echo "exit=$?"
echo "== interpreted run"
$BEND pool.bend; echo "exit=$?"
echo "== native run"
$BEND pool.bend -o pool.bin >/dev/null 2>&1 && ./pool.bin; echo "exit=$?"
