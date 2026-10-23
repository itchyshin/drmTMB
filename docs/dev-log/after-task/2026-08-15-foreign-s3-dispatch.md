# After Task: `ranef()` and `fixef()` dispatch regardless of attach order

## 1. Goal

Make `ranef(fit)` and `fixef(fit)` work for a drmTMB fit no matter which packages
the user has attached. The reader is an applied user who follows a tutorial that
loads `glmmTMB` or `lme4` alongside drmTMB, and who currently loses both verbs
for no reason they can see.

## 2. Implemented

`R/zzz.R`'s `.onLoad` gained `register_foreign_s3_methods()`, which registers
`fixef.drmTMB` and `ranef.drmTMB` against `nlme`'s generics when `nlme` is
installed. `nlme` added to `Suggests`. New test file
`tests/testthat/test-foreign-s3-dispatch.R`.

## 3a. Decisions and Rejected Alternatives

**Register on `nlme`, not on each package.** `lme4` and `glmmTMB` re-export
`nlme`'s generic rather than defining their own, verified by `identical()`. One
registration therefore covers all three, and will cover any future package that
follows the same convention.

**Dynamic registration, not a `NAMESPACE` directive.** An `@exportS3Method
nlme::ranef` roxygen tag would have to live beside the method in `R/methods.R`,
which is byte-pinned whole-file by the C17/C14 capability receipt — a one-character
change there fails CI. Dynamic registration in `.onLoad` also matches the fact that
`nlme` is genuinely optional: drmTMB does not import it and must load without it.
`NAMESPACE` is unchanged as a result.

**Rejected: changing `sigma()`.** It is already registered against `stats::sigma`,
which `lme4` and `glmmTMB` also use, so it was never at risk. A test records this
so a later contributor does not "fix" it by symmetry.

**Rejected: continuing to fix callers.** That is what the previous two repairs did.

## 5. Checks Run

| Check | Outcome |
| --- | --- |
| `test-foreign-s3-dispatch.R` | 12 pass, 0 fail, 0 skip |
| same file, fix disabled | **2 fail** — the test is non-vacuous |
| user scenario: attach `glmmTMB`, then `lme4`, after drmTMB | bare `ranef()`/`fixef()` both work |
| `test-reader-journeys.R` / `-public-schema.R` | 53 / 34, no failures or skips |
| `test-comparators-external-oracle.R` / `test-comparators.R` | 28 / 134, no failures or skips |
| `tools/check-reader-contracts.R` | OK |
| `capability_ledger.py --check` + 73 ledger tests | OK, C17 PASS |
| five receipt-pinned files | untouched |
| `NAMESPACE` | unchanged |

## 6. Tests of the Tests

The fix was disabled and the suite re-run: `nlme::ranef` and `nlme::fixef` both
error, 2 failures. Restored: 12 pass. The registration is also asserted
structurally, so dropping the `.onLoad` hook fails the suite even if drmTMB's own
generic still works.

## 9. What Did Not Go Smoothly

Two of my own assertions were wrong before the package was: `drmTMB::sigma` does
not exist (sigma is a method on the `stats` generic, which is the point), and
`getS3method()` searches more broadly than I assumed, so an expectation that it
return `NULL` for a foreign namespace was testing my misunderstanding rather than
the package. Both were corrected rather than worked around.

## 10. Known Residuals

- `R CMD check --as-cran` has not been run on this branch; CI will.
- Only `fixef` and `ranef` were audited for this class. Any future drmTMB generic
  whose name is shared with `nlme`, `lme4` or `glmmTMB` will need the same
  treatment, and nothing currently enforces that.

## 11. Team Learning

A masked generic is invisible to focused tests and shows up only when unrelated
work runs in the same session — here, eight vignettes failing under `--as-cran`
after one `library()` call. Two caller-side repairs preceded this one. The lesson
is to ask whether a masking incident is a caller mistake or a package defect;
twice it looked like the former and was the latter.
