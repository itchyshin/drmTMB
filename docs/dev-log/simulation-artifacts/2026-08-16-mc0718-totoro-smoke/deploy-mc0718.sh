#!/usr/bin/env bash
# Clone cursor/ng-correlated-slope-wave2 onto Totoro and install into a
# dedicated library. Does not launch the 27-fit smoke.

set -euo pipefail

REPO="${DRMTMB_REPO:-$HOME/hsq_work/drmTMB-mc0718}"
LIB="${DRMTMB_LIB:-$HOME/hsq_work/drmTMB-mc0718-library}"
BRANCH="cursor/ng-correlated-slope-wave2"
EXPECT_SHA="${DRMTMB_EXPECT_SHA:-3e8a9aaec9aae3e20a5e3bbd46fb65561304e368}"

mkdir -p "$(dirname "$REPO")" "$LIB"

if [[ ! -d "$REPO/.git" ]]; then
  git clone --branch "$BRANCH" --single-branch \
    https://github.com/itchyshin/drmTMB.git "$REPO"
else
  git -C "$REPO" fetch origin "$BRANCH"
  git -C "$REPO" checkout "$BRANCH"
  git -C "$REPO" reset --hard "origin/$BRANCH"
fi

cd "$REPO"
HEAD="$(git rev-parse HEAD)"
echo "HEAD=$HEAD"
if [[ "$HEAD" != "$EXPECT_SHA" ]]; then
  echo "REFUSED: HEAD $HEAD != expected $EXPECT_SHA" >&2
  exit 2
fi

if ! R_PROFILE_USER=/dev/null Rscript --no-init-file -e 'if (!requireNamespace("glmmTMB", quietly=TRUE)) quit(status=2)'; then
  echo "REFUSED: glmmTMB missing. Do not switch to glmer." >&2
  exit 2
fi

R_PROFILE_USER=/dev/null Rscript --no-init-file -e \
  "install.packages('.', repos=NULL, type='source', lib='$LIB', INSTALL_opts='--no-multiarch')"

R_PROFILE_USER=/dev/null Rscript --no-init-file -e \
  ".libPaths(c('$LIB', .libPaths())); stopifnot(requireNamespace('drmTMB', quietly=TRUE)); cat(as.character(packageVersion('drmTMB')), '\n')"
