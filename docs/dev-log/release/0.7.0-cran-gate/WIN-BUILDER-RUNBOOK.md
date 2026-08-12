# win-builder run-book for drmTMB 0.7.0

## What win-builder is and why it is needed

win-builder is a free CRAN service that runs `R CMD check` on Windows against your source tarball
before you submit to CRAN. It is the only platform class currently absent from the evidence set for
this candidate, and it is also the only way to measure the real Windows CRAN-lane test runtime (the
GitHub Actions Windows run sets `NOT_CRAN=true` and therefore runs the full suite, a different lane).
This run is what would close the last absent platform class and turn the projected Windows CRAN-lane
`checking tests` figure into a measured one.

## Before you start — the frozen bytes are perishable

`R CMD build` embeds timestamps, so rebuilding from the source commit produces a *different* file.
These exact bytes therefore cannot be recreated: if every copy is lost, the candidate must be re-frozen
and every platform result above it re-run. Three copies exist, all verified byte-identical on
2026-08-11:

- `~/drmTMB-release-artifacts/0.7.0/drmTMB_0.7.0.tar.gz` — **use this one**; durable, outside `/tmp`
- `~/drmTMB_0.7.0_cand2.tar.gz` on Totoro — durable off-machine copy
- `/private/tmp/drmTMB-07-freeze2/drmTMB_0.7.0.tar.gz` — **volatile**, macOS purges `/private/tmp`

Before uploading, confirm the file you are about to send is the candidate:

```sh
shasum -a 256 ~/drmTMB-release-artifacts/0.7.0/drmTMB_0.7.0.tar.gz
# expect 2176e4b81b887e8d944456e4a74fa581afda959d0d2a5468c89bc700d693cda9
```

If a copy is missing, restore it from one of the others rather than rebuilding.

## How to submit

### Route 1: devtools (rebuilds from source — does NOT test frozen bytes)

```r
devtools::check_win_release()
devtools::check_win_devel()
```

**Caveat:** The `devtools` functions rebuild the tarball from your current working directory and
**do not test the frozen candidate bytes** (`2176e4b81b887e8d944456e4a74fa581afda959d0d2a5468c89bc700d693cda9`). 
This matters for a CRAN submission because the frozen file is what CRAN will receive.

### Route 2: manual upload to frozen tarball (recommended)

1. Visit https://win-builder.r-project.org/upload.aspx in your browser.
2. Upload the frozen `drmTMB_0.7.0.tar.gz` from
   `~/drmTMB-release-artifacts/0.7.0/drmTMB_0.7.0.tar.gz` — the durable copy, not the `/private/tmp`
   one, which macOS may have already removed.
3. Select version: **R-release**.
4. Repeat steps 1–3, selecting **R-devel** instead.

The frozen file is the exact bytes that will ship to CRAN, so this route tests what matters.

## What to expect

Results arrive by email to the address in DESCRIPTION (`itchyshin@gmail.com`) within approximately 30
minutes. win-builder does not provide a web result page — check your email inbox and spam folder.

## What to read in the reply

- **Status line:** expect `Status: 1 NOTE` (the `New submission` message) and 0 ERROR, 0 WARNING.
- **Any additional NOTEs/WARNINGs/ERRORs:** if present, they require investigation before submission.
- **`checking tests` timing:** this is the unmeasured Windows CRAN-lane runtime. Note this number.

## Where to file the result

1. Save the R-release email body as: `docs/dev-log/release/0.7.0-cran-gate/platform-0.7.0/win-builder-release.txt`
2. Save the R-devel email body as: `docs/dev-log/release/0.7.0-cran-gate/platform-0.7.0/win-builder-devel.txt`
3. Add a line to `docs/dev-log/release/0.7.0-cran-gate/RUNG-REPORT-0.7.0.md` in the evidence table:

```markdown
| **win-builder R-release** | **status** | **CURRENT** |
| **win-builder R-devel** | **status** | **CURRENT** |
```

Replace `**status**` with the result (e.g., `success` or a brief description of any failure).

## What this proves and does not prove

A **green win-builder run** proves:

- The frozen tarball passes `R CMD check --as-cran` on Windows with the expected status (1 NOTE).
- The Windows CRAN-lane test runtime, enabling a real measurement instead of a projection.

A **green win-builder run does not by itself** establish the `platform-clean` rung.
`RUNG-REPORT-0.7.0.md` lists four items standing in the way. This run closes **two** of them —
win-builder ABSENT, and Windows CRAN-lane timing UNMEASURED, since the reply reports that timing.
Two would remain:

1. **valgrind is a documented seven-file subset**, not the full suite — the full suite exceeded six
   hours under memcheck. Cite it as "clean on a documented subset", never as "valgrind clean".
2. **Owner authorisation** under D-49, which is a separate decision from the evidence being green.

One further caveat, not on that list of four but worth carrying: the 3-OS matrix and the sanitizer
runs are **same-source, not same-bytes** — those services build their own tarball from commit
`a75c3c901` rather than checking `2176e4b8…cda9`.

So the honest statement after a green run is "win-builder is now green on this tarball", not "the
platform evidence is complete".
