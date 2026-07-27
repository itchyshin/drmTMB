# Lane-B E0 prerequisite receipt — 2026-07-27

E0 readiness starts only after the two Arc D numerical-safety prerequisites
are merged and their Ubuntu release checks are green. This receipt records the
GitHub state checked on 2026-07-27; it is not campaign evidence and it does
not authorize remote compute.

| Prerequisite | Merged commit on `main` | Ubuntu release check | Result |
| --- | --- | --- | --- |
| Arc D Design 1 narrow log-scale overflow guard ([PR #856](https://github.com/itchyshin/drmTMB/pull/856)) | `02fbbe1e91cdbdbb6175fc0b36c14e0e824ff02d` | [run 30262881936](https://github.com/itchyshin/drmTMB/actions/runs/30262881936/job/89966689603) | `SUCCESS` at 2026-07-27 12:15:53 UTC |
| Arc D Design 2 trace-first `clamp_limited` contract ([PR #857](https://github.com/itchyshin/drmTMB/pull/857)) | `f6cc6fe52250827d1b9cfc54912e4954b7093f50` | [run 30276702978](https://github.com/itchyshin/drmTMB/actions/runs/30276702978/job/90014048471) | `SUCCESS` at 2026-07-27 15:28:53 UTC |

Both PRs also report a successful `os-matrix` run. E0 retains the resulting
contract: any `clamp_limited` or trace-incomplete profile is unavailable and
non-covering; K=12 remains explicit negative evidence. This only clears the
readiness prerequisite. A DRAC/Totoro smoke or pregrid still requires a
separate, explicit approval after the complete no-compute packet is reviewed.
