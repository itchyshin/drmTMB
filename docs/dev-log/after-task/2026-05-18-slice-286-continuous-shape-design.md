# After Task: Slice 286 Continuous Shape Design

## Goal

Document the continuous-shape and skewness boundary before admitting shape,
skewness, or tail surfaces into broader simulation work.

## Implemented

Slice 286 is a design-hardening slice, not a likelihood slice. The family
registry now separates fitted fixed-effect Student-t `nu`, planned
fixed-effect skew-normal `nu`, planned skew-t `nu` plus future `tau`, and
design-only latent-effect `skew(id) ~ ...`. The likelihood notes now include a
planned skew-t gate, and the robust Student-t and formula-grammar tutorials
tell readers that residual `nu ~ x` and future latent-effect skewness are
different questions.

## Mathematical Contract

The fitted Student-t contract is unchanged:

```text
nu_i = 2 + exp(eta_nu_i)
```

This keeps the Student-t path in the finite-variance region. The planned
skew-normal contract remains fixed-effect-first with `nu` as residual
asymmetry. The planned skew-t contract reserves `tau` for a second shape
parameter, but no `tau` formula syntax is fitted now. Future `skew(id) ~ ...`
would target the shape of a latent random-effect distribution, not the
observation-level residual distribution.

## Files Changed

- `NEWS.md`
- `ROADMAP.md`
- `docs/design/02-family-registry.md`
- `docs/design/03-likelihoods.md`
- `docs/design/46-pre-simulation-readiness-matrix.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/recovery-checkpoints/2026-05-18-213841-codex-checkpoint.md`
- `vignettes/formula-grammar.Rmd`
- `vignettes/robust-student.Rmd`

## Checks Run

```sh
air format NEWS.md ROADMAP.md docs/design/02-family-registry.md docs/design/03-likelihoods.md docs/design/46-pre-simulation-readiness-matrix.md vignettes/robust-student.Rmd vignettes/formula-grammar.Rmd
Rscript -e "devtools::test(filter = 'student-location-scale|nongaussian-scale-boundary', reporter = 'summary')"
Rscript -e 'devtools::load_all(quiet = TRUE); rmarkdown::render("vignettes/robust-student.Rmd", output_dir = tempfile("robust-student-render-"), quiet = FALSE); rmarkdown::render("vignettes/formula-grammar.Rmd", output_dir = tempfile("formula-grammar-render-"), quiet = FALSE)'
rg -n 'skew_t\(\)|skew_normal\(\)|tau ~|skew\(id\)|Shape and skewness|Slice 286|Student-t `nu`|future `tau`' NEWS.md ROADMAP.md docs/design/02-family-registry.md docs/design/03-likelihoods.md docs/design/46-pre-simulation-readiness-matrix.md vignettes/robust-student.Rmd vignettes/formula-grammar.Rmd
Rscript -e "pkgdown::check_pkgdown()"
git diff --check
Rscript tools/codex-checkpoint.R --goal "Slice 286 continuous-shape design" --next "stage, commit, push, and open draft PR"
```

All commands passed.

## Tests Of The Tests

No new tests were added because the slice does not change code. The targeted
Student-t and non-Gaussian boundary tests still prove that fitted fixed-effect
Student-t shape works and that shape random-effect bar terms fail before
fitting.

## Consistency Audit

The roadmap now marks Slice 286 done locally. The family registry,
likelihoods note, pre-simulation readiness matrix, robust Student-t tutorial,
and formula-grammar tutorial all tell the same story: fitted Student-t `nu` is
fixed-effect only; skew-normal and skew-t are fixed-effect-first design lanes;
shape and skewness random effects stay out of Phase 18 grids until fixed-effect
density, recovery, false-positive, diagnostic, and interval evidence exists.

## What Did Not Go Smoothly

The first status search used backticks in a shell pattern without proper
quoting, which let the shell try to execute `nu`. I reran the evidence scans
with single-quoted patterns and recorded the corrected command.

## Team Learning

Ada kept this as design hardening instead of opening a family. Boole kept
`nu`, future `tau`, and `skew(id)` in separate syntax lanes. Fisher and Curie
kept simulation admission tied to fixed-effect recovery, false-positive, and
diagnostic evidence. Pat and Darwin made the tutorial boundary clearer for
applied users comparing Gaussian and Student-t fits. Grace confirmed pkgdown
and the targeted checks. Rose flagged the shell-quoting mistake and the risk of
accidentally teaching `skew(id)` as an alias for residual `nu`. No spawned
subagents were used.

## Known Limitations

No skew-normal, skew-t, shape-random-effect, phylogenetic shape, spatial shape,
bivariate shape, or latent-effect skewness likelihood was added. No new
profile target, extractor, diagnostic row, or simulation runner was added.

## Next Actions

Continue with Slice 287 by auditing ordinal readiness: cumulative-logit
likelihood, cutpoint intervals, prediction, unsupported random effects, and
reader-facing examples before any ordinal mixed-model or ordinal-scale claims.
