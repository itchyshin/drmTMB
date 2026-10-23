# Timing and size receipt — candidate `6b45164b…`

## Size

- source tarball: 4,367,799 bytes;
- tarball inventory: 945 entries;
- installed package (`du -sk`): 25,320 KiB = 25,927,680 bytes;
- installed `doc/`: 4,824 KiB = 4,939,776 bytes;
- installed `help/`: 760 KiB;
- installed `html/`: 24 KiB.

The exact tarball installed successfully into a disposable library with
`R_PROFILE_USER=/dev/null` and `NOT_CRAN=true`. The installed-package size
check is `OK` in local and all three win-builder logs.

## Check timing

| Environment | Test stage | Whole check / notification |
| --- | ---: | ---: |
| local macOS CRAN lane | 203 s elapsed / 239 s reported | terminal 0 errors, 0 warnings, 1 NOTE |
| win-builder R-devel | 14 min | 1,422 s check + 300 s install |
| win-builder R-release 4.6.1 | 14 min | 1,360 s check + 293 s install |
| win-builder R-oldrelease 4.5.3 | 560 s | notification body not supplied |

The suite already excludes exhaustive simulation/reporting and selected
statistical-validation files on the CRAN lane while repository CI retains the
full `NOT_CRAN=true` surface. The remaining Windows duration is material and is
presented to Grace for an explicit submission-readiness judgement. No hard
timing threshold is invented.

