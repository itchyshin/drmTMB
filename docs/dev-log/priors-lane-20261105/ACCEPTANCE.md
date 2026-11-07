# Gates: first fixed-effect priors

OWNS: R/fixed-effect-priors.R R/fixed-priors-workflow.R R/drmTMB.R src/drmTMB.cpp tests/testthat/test-fixed-effect-priors.R tests/testthat/test-fixed-priors-workflow.R docs/dev-log/priors-lane-20261105/**

Scope: approved Gaussian mu/sigma and binomial logit fixed-effect normal/ridge priors in isolated R and Julia lanes, with independent numeric validation and no merge/release.

- [x] G0: owner approved fixed-effect design and isolated Julia overlapping edits
  EVIDENCE: chat approval 2026-11-05; Julia overlap reply Yes, isolated prior-only changes.

- [x] G1: R constructor and numerical oracle suite passes on the compiled candidate
  CHECK: python3 docs/dev-log/priors-lane-20261105/verify-evidence.py r
  EXPECT: PRIORS_R_RECEIPT_PASS
  EVIDENCE: exit=0; shell=/bin/sh; cwd=/Users/z3437171/.codex/worktrees/drm-priors-design-20261105/drmTMB; path=8d424342f38b/44 entries; output=PRIORS_R_RECEIPT_PASS negative_controls=6

- [x] G2: Julia constructor and numerical oracle suite passes on the candidate
  CHECK: python3 docs/dev-log/priors-lane-20261105/verify-evidence.py julia
  EXPECT: PRIORS_JULIA_RECEIPT_PASS
  EVIDENCE: exit=0; shell=/bin/sh; cwd=/Users/z3437171/.codex/worktrees/drm-priors-design-20261105/drmTMB; path=8d424342f38b/44 entries; output=PRIORS_JULIA_RECEIPT_PASS

- [x] G3: matched R-Julia target fixtures agree within declared tolerances
  CHECK: python3 docs/dev-log/priors-lane-20261105/verify-evidence.py pair
  EXPECT: PRIORS_PAIR_RECEIPT_PASS
  EVIDENCE: exit=0; shell=/bin/sh; cwd=/Users/z3437171/.codex/worktrees/drm-priors-design-20261105/drmTMB; path=8d424342f38b/44 entries; output=PRIORS_PAIR_RECEIPT_PASS negative_controls=2

- [x] G4: documentation, inference guards, update/rebuild and no-prior regressions pass
  EVIDENCE: R closeout focused78 and affected10files pass; unused-dots, export and reader contracts pass; phylo fixture22tests pass; five live bridge fixtures pass; package check0errors/2unbuilt-vignette warnings; Julia focused82 and affected14files pass. Broad R residual3assertions reproduced on exact baseline; Julia full run exited124 at90minutes and remains incomplete, not a full-suite pass.

- [x] G5: independent review, source manifests, check log and after-task report complete
  EVIDENCE: scoped READY from Noether, independent integration reviewer and Pat; closeout integration diff re-reviewed READY; source manifests verified, check log and after-task complete, exact-draft assessments recorded, full-suite residuals explicit; no push merge or release.
