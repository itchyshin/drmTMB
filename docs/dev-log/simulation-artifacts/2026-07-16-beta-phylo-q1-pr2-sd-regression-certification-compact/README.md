# Beta phylogenetic q1 PR 2 certification: compact HOLD evidence

This directory is the tracked compact evidence packet for the frozen 4,800-fit
Totoro certification. It contains the complete design, seed audit, provenance,
4,800-row attempt table, summaries, quality gates, and promotion decision. The
atomic attempt shards and their complete manifest remain local and on Totoro;
they are not GitHub artifacts and are not duplicated as 9,600 repository files.
The local sealed copy is under
`/Users/z3437171/Dropbox/Github Local/drmTMB-local-artifacts/2026-07-16-beta-phylo-q1-pr2/`.

Before compaction, the full imported output passed
`authenticate_pr2_output()`. Its `output-manifest.tsv` SHA-256 was
`7e5532c61e0f97f107e54c0be43f438e2859421e8630129bbba529e91123459f`;
the completion-seal file SHA-256 was
`1e4a1462683943f53cd5db36741b716550efa27e07079982636e08ec54bec462`.
The exact source was
`2f1399dda78253ea725f93e47a0e88da2ed5a8e6` and the Totoro DLL SHA-256
was `13794968870e0603e382de7f322bfa6466a86c62b94201bf9f9bcb9fa4c85f0e`.

The frozen decision is `HOLD_NO_PR2_PROMOTION`. The distinct
`g = 1024, m = 4` arm passed. The shared arm retained 400 attempts but only
399 finite fits because replicate 373, seed `2099879627`, generated a response
outside Beta's strict interior support. The failed attempt was retained. No
rerun, filtering, replacement seed, gate change, ledger promotion, or PR 2 is
authorized by this evidence.
