# Q4 REML Requested/Effective Audit

Goal:

- Bank SR135 by separating requested estimator labels from the estimator that
  actually runs for q4 phylogenetic rows.

What changed:

- Added
  `docs/dev-log/dashboard/structured-re-q4-reml-requested-effective-audit.tsv`
  with five validator-owned rows:
  - native TMB q4 ML is ML point evidence only;
  - native TMB q4 REML is unsupported;
  - direct DRM.jl q4 REML is route-specific Patterson-Thompson evidence;
  - R-via-Julia q4 REML is experimental Patterson-Thompson point-route evidence;
  - HSquared AI-REML transfer remains unsupported and not run.
- Wired the table into `tools/validate-mission-control.py` and the local
  dashboard renderer.
- Moved SR135 from `blocked` to `banked` as an audit row only.

Boundary:

- This does not promote native q4 REML, HSquared AI-REML, public bridge support,
  interval reliability, interval coverage, a commit, a PR, or an Ayumi-facing
  reply. SR160 remains the broader REML acceptance blocker until exact
  derivations, route-specific tests, docs, and claim scans exist.

Checks:

- `Rscript --vanilla -e "devtools::test(filter = 'structured-re-conversion-contracts')"`
  passed as part of the focused
  `structured-re-ademp-scaffold|structured-re-conversion-contracts` run with
  433 assertions total across the two contexts.
- `python3 tools/validate-mission-control.py` passed and reported five q4 REML
  requested/effective audit rows.
- `python3 -m json.tool docs/dev-log/dashboard/sweep.json` passed.
- `sh -n tools/start-mission-control.sh` passed.
- `git diff --check` passed.
- The served widget fetched build `r26` and
  `structured-re-q4-reml-requested-effective-audit.tsv` directly from
  `http://127.0.0.1:8765/`.
