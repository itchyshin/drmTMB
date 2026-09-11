# P3 heterogeneous AR1 — source fingerprint

- Child-plan source: `393d7eee1` (`feat: integrate temporal homogeneous Toeplitz phase`)
- Parent ledger: `docs/dev-log/plans/2026-09-09-temporal-covariance-programme/`
- P2 prerequisite closeout: `docs/dev-log/evidence/temporal-homtoep/2026-09-10-p2-closeout.md`
- Comparison source: glmmTMB covariance vignette, retrieved 2026-09-11; its heterogeneous covariance terms clarify that heterogeneous refers to marginal variances and that a full time-level design is needed. drmTMB retains its own `temporal()` grammar and independent oracle.
- Scope pin: univariate Gaussian location temporal covariance only; constant residual `sigma`; no temporal scale field.

A P3 implementation run must refresh this source commit and record hashes of every P3 runner and fixture generator before emitting evidence.
