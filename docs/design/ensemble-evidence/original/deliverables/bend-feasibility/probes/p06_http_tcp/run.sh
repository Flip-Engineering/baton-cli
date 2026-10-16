#!/bin/sh
# p06: HTTP/1.1 with incremental reads over Base TCP (no C effects).
# Server serves one connection and exits by itself.
set -u
BEND=/run/baton2-native-homelab/retained/baton2-compiler-741-20261015/postrelease-751-761-20261015-9/toolchain-home/bin/bend
export BEND_NO_TELEMETRY=1
export CC=/usr/bin/clang-19
cd "$(dirname "$0")"
rm -rf work out && mkdir -p work out
echo "== --check-only"
$BEND http.bend --check-only; echo "exit=$?"
$BEND http.bend -o out/http.c && $CC -O1 -pthread out/http.c -o out/http || exit 1
cd work
python3 ../server.py &
srv=$!
sleep 0.4
echo "== native run"
../out/http
echo "exit=$?"
wait $srv
echo "== done"
