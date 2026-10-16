#!/bin/sh
# p10: in-process evaluation of a .bend module from a JS host via the
# compiler's bun plugin (main.ts default export; GUIDE.md "a JS file may
# import Game from ./game.bend").
set -u
TC=/run/baton2-native-homelab/retained/baton2-compiler-741-20261015/postrelease-751-761-20261015-9/toolchain-home
export BEND_NO_TELEMETRY=1
cd "$(dirname "$0")"
$TC/bin/bun --preload "$TC/bend2/main.ts" host.mjs
echo "exit=$?"
