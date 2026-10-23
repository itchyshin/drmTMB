# drmTMB 0.7.0 CRAN Release Recon — S0 Inventory

**Execution date:** 2026-08-15  
**Branch:** `claude/07-cran-ladder` (current with `origin/main`)  
**Worktree:** `/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/cran-07`

---

## A. Gate 1 items

**Report source:** `/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/cran-07/docs/dev-log/release/0.7.0-cran-gate/RUNG-REPORT-0.7.0.md:123`

**Stated summary:** "SHIP 4 · EXCLUDE 0 · UNRESOLVED 2"

### Status of enumeration

**The two unresolved items are NOT explicitly named in RUNG-REPORT-0.7.0.md.** The report states the summary only. The ledger and evidence files disclose the gaps:

**Ledger source:** `/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/cran-07/docs/dev-log/release-audits/2026-08-11-070-cran-release-ledger.json:98`

"gate1_unresolved_items": "RUNG-REPORT-0.7.0.md Gate 1 records 'SHIP 4 · EXCLUDE 0 · UNRESOLVED 2'. Two rights/product-contract items remain unresolved and are not resolved by this ledger."

### Identified unresolved items

From `known_evidence_gaps` in the ledger:

1. **UNRESOLVED 1: Rights review for Binomial link generalisation borrowing**
   - **Source:** Ledger lines 97–98
   - **Description:** The cited rights skim (dated 2026-08-07 at commit `8df6f2402`) predates the candidate (`a75c3c901`). The candidate ships a later borrowing: `inst/COPYRIGHTS` section *"Binomial link generalisation -- probit/cloglog dispatch and log-pnorm (2026-08-09)"*, adapting gllvmTMB commit `431e173f7198f74c356ec3099ffa211f1ee85fd0` (GPL-3), including `drm_log_pnorm()` in `src/drm_numeric.h`. The borrowing IS documented with upstream commit and line-level provenance, so it is not undocumented; the gap is that **no rights review has covered it.**
   - **Must be closed before:** submission-ready

2. **UNRESOLVED 2: Product-contract and rendered-site evidence freshness**
   - **Source:** Ledger lines 99–101
   - **Description:** The product-contract and rendered-site evidence describe commit `8df6f2402`; 339 files changed between that commit and the candidate (`a75c3c901`), including a new vignette (`vignettes/first-week-intervals.Rmd`) and a new Suggests (`detectseparation`). No rendered-site check covers the candidate. Also, NEWS.md on main was corrected (2026-08-11) so it no longer claims "First CRAN release" for an unreleased package—a shipped file—so the frozen candidate no longer represents main's shipped source.
   - **Must be closed before:** submission-ready (re-freeze required)

### The SHIP 4 items

**NOT ENUMERATED.** RUNG-REPORT does not name them. `inst/COPYRIGHTS` documents three borrowing components (see section C below); a fourth SHIP item is inferred but not stated. The 4 SHIP items remain mechanically unidentified in the release gate documentation.

---

## B. Version pins — literal `0.7.0` audit

**Search scope:** DESCRIPTION, NEWS.md, R/, tests/, tools/, _pkgdown.yml, vignettes/, man/, inst/, .github/, docs/dev-log/dashboard/

### PIN-class version references (code/test that would break)

| File | Line | Context | Classification | Notes |
|------|------|---------|-----------------|-------|
| DESCRIPTION | 3 | `Version: 0.7.0` | **PIN** | Would require manual update if bumped to 0.7.0.9000 |

**Total PIN-class hits: 1**

### DOC-class version references (prose references, harmless)

| File | Line | Context | Classification | Notes |
|------|------|---------|-----------------|-------|
| NEWS.md | 1 | `# drmTMB 0.7.0` | DOC | Section header |
| NEWS.md | 95 | `## Binomial models accept probit and cloglog links (new in 0.7.0)` | DOC | Prose feature note |
| NEWS.md | 835 | `is `0.7.0`** (decided 2026-07-25).*` | RELEASE-EVIDENCE | Historical decision record in versioning note |
| tests/testthat.R | 9 | `# in docs/dev-log/release/0.7.0-cran-gate/test-timings.csv)` | DOC | Comment referencing evidence file path |
| vignettes/comparing-with-other-packages.Rmd | 299 | `in `drmTMB` 0.7.0:` | DOC | Prose comparison note |
| _pkgdown.yml | 7 | `'0.6.0 experimental'` | DOC | navbar version label (note: 0.6.0, not 0.7.0) |

**Note on 0.6.0 references (not part of 0.7.0 bump audit):**
- vignettes/drmTMB.Rmd:59 — `'0.6.0' line) from GitHub`
- vignettes/drmTMB.Rmd:67 — `a '0.6.0' release will be tagged`
- vignettes/capability-and-limits.Rmd:476 — `### Known limitations for 0.6.0`
- vignettes/capability-and-limits.Rmd:514 — `post-0.6.0`

These reference the predecessor version and do not require changes for the 0.7.0 → 0.7.0.9000 bump.

---

## C. COPYRIGHTS borrowing block

**Source file:** `/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/cran-07/inst/COPYRIGHTS`

### Full Binomial link generalisation section

**File:lines:** `inst/COPYRIGHTS:53–80`

```
## Binomial link generalisation -- probit/cloglog dispatch and log-pnorm (2026-08-09)

Two things are adapted from gllvmTMB commit `431e173f7198f74c356ec3099ffa211f1ee85fd0`
(GPL-3), per `docs/design/252-binomial-link-generalisation.md`:

1. The link-DISPATCH PATTERN (not the numerics): gllvmTMB's `family_to_id()`
   at `R/fit-multi.R:441-450`/`:375-`(`switch(f$link, logit = 0L, probit = 1L,
   cloglog = 2L, ...)`) and the paired C++ `DATA_IVECTOR(link_id_vec)` /
   `if (lid == 0) ... else if (lid == 1) ... else if (lid == 2)` dispatch at
   `src/gllvmTMB.cpp:2185-2196` motivate drmTMB's `link_code` integer
   (0 = logit, 1 = probit, 2 = cloglog) plumbed as a single `DATA_INTEGER`
   alongside the existing `model_type == 18` binomial family tag.

2. The tail-safe log-scale normal CDF `drm_log_pnorm()` in `src/drm_numeric.h`
   is closely adapted from gllvmTMB's `gll_log_pnorm()` at
   `src/gllvmTMB.cpp:112-146` (Mills-ratio asymptotic expansion below x = -20,
   direct `log(pnorm(x))` above it).

drmTMB deliberately does NOT adopt gllvmTMB's probability-scale clamp
(`gll_clamp(p, 1e-12, 1 - 1e-12)` before `dbinom()`, `src/gllvmTMB.cpp:2196-2199`).
That clamp is a downgrade against drmTMB's existing log-scale `logspace_add`
binomial path: every drmTMB binomial link (logit, probit, cloglog) is
evaluated as `log(mu)`/`log(1-mu)` on the log scale throughout
(`drm_binom_log_mu()` in `src/drm_numeric.h`), with no probability-scale
floor or ceiling. `drm_binom_log_mu_eta()` (the `log|dmu/deta|` primitive for
the MSPL Jeffreys weight) is independently derived, not adapted from
gllvmTMB, which has no MSPL-style penalty.
```

### Actual `drm_log_pnorm()` definition

**Source file:** `/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/cran-07/src/drm_numeric.h:76–89`

```c++
template<class Type>
Type drm_log_pnorm(Type x)
{
  Type cut = Type(-20.0);
  Type xa = CppAD::CondExpLt(x, cut, x, cut);            // min(x, -20)
  Type inv2 = Type(1.0) / (xa * xa);
  Type series = Type(1.0) - inv2 * (Type(1.0) - Type(3.0) * inv2 *
                (Type(1.0) - Type(5.0) * inv2 *
                (Type(1.0) - Type(7.0) * inv2)));
  Type tail = -Type(0.5) * xa * xa - log(-xa) -
    Type(0.5) * log(Type(2.0) * M_PI) + log(series);
  Type xd = CppAD::CondExpLt(x, cut, cut, x);            // max(x, -20)
  Type direct = log(pnorm(xd));
  return CppAD::CondExpLt(x, cut, tail, direct);
}
```

### References to `drm_log_pnorm()` in the codebase

| File | Line(s) | Context |
|------|---------|---------|
| `src/drm_numeric.h` | 76 | Function definition (template) |
| `src/drm_numeric.h` | 108 | `out.log_mu = drm_log_pnorm(eta);` in probit branch of `drm_binom_log_mu()` |
| `src/drm_numeric.h` | 109 | `out.log_one_minus_mu = drm_log_pnorm(-eta);` in probit branch of `drm_binom_log_mu()` |

### drmTMB License statement

**Source:** `/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/cran-07/DESCRIPTION:25`

```
License: GPL (>= 3)
```

### Upstream source statement

**gllvmTMB commit:** `431e173f7198f74c356ec3099ffa211f1ee85fd0` (GPL-3)

**Upstream file references:**
- gllvmTMB `R/fit-multi.R:441-450` — link-dispatch pattern
- gllvmTMB `src/gllvmTMB.cpp:112-146` — `gll_log_pnorm()` implementation
- gllvmTMB `src/gllvmTMB.cpp:2185-2196` — binomial dispatch logic

---

## Summary

| Item | Count | Status |
|------|-------|--------|
| **PIN-class version references** | **1** | DESCRIPTION line 3 |
| **DOC-class version references** | **6** | NEWS.md (3), tests/testthat.R (1), vignettes (2) |
| **Gate 1 SHIP 4 items enumerated** | 0 | **NOT NAMED in any release doc** |
| **Gate 1 UNRESOLVED 2 items identified** | 2 | Rights review gap (Binomial borrowing); product-contract freshness gap |

**The two Gate 1 unresolved items are identifiable from ledger `known_evidence_gaps` but were never explicitly enumerated in the RUNG-REPORT or any release-gate document.**
