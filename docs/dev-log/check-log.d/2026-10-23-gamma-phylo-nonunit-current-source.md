# Gamma phylogenetic SD non-unit-height current-source rerun

- R candidate: `codex/general-sd-regression` at `425bee81572c625a634b2b083050c5c57c1dc1f1`.
- Julia candidate: `codex/general-sd-regression` at `70dbf564eb670144c63c08f61ea099084d95add2`.
- The existing focused live bridge test passed 6 assertions, with 1 live Julia bridge test and exit code 0.
- It checks convergence, target coefficient names and agreement, and tip-level SD prediction agreement for the same Gamma fixture on a tree of maximum tip height 6.404475. Julia warns that `sd_phylo` is on its raw branch-length scale.
- The current-source rerun is needed because multiple implementation hashes differ from the earlier receipt. No product code changed.
- This is one same-data candidate parity fixture only; it does not establish recovery, calibrated uncertainty, arbitrary tree scaling, or general family/provider parity.
- Manifest, full console, and source hashes: `docs/dev-log/evidence/gamma-phylo-nonunit-current-source-20261023/`.
