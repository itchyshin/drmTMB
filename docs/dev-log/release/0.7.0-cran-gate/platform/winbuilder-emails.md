# win-builder result emails (2026-08-07)

Gmail thread id: `19fdd3b95ebe5f0b` (from `ligges@statistik.tu-dortmund.de`).

## Fixed-tarball adjudication (authoritative for CondExp repair)

FTP **226** of fixed SHA `f9b9588e31c15040ad6b4b4eafa7ffeb1e7eb64a2379d1a6a3859670109a8065`
(size **9818425**, CondExp path repair inside) ~2026-08-07T23:00Z. Result emails
and check logs below are the ones that count.

| Flavor | Email time (UTC) | Message id | URL | Email status | Log status | CondExp `drm_src_path` ERROR |
| --- | --- | --- | --- | --- | --- | --- |
| **R-devel** | 2026-08-07T23:44:22Z | `19fde9d72e2b03a1` | https://win-builder.r-project.org/qS15UqA2O00A | **1 NOTE** | **1 NOTE** (`winbuilder-devel-fixed-00check.log`) | **cleared** (tests OK; no CondExp / `Cannot locate` match) |
| **R-release 4.6.1** | 2026-08-07T23:49:12Z | `19fdea1dfc41e8b5` | https://win-builder.r-project.org/BQVnXOH066rJ | **1 NOTE** | **1 NOTE** (`winbuilder-release-fixed-00check.log`) | **cleared** (tests OK; no CondExp / `Cannot locate` match) |

Remaining NOTE on both flavors (CRAN incoming feasibility only):

- New submission
- Possibly misspelled DESCRIPTION words: `centile`, `mis`, `uncalibrated`
- Possibly invalid file URI `function-map-cheatsheet.png` from
  `inst/doc/function-map-cheatsheet.html`

Check times on the fixed logs: R-devel start ~23:07 UTC; R-release ~23:13 UTC
(consistent with the ~23:00Z FTP, not the morning ERROR runs).

**Ledger:** leave `status_claim` at **`tarball-clean`**. ERROR-free win-builder
evidence exists and is ready for **owner authorize** of any `platform-clean`
advance. Do not bump DESCRIPTION / do not upload CRAN without owner word.

## Historical — morning ERROR runs (unrepaired layout)

| Flavor | Email time (UTC) | URL | Status |
| --- | --- | --- | --- |
| R-devel | 2026-08-07T17:17:52Z | https://win-builder.r-project.org/nF44JzoI2nZ9 | **1 ERROR, 1 NOTE** |
| R-release 4.6.1 | 2026-08-07T17:20:58Z | https://win-builder.r-project.org/XhAiv0jf1AUd | **1 ERROR, 1 NOTE** |

These used the unrepaired CondExp path. Logs retained as
`winbuilder-devel-00check.log` / `winbuilder-release-00check.log`.

## Intermediate queue noise (do not use for rung claim)

Same-name FTP queue produced additional emails before the fixed ~23:00Z pair
was definitive. Recorded for audit only:

| Email time (UTC) | Flavor | URL | Status | Note |
| --- | --- | --- | --- | --- |
| 20:45:09Z | R-release | https://win-builder.r-project.org/IgzzdjY2ctOv | 1 NOTE | Earlier queue; not the fixed SHA adjudication |
| 20:58:14Z | R-devel | https://win-builder.r-project.org/Azl1po0RxxHY | 1 NOTE | Earlier queue; not the fixed SHA adjudication |
| 21:44:42Z | R-release | https://win-builder.r-project.org/RZauGciQ8XdG | **1 ERROR, 1 NOTE** | Likely stale morning tarball (9817096) from the accidental upload |
| 21:54:29Z | R-devel | https://win-builder.r-project.org/dphjeeS8Qm5a | 1 NOTE | Intermediate; superseded by 23:44Z fixed result |
