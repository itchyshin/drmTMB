# URL-check adjudication — candidate `e9c5556d…`

Date: 2026-08-18

`urlchecker::url_check()` completed against 34 URL groups and reported two 403 responses:

| DOI | Source location | Crossref title | Publisher | Verdict |
| --- | --- | --- | --- | --- |
| `10.1111/2041-210X.70160` | `vignettes/location-scale-scale.Rmd:478` | *Quantifying macro-evolutionary patterns of trait mean and variance with phylogenetic location-scale models* | Wiley | Registered DOI; publisher redirect blocks the checker |
| `10.1198/0003130032369` | `vignettes/figure-gallery.Rmd:399` | *Raindrop Plots* | Informa UK Limited | Registered DOI; publisher redirect blocks the checker |

The Crossref API returned both DOI records successfully and gave the corresponding canonical
`https://doi.org/...` URLs. This establishes that the DOI registrations exist; it does not claim
that the publisher landing pages accept automated clients.

The first sandboxed URL-check attempt failed DNS resolution for every hostname and is retained as
infrastructure-failure evidence, not as a package finding.
