# 0.6.0 pre-CRAN pkgdown and reference audit

**Reviewed SHA:** `99bf0974df8104dde66bf9e0219cc4a4b570fca3` (`origin/main`, 2026-07-21).

## Scope and fence

This review audited the README, 34 article sources, and 68 generated Rd pages
against the 20 July release-scope manifest and generated capability ledger.
A blocker was limited to a correctness defect or a false shipped claim. The
frozen tarball-clean rung was not rerun.

## Corrected blockers

- Gamma's ordinary log-`sigma` random intercept had been described as
  recovery-only. Public pages now state its exact ML-Laplace profile-interval
  evidence: true SD 0.40, `n_each=12`, `M >= 32`, with `M=16` borderline; no
  slopes, labels, combined `mu`/`sigma`, REML, or `supported` claim.
- ~~Four public pages gave an interval claim for regression `rho12 ~ x`. They now
  distinguish the point-only regression curve from the admitted profile interval
  for constant `rho12 ~ 1`.~~ **WITHDRAWN 2026-07-21 — this was a false positive
  and the "correction" was reverted.** A `rho12 ~ x` regression *does* produce
  row-specific intervals once `newdata` is supplied. `conf.status =
  "newdata_required"` is an instruction to supply `newdata`, not a denial of
  capability. The four pages were stating the truth; the edit removed it. See
  the reversal record in
  `docs/dev-log/after-task/2026-07-21-rho12-interval-audit-reversal.md`. What is
  genuinely absent is *coverage evidence* for those row-specific intervals, and
  the restored pages now say exactly that.
- Three Julia/cross-family claims exceeded the 0.6.0 fence. The q4 Julia claim
  is now explicitly deferred, and the cross-family page is a short development
  note with no point or interval inference recommendation. It names the future
  estimand `rho_latent`, not native-Gaussian `rho12`.
- The zero-one-beta pages now retain the terminal generator-qualified conclusion
  rather than promising a strictly-interior rerun.

## Follow-ups retained

- Add measured provenance or remove the illustrative laptop-time statement in
  `phylogenetic-models.Rmd`.
- Link the structural and large-data reader paths more directly to the
  row-specific capability guide.
- Confirm the normal pkgdown deployment after merge; the newly added
  function-map page was absent from the then-live site before its source merged.

## Verification

```sh
python3 tools/capability_ledger.py --check
R_PROFILE_USER=/dev/null Rscript --vanilla tools/check-capability-runtime.R
R_PROFILE_USER=/dev/null Rscript --vanilla -e 'pkgdown::build_site(); pkgdown::check_pkgdown()'
```

The ledger check reported 30 generated outputs; the runtime check reported 18
routes with G0/G1/G2 all zero; the full site build completed with URL, metadata,
reference, and pkgdown checks clean (69 reference and 35 article HTML pages).

## Disposition

**Superseded in part, 2026-07-21.** Of the seven blockers this pass acted on,
the three Julia/cross-family findings and the Gamma and zero-one-beta wording
stand. The four regression-`rho12` findings were false positives; their edits
have been reverted and the manifest itself corrected. This pass's own claim of
"no remaining blocker" was therefore not earned: the audit verified each cited
line but never called the function it was making a claim about, and never
grepped the claim token across the other surfaces that carried it.

Subject to that correction, the audited 0.6.0 reader and reference surface
contains no remaining blocker found in this pass. This does NOT cover a platform
matrix, CRAN submission, or post-0.6 Julia development.
