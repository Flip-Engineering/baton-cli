#!/bin/sh
# p12: the checker delta between the prior audit's pin and the actual
# release toolchain: the template instantiation depth guard.
set -u
BEND=/run/baton2-native-homelab/retained/baton2-compiler-741-20261015/postrelease-751-761-20261015-9/toolchain-home/bin/bend
export BEND_NO_TELEMETRY=1
cd "$(dirname "$0")"
$BEND spin.bend --check-only 2>&1 | head -6
echo "exit=$?"
