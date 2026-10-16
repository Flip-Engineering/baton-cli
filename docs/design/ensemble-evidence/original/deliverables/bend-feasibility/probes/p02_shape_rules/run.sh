#!/bin/sh
# p02: checker shape rules on the actual pinned toolchain.
set -u
BEND=/run/baton2-native-homelab/retained/baton2-compiler-741-20261015/postrelease-751-761-20261015-9/toolchain-home/bin/bend
export BEND_NO_TELEMETRY=1
cd "$(dirname "$0")"
for prog in match_in_do computed_scrutinee closure_twice dispatcher waitloop; do
  echo "== $prog.bend --check-only"
  out=$($BEND "$prog.bend" --check-only 2>&1); code=$?
  echo "$out"
  echo "exit=$code"
done
echo "== dispatcher.bend interpreted run"
$BEND dispatcher.bend; echo "exit=$?"
echo "== waitloop.bend interpreted run"
$BEND waitloop.bend; echo "exit=$?"
