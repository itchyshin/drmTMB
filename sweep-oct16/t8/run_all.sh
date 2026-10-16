#!/usr/bin/env bash
set -u
export T8_ROOT="${T8_ROOT:-/workspace/sweep-oct16/t8}"
export R_LIBS_USER="${R_LIBS_USER:-/home/ubuntu/R/library}"
CASES=(
  warpbreaks:120
  ToothGrowth:120
  Prestige:120
  GasolineYield:180
  ReadingSkills:180
  quine:180
  crowder_seeds:180
  beall_webworms:180
  cbpp:180
  epil:180
  Orthodont:180
  yates_oats:180
  Pastes:180
  bacteria:180
  Owls:180
)
for item in "${CASES[@]}"; do
  id="${item%%:*}"
  to="${item##*:}"
  bash "$T8_ROOT/run_case.sh" "$id" "$to"
done
echo "ALL_CASES_DONE $(date -u +%FT%TZ)"
