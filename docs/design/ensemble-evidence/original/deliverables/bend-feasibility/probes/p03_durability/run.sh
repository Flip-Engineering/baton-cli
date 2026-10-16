#!/bin/sh
# p03: durability effect family on Linux (emit C, clang link, run).
set -u
BEND=/run/baton2-native-homelab/retained/baton2-compiler-741-20261015/postrelease-751-761-20261015-9/toolchain-home/bin/bend
export BEND_NO_TELEMETRY=1
export CC=/usr/bin/clang-19
cd "$(dirname "$0")"
rm -rf work out && mkdir -p work out
echo "== --check-only"
$BEND dur.bend --check-only; echo "exit=$?"
echo "== emit C"
$BEND dur.bend -o out/dur.c; echo "exit=$?"
echo "== clang link"
$CC -O1 -pthread out/dur.c -o out/dur; echo "exit=$?"
echo "== native run (cwd=work)"
cd work && ../out/dur; code=$?; echo "exit=$code"
echo "== final file content:"; cat store/log.jsonl 2>&1; echo
echo "== tmp path after rename (expect absent):"; ls store 2>&1
cd ..
echo "== interpreted run"
cd work && $BEND ../dur.bend; echo "exit=$?"
