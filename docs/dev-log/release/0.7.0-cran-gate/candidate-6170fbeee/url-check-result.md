# CRAN URL audit — source `6170fbeee`

Date: 2026-08-19 UTC

The exact clean source checkout was checked with:

```sh
R_PROFILE_USER=/dev/null NOT_CRAN=false \
  Rscript --no-init-file -e \
  'x <- urlchecker::url_check("."); print(x)'
```

`urlchecker` fetched 35 URLs. It reported one automated-access failure:

```text
vignettes/location-scale-scale.Rmd:478:43 403: Forbidden
https://doi.org/10.1111/2041-210X.70160
```

The DOI is not malformed or dead. An independent title/DOI lookup resolves it
to *Quantifying macro-evolutionary patterns of trait mean and variance with
phylogenetic location-scale models*, published in *Methods in Ecology and
Evolution* (2025), and the publisher record carries the same DOI. Direct
automated requests to the DOI resolver receive HTTP 403, so the finding is
classified as publisher/bot access behaviour rather than a package URL defect.
The canonical DOI remains preferable to replacing the citation with a less
durable publisher-session URL.

This is same-source, read-only release hygiene evidence. It does not change the
immutable tarball or promote the candidate beyond the external platform rung.
