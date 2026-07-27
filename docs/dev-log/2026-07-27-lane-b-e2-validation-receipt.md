# Lane B E2 validation receipt

## Mechanical census check

The three E2 source-card TSVs were read together and checked against the E0
inventory derived from `binding_status == "needs_exact_binding"`.

| Check | Result |
| --- | --- |
| Source-card rows | 97 |
| Distinct source-card IDs | 97 |
| Exact equality with current unresolved ID set | pass |
| Shared card schema | 18 columns in each file |
| `source_found_field_missing` | 85 |
| `source_found_not_direct` | 12 |
| `source_fields_complete_pending_review` / `candidate_review` | 0 / 0 |

The check rejects duplicate, omitted, or out-of-cohort IDs, unknown
availability states, and any candidate-review disposition.

## E0 invariant

```text
Lane-B E0 readiness verified: 158 target cells; 62 recovered targets;
2 retained negative targets; 97 unresolved cells;
pregrid_authorized=FALSE.
```

This verifier does not read E2 source cards.  The separate mechanical census
check above is therefore the evidence for the E2 union; the verifier confirms
that E2 did not alter E0 readiness state.

## Changed-file audit

`git status --short`, `git diff --check`, and a path audit were run after the
E2 documentation writes.  The intended changes are only E2 files under
`docs/dev-log/`; no canonical binding TSV, package/test code, ledger,
configuration, schedule, smoke receipt, public document, or foreign-lane file
is in scope.

## Routing receipt

The planned Luna mechanical-verification job was launched through
`codex-tier-run.sh` with the catalog-confirmed `gpt-5.6-luna` model, medium
effort, read-only sandbox, and fresh ephemeral context.  It failed before the
agent started because the sandbox could not write
`~/.codex/state_5.sqlite`; its retained dispatch manifest is
`/private/tmp/e2-luna-mechanical-verify-events.dispatch.txt`.  The manifest
records `status=1`, rather than falsely reporting a Luna result.  The explicit
R census comparison above is the completed mechanical verification.

## Result

The packet passes its no-compute and no-binding checks.  It does not authorize
a binding edit, smoke, schedule, pregrid, or compute request.
