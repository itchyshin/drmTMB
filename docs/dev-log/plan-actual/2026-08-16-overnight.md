# Plan vs actual — overnight run (Melissa)

**Lane:** `claude/lane-overnight-0815` · 2026-08-15/16 · **Plan:** the A1–A7 night plan stated to the
owner at hand-off, under the rules "Mac CPU minimal · reversible freely · merge only ledger/docs-grade
on green · `mc-0596` and the 44-cell decision stay Shinichi's".

## Verdict

All seven arcs ran. Six closed; one (A2) deliberately stopped at facts, as promised. **No drift
charged.** Two adaptive deviations and one self-caught error class.

| Axis | Actual vs plan | Tag |
| --- | --- | --- |
| Scope | A1–A7 all attempted; A2 stopped at a facts document by design | none |
| Scope | +1 unplanned: attempted the "cheap half" of the 44-cell fix, then reverted it | **adaptive** — a legitimate probe that found a real coupling; reverting was the finding |
| Evidence | A3 exceeded plan: expected partial truth recovery, got 31/31 and a full location check | **adaptive** |
| Evidence | A5/A6 both *overturned my own prior claims* rather than confirming them | **adaptive** — and the more useful outcome |
| Routing | 6 cloud agents (4 archaeology + truth recovery + staleness), conductor did the ledger/render work | none — matches the CPU constraint |
| Safety gates | no merge; no push yet; B4-CI re-frozen only under field-level proof (3rd time); 3 single fits were the entire compute spend; orphaned PSOCK workers killed after each R run | none |
| Claims | 44-cell disposition and `mc-0596` left to the owner, exactly as scoped | none |
| Handoff | after-task PASS, this file, check-log, LOOP checkpoint current | none |

## The one thing worth escalating

**I introduced two citation errors earlier in the day** (an over-reaching range extension and an
off-by-one) and they were caught only because independent agents re-read the same cells tonight. Both
came from one mechanical line-shift across cited ranges. Routed to Rose: a shift that moves cited line
ranges should be verified by re-reading the *content* at the new range, not by arithmetic alone.

## Process note

The night's most productive move was applying the day's own lesson deliberately — "a blank field is
not evidence of absence" — which turned 31 supposedly-unrecoverable cells into 31 verdicts at zero
compute cost. The lesson had been written down that morning; using it as a *search strategy* rather
than a caution is what paid.
