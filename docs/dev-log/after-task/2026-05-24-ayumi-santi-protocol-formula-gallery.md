# After Task: Ayumi and Santi Protocol Formula Gallery

## Goal

Start the Ayumi/Santi improvement path by creating the no-fit protocol formula
gallery called for in Phase 1 of
`docs/design/76-ayumi-santi-phylo-model-improvement-path.md`.

## Implemented

Added `docs/design/77-ayumi-santi-protocol-formula-gallery.md` and linked it
from the improvement-path note. The gallery marks each protocol route as
runnable validation, diagnostic only, workflow only, or planned.

## Mathematical Contract

The gallery keeps three correlation layers separate:

- phylogenetic `corpairs()` rows for structured shared-ancestry covariance;
- residual `rho12` rows for within-row bivariate Gaussian coscale;
- workflow-only split fits for lifestyle or nest-habitat contrasts until
  class-specific covariance syntax exists.

The q4 location-scale formulas are shown as diagnostic-only because full q4
correlations are currently derived-only for intervals and need real-data
hardening before they become applied inference.

## Files Changed

- `docs/design/77-ayumi-santi-protocol-formula-gallery.md`
- `docs/design/76-ayumi-santi-phylo-model-improvement-path.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-24-ayumi-santi-protocol-formula-gallery.md`

## Checks Run

```sh
rg -n 'prune_tree_to_species|match_data_to_tree|exported `drmTMB` functions|Status:|Planned feature|Diagnostic only|Runnable validation|Workflow only' docs/design/77-ayumi-santi-protocol-formula-gallery.md
rg -n 'routine applied inference|full protocol.*routine|rho12.*phylogenetic|phylogenetic.*rho12|class-specific.*implemented|posterior pooling.*implemented|meta_gaussian\(|tau ~|rho ~' docs/design/76-ayumi-santi-phylo-model-improvement-path.md docs/design/77-ayumi-santi-protocol-formula-gallery.md README.md ROADMAP.md NEWS.md vignettes docs/design --glob '!docs/design/76-ayumi-santi-phylo-model-improvement-path.md' --glob '!docs/design/77-ayumi-santi-protocol-formula-gallery.md'
gh issue list --repo itchyshin/drmTMB --state open --search "Ayumi Santi phylogenetic protocol formula" --limit 20 --json number,title,state,url,labels
gh issue list --repo itchyshin/drmTMB --state open --search "phylogenetic location scale q4 Ayumi Santi" --limit 20 --json number,title,state,url,labels
git diff --check
```

## Tests Of The Tests

No R tests were added or run because this task added a planning and formula
gallery artifact only. The next executable slice should add model-run scripts
or validation records for the q2 Objective 1 fits.

## Consistency Audit

The gallery states that helper names such as `prune_tree_to_species()` and
`match_data_to_tree()` are placeholders for applied analysis scripts, not
exported `drmTMB` functions. The stale-claim scan found only intended
guardrails in the new files and existing roadmap/documentation language that
already separates residual `rho12` from phylogenetic covariance.

No `NEWS.md`, roxygen, `_pkgdown.yml`, or pkgdown rebuild was needed because no
exported function, public reference page, or user-facing package behaviour
changed.

## GitHub Issue Maintenance

The issue searches returned no exact open issue for the Ayumi/Santi formula
gallery or the q4 validation path. No GitHub issue was opened or mutated from
this mixed dirty branch.

## What Did Not Go Smoothly

One local stale-wording scan initially used shell double quotes around a pattern
containing backticks, which triggered shell command substitution. The scan was
rerun with single quotes before closeout.

## Team Learning

For planning galleries, label analysis-script helper names explicitly. This
avoids turning pseudo-code into an accidental API promise.

## Known Limitations

The gallery does not fit models or verify convergence. It also does not solve
partial-response marginalization, single-model class-specific covariance,
predictor-dependent q4 phylogenetic `corpair()` regression, q4 derived
intervals, or Bayesian tree pooling.

## Next Actions

Run or scaffold the first q2 Objective 1 validation fits for mammal body
mass-litter size and avian body mass-clutch size on representative trees.
