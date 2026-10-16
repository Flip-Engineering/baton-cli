#!/bin/sh
# p09: law-gated admission and record forgeability.
set -u
BEND=/run/baton2-native-homelab/retained/baton2-compiler-741-20261015/postrelease-751-761-20261015-9/toolchain-home/bin/bend
export BEND_NO_TELEMETRY=1
cd "$(dirname "$0")"
echo "== hostprog --check-only with open law in import (expect TODO error)"
$BEND hostprog.bend --check-only; echo "exit=$?"
echo "== hostprog --checkup (per-import check+run markers)"
$BEND hostprog.bend --checkup; echo "exit=$?"
echo "== reflexivity proof attempt (expect expected/observed mismatch)"
$BEND proof.bend --check-only 2>&1 | head -8; echo "exit=${?}"
echo "== forge.bend interpreted run (forged record accepted)"
$BEND forge.bend; echo "exit=$?"
