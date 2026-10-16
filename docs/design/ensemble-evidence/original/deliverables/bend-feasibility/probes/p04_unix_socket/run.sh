#!/bin/sh
# p04: AF_UNIX round trip through an authored C effect, against a Python
# server. The server handles one connection and exits on its own (no
# signaling). `wait` only reaps our own background server.
set -u
BEND=/run/baton2-native-homelab/retained/baton2-compiler-741-20261015/postrelease-751-761-20261015-9/toolchain-home/bin/bend
export BEND_NO_TELEMETRY=1
export CC=/usr/bin/clang-19
cd "$(dirname "$0")"
rm -rf work out && mkdir -p work out
$BEND sock.bend -o out/sock.c && $CC -O1 -pthread out/sock.c -o out/sock || exit 1
cd work
python3 ../server.py ./lane.sock &
python3 ../server.py ./lane.sock &
srv=$!
sleep 0.4
echo "== native AF_UNIX request"
../out/sock ./lane.sock PING
echo "exit=$?"
wait $srv
echo "== server log above; done"
