#!/usr/bin/env bash
set -u
b=/home/snakagaw/hsq_work/drm-priors-20261105-01a1ad0b
out="$b/bridge-recheck-b867-f940"
r="$b/r-bridge-b867-src"
j="$b/j-bridge-f940-clean"
export OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 JULIA_NUM_THREADS=1 MAKEFLAGS=-j1
export JULIA_HOME=/home/snakagaw/hsq_work/julia-1.10.10/bin JULIA_DEPOT_PATH="$b/julia-depot:/home/snakagaw/.julia"
export DRM_JL_PATH="$j" DRMODELS_JL_PATH="$j" R_LIBS_USER="$b/r-bridge-b867-lib:/home/snakagaw/R/lib" R_PROFILE_USER=/dev/null NOT_CRAN=true
unset R_MAKEVARS_USER
cd "$r"
test "$(git rev-parse HEAD)" = b86709e16b477c4d232eaec16e9567ec12e136fa || exit 10
test "$(git -C "$j" rev-parse HEAD)" = f940fc4042ee2832c3343f7d334e830a96942f1b || exit 11
printf "R b86709e16b477c4d232eaec16e9567ec12e136fa\nJulia f940fc4042ee2832c3343f7d334e830a96942f1b\nR CMD INSTALL --preclean --no-multiarch --with-keep.source --library=r-bridge-b867-lib r-bridge-b867-src\nenv LD_PRELOAD=Julia-1.10.10/lib/julia/libunwind.so.8.0.1 Rscript --no-init-file tools/run-julia-phylo-labels-public.R JULIA_ROOT NEW_JSON tree\nRscript --no-init-file tools/check-julia-phylo-labels-receipt.R NEW_JSON --current --self-test\n" > "$out/commands.txt"
date -u > "$out/start.utc"
R CMD INSTALL --preclean --no-multiarch --with-keep.source --library="$b/r-bridge-b867-lib" "$r" > "$out/install.log" 2>&1
s=$?; printf "%s\n" "$s" > "$out/install.exit"; [ "$s" -eq 0 ] || exit "$s"
new=docs/dev-log/priors-lane-20261105/release-default-bridge-recheck/current.json
mkdir -p "$(dirname "$new")"
env LD_PRELOAD=/home/snakagaw/hsq_work/julia-1.10.10/lib/julia/libunwind.so.8.0.1 Rscript --no-init-file tools/run-julia-phylo-labels-public.R "$j" "$new" tree > "$out/runner.log" 2>&1
s=$?; printf "%s\n" "$s" > "$out/runner.exit"; [ "$s" -eq 0 ] || exit "$s"
Rscript --no-init-file tools/check-julia-phylo-labels-receipt.R "$new" --current --self-test > "$out/checker.log" 2>&1
s=$?; printf "%s\n" "$s" > "$out/checker.exit"; [ "$s" -eq 0 ] || exit "$s"
Rscript - "$new" > "$out/fixture-comparison.log" 2>&1 <<'RS'
args<-commandArgs(TRUE); a<-jsonlite::fromJSON("docs/dev-log/evidence/julia-r-parity/lss-tip-identity/public-001.json"); b<-jsonlite::fromJSON(args[[1]])
stopifnot(identical(a$result$labels,b$result$labels),identical(a$result$direct_order,b$result$direct_order),identical(a$result$permutation,b$result$permutation),isTRUE(all.equal(a$result$data,b$result$data,tolerance=1e-14,check.attributes=FALSE)),isTRUE(all.equal(a$result$tree_edge,b$result$tree_edge,tolerance=0)),isTRUE(all.equal(a$result$tree_edge_length,b$result$tree_edge_length,tolerance=0)),isTRUE(all.equal(a$result$group_covariate,b$result$group_covariate,tolerance=1e-14)))
cat("HISTORICAL_FIXTURE_MATCH labels=12 rows=72 direct_order=tree\n")
RS
s=$?; printf "%s\n" "$s" > "$out/fixture-comparison.exit"; [ "$s" -eq 0 ] || exit "$s"
while read -r hash path; do test "$(git hash-object "$path")" = "$hash" || exit 12; done < "$out/r-blob-manifest.txt"
while read -r hash path; do test "$(git hash-object "$j/$path")" = "$hash" || exit 13; done < "$out/julia-blob-manifest.txt"
printf "SOURCE_BLOBS_BEFORE_AFTER_IDENTICAL\n" > "$out/source-after.log"
date -u > "$out/end.utc"
