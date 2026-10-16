#!/bin/sh
# p11: build and startup costs on this host (Linux x64, clang-19,
# bun --smol). Smallest IO program and the dispatcher program.
set -u
BEND=/run/baton2-native-homelab/retained/baton2-compiler-741-20261015/postrelease-751-761-20261015-9/toolchain-home/bin/bend
export BEND_NO_TELEMETRY=1
export CC=/usr/bin/clang-19
cd "$(dirname "$0")"
rm -rf work && mkdir work
cd work
cp ../../p02_shape_rules/dispatcher.bend .

ms() { python3 -c "import time; print(int((time.time() - $1) * 1000))"; }

t0=$(date +%s%N); ms0=$(python3 -c "import time; print(time.time())")
$BEND dispatcher.bend --check-only >/dev/null 2>&1
echo "check-only dispatcher: $(ms $ms0) ms exit=$?"

ms0=$(python3 -c "import time; print(time.time())")
$BEND dispatcher.bend -o disp.c >/dev/null 2>&1
echo "emit C dispatcher: $(ms $ms0) ms exit=$?"

ms0=$(python3 -c "import time; print(time.time())")
$CC -O1 -pthread disp.c -o disp >/dev/null 2>&1
echo "clang -O1 link dispatcher: $(ms $ms0) ms exit=$?"

ms0=$(python3 -c "import time; print(time.time())")
./disp >/dev/null
echo "native startup+run dispatcher: $(ms $ms0) ms exit=$?"

ms0=$(python3 -c "import time; print(time.time())")
$BEND dispatcher.bend >/dev/null 2>&1
echo "interpreted run dispatcher: $(ms $ms0) ms exit=$?"

ms0=$(python3 -c "import time; print(time.time())")
$BEND dispatcher.bend -o disp.js >/dev/null 2>&1
echo "emit JS dispatcher: $(ms $ms0) ms exit=$?"

ls -la disp disp.c disp.js 2>/dev/null | awk '{print $5, $9}'
echo "== emitted C size and binary size above"
