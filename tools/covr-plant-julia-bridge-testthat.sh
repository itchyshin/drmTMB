#!/usr/bin/env bash
# Plant the Julia-bridge covr test driver at the covr install root.
# covr::package_coverage() sources <lib>/drmTMB/tests/testthat.R via
# tools::testInstalledPackage; this swaps in the Julia-only filter without
# editing the committed tests/testthat.R sharded driver.
#
# Usage: bash tools/covr-plant-julia-bridge-testthat.sh <install_path> <pkg_root>
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
driver_src=$pkg_root/tools/covr-julia-bridge-testthat.R
if [[ ! -f $driver_src ]]; then
  echo "missing driver: $driver_src" >&2
  exit 1
fi

dest=$install_path/drmTMB/tests/testthat.R
if [[ ! -d $(dirname "$dest") ]]; then
  echo "installed drmTMB tests directory missing: $(dirname "$dest")" >&2
  exit 1
fi

cp "$driver_src" "$dest"
echo "covr_julia_testthat=$dest"
