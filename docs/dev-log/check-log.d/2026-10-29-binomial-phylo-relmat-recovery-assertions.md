# Check log: Binomial phylo and relmat recovery assertions

- Date: 2026-10-29
- Candidate: drmTMB `425bee81572c625a634b2b083050c5c57c1dc1f1` plus its current working tree.
- Command: `Rscript -e 'devtools::test(filter = "binomial-phylo-relmat-sd", reporter = "summary", stop_on_failure = TRUE)'`
- Result: exit 0. The fixed-seed logit, probit, and cloglog fits passed the strengthened direction and magnitude checks, including the covariance/precision comparisons.
- Scope: focused native recovery assertions only. No interval calibration, coverage, Julia parity, or support-status promotion.
- Detailed report: `docs/dev-log/after-task/2026-10-29-binomial-phylo-relmat-recovery-assertions.md`.
