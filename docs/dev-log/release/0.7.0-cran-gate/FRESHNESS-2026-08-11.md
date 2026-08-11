# Candidate freshness re-verified — 2026-08-11

**The 0.7.0 candidate is NOT stale.** `main` has moved three times and the candidate branch five
since the tarball was cut, and the artifact still describes exactly what would ship.

Recorded because the *predecessor* candidate went stale in about three hours and nobody noticed until
its platform evidence was already being cited. Re-deriving this check costs ten minutes; reading it
costs ten seconds.

## The artifact this concerns

| field | value |
| --- | --- |
| tarball | `drmTMB_0.7.0.tar.gz` |
| SHA-256 | `2176e4b81b887e8d944456e4a74fa581afda959d0d2a5468c89bc700d693cda9` |
| source commit | `a75c3c901` (cut when `main` was `6065b90e5`) |

## What moved, and why none of it reaches the tarball

**`main`: `6065b90e5` → `256e586e5`, 13 commits.**

| PR | subject | paths |
| --- | --- | --- |
| #992 | remove a leftover merge-conflict marker from check-log | `docs/` |
| #995 | F1 TMB-Laplace finiteness campaign | `docs/` |
| #997 | F2 + F2b rare-prevalence campaign | `docs/` |
| #998 | C17 re-certification tool (issue #979) | `tools/` |

**Candidate branch: `a75c3c901` → `6ec09d30c`, 5 commits**, all `docs/` — the freeze notes, the rung
report, the rewritten `cran-comments.md` (itself `.Rbuildignore`d), the handover, and the arc closeout.

Every changed path across both sets is under `docs/` or `tools/`.

## Proven from the tarball, not from `.Rbuildignore`

Gate 1 requires exclusions be proven by listing the built tarball. From
`tarball-0.7.0-inventory.txt`, the inventory of the frozen artifact:

```
paths in tarball                : 937
paths under docs/ or tools/     : 0
```

`.Rbuildignore` lines 10 (`^docs$`) and 16 (`^tools$`) are the mechanism; the inventory is the proof.

## Stored copies — all three byte-identical

Verified 2026-08-11 by `shasum -a 256`:

| copy | result |
| --- | --- |
| `~/drmTMB-release-artifacts/0.7.0/drmTMB_0.7.0.tar.gz` | **MATCH** |
| `/private/tmp/drmTMB-07-freeze2/drmTMB_0.7.0.tar.gz` | **MATCH** (volatile — macOS purges `/private/tmp`) |
| `~/drmTMB_0.7.0_cand2.tar.gz` on Totoro | **MATCH** |

## What this does and does not establish

**Does:** the platform evidence gathered against `2176e4b8…` still describes the bytes that would be
submitted. No re-freeze and no re-run of 3-OS, sanitizers or valgrind is needed on account of these
13 + 5 commits.

**Does NOT:** advance any rung. The highest proven rung remains **`tarball-clean`** and the next
unproven remains **`platform-clean`**, still blocked on **win-builder (ABSENT)** and the consequent
**unmeasured Windows CRAN-lane time** — projected ~11 min against CRAN's ~10-minute incoming
threshold, which the release protocol treats as a blocker for a first submission even when the status
is only a NOTE. Those two are one action: win-builder measures the timing and closes the last platform
class.

**This check is perishable.** It held as of `main` `256e586e5` and candidate `6ec09d30c`. Any later
commit touching a path *not* under `docs/` or `tools/` invalidates it, and the artifact must be
re-frozen and its platform evidence re-run.

## Update — #996 merged; `main` now EQUALS the artifact

**PR #996 merged as `a3217da93`.** That brought the candidate's own `DESCRIPTION` (0.7.0) and
`NEWS.md` onto `main` — the first tarball-visible change since the cut, and by the paragraph above it
triggers a re-check.

Re-checked, and it **strengthens** rather than invalidates:

```
git diff --name-only a75c3c901 origin/main -- R/ src/ tests/ man/ vignettes/ \
                                              NAMESPACE DESCRIPTION inst/ data/
(empty)
```

`main`'s shipped surface is now **byte-equal to the frozen tarball's**. `DESCRIPTION` reads
`Version: 0.7.0` on both. The change that triggered the re-check *was the candidate landing*, so it
moved `main` onto the artifact rather than away from it — the one case where a tarball-visible commit
does not stale the evidence.

**Perishability now reads from `main` `a3217da93`.** The next commit touching a shipped path *will*
stale it, because there is no longer any gap for it to close.
