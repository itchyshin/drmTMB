#!/usr/bin/env bash
# Plant the R CMD check 00_pkg_src layout that tests/testthat helpers
# drm_src_path / drm_pkg_path already resolve (Unix Rcheck: 00_pkg_src/drmTMB).
#
# covr::package_coverage() runs tools::testInstalledPackage from
# <lib>/drmTMB/drmTMB-tests/testthat, which has no package src/, R/, or man/.
# Those guards must still run; this harness makes the sanctioned layout
# visible without skipping or rewriting them.
#
# Usage: bash tools/covr-source-tree-layout.sh <install_path> <pkg_root>
set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "usage: $0 <install_path> <pkg_root>" >&2
  exit 2
fi

install_path=$1
pkg_root=$2

if [[ ! -d $pkg_root ]]; then
  echo "pkg_root is not a directory: $pkg_root" >&2
  exit 1
fi

pkg_root=$(cd "$pkg_root" && pwd)
mkdir -p "$install_path/00_pkg_src"
dest=$install_path/00_pkg_src/drmTMB
rm -rf "$dest"
ln -s "$pkg_root" "$dest"

needed=(
  DESCRIPTION
  R/drmTMB.R
  man/is_converged.Rd
  src/drmTMB.cpp
)
missing=()
for rel in "${needed[@]}"; do
  if [[ ! -e $dest/$rel ]]; then
    missing+=("$rel")
  fi
done
if ((${#missing[@]})); then
  echo "00_pkg_src/drmTMB missing: ${missing[*]}" >&2
  exit 1
fi

# The locator walks up from covr's testthat cwd to the library root and
# looks for 00_pkg_src/drmTMB/{src,R,man}/.... That candidate must exist
# before package_coverage() starts tests.
echo "covr_pkg_src=$dest"
echo "pkg_root=$pkg_root"
