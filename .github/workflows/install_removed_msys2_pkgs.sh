#!/bin/bash
# [local patch] MSYS2 deprecated the MINGW64 environment and dropped some leaf
# packages Natron still needs (pyside2, shiboken2, python-qtpy, breakpad-git).
# Install them directly from the MSYS2 mirror if pacman can no longer find them.
set -u

MIRROR=https://mirror.msys2.org/mingw/mingw64
INDEX=/tmp/msys2_mingw64_index.html
wget -q -O "${INDEX}" "${MIRROR}/" || { echo "Could not fetch mirror index"; exit 1; }

PKGS=()
for p in shiboken2 pyside2 python-qtpy breakpad-git; do
    name="mingw-w64-x86_64-${p}"
    if pacman -Si "${name}" >/dev/null 2>&1; then
        echo "${name} is available from pacman repos"
        continue
    fi
    f=$(grep -oE "\"${name}-[0-9r][^\"/]*-any\.pkg\.tar\.(zst|xz)\"" "${INDEX}" | tr -d '"' | sort -uV | tail -1)
    if [ -z "${f}" ]; then
        echo "WARNING: ${name} not found on mirror"
        continue
    fi
    echo "Downloading ${f}"
    wget -q "${MIRROR}/${f}" && PKGS+=("${f}")
done

if [ ${#PKGS[@]} -gt 0 ]; then
    pacman -U --needed --noconfirm --overwrite "*" "${PKGS[@]}"
fi
