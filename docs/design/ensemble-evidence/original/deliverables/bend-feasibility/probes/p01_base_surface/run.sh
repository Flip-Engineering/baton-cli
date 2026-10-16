#!/bin/sh
# p01: Base surface inventory and refusals on the actual pinned toolchain.
# Records: absent durability/process names, present IO/Chan/TCP names.
set -u
BEND=/run/baton2-native-homelab/retained/baton2-compiler-741-20261015/postrelease-751-761-20261015-9/toolchain-home/bin/bend
export BEND_NO_TELEMETRY=1
echo "== bend version"; $BEND version; echo "exit=$?"
echo "== bend --help command list"; $BEND --help 2>&1 | sed -n '1,20p'
echo "== bend base --types | File names"
$BEND base File 2>&1
echo "exit=$?"
echo "== bend base IO (concurrency names)"
$BEND base IO 2>&1
echo "== absent-name refusals"
for name in File.sync File.rename File.stat File.mkdir Json exec Regex HTTP TLS; do
  out=$($BEND base "$name" 2>&1); code=$?
  echo "bend base $name -> exit=$code out=[$out]"
done
echo "== hidden --checkup presence (usage line, no run)"
$BEND 2>&1 | head -3
echo "exit=$?"
