# Formula grammar: audit closeout

- **Audit date:** 2026-07-21
- **Pinned base:** `origin/main` `83d48549e8925a97aa2c156941a97a9bf9b785c4`
- **Source:** `vignettes/formula-grammar.Rmd`
- **Rendered route:** `articles/formula-grammar.html`
- **Scope:** authored formula grammar only; `bivariate-coscale` excluded.

## Findings and repair

The status matrix was checked against `R/bf.R`, `NAMESPACE`, the release-scope
manifest, and the ledger-boundary language used throughout the audit. The
article correctly identifies `drm_formula()` as the canonical constructor and
`bf()` as its short alias. Its formula, parameter, marker, and extractor
language distinguishes fitted paths from row-specific recovery and
inference-ready evidence.

One P2 wording repair was needed: a binomial row described `engine = "julia"`
as merely unsupported syntax. The bridge is halted/deferred, not an alternate
engine awaiting routine use. The row now directs readers to future Julia
support. Responsive styling was also added so the long status matrix remains
horizontally scrollable rather than compressed on a phone.

No P1 formula/parser mismatch was found. In particular, the page does not
promote profile intervals or coverage beyond their recorded cells, and it keeps
residual `rho12` distinct from latent `corpair()` correlations.

## Render and checks

- Rebuilt locally with `pkgdown::build_article("formula-grammar", ...)` on
  2026-07-21.
- `git diff --check` passed.
- Fresh render evidence: `renders/formula-grammar-desktop-1440x1000.png` and
  `renders/formula-grammar-mobile-390x844.png`.
- Mobile inspection confirmed a readable article path and a scrollable status
  matrix; the page deliberately remains long because it is the authoritative
  grammar inventory.

## Boundary retained

This repair does not establish any new formula path, parser capability,
interval calibration, coverage result, or Julia implementation. It only makes
the existing support boundary legible and current.
