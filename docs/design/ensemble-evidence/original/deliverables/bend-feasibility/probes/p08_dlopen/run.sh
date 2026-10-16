#!/bin/sh
# p08: runtime native extension via dlopen through an authored effect.
set -u
BEND=/run/baton2-native-homelab/retained/baton2-compiler-741-20261015/postrelease-751-761-20261015-9/toolchain-home/bin/bend
export BEND_NO_TELEMETRY=1
export CC=/usr/bin/clang-19
cd "$(dirname "$0")"
rm -rf work out && mkdir -p work out
echo "== build extension library (separate artifact, no checker verdict)"
$CC -O1 -shared -fPIC ext.c -o work/libext.so || exit 1
echo "== emit + link seat"
$BEND dlopen.bend -o out/dl.c && $CC -O1 -pthread out/dl.c -o out/dl -ldl || exit 1
cd work
echo "== native run"
../out/dl
echo "exit=$?"
