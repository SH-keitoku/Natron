#!/bin/bash
# [CI only] Cycles' NODE_DEFINE runs get_node_type() during static initialisation,
# before the static node_type_mutex_ member (defined on the next line, and in other
# translation units) is constructed. With MSYS2 GCC 16 std::mutex is no longer
# constant-initialised, so locking it throws std::system_error(EINVAL) at startup.
# Use a function-local static mutex, which is constructed on first use.
# Usage: patch_cycles_static_mutex.sh <cycles dir>
set -eu
f="$1/src/graph/node_type.h"
[ -f "$f" ] || { echo "no $f"; exit 0; }
grep -q "node_type_local_mutex" "$f" && { echo "already patched"; exit 0; }
python3 - "$f" <<'PY'
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
old = "      thread_scoped_lock lock(node_type_mutex_); \\\n"
new = ("      static thread_mutex node_type_local_mutex; \\\n"
       "      thread_scoped_lock lock(node_type_local_mutex); \\\n")
assert s.count(old) == 1, "pattern not found"
s = s.replace(old, new)
open(p, "w", encoding="utf-8").write(s)
print("patched", p)
PY
