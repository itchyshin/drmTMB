# win-builder re-upload receipt — candidate `302ac2579` (missing lanes)

**2026-08-16T14:47Z · Cursor · unlock lane only · NOT a CRAN submission**

## Why

Gmail (`itchyshin@gmail.com`, `in:anywhere`, include Trash) holds exactly one
`drmTMB_0.7.0` win-builder result: R-devel (Status 1 NOTE), already filed as
`winbuilder-devel.txt` + `winbuilder-devel-00check.log`. R-release and
R-oldrelease result emails are **absent** despite the original 2026-08-16
~00:06Z / ~00:49Z upload wave. Positive control: the same query family returns
that devel thread plus historical `drmTMB_0.6.0` threads — mailbox access works;
the two lanes simply never mailed back.

Shinichi pre-authorised the original upload wave; this session re-uploads only
the missing lanes against the **immutable** frozen bytes (handover unlock).

## Bytes (immutable — never rebuild)

| | |
| --- | --- |
| File | `/Users/z3437171/drmTMB-release-artifacts/0.7.0-302ac2579/drmTMB_0.7.0.tar.gz` |
| SHA-256 immediately before upload | `0d150ef38b8d3b8b2d3dca084a62f8242832048b01e60caa4b08c5388b95e075` |
| Size | 10,087,906 bytes |
| Match to freeze | YES |

## Uploads this session

| Lane | FTP target | UTC | curl exit | Post-upload listing |
| --- | --- | --- | --- | --- |
| R-release | `ftp://win-builder.r-project.org/R-release/` | **2026-08-16T14:47:41Z** | 0 | `drmTMB_0.7.0.tar.gz` present |
| R-oldrelease | `ftp://win-builder.r-project.org/R-oldrelease/` | **2026-08-16T14:47:45Z** | 0 | `drmTMB_0.7.0.tar.gz` present |

R-devel was **not** re-uploaded (result already filed and clean).

## Explicit non-claims

- This receipt is **not** a check result.
- `status_claim` stays `tarball-clean`.
- `platform-clean` is **not** advanced (`evidence.external_logs` incomplete).
- Gate 7 panel is **not** run.
- CRAN submission remains **forbidden**.
