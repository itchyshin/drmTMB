## Mechanical verification receipt

- Branch/HEAD: `codex/fixed-design-binary-separation-experiment` / `b441227fa0e11f9ab4347fc963266801cfb75a5f`
- Exact packages:
  - `drmTMB 0.6.0`: `/private/tmp/drmTMB-separation-s0-pkglib/drmTMB`
  - `detectseparation 0.4.0`: `/private/tmp/drmTMB-separation-s0-rlib/detectseparation`
  - Tarball SHA-256: `339d4384735934466826812c2a8ece689e03b0d5d620a3cbe1602cb9f35a59de`

Command exited `1` with the declared core-gate message. TSV was deterministically rewritten with unchanged SHA-256.

- Script SHA-256: `bda50d37438ec24c8146ab2fd482ccc294c373187303062ed0592a948acd919a`
- TSV SHA-256: `efc0c296fa2e7117436593cfe662c454a5937506ad4bea9207f4ce7b92d2c030`

Counts: 82 rows; 51 fit; 31 gate; 30 PASS; 1 FAIL; 0 fit errors. Required fields are non-empty.

Exact failure:

`mu_complete / detectseparation / (Intercept) / oracle -Inf / expected finite`

Controls were not run; no `binomial_controls` or hurdle rows exist. Intercept-only designs have one column and pass `+Inf`/`-Inf`. Rank-deficient control was preclassified with detector `not_run`. Grouped/expanded core gates pass.

Session: R 4.6.0, aarch64-apple-darwin23, macOS Tahoe 26.6.

File fence: no tracked changes; exactly the five expected S0 artifacts are untracked.

**Verdict: `MECHANICAL_STOP_EVIDENCE_VALID`**