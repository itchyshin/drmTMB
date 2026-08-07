# R-hub compiled-code matrix — platform attempt (2026-08-07)

- URL: https://github.com/itchyshin/drmTMB/actions/runs/31195195196
- Config: `clang-asan,clang-ubsan,gcc-asan,valgrind,rchk`
- Head SHA: `744b9fbeec226784fa0b94f27e63bf121f31bed7`
- Run status/conclusion at write: **in_progress / pending**

| Job | Conclusion | URL | Adjudication |
| --- | --- | --- | --- |
| setup | success | https://github.com/itchyshin/drmTMB/actions/runs/31195195196/job/92921580229 | n/a |
| clang-asan | success | https://github.com/itchyshin/drmTMB/actions/runs/31195195196/job/92921625976 | PASS — no package-owned ASAN findings recorded in job success |
| valgrind | in_progress | https://github.com/itchyshin/drmTMB/actions/runs/31195195196/job/92921626041 | INCOMPLETE at ledger close — job still in_progress after >2.5h; does not unblock platform-clean while win-builder ERROR stands |
| rchk | failure | https://github.com/itchyshin/drmTMB/actions/runs/31195195196/job/92921626073 | FAIL job; adjudicated NOISE (TMB headers / abstraction limits) — see rhub-rchk-adjudication.md |
| clang-ubsan | success | https://github.com/itchyshin/drmTMB/actions/runs/31195195196/job/92921626079 | PASS |
| gcc-asan | success | https://github.com/itchyshin/drmTMB/actions/runs/31195195196/job/92921626099 | PASS |
| matrix.config.label | skipped | https://github.com/itchyshin/drmTMB/actions/runs/31195195196/job/92921627134 | skipped (rhub other-platforms empty) |
