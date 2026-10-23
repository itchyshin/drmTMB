# After-task — p-1156: `profile_targets()` must close over what `confint()` accepts on a Julia fit

- **Date**: 2026-09-05
- **Branch**: `claude/parity-p-1156-profile-targets`
- **Worktree**: `/Users/z3437171/local-scratch/parity-joint/wt-p-1156`
- **Pin**: DRM.jl `430ef64cc` at `/Users/z3437171/local-scratch/parity-joint/drmjl-430ef64cc`
- **Issue**: drmTMB #1156 (CLOSED before this leaf opened, by PR #1178)
- **Ledger**: `.unlazy/parity/gates/leaf-p-1156-profile-targets.md`
- **Raw measurement log**: `docs/dev-log/evidence/2026-09-05-p1156-profile-targets-live-measure.log`

## 1. Goal

Measure, at the pin, the two claims the collaborator-facing julia-engine docs
still make about `profile_targets()` on an `engine = "julia"` fit -- that it
UNDER-REPORTS, and that the two engines expect DIFFERENT target names -- then
close whatever is still true, with a test that fails if any target `confint()`
accepts is missing from the list, plus a red control.

## 2. Resume note

Nothing carried over. The branch is complete and its PR is open, not merged.

An earlier dispatch of this leaf left uncommitted work in this worktree. It was
read, not discarded wholesale: its `R/julia-bridge.R` helpers were kept (after
review and rewriting of every comment to cite THIS run's numbers), and its
`R/profile.R` hunk -- which deleted `drm_julia_wald_scale_targets()` from
`drm_julia_profile_target_union()` -- was DISCARDED. Red control 1 below shows
that hunk is a genuine regression: it drops `sigma` from the inventory and
breaks 15 assertions, 3 of them the closure gates this leaf exists to add.

## 3. Implemented

`R/julia-bridge.R` only. `R/profile.R` is byte-identical to `origin/main`.

- `drm_julia_lss_dpar_aliases(object)` -- derives, from the fit's OWN formula,
  the map from the canonical native location-scale-scale dpar
  (`sd_phylo(species)`) to the bridge's block key (`sd_phylo`). Empty for a fit
  with no `sd()`/`sd_phylo()` submodel.
- `drm_julia_canonicalise_parm(object, parm, targets)` -- rewrites a canonical
  `fixef:sd_phylo(species):z` to the bridge's `fixef:sd_phylo:z`, but ONLY when
  the rewrite lands on a real target of that fit, so a bogus term is still
  refused and the error quotes what the user typed.
- `drm_julia_listed_not_dispatchable(object, parm, dispatchable)` -- for a name
  that `profile_targets()` LISTS but `method = "profile"`/`"bootstrap"` cannot
  dispatch, aborts with the truth (listed, its inventory note, the profile-ready
  alias to use, and the profile-ready target list) instead of
  `Unknown confidence-interval target`.
- Two call sites: `confint.drmTMB_julia()` (canonicalise + listed-check) and
  `drm_julia_wald_confint()` (canonicalise).

Three further defects were found in the adversarial re-read pass and fixed
before the PR:

- **Ambiguous block key.** `bf()` accepts two `sd()` submodels on different
  grouping factors -- verified this run: `bf(y ~ x + (1 | g1) + (1 | g2),
  sigma ~ 1, sd(g1) ~ z, sd(g2) ~ w)` yields dpars `mu | sigma | sd(g1) |
  sd(g2)` -- and BOTH reduce to the bridge block key `sd`. Without a guard a
  canonical name would have silently resolved to whichever group came first.
  The alias map now fails closed and returns no alias for a duplicated key
  (red control 4).
- **`NA` tmb_parameter.** A logical subset containing `NA` returns `NA`
  elements, so a listed row with `tmb_parameter = NA` would have made the error
  message name `NA` as the alias to use. Guarded with an explicit `is.na()`
  branch and `which()`.
- **Width-dependent assertion.** cli wraps its hint at console width, so a
  target name can be split across lines; the message assertions now match a
  whitespace-normalised copy rather than the width this suite happens to use.

Documentation: `docs/design/258-coefficient-naming-contract.md` section 9 (which
spelling is canonical and why); `NEWS.md` (one entry); this report.

## 4. Measurements (D-139)

All measured in this run, at DRM.jl pin `430ef64cc`, on ONE Gaussian 32-tip fit
of `bf(y ~ x + phylo(1 | species, tree), sigma ~ 1, sd(species, level = "phylogenetic") ~ z)`
fitted on BOTH engines. Runtime ~4 min per engine pair including Julia boot;
well under the 30-minute D-139 line, so run directly.

| # | Documented claim | Verdict | Evidence measured here |
| --- | --- | --- | --- |
| 1 | `profile_targets()` UNDER-REPORTS on a Julia fit | **STALE** | `setdiff(accepted, listed)` and `setdiff(listed, accepted)` were BOTH `character(0)` under Wald over 20 probed candidate names. PR #1178 fixed it. It was, however, UNTESTED -- hence the closure tests added here. |
| 2 | The two engines expect DIFFERENT target names | **STANDING** | TMB lists `fixef:sd_phylo(species):z`, Julia lists `fixef:sd_phylo:z`; each engine REFUSED the other's spelling; the Wald interval for the same estimand agreed to six significant figures. |
| 3 | *(not in the brief; found here)* a LISTED target reported as UNKNOWN | **NEW DEFECT** | `profile_targets()` lists `sigma`; `confint(julia, "sigma", method = "profile")` answered `Unknown confidence-interval target: "sigma".` |

Verbatim, from the log:

```
-- JULIA confint(parm="fixef:sd_phylo(species):z", wald) --
REFUSED: Unknown confidence-interval target: "fixef:sd_phylo(species):z".

-- JULIA confint(parm="fixef:sd_phylo:z", wald) --
              parm     lower     upper
1 fixef:sd_phylo:z 0.1548585 0.5961239

-- TMB confint(parm="fixef:sd_phylo(species):z", wald) --
                       parm     lower    upper
1 fixef:sd_phylo(species):z 0.1548584 0.596124

-- TMB confint(parm="fixef:sd_phylo:z", wald) --
REFUSED: Unknown confidence-interval target: "fixef:sd_phylo:z".
```

```
UNLISTED-BUT-ACCEPTED (must be empty):
character(0)
LISTED-BUT-NOT-WALD-ACCEPTED:
character(0)
```

```
[sigma] -> Unknown confidence-interval target: "sigma".
```

Note the unknown-target message ALREADY lists the valid names
(`First available targets: ...`), so the brief's "make the error message list
the valid names" was already satisfied for that branch. The gap was the
listed-but-not-dispatchable branch, which is what this leaf fixed.

## 5. Decision recorded (design 258 section 9)

The NATIVE spelling `fixef:sd_phylo(species):z` is CANONICAL: it carries the
grouping factor the bridge's block key drops, and it disambiguates a fit with
two `sd()` submodels on different groups. The bridge keeps REPORTING its short
form (that is what `coef()`, `vcov()` and `profile_targets()` print, and
renaming those would break every banked Julia coefficient-label pin) but now
ACCEPTS the canonical form and resolves it to the row it reports. So
`profile_targets()` lists exactly one name per target, and the accepted-input
set is a documented superset: listed names plus enumerable aliases.

## 6. RED CONTROL

Four planted defects, one per negative gate. Restored byte-identically (never
`git stash`); sha256 before and after match: `R/julia-bridge.R
3e37782c15b0c992fb2cef28e38fff88330f02218701d05bacbcdf589cb09af6`,
`R/profile.R ee3213a504120a427db95432acb29631b02f65b9541b99d48e13c6d82ce5dea7`.
| # | Defect planted | Result |
| --- | --- | --- |
| 1 | drop `drm_julia_wald_scale_targets()` from `drm_julia_profile_target_union()` (the earlier dispatch's leftover hunk) | `RC-A FAIL 15 ERR 0 PASS 33`, including `Expected setdiff(seen$reported, listed) to equal character(0)` and `setdiff(seen$inputs, listed)` |
| 2 | remove both `drm_julia_canonicalise_parm()` calls | `RC-B FAIL 1 ERR 1 PASS 38`; `Error ... Unknown confidence-interval target: "fixef:sd_phylo(species):z"` |
| 3 | remove the `drm_julia_listed_not_dispatchable()` call | `RC-C FAIL 3 ERR 0 PASS 45`; `Expected grepl("Unknown confidence-interval target", flat) to be FALSE` |
| 4 | remove the ambiguous-key fail-closed guard | `RC-D FAIL 1 ERR 0 PASS 47` |

## 7. Checks run

All with `NOT_CRAN=true` so skips cannot masquerade as passes.

- `tests/testthat/test-profile-targets-julia.R`, no Julia env:
  `FAIL 0 ERR 0 SKIP 2 PASS 48`.
- Same file, LIVE at the pin: `FAIL 0 ERR 0 SKIP 0 PASS 92` -- both live tests
  RAN (`Julia bridge: 2 live tests ran; bridge glue was exercised`).
- Nine-file neighbour surface, LIVE at the pin, zero skips:

| file | result |
| --- | --- |
| test-profile-targets-julia.R | FAIL 0 ERR 0 SKIP 0 PASS 92 |
| test-julia-inference.R | FAIL 0 ERR 0 SKIP 0 PASS 175 |
| test-profile-targets.R | FAIL 0 ERR 0 SKIP 0 PASS 986 |
| test-julia-bridge.R | FAIL 0 ERR 0 SKIP 0 PASS 146 |
| test-julia-sigma-phylo-reml.R | FAIL 0 ERR 0 SKIP 0 PASS 76 |
| test-coefficient-labels.R | FAIL 0 ERR 0 SKIP 0 PASS 135 |
| test-julia-tmb-parity.R | FAIL 0 ERR 0 SKIP 0 PASS 126 |
| test-summary.R | FAIL 0 ERR 0 SKIP 0 PASS 200 |
| test-control.R | FAIL 0 ERR 0 SKIP 0 PASS 156 |

Total 2092 passing assertions, 0 failures, 0 errors, 0 skips.

- Non-ASCII bytes on added lines of `R/` and `tests/`: 0 and 0.

## 8. Not covered

- **Bivariate LSS spellings.** `sd1`/`sd2` submodels on a `biv_gaussian` fit were
  not measured; the alias map's regex would match `sd(id)` but no bivariate LSS
  fit was fitted, so nothing is claimed for that route.
- **The ambiguous-key case is guarded, not supported.** A fit with two `sd()`
  submodels on different groups now gets NO alias (fail closed). Whether the
  bridge can fit such a model at all was not measured -- the guard is tested at
  the helper level only.
- **`coef()` / `vcov()` / `summary()` names on a Julia fit are UNCHANGED.** This
  leaf makes the canonical name ACCEPTED as an interval target only. A user
  reading coefficient names off `summary(fit)` still sees `sd_phylo`.
- **The per-tip `sd:sd_phylo(species):...:tN` rows.** On this model the native
  engine listed 32 of them plus 6 direct rows; the bridge lists 6 and has no
  counterpart for the per-tip rows. That asymmetry is measured and recorded, not
  closed.
- **`profile`/`bootstrap` on the `sigma` row.** Still refused; the fix is the
  message, not a new DRM.jl entry point.
- **Closure measured on ONE model.** Two synthetic fixtures plus one live fit.
  Closure is not asserted for every family or route.
- **No DRM.jl change** was needed, so no DRM.jl PR was opened.

## 9. Errors I made

- Trusted the brief's statement that the earlier dispatch "did no work". It had
  done substantial work, uncommitted. Checking `git diff` first cost one minute
  and saved re-deriving the helpers.
- The first live measurement script crashed printing a `confint()` result whose
  columns I had assumed; I had to re-run the Julia boot. Should have printed
  `names()` before selecting columns.
