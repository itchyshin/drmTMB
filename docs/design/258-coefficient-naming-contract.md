# 258 — Coefficient-naming contract between drmTMB and DRM.jl

Status: **specification only**. No R code changed. Implementation is deliberately
deferred until the authority question below is settled (see "NOT decided here").

## 1. The problem, as measured

The gated `engine = "julia"` bridge parity suite in DRM.jl
(`test/parity/runparity_bridge_formula.jl`, cohort `_BRIDGE_FORMULA_COHORT`)
currently reads **1 pass / 6 fail** when run with `DRM_PARITY_TESTS=1`:

- `bridge-minus-term` — **passes**.
- `bridge-I`, `bridge-factor`, `bridge-poly`, `bridge-poly-cross`, `bridge-power`,
  `bridge-scale` — **fail**.

Source: DRM.jl issue #467, comment 5501007899.

The failures are **coefficient-NAME mismatches only** — `compare_bridge` compares
`out` (what `drm_bridge` actually names its columns) against `expected`
(`expected.toml`, generated from drmTMB's own `coef()`/`vcov()` names via an
explicit `name_map`, see `test/parity/gen_bridge_formula_fixtures.R`). The
numeric coefficient values and vcov entries are not in dispute; only the string
keys used to look them up differ, so every construct except plain term removal
(`- term`, which introduces no synthetic column) fails to match by name. `vcov`
axis-ordering failures are downstream of the same name mismatch, not a separate
numerical problem.

Because the suite is gated behind `DRM_PARITY_TESTS=1`, it is not part of CI,
and this drift was invisible until someone ran it by hand.

A second, independent thread of prior work
(`docs/dev-log/evidence/julia-r-parity/coefficient-labels/CHECK-EXPECT.md` and
`RESULT.md`, branch `origin/codex/rebase-julia-optimizer-controls`) built a
bounded, non-shipping oracle that reproduces the same underlying gap for a
wider set of ten model-matrix constructs plus four base-R spelling-precedent
cases, and sketched (but did not land) a `bridge_formula_labels_v1` public/raw
name-map contract. **DRM.jl's `src/` does not currently implement or emit
`coef_label_contract` / `bridge_formula_labels_v1` for `drm_bridge` at all** —
grep across DRM.jl's tracked `.jl` sources for `coef_label_contract`,
`bridge_formula_labels_v1`, and `coef_name_map` returns nothing. On the R side,
`R/julia-coefficient-labels.R`'s `drm_julia_bridge_coef_labels()` and
`drm_julia_public_inference_term()` are validators for that map — they check it
is well-formed and self-consistent, but they do not construct it, and they are
presently unreachable because no fit ever populates
`object$bridge_public_coef_labels`. drmTMB's own
`coefficient_labels()` (`R/methods.R`, `coefficient_labels <- function(object)`,
at line 6061) is unconditional pass-through:

```r
coefficient_labels <- function(object) {
  unlist(
    lapply(names(object$coefficients), function(dpar) {
      paste0(dpar, ":", names(object$coefficients[[dpar]]))
    }),
    use.names = FALSE
  )
}
```

`names(object$coefficients[[dpar]])` comes straight from
`colnames(stats::model.matrix(...))`. There is no canonicalisation step
anywhere in R today.

## 2. Construct table

Columns: what base-R `model.matrix()`/`coef()` names the term today (drmTMB's
own spelling, taken from `gen_bridge_formula_fixtures.R`'s `name_map` LHS and
the `public-004.json` `expected` oracle for the four later cases); what
`drm_bridge` emits today (the RHS of that same `name_map`, i.e. DRM.jl's actual
column names, taken from `runparity_bridge_formula.jl`'s failing fixtures and
`public-004.json`'s `labels.raw`); and a **proposed** canonical name. The
canonical column is a proposal for this document, not a decision — see §3–4.

| # | Construct | Formula fragment | Base-R name (drmTMB today) | DRM.jl `drm_bridge` name (today) | Proposed canonical name |
|---|---|---|---|---|---|
| 1 | `I()` | `y ~ x + I(x^2)` | `mu:I(x^2)` | `mu___bridge_I_1` | `mu:I(x^2)` |
| 2 | `factor()` | `y ~ factor(grp)` | `mu:factor(grp)lo`, `mu:factor(grp)mid` | `mu___bridge_factor_1: lo`, `mu___bridge_factor_1: mid` | `mu:factor(grp)lo`, `mu:factor(grp)mid` |
| 3 | `poly()` | `y ~ poly(x, 3)` | `mu:poly(x, 3)1`, `mu:poly(x, 3)2`, `mu:poly(x, 3)3` | `mu___bridge_poly3c1_1`, `mu___bridge_poly3c2_2`, `mu___bridge_poly3c3_3` | `mu:poly(x, 3)1`, `mu:poly(x, 3)2`, `mu:poly(x, 3)3` |
| 4 | crossed `poly()` | `y ~ z * poly(x, 2)` | `mu:z:poly(x, 2)1`, `mu:z:poly(x, 2)2` (plus main effects) | `mu_z & __bridge_poly2c1_1`, `mu_z & __bridge_poly2c2_2` | `mu:z:poly(x, 2)1`, `mu:z:poly(x, 2)2` |
| 5 | powers `(...)^k` | `y ~ (x + z)^2` | `mu:x:z` | `mu_x & z` | `mu:x:z` |
| 6 | `scale()` | `y ~ scale(x)` | `mu:scale(x)` | `mu___bridge_scale_1` | `mu:scale(x)` |
| 7 | reversed two-factor interaction | `~ g + factor(h) + factor(h):g` | `(Intercept)`, `gb`, `gc`, `factor(h)10`, `factor(h)20`, `gb:factor(h)10`, `gc:factor(h)10`, `gb:factor(h)20`, `gc:factor(h)20` | `g: b`, `g: c`, `__bridge_factor_1: 10.0`, `__bridge_factor_1: 20.0`, `__bridge_factor_1: 10.0 & g: b`, `__bridge_factor_1: 20.0 & g: b`, `__bridge_factor_1: 10.0 & g: c`, `__bridge_factor_1: 20.0 & g: c` (all `mu_`-prefixed) | same as base-R column, `mu:` prefixed |
| 8 | unary-plus arithmetic | `~ I(+x)` | `I(+x)` | `__bridge_I_1` | `mu:I(+x)` |
| 9 | explicitly parenthesised arithmetic | `~ I(x + (z + 2))` | `I(x + (z + 2))` | `__bridge_I_1` | `mu:I(x + (z + 2))` |
| 10 | decimal-spelled integer exponent | `~ I(x^2)` | `I(x^2)` | `__bridge_I_1` | `mu:I(x^2)` |

Notes on the table:

- Rows 1–6 are the six DRM.jl parity failures named in the problem statement;
  their base-R/bridge pair is read directly from the committed
  `name_map` in `gen_bridge_formula_fixtures.R` (lines 148–279), which is
  itself generated from a real `drmTMB()` fit's `coef()`/`vcov()` names, so
  these are not reconstructed from memory.
- Rows 7–10 are the four cases added later per `CHECK-EXPECT.md`'s "Review
  expansion before public004" section; their base-R (`expected`/`actual`) and
  bridge (`labels.raw`) spellings are read from
  `public-004.json` in the `codex/rebase-julia-optimizer-controls` evidence
  branch (an independent, non-shipping oracle, not `drm_bridge` itself —
  flagged explicitly in §5).
- Every `drm_bridge` name in the table uses the synthetic
  `__bridge_<kind>_<n>` materialised-column convention for `I()`, `scale()`,
  `poly()`, and `factor()`, and StatsModels' `x & z` (space-padded `&`) for
  interactions, in place of R's `:`. Row 7's factor levels are also rendered
  as `10.0`/`20.0` (float-coerced) rather than R's bare `10`/`20`, because
  `Vector{Any}` numeric-as-string columns get parsed as floats on the Julia
  side — a second, independent source of name drift beyond the `__bridge_*`
  materialisation itself, worth noting for whoever implements the fix.
- The "proposed canonical name" column reuses the base-R spelling with the
  `mu:`/`sigma:`/… prefix drmTMB already applies via `coefficient_labels()`.
  This follows candidate (a) in §3 below; it is a proposal for discussion, not
  an adopted answer — see §3–4.

## 3. The binding constraint already in force: no punctuation-based guessing

`R/julia-coefficient-labels.R`'s header states it plainly: "No term spelling is
inferred from synthetic ordinals or punctuation: the engine supplies an exact
map." `drm_julia_bridge_coef_labels()` and `drm_julia_public_inference_term()`
enforce this — they validate a versioned map (`bridge_formula_labels_v1`) for
completeness, uniqueness, order-consistency between `public`/`raw`/`vcov_names`,
and per-`dpar` block agreement, and they hard-`stop()` on any inconsistency
rather than falling back to a guess. `CHECK-EXPECT.md` restates the same rule:
"Corrupt versioned metadata must fail before Julia startup; no
punctuation-based guessing is permitted."

Why this constraint is load-bearing rather than pedantic: a regex or
string-substitution translator built against the six failing constructs in §2
(strip `__bridge_<kind>_<n>`, replace ` & ` with `:`, replace `: ` with no
space) would look complete after those six pass. Row 7 (reversed two-factor
interaction) already shows why that is not safe — the same `__bridge_factor_1`
materialisation appears on both sides of an interaction with the level
rendered as `10.0` rather than `10`, and `public-004.json`'s own `expected`
vs `actual` diff for that case shows the two sides *disagree on interaction
term ORDER* (`gb:factor(h)10` before `gc:factor(h)10` in `expected` vs
`gb:factor(h)10` before `gb:factor(h)20` in `actual`) even after name
translation — a class of error a spelling-only guesser would not catch, and
would not know it had gotten wrong, on a case outside its original six. A
punctuation guess that passes on the constructs it was tuned against is
exactly the failure mode the existing validator was built to refuse silently
propagating; the fix belongs in an exact map the engine supplies, not in a
heuristic string translator on either side.

## 4. The two candidate authorities

**(a) Base-R spelling wins.** drmTMB's `coefficient_labels()` output (what
`summary()`, `coef()`, `fixef()`, `confint()`, and `vcov()` dimnames already
show an R user) becomes the contract's `public` name. DRM.jl's fixtures in
`expected.toml` change their keys to match, and `drm_bridge` gains a
translation layer that maps its synthetic `__bridge_*`/`&`-joined internal
names back to R's own spelling before returning results across the bridge.

*For*: R users already see base-R spelling in every existing output surface —
adopting it changes nothing they currently read. Usability is the principle
this project does not bend on (project doctrine, `AGENTS.md`); a user who
writes `poly(x, 3)` in a `drm_formula()` and later reads `poly(x, 3)1` in
`summary()` should not need to learn a second, Julia-internal spelling
(`__bridge_poly3c1_1`) to interpret a `engine = "julia"` fit's output — the
engine choice is meant to be invisible in output shape, per the pkgdown
positioning of `engine = "julia"` as a backend switch, not a different
package.

*Against*: DRM.jl's fixtures encode real, already-verified work — every
`expected.toml` in `test/parity/fixtures/bridge-*` was generated from an
actual byte-identical drmTMB fit (see `gen_bridge_formula_fixtures.R`'s
`write_bridge_fixture()`), and changing what they assert re-opens numerical
review of files that already passed. It also does not remove the underlying
translation problem, only moves which side has to solve it: `drm_bridge` still
needs an internal map from its synthetic columns back to R spelling, which is
nontrivial for the same reasons row 7 shows (interaction order, factor-level
type coercion).

**(b) DRM.jl's translated map wins.** `drm_bridge`'s current
`__bridge_<kind>_<n>` / `x & z` spelling becomes the contract's `public` name,
and drmTMB's Julia-engine code path translates its own `coefficient_labels()`
output to match before returning to the user — i.e. an `engine = "julia"` fit's
`summary()` would show `I(x^2)` translated to something like
`mu___bridge_I_1` (or a cleaned variant of it), diverging from what the same
formula shows under the native TMB engine.

*For*: DRM.jl's fixtures stay untouched; no re-verification of already-checked
numeric evidence is needed on the Julia side; the synthetic-column names are
also arguably more information-preserving in one respect — `__bridge_poly3c1_1`
records the term-and-column *provenance* (which named term, which sub-column)
in a way `poly(x, 3)1` alone does not carry as unambiguously across two
different formula parsers.

*Against*: this directly breaks the invisible-engine-swap premise — the same
formula fit under `engine = "TMB"` vs `engine = "julia"` would show two
different coefficient vocabularies in `summary()`/`coef()`/`confint()`, which
is a much larger and more visible break to users than any single row in §5,
and it pushes the translation work onto every drmTMB output function that
currently trusts `coefficient_labels()`'s pass-through spelling.

**Recommendation**: (a), base-R spelling wins, on usability grounds — but this
is a cross-repo governance call between drmTMB and DRM.jl fixture ownership,
**not decided unilaterally by this document, nor by its author**. See §6.

## 5. Breaking-change assessment

Per construct in §2, would adopting the proposed canonical name (§2's last
column, i.e. candidate (a)) change a name a drmTMB user currently sees in
`summary()`, `coef()`, `fixef()`, `confint()`, or `vcov()` dimnames?

| # | Construct | Changes a name already shown under `engine = "TMB"` (native)? | Changes a name currently shown under `engine = "julia"`? |
|---|---|---|---|
| 1 | `I()` | No | **Cannot determine** — flagged below |
| 2 | `factor()` | No | **Cannot determine** — flagged below |
| 3 | `poly()` | No | **Cannot determine** — flagged below |
| 4 | crossed `poly()` | No | **Cannot determine** — flagged below |
| 5 | powers `(...)^k` | No | **Cannot determine** — flagged below |
| 6 | `scale()` | No | **Cannot determine** — flagged below |
| 7 | reversed two-factor interaction | No | **Cannot determine** — flagged below |
| 8 | unary-plus arithmetic | No | **Cannot determine** — flagged below |
| 9 | explicitly parenthesised arithmetic | No | **Cannot determine** — flagged below |
| 10 | decimal-spelled integer exponent | No | **Cannot determine** — flagged below |

Reasoning for the "No" column: `coefficient_labels()` and every caller of
`names(object$coefficients[[dpar]])` read directly off
`colnames(stats::model.matrix(...))` (`R/methods.R`, `coefficient_labels()`
and its callers at lines 2336, 4410, 5234). None of that code path consults
`object$bridge_public_coef_labels` or any Julia-supplied map; adopting
candidate (a) as the *bridge's* contract changes nothing about what a
native-TMB fit's `model.matrix()`-derived names already are, because (a) by
construction sets the canonical name equal to that same base-R spelling. This
is read directly from the code, not inferred.

Reasoning for the "**Cannot determine**" column: this document could not
locate a shipping, non-gated `engine = "julia"` fit path in `drmTMB` whose
`summary()`/`coef()`/`confint()`/`vcov()` output currently exposes any of
these ten constructs' coefficient names end-to-end, because (as established in
§1) `object$bridge_public_coef_labels` is never populated by any code this
document found — `drm_julia_bridge_coef_labels()` and
`drm_julia_public_inference_term()` are validators with no current producer.
Whether an `engine = "julia"` fit today shows `__bridge_I_1`-style raw names,
base-R names via some other translation this review did not find, or refuses
these constructs outright, was not established by reading `R/julia-coefficient-labels.R`
and `R/methods.R` alone; it would require exercising an actual
`engine = "julia"` fit of each construct (out of scope — this document commits
to writing no R code and running no tests) or a further read of the
`engine = "julia"` dispatch path in `R/` beyond the two files this review was
scoped to. **This is flagged rather than guessed**, per this document's own
brief.

## 6. NOT decided here

- **Which authority wins** (§4) — this is a cross-repo governance call between
  drmTMB and DRM.jl maintainers/reviewers, not a decision this specification
  document makes.
- **Whether `drm_bridge` gains a translation layer, or drmTMB's Julia-engine
  code path does** — a consequence of the authority decision above.
- **The exact `bridge_formula_labels_v1` map format** — the sketch in
  `public-004.json`/`CHECK-EXPECT.md` (a `public`/`raw`/`map` triple) is
  existing prior art to build from, not a ratified schema; `R/julia-coefficient-labels.R`'s
  validator already assumes a specific list-or-character-vector shape for
  `coef_name_map` that any implementation must satisfy, but this document does
  not specify how DRM.jl should construct or serialise it.
  This document does not adjudicate whether that or a different shape ships.
- **Row 7's term-order disagreement** (`gb:factor(h)10` vs `gc:factor(h)10`
  ordering, noted in §3) — whether this is a naming-contract issue or a
  separate column-order bug in `drm_bridge`'s interaction expansion is not
  determined here.
- **Timeline or issue ownership** for implementing whichever authority is
  chosen — no PR, branch, or milestone is proposed by this document.
- **Whether the gated parity suite (`DRM_PARITY_TESTS=1`) should be un-gated
  once fixed** — a CI-cost and cross-repo governance question outside this
  document's scope (`.github/workflows/` is explicitly out of scope per this
  slice's constraints).
- **Any change to `inst/extdata/julia-capabilities.tsv` or
  `docs/dev-log/coordination-board.md`** — both explicitly out of scope for
  this slice.

## 7. The producer contract (S3, drmTMB half; decided by D-202)

Owner decision (Shinichi, 2026-09-02, D-202): candidate (a) from §4 is
canonical -- base-R spelling wins. This section specifies the exact wire
contract drmTMB now implements on its side, so the DRM.jl lane can build the
matching echo without re-deriving the shape from `R/julia-coefficient-labels.R`.
This is a specification for the WHOLE round trip; only the drmTMB (R) half is
implemented by this slice (S3) -- see "What S3 does NOT cover" below.

### 7.1 Payload: `coef_labels`

`drm_julia_bridge_payload()` (`R/julia-bridge.R`) now sends an additional
top-level field, alongside the existing `formula`/`data`/`tree`/`options`:

```
coef_labels: list, keyed by dpar (e.g. "mu", "sigma", "mu1", "rho12", ...)
  each element: character vector, base-R model.matrix() column order
```

Built by `drm_julia_bridge_payload_coef_labels(formula, data, env)`: for each
`formula$entries` entry whose `dpar` is one of `julia_bridge_supported_dpars()`
and whose `entry$structured` is empty (no phylo / random-effect / `sd(...)`
term anywhere in that entry's RHS), it forms `~ <rhs>` with the SAME `data`
(the already row-ordered, column-subset `data_out` the rest of the payload
marshals) and `env`, runs `stats::model.frame()` then
`colnames(stats::model.matrix(stats::terms(mf), mf))`, and stores the result
under that dpar's key. A dpar is silently absent from `coef_labels` when it
carries a structured term, or when building the model matrix errors --
neither case is a plain fixed-effect coefficient block this contract covers
in its first cut (design doctrine: keep first implementations simple before
adding random effects). These are precisely drmTMB's own `coefficient_labels()`
column names (`R/methods.R`), minus the `"<dpar>:"` prefix that function adds
afterwards -- i.e. `coef_labels$mu` for `y ~ x + I(x^2)` is
`c("(Intercept)", "x", "I(x^2)")`, matching row 1 of §2 exactly.

### 7.2 Echo: `bridge_formula_labels_v1`

This is DRM.jl's half to implement -- not built by this slice, but specified
here precisely enough to build against, transcribed directly from the
EXISTING validator `drm_julia_bridge_coef_labels()` (`R/julia-coefficient-labels.R`,
unchanged by S3) rather than invented fresh. To supply a map, a fitted
`result` must set ALL of:

| Field | Type | Meaning |
|---|---|---|
| `coef_label_contract` | scalar string, exactly `"bridge_formula_labels_v1"` | version tag |
| `coef_names` | character vector, length *n*, no NA/empty/duplicates | the **public** names, base-R spelling, `"<dpar>_<term>"` (underscore-joined -- e.g. `"mu_I(x^2)"`, matching `coef_labels$mu` term-for-term with the dpar re-prefixed with `_`), in the SAME order as `coefficients`/`vcov` |
| `raw_coef_names` | character vector, length *n*, no NA/empty/duplicates | the **raw** synthetic names DRM.jl actually computed internally (e.g. `"mu___bridge_I_1"`), same length as `coef_names` |
| `coef_name_map` | named list or named character vector, length *n* | keys = every `coef_names` entry (as a set, order-free); values = the paired `raw_coef_names` entry for that key, so that `map[coef_names]` reproduces `raw_coef_names` in `coef_names`' order |
| `vcov_names` | character vector | must be `identical()` to `coef_names` (covariance axis order matches the public name order) |
| `coefficients`, `vcov` | as already returned | lengths/dimensions must match *n* |

The validator additionally requires `drm_julia_split_coef_name(coef_names)$dpar`
to equal `drm_julia_split_coef_name(raw_coef_names)$dpar`
element-for-element -- i.e. the public/raw pairing must agree on which dpar
block each coefficient belongs to, even though the term spelling differs.
`drm_julia_split_coef_name()` (`R/julia-bridge.R`) matches the LONGEST known
block prefix from `drm_julia_bridge_blocks()`, so `"mu_I(x^2)"` splits to
dpar `"mu"`, term `"I(x^2)"`.

**Failure text** (`drm_julia_bridge_coef_labels()`, unchanged): on any
inconsistency it calls `stop("Invalid Julia coefficient label metadata: ",
what, call. = FALSE)`, where `what` is one of, in check order: `"unknown
contract"`, `"missing or duplicate labels"`, `"incomplete label map"`,
`"invalid map values"`, `"map order or coefficient identity mismatch"`,
`"coefficient block mismatch"`, `"covariance label order mismatch"`,
`"coefficient coverage mismatch"`, `"covariance dimensions mismatch"`,
`"covariance axes mismatch"`. This is the exact, already-shipping validator;
S3 adds no new echo-side checks.

### 7.3 R-side rule after the call (S3, implemented)

`new_drmTMB_julia()` (`R/julia-bridge.R`), immediately after computing
`public_coef_labels <- drm_julia_bridge_coef_labels(result)`:

- **Map present and valid** (`public_coef_labels` non-`NULL`): unchanged from
  before S3 -- `coef_names <- public_coef_labels$public` and the fit proceeds.
  An invalid map (any §7.2 failure text) already aborts inside
  `drm_julia_bridge_coef_labels()` before this point.
- **Map absent** (`drm_julia_bridge_coef_labels()` returned `NULL` because
  none of `coef_label_contract`/`raw_coef_names`/`coef_name_map` are present
  on `result`): `drm_julia_bridge_check_coef_labels(coef_names, bridge_payload$coef_labels)`
  runs. For every dpar present in the payload's `coef_labels`, it splits the
  engine's raw `coef_names` by dpar (`drm_julia_split_coef_name()`) and
  compares the per-dpar term vector to `coef_labels[[dpar]]` by
  `identical()` (exact strings, exact order). If every checked dpar matches,
  the fit proceeds unchanged (this is what keeps plain-term bridge fits, e.g.
  §2 row for `- term`, working exactly as before). If any dpar's names
  differ, it `cli::cli_abort()`s, naming DRM.jl explicitly and listing, per
  mismatched dpar, drmTMB's expected column names against what DRM.jl
  returned:

  > "DRM.jl returned coefficient names that do not match drmTMB's base-R
  > `model.matrix()` spelling, and supplied no `bridge_formula_labels_v1` map
  > to translate them." followed by one bullet per mismatched dpar
  > (`"<dpar>: drmTMB expects (<names>); DRM.jl returned (<names>)."`) and a
  > hint: "DRM.jl must supply `bridge_formula_labels_v1` (design 258 §7) for
  > this formula construct."

  A dpar absent from the payload's `coef_labels` (structured term, or the
  payload builder that produced `bridge_payload` predates this field) is not
  checked -- this keeps the rule additive for the structured/xfam/known-cov
  bridge routes that build their own `payload` objects outside
  `drm_julia_bridge_payload()` and do not yet populate `coef_labels`.

No punctuation is stripped, guessed, or translated anywhere in this path --
`drm_julia_bridge_check_coef_labels()` performs only an `identical()` string/
order comparison of two already-final name vectors, never a `gsub()` on
`__bridge_*` or `&`-joined names (§3's binding constraint).

### 7.4 What S3 does NOT cover

- **DRM.jl's `src/bridge.jl`** does not implement `bridge_formula_labels_v1`
  after this slice; §7.2 is a specification for that lane, not code landed by
  it. Until DRM.jl echoes the map, EVERY one of §2's six/ten failing
  constructs still fails closed via §7.3's abort path (an improvement over
  today's silent wrong-name pass-through, but still a refusal, not a fix) --
  a live round trip through an actual `engine = "julia"` fit of e.g.
  `y ~ I(x^2)` is not exercised by this slice's tests (no live Julia
  available in this worktree); only the R-side functions are unit-tested
  against constructed `result`/payload fixtures.
- **Structured/xfam/known-covariance bridge routes**
  (`drm_julia_structured_payload()`, `drm_julia_biv_known_structured_payload()`,
  the cross-family `drm_julia_xfam_axes()` path) do not yet call
  `drm_julia_bridge_payload_coef_labels()` or populate `coef_labels` on their
  own `payload` objects -- out of this slice's touch scope
  (`R/julia-bridge.R (drm_julia_bridge_payload and the post-call label step
  only)`). Their fits are unaffected either way, since §7.3's check is a
  no-op when `bridge_payload$coef_labels` is absent.
- **Row 7's term-order disagreement** (§3, §6) is unchanged -- if DRM.jl ever
  echoes a syntactically valid but reordered map for that construct, §7.2's
  existing validator (unchanged) still refuses it via `"map order or
  coefficient identity mismatch"`.

## Sources

- DRM.jl issue #467, comment 5501007899 (1 pass / 6 fail measurement).
- `test/parity/runparity_bridge_formula.jl` (DRM.jl, cohort definition and
  comparison logic).
- `test/parity/gen_bridge_formula_fixtures.R` (DRM.jl, base-R vs `drm_bridge`
  name pairs for constructs 1–6, generated from real `drmTMB()` fits).
- `docs/dev-log/evidence/julia-r-parity/coefficient-labels/CHECK-EXPECT.md` and
  `RESULT.md` (drmTMB, branch `origin/codex/rebase-julia-optimizer-controls`;
  prior bounded, non-shipping oracle work; source of constructs 7–10 and the
  `bridge_formula_labels_v1` sketch).
- `docs/dev-log/evidence/julia-r-parity/coefficient-labels/public-004.json`
  (same branch; concrete `expected`/`actual`/`labels` data for constructs 7–10).
- `R/julia-coefficient-labels.R` (drmTMB, all 54 lines — validator only, no
  producer found).
- `R/methods.R` (drmTMB, `coefficient_labels()` at line 6061 and its callers
  at lines 2336, 4410, and 5234).
- `docs/src/capabilities.md` (DRM.jl) — reviewed; contains no coefficient-label
  contract documentation to cite.
