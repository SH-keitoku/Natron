#!/bin/bash
# [CI only] MSYS2 deprecated MINGW64 and dropped packages Natron needs (pyside6, shiboken6,
# openimageio, opencolorio, ...). Retarget the win-build scripts and CMake files from
# MINGW64 to UCRT64, where those packages are still maintained.
# Usage: retarget_ucrt64.sh <dir> [<dir> ...]
set -eu
for root in "$@"; do
  [ -d "$root" ] || continue
  grep -rlI --exclude-dir=.git --exclude-dir=.github \
       --include='*.sh' --include='CMakeLists.txt' --include='*.cmake' --include='*.py' \
       --include='Makefile*' --include='*.mk' \
       -e 'msys64/mingw64' -e 'mingw-w64-x86_64-' "$root" 2>/dev/null |
  while read -r f; do
    sed -i -e 's#/c/msys64/mingw64#/c/msys64/ucrt64#g' \
           -e 's#C:/msys64/mingw64#C:/msys64/ucrt64#g' \
           -e 's#mingw-w64-x86_64-#mingw-w64-ucrt-x86_64-#g' "$f"
    echo "retargeted: $f"
  done
done
