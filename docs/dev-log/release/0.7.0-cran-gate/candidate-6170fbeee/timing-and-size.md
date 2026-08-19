# Timing and size receipt — candidate `1d6445db…`

## Size

- source tarball: 4,368,396 bytes;
- tarball inventory: 946 entries;
- installed package reported by `R CMD check`: 24.7 MB;
- installed `doc/`: 4.7 MB;
- installed `libs/`: 13.7 MB;
- installed `R/`: 3.1 MB;
- installed `sim/`: 1.9 MB.

The source archive is below CRAN's preferred 10 MB source-package guideline.
The installed documentation occupies 4,824 KiB on disk (4,939,776 bytes),
below but close to the general 5 MB documentation guideline.

## Check timing

| Environment | Test stage | Result / boundary |
| --- | ---: | --- |
| local macOS exact-byte CRAN lane | 45 s elapsed / 54 s reported | 0 errors, 0 warnings, 1 expected first-submission NOTE; `PASS 3501` |
| GitHub macOS full developer suite | 23 min | success; same-source evidence, not the CRAN lane |
| GitHub Ubuntu full developer suite | 40 min wall / 25 min CPU | success; same-source evidence, not the CRAN lane |
| GitHub Windows full developer suite | 43 min | success; same-source evidence, not the CRAN lane |
| win-builder R-devel exact-byte CRAN lane | 149 s | 1 NOTE; `PASS 3501`; URL `ltSumbZi569n` |
| win-builder R-release exact-byte CRAN lane | 152 s | 1 NOTE; `PASS 3501`; URL `fyFu1tPBAw5y` |
| win-builder R-oldrelease exact-byte CRAN lane | 110 s | 1 NOTE; `PASS 3501`; URL `S2uf1uo65N7E` |

The GitHub jobs intentionally run the complete `NOT_CRAN=true` development
suite. Their durations are not used to predict CRAN check time. The bounded
exact-byte Windows timings come from the three raw `testthat.Rout` files linked
to uploads completed at 2026-08-19 01:51–01:52 UTC. All are well below the
project's conservative first-submission timing margin.
