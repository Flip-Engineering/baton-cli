#!/bin/sh
# p04: AF_UNIX round trip through an authored C effect, against a Python
# server. The server serves exactly one connection and exits by itself.
# `timeout 20` only bounds our own probe children as a hang safety net.
set -u
BEND=/run/baton2-native-homelab/retained/baton2-compiler-741-20261015/postrelease-751-761-20261015-9/toolchain-home/bin/bend
export BEND_NO_TELEMETRY=1
export CC=/usr/bin/clang-19
cd "$(dirname "$0")"
rm -rf work out && mkdir -p work out
$BEND sock.bend --check-only; echo "check_exit=$?"
$BEND sock.bend -o out/sock.c && $CC -O1 -pthread out/sock.c -o out/sock || exit 1
cd work
timeout 20 python3 ../server.py ./lane.sock &
srv=$!
i=0
while [ ! -S ./lane.sock ] && [ $i -lt 40 ]; do
  sleep 0.1; i=$((i+1))
done
echo "== native AF_UNIX request"
timeout 20 ../out/sock ./lane.sock PING
echo "client_exit=$?"
wait $srv
echo "== server log above; done"
