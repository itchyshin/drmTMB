# After-task -- closure artefacts for the parity-joint programme (2026-09-05)

Reader: whoever runs the A11 closure pass, and Shinichi. This leaf prepared the
four artefacts the closure needs so that the final pass is a REGENERATION plus a
diff, not an authoring job under time pressure. Nothing here closes the
programme; it makes the closure checkable.

## Shas everything was measured against

| repo | sha |
|---|---|
| drmTMB (branch base, after merging `origin/main` twice during the leaf) | `df1aca4a60f9f450629238f241392d11f44d2d3a` |
| DRM.jl (`origin/main` when the leaf pinned it) | `aee371cc9627c24945859f4caa749e0d5b691782` |

`origin/main` moved under this leaf on both sides while it ran. DRM.jl went
`84120ff74` -> `aee371cc9` between generating a draft scoreboard and generating
the join, twenty minutes apart. That is why every artefact this leaf produces
writes both shas into its own header: a count without its shas is not a
measurement. The programme pin named in the brief, DRM.jl `430ef64cc`, is an
ancestor of `aee371cc9` and was NOT used for these artefacts -- they read
committed docs and evidence tables only, no Julia is started, so reading the
current `origin/main` is both safe and more useful than reading a stale pin.
Measured: `430ef64cc..origin/main` is **51 commits, 31 of them merges**, and
DRM.jl's `docs/design/capability-status.md` DIFFERS between the two. Generating
the native_Julia axis at `430ef64cc` would have reported a Julia surface that no
longer exists.

## THE HEADLINE: 23 of 45

**45** drmTMB-native capabilities (not 43 -- see "Numbers that were wrong going
in"). Of those, on the bridge axis:

| verdict | n |
|---|---:|
| `RECEIPT` -- a passing DRM.jl receipt reached through a committed ledger row | **17** |
| `RECEIPT-NOT-LEDGERED` -- a passing receipt exists, no ledger row connects it | 4 |
| `REFUSED+UPSTREAM-RECEIPT` -- drmTMB refuses a route DRM.jl has a receipt for | 1 |
| **`UNCITED`** -- no receipt and no cited refusal | **23** |

**23 of 45 is the number the closure will quote.** It is not "23 capabilities
are broken": it is "23 capabilities cannot be pointed at". The distinction is
made explicit in the scoreboard's own "Evidence that exists and lifts nothing"
section, which lists the 12 receipt `capability_id`s no capability row reaches
and the 9 `parity-intervals.tsv` rows that are keyed by `cell_id` and therefore
join to nothing at all.

Native axes, for contrast: `native_R` 32 FITS / 8 PARTIAL / 5 NO; `native_Julia`
41 FITS / 1 PARTIAL / 3 NO; **0 UNCITED on either native axis**, because both
twins' `capability-status.md` files carry a status word for every matched row.
The gap is entirely on the bridge.

## What was produced

| # | artefact | generator | committed |
|---|---|---|---|
| 1 | `docs/design/parity-scoreboard.md` | `tools/write-parity-scoreboard.R` | yes |
| 2 | the parity-matrix diff summary (below) | re-ran `tools/write-parity-matrix.R` | report only, see "Why the matrix is not re-committed here" |
| 3 | `docs/design/capability-status-join.md` | `tools/write-capability-status-join.R` | yes |
| 4 | `docs/dev-log/plan-actual/2026-09-05-parity-joint.md` | one-shot, arc list checked mechanically | yes, as a TODO skeleton |

Both generators `sys.source()` `tools/write-parity-matrix.R` rather than
re-implementing its parsing. The scoreboard reuses `pm_load_context()`,
`pm_build_matrix()` and `pm_cite()`; the join reuses `pm_parse_status_table()`.
That is deliberate. The capability-name -> ledger-row join is subtle -- the
`phylo_gamma_beta_binomial` substring trap, the `|` random-effect guard, the
modifier-dpar routes -- and a second independent implementation of it would be a
second chance to be confidently wrong. One matcher, three readers.

## (2) What MOVED in the parity matrix

Re-ran `tools/write-parity-matrix.R` twice against different DRM.jl inputs to
separate drmTMB-side movement from DRM.jl-side movement.

| comparison | raw changed lines | substantive changed lines |
|---|---:|---:|
| committed `docs/design/parity-matrix.md` vs regeneration at its OWN recorded pin `d3efbad2f` | 66 | 4 |
| regeneration at `d3efbad2f` vs regeneration at DRM.jl `aee371cc9` | 98 | 0 |
| committed vs regeneration at `aee371cc9` (drmTMB `df1aca4a`) | 100 | 4 |

"Substantive" means: after normalising away sha labels and every `file:line`
number, which is what the normalising diff in this leaf's scratch measured.

The four substantive lines are two changed lines counted twice (once removed,
once added), and they carry ONE fact.

**Everything that moved is one fact, stated twice.** The bridge ledger is
unchanged (25 rows); the gate registry grew from 14 to 15 rows -- the new row is
`fe_only_random_effects` (`inst/extdata/julia-gates.tsv:16`, added by
`b43897d03`, the A4.G17 fixed-effect-only scope fence) -- and the matrix reports
that count in two places, its Inputs list and the `R to Julia bridge
(engine=julia)` row. Nothing else changed semantically:

- 45 rows before and after; no capability added or removed.
- **4 GREEN before and after.** The GREEN count did not move.
- No `native_R` or `native_Julia` status word changed.
- Between DRM.jl `d3efbad2f` and `aee371cc9`, DRM.jl's `capability-status.md`
  and all five evidence tables are BYTE-IDENTICAL; only `src/bridge.jl` differs,
  and not on any line the matrix cites. The matrix's DRM.jl-side inputs have not
  moved SINCE `d3efbad2f`. They did move before it: between the brief's pin
  `430ef64cc` and `aee371cc9`, DRM.jl's `capability-status.md` DIFFERS.
- All remaining diff lines are line-number drift. Since the commit that last
  generated the matrix (`1cde89fa8`), `git diff --numstat` over the matrix's
  drmTMB-side inputs reads `R/julia-bridge.R` +429/-41, `R/drmTMB.R` +47/-11,
  `inst/extdata/julia-gates.tsv` +1/-0, and NOTHING for
  `docs/design/capability-status.md` or `inst/extdata/julia-capabilities.tsv`.
  Only the one gate line is semantic; the rest just moved the cited lines.

**The committed matrix is provably stale, and the repo says so itself.** With
`DRM_JL_PATH` set to a clone at the matrix's own recorded pin, the repo's own
gate fails:

```
tools/write-parity-matrix.R regenerates byte-identically and matches the
committed artefact at its pin  -- FAILED
...gates.tsv) | ... 15 gates ... (actual)
...gates.tsv) | ... 14 gates ... (expected)
```

That test SKIPS when `DRM_JL_PATH` is unset, which is how the staleness survived
in CI. Measured at this sha with the variable unset: `pass: 128  fail: 0
error: 0  skip: 2` -- green. With the variable set to a clone at the matrix's own
pin, the byte-identity test fails as quoted above. The skip is the whole
difference.

### Why the matrix is not re-committed here

PR **#1211** (`claude/parity-docs-staleness`, "re-derive both generated design
docs over today's merges (7 staleness items)") already owns that regeneration.
Committing a regenerated `docs/design/parity-matrix.md` from this leaf would
collide with it for no gain. The diff summary above is the deliverable; the
regeneration belongs to #1211, and the closure should read #1211's merged output,
not this leaf's scratch copy.

## (3) The capability-status join

45 drmTMB rows, 48 DRM.jl rows, read with `git show origin/main:...` against the
canonical DRM.jl repo -- never its working tree, which sits on another lane's
branch.

- **0 rows only in drmTMB's file.** Every drmTMB capability name exists
  byte-for-byte in DRM.jl's file.
- **3 rows only in DRM.jl's file**: Conjugate-EM Gaussian phylo-mean
  (`algorithm = :em`, `implemented`), Natural-gradient EM
  (`algorithm = :natgrad`, `rejected`), Fisher / observed-info metric
  (`lc_metric`, `implemented`).
- **14 matched rows whose STATUS WORD differs.** This is the finding the matrix
  cannot show, because the matrix reports both words side by side and never
  counts the disagreement. ELEVEN of the fourteen are DRM.jl claiming MORE than
  drmTMB -- `implemented` against `scope-limited` (4), `point-fit-recovery` (4)
  or `planned` (3). TWO run the other way: `Missing-response handling` (drmTMB
  `implemented`, DRM.jl `missing`) and `Missing-predictor imputation (mi())`
  (drmTMB `implemented`, DRM.jl `experimental`). The fourteenth,
  `Cross-family bivariate`, is non-implemented on both sides in different words
  (`planned` against `missing`).

A closure sentence of the form "the twins agree" is false at this sha for 14 of
45 rows, and the file names all 14 with both line numbers.

## (4) The plan-vs-actual skeleton

`docs/dev-log/plan-actual/2026-09-05-parity-joint.md`, **23 arcs**, every status
`TODO`. The arc list was extracted from the committed
`docs/dev-log/loop/parity-joint-20260905/ultra-plan.md` and the extractor ABORTS
if any `| **A...** |` row of the ARC PROGRAM table is unrepresented -- all 12
table rows are covered, with `A4.1`-`A4.9` and `A7.1`-`A7.3` expanded into the
families and leaves the plan itself names, and `A0.5` cited to the 24-HOUR BURN
line that adds it.

The skeleton also carries an "Executed but not planned" table (empty, `TODO`), a
node-gate table (N1-N5 from the plan's own acceptance ledger), a closure
checklist, and required `Process drift` and `What this lane did NOT cover`
sections. It points at the existing working draft in `LOOP/` as a source of
LEADS and says explicitly not to copy numbers out of it without re-measuring --
that draft's A2 row says the matrix has 43 rows.

## Red controls

Every negative gate in the two new generators was planted, shown to fail with
verbatim output, and restored byte-identically.

| # | gate | planted defect | verbatim failure | restored |
|---|---|---|---|---|
| RC1 | a declared receipt alias must resolve | added alias `Poisson counts -> fe_this_receipt_does_not_exist` | `Error: declared receipt alias has no receipt row at the ref: Poisson counts -> fe_this_receipt_does_not_exist` | `cmp` against backup: identical |
| RC2 | a declared alias must not duplicate a ledger row | added alias `Poisson counts -> fe_poisson` | `Error: receipt alias is redundant (a ledger row already cites it): Poisson counts -> fe_poisson` | `cmp` against backup: identical |
| RC3 | an unrecognised status word must abort, not fall through | `\| Poisson counts \| totally-fine \|` in `capability-status.md` | `Error: entry table and capability-status.md disagree: missing ; extra Poisson counts` | `git show HEAD:` restore, `git diff --stat` empty |
| RC4 | the join must actually DETECT a drmTMB-only row | renamed `Poisson counts` -> `Poisson counts RENAMED` | join went `0 drmTMB-only` -> `1 drmTMB-only`, and the row is listed with its line | `git show HEAD:` restore, join back to `0` |
| RC5 | `sb_native_verdict()` has no silent fall-through | called it with `"a-word-nobody-added-here"` | `unknown capability status word: a-word-nobody-added-here` | no file touched |

RC4 matters most. "0 rows only in drmTMB's file" is a claim about an empty set,
and an empty set is not a pass unless the check can produce a non-empty one.

## Independent cross-check of the 4 `RECEIPT-NOT-LEDGERED` rows

The scoreboard reaches Truncated NB2, Cumulative logit, Zero-one-inflated beta
and Tweedie only through declared aliases, because no committed ledger row
connects them to their receipts. The repository's own
`tests/testthat/test-parity-matrix.R` reports, in its skip reason at this sha:

```
4 routes await their TSV row from PR #1184 (not yet merged here):
truncated_nbinom2, zero_one_beta, tweedie, cumulative_logit
```

The same four, identified by a different mechanism. That is the strongest
validity evidence this leaf has for the alias tier.

## Numbers that were wrong going in

- The dispatch brief said **43** drmTMB-native capabilities. Measured: **45**.
  Both the committed `docs/design/parity-matrix.md` header and a fresh
  regeneration say 45; the 43 traces to a working draft in `LOOP/` and to a
  stale comment inside `tools/write-parity-matrix.R` (`| rows in this file |
  43 |`, at the `pm_parse_status_table()` docstring). The comment is inside
  another lane's file and was NOT edited here.
- The brief named DRM.jl `430ef64cc` as the pin. It is four merges behind
  `origin/main` for the documents these artefacts read, so the artefacts read
  `aee371cc9` and say so.

## What this leaf does NOT cover

- No fit was run and no Julia was started. Every number is a join over committed
  files. A `RECEIPT` verdict means a receipt row EXISTS and passes at the read
  sha; this leaf did not re-execute any receipt.
- The scoreboard cannot report a drmTMB-only capability, because the shared join
  aborts on one. That case is the join artefact's job, and RC4 proves the join
  detects it.
- `parity-intervals.tsv` is keyed by `cell_id`, carries no `capability_id`, and
  is not joined. Its `INTERVAL_PASS` rows for `gauss_locscale_fe` and
  `poisson_fe` therefore do NOT lift `Wald SEs and CIs` out of `UNCITED`. Wiring
  a `cell_id` join is the obvious next improvement, and was left undone rather
  than done by inference.
- No new testthat file was added. Neither generator can run in CI: both need a
  DRM.jl clone and `git`, the same reason the matrix's own byte-identity check
  skips there. That skip is how today's staleness survived, and it is worth a
  leaf of its own.
- `docs/design/parity-matrix.md` is NOT regenerated here; PR #1211 owns it.
