#!/bin/sh
# p12: checker delta between the prior audit's pin and the actual release
# toolchain. The compiler's own exit status is captured separately from
# any pipeline wrapper status.
set -u
BEND=/run/baton2-native-homelab/retained/baton2-compiler-741-20261015/postrelease-751-761-20261015-9/toolchain-home/bin/bend
export BEND_NO_TELEMETRY=1
cd "$(dirname "$0")"
$BEND spin.bend --check-only > spin.stderr 2>&1
code=$?
head -8 spin.stderr
echo "bend_exit=$code"
