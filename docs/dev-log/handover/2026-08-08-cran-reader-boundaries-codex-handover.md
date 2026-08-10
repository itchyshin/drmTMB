# Handover: reader boundary live; current-main 0.6.0 tarball-clean

Date: 2026-08-08 MDT. This closes M1 and M2 of
`docs/dev-log/2026-08-08-cran-reader-boundaries-ultra-plan.md`.

## Current truth

- M1 is live. PR #948 merged at
  `ad475cc39f62f47a346c77aa17c3d20bf3fc9bae`; post-merge R-CMD-check run
  `31266713858` and pkgdown/Pages run `31268615909` passed.
- Public page: **Can I fit and report this model?** at
  `articles/capability-and-limits.html`. Homepage/navigation, reader journeys,
  one-hop `ROADMAP.html` redirect, search, sitemap, and desktop/mobile layouts
  were verified live.
- Exact M2 artifact: `/private/tmp/drmTMB-07-reader-boundaries-tarball/drmTMB_0.6.0.tar.gz`.
  Source `ad475cc39f62f47a346c77aa17c3d20bf3fc9bae`; SHA-256
  `2e5234bd4bf819663e9ef95f10a1944d51c90ce64ffd5dd7a9641b69fa50c5ea`;
  9,831,204 bytes; 922 entries.
- Exact `R CMD check --as-cran --run-donttest`: 0 ERROR, 0 WARNING, 1 NOTE
  (`New submission` only). Independent identity and extracted-tarball article
  rendering passed.
- Highest proven rung: **`tarball-clean`**. Next unproven rung:
  **`platform-clean`**.

## Boundaries

DESCRIPTION is still 0.6.0. Earlier fixed win-builder and platform results are
predecessor evidence only and do not prove this artifact. No `platform-clean`
write, platform campaign, D-43 panel, `cran-comments.md` finalization, or CRAN
upload occurred. Do not touch #858, #937, #947, the dirty primary
`claude/handover-freshness-0718` checkout, or foreign worktrees/stashes.

The release ledger, hash, size, inventory, check logs, freeze note, check log,
after-task report, and plan-vs-actual note were refreshed only under
build-excluded `docs/dev-log`; frozen package bytes remain unchanged.

## START A FRESH TASK

Future copy-ready prompt:

> Rehydrate from
> `docs/dev-log/handover/2026-08-08-cran-reader-boundaries-codex-handover.md`
> plus AGENTS.md. Highest proven rung is exact current-main `0.6.0`
> `tarball-clean` at SHA `2e5234bd…`. First ask Shinichi whether to authorize
> the real `0.7.0` candidate and later writing `platform-clean`. Do not inherit
> predecessor platform evidence, change DESCRIPTION, finalize
> `cran-comments.md`, fire D-43, or upload without the corresponding explicit
> authorization. Preserve #858, #937, #947 and the dirty primary checkout.
