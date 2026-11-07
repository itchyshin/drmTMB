# Required-universe denominator review
<!-- slop-ok: preserve superseded reviewer findings verbatim as provenance -->

**Historical review note (2026-10-17):** The findings below preserve earlier
5,438-row and 10,806-row generator snapshots. Their denominator gaps and mesh
status findings were superseded by
[universe-correction-receipt.md](universe-correction-receipt.md) and the later
[universe-final-review.md](universe-final-review.md). The final review confirms
the 18,996-row candidate ledger, including 6,750 endpoint-subset candidates,
1,440 native tagged-q4 mirrors, and 72 narrow single-endpoint cross-block
exclusions. It also keeps G0 open for base-route and mathematical review.
Retain the dated sections below as provenance; use the final review and
correction receipt for current counts and findings.

**Scope.** Read-only review of `required-universe.md`, `required-rows.tsv`, and `tools/general-sd-regression/universe.py` against the approved finite union of existing response routes, latent endpoint kinds, provider/input primitives, layouts and engines. This review does not promote any row to direct-SD support or decide G0.

## Findings

The inventory is useful as a deterministic *candidate denominator scaffold*: it keeps both engines and all 20 listed family routes, expands the 54 endpoint source rows over 25 named mechanism templates, distinguishes the listed input primitives and explicit provider pairs, and labels rows as required, blocked, structurally inapplicable, or unresolved. The generator checks row-key uniqueness and equality with its own deterministic expansion; all 5,438 present rows have `direct_sd_claim=none`. I found no evidence that rows disappear silently within the generator’s declared expansion rules.

This is not yet a complete denominator for the approved endpoint × supported block-dimension union. For every multi-endpoint family and cross-endpoint block template, the generator emits one `endpoint="block"` row with `endpoint_members="unresolved_multi_endpoint_member_set"` and skips later endpoint rows. There are 306 such rows. The document openly labels them unresolved, so they are not misrepresented as implemented; however, they do not enumerate which endpoint-member sets are required, nor distinguish their block dimensions. A family with several distributional parameters can have multiple different valid cross-parameter sets. Resolve those sets from the pinned grammar/fit metadata and generate a row for each approved member composition before treating the denominator as complete.

Likewise, `block_shape` stores prose such as “q-general; source examples q2/q4/q8” as one cell rather than expanding the supported q dimensions into distinct rows. This makes the 5,438 count a count of templates/input combinations, not the full approved endpoint × q-dimension universe. The generated summary calls the mechanism templates finite, but “q-general” and “arbitrary predictor count excluded” leave the actual q boundary unresolved. Freeze the q set or a precise symbolic rule for each mechanism and encode it machine-readably before G0.

The source-link table is deliberately sparse: it has explicit variants for native binomial logit/probit/cloglog and Julia binomial logit, with the other family routes assigned `single_or_family_default`. That is acceptable only if the pinned constructors establish one and only one admitted base link for every other family and endpoint represented. The Python checks that non-binomial families have no link rows; it does not verify those unique-link claims against a registry. Record that source audit (or expand the link table where a family/endpoint admits multiple links) before calling link coverage closed.

Several engine classifications are explicitly provisional. For example, row classification reuses source evidence columns containing both native and Julia pins, and the summary acknowledges that engine-specific base-plumbing classifications and spatial mesh slope/block math remain to be reviewed. This is transparent, not a silent exclusion, but it means `required` versus `blocked_base_plumbing` is not yet a reviewed per-cell scientific classification. Also, native/Julia coverage is not symmetrical by implication: a blocked Julia spatial or temporal row remains in the denominator, which is the correct treatment pending a documented incompatibility decision.

## Disposition and exact limits

**Disposition:** generator mechanics pass for preservation of the rows its current templates define; denominator completeness is **not yet established**. The unresolved endpoint-member sets, unexpanded q dimensions, and unaudited single-default-link assumption are blockers to declaring the approved finite union fully enumerated. They are not evidence that direct-SD support has been established or that any required row may be excluded. The current markdown correctly leaves G0 open and reports zero direct-SD promotions.

No fits or source mutations were performed. This review does not validate the pinned source citations line by line, approve any family/provider combination as mathematically compatible, decide whether every listed row is identifiable, or close G0.

## Re-review of the expanded cross-engine denominator

The revised expansion resolves two earlier bookkeeping defects: the old 306 placeholder rows are gone, and q anchors, symbolic coefficient-count domains, and partition labels now appear as explicit machine-readable fields. The current generator is deterministic and has 10,806 unique rows, with `direct_sd_claim=none` throughout. These are useful repairs, but the generated universe is still not complete under the approved cross-engine union.

**Blocker — mesh q1 source limit is misclassified as structural inapplicability.** There are 586 rows whose status is `structural_inapplicable` solely because the pinned mesh contract is q1-only. A q1-only implementation establishes that higher-q mesh plumbing is absent; it does not establish that the corresponding covariance/labelled-block model is mathematically impossible or outside the approved scope. The root review already says mesh covariance mechanisms must remain unresolved or blocked unless an explicit scope decision excludes them. Reclassify these rows as `blocked_base_plumbing` or `unresolved`, with the pinned q1 limit retained as evidence. The other 72 structural rows are single-endpoint-family cross-endpoint blocks; that exclusion is coherent where there truly is only one response endpoint.

**Blocker conditional on the approved cross-engine-union interpretation — Julia tagged q4 rows lack native counterparts.** The table contains 1,440 Julia rows for tagged q4 partitions: 15 partition labels across three bivariate families and four structured provider mechanisms. I found zero exact native rows with the same family, endpoint members, provider/input, q, and partition label. Native has some corresponding q4 block rows with a different partition label, so this is not a general absence of the block mechanism; it is an exact partition-denominator gap. If the agreed union means every existing engine-specific primitive is represented for both engines, generate the 1,440 native rows with the matching tag and retain an honest `blocked_base_plumbing` or `unresolved` status. Do not mark them structurally inapplicable merely because native does not yet expose the Julia layout. If the contract instead makes partitions engine-local, record that narrower interpretation explicitly before treating this as out of scope.

**Blocker — special dpars are not enumerated as multi-endpoint candidate sets.** The source family inventory includes `nu`, `zi`, `hu`, `zoi`, `coi`, and `rho12`, but `block-rules.tsv` has member sets only for `mu1,mu2`, `mu1,mu2,sigma1,sigma2`, `sigma1,sigma2`, `mu,sigma`, and `*`. In the generated block rows, the only special-parameter cross-endpoint composition I find is `mu,zi` (18 rows); `nu`, `hu`, `zoi`, `coi`, and `rho12` occur as individual endpoint members, not as labelled multi-endpoint candidate sets. This falls short of the root review’s instruction to preserve these targets as unresolved or blocked unless a math/scope decision excludes them. Add the finite canonical member-set candidates for the affected family endpoints and block mechanisms, or document a specific incompatibility/scope reason for each omitted set. A candidate row must not be read as an admission or identifiability claim; retain `unresolved` where the evidence does not decide compatibility.

Keep q coverage finite and symbolic: retain the finite q anchors that validate each mechanism and the exact coefficient-count domain (for example, a symbolic `q=p` class), rather than enumerating arbitrarily many predictor counts. The 1,440-row counterpart request concerns the finite Julia q4 partition set only; it does not justify an unbounded q expansion.

**Disposition.** The denominator remains open. The 586 mesh classifications are a concrete status error relative to the reviewed scope; the missing native tagged rows and special-dpar member compositions are denominator gaps unless the scope contract is explicitly narrowed. This review does not decide which unresolved combinations are mathematically identifiable, promote any row to supported, or close G0. No fits or source edits were performed.

**Version note.** The first review section above records the earlier 5,438-row generator snapshot; its statements about current 306 placeholders and unexpanded q dimensions are superseded by this re-review of the 10,806-row revision. The unresolved blockers in this section are the current findings.
