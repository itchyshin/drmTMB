# CRAN extra checks — source `6170fbeee`

Date: 2026-08-19 UTC

These checks supplement, rather than replace, the exact-byte
`R CMD check --as-cran --run-donttest` receipt.

## Package metadata and installation surface

- `DESCRIPTION` identifies package/version `drmTMB` 0.7.0, uses a title-case
  61-character title, gives a substantive description, and records Shinichi
  Nakagawa as `aut`, `cre`, and `cph` with email and ORCID.
- `License: GPL (>= 3)` is backed by the complete GPL-3 licence file.
- Package and bug-report URLs use HTTPS.
- `README.md` contains current pre-CRAN installation instructions and clearly
  reserves `install.packages("drmTMB")` for after CRAN acceptance. It has no
  relative Markdown link or insecure HTTP package link.
- The built inventory contains no `.git`, `.Rproj.user`, compiled residue,
  release evidence, or protected `_julia_skip2_artifacts/` entry.

## Documentation surface

The 59 namespace exports all have installed aliases and `\\value` sections.
Five exports do not own a separate `\\examples` block:

- `association()` and `latent_normal()` are both exercised together in the
  `associate_pairs()` example on their shared public workflow;
- `gr()` and `meta_known_V()` are deprecated/internal compatibility markers;
- `rho_latent()` is a compatibility extractor for the optional, deferred Julia
  bridge and has no ordinary CRAN-lane constructor.

This is documented-example sharing or compatibility scope, not a missing
public workflow. The exact check independently reports examples,
code/documentation matching, and missing documentation entries as `OK`.

## Rights and provenance

`inst/COPYRIGHTS` records the original package artwork and the two relevant
GPL-compatible adaptations with upstream repository, commit, files/lines, and
the boundaries of what was and was not adapted. The separate
`rights-and-consent.md` receipt confirms that the built inventory excludes the
unverified cheatsheet image and carries no unidentified third-party data or
binary asset.

## URLs and spelling

`urlchecker` fetched 35 URLs and returned only a publisher/bot HTTP 403 for the
valid Wiley DOI `10.1111/2041-210X.70160`; see `url-check-result.md`.

Incoming-feasibility spelling checks identify `centile`, `misspecification`,
and `uncalibrated`. All three are intentional technical/British-English terms
used accurately in `DESCRIPTION`. Final `cran-comments.md` must name them
explicitly rather than describing the incoming NOTE as new-submission-only.

## Verdict

No extra-check finding requires a shipped-byte repair. The DOI 403 and the
three intentional words require transparent submission comments. This receipt
does not itself establish `platform-clean` or `submission-ready`.
