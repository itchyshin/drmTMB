"""Shared neighbour-row guard for the B4-CI cohort integrations (C1-C4).

Each cohort script freezes a ``BASE_COMMIT`` and asserts that ledger rows OUTSIDE
its own allowlist are unchanged. The claim that matters is *"cohort Cn's
``--apply`` did not touch its neighbours"*, and that claim is true forever.

Byte-equality against ``BASE_COMMIT`` asserts something strictly stronger --
*"no LATER arc touched them either"* -- which no reviewer ever agreed to and
which decays the moment any approved arc lands. It decayed on 2026-08-03: four
neighbours had moved under three separately reviewed arcs (mc-0207 by Arc 4b's
q4/q6/q8 split, mc-0269 by the Arc 1 REML-slope promotion, mc-0199 and mc-0672
by the spatial-q2 confidence-eye work). All four were legitimate; the guards
were nonetheless red, and because nothing ran them the redness went unnoticed
while the evidence record still credited them.

This module keeps the real claim and replaces the time-coupled one with two
checks that together are *stronger* than byte-equality was:

1. **Identity is frozen forever.** The fields that say *which cell this is*
   (:data:`IDENTITY_FIELDS`) may never change for a neighbour. A hand-edited
   ``source_order``, a retyped ``dpar``, a swapped ``family_route`` still fails,
   exactly as before.
2. **Evidence-bearing fields may move, but only with recorded provenance.** A
   neighbour's tier, work status, claim boundary and so on may differ from the
   frozen base only when the append-only transitions ledger contains a
   transition -- belonging to some OTHER cohort -- that names the evidence the
   row's ``primary_evidence_id`` now points at.

So an unexplained edit still fails, a deleted row still fails, and a cohort
quietly claiming a neighbour it never had permission to promote fails *louder*
than before: byte-equality could only say "this differs", whereas the
provenance rule names it as an unauthorised claim.
"""

from __future__ import annotations

import hashlib
import json

#: Fields that identify a cell. A neighbour may never change these, whatever
#: arc touches it. Everything not listed here is evidence-bearing and may move
#: with recorded provenance.
IDENTITY_FIELDS = (
    "cell_id",
    "source_order",
    "axis",
    "family_route",
    "family_type",
    "model_type",
    "dpar",
    "effect_type",
    "structure_provider",
    "dimension",
    "estimator",
)


def identity_projection(row: dict[str, str]) -> dict[str, str]:
    """The immutable identity of one ledger row."""
    return {field: row.get(field, "") for field in IDENTITY_FIELDS}


def identity_digest(rows: list[dict[str, str]]) -> str:
    """Digest of the identity projection of ``rows``, in the order given.

    Used by cohorts whose CI-facing check must not reach into git history: it
    pins identity without pinning the evidence-bearing fields that later arcs
    legitimately move.
    """
    return hashlib.sha256(
        json.dumps([identity_projection(row) for row in rows], sort_keys=True, separators=(",", ":")).encode()
    ).hexdigest()


def _evidence_ids(transition: dict[str, str]) -> set[str]:
    return {part.strip() for part in transition.get("evidence_ids", "").split(";") if part.strip()}


def unexplained_drift(
    *,
    protected_ids,
    base_cells: dict[str, dict[str, str]],
    local_cells: dict[str, dict[str, str]],
    transitions: list[dict[str, str]],
    cohort_evidence_ids: set[str] = frozenset(),
    cohort_transition_ids: set[str] = frozenset(),
) -> list[tuple[str, str]]:
    """Return ``[(cell_id, reason)]`` for neighbour rows whose drift is not accounted for.

    ``base_cells`` is the cohort's frozen view (typically read from its
    ``BASE_COMMIT``); ``local_cells`` is the working ledger. A cell absent from
    ``base_cells`` is ignored -- it was created after the cohort froze and was
    never that cohort's to protect.
    """
    by_cell: dict[str, list[dict[str, str]]] = {}
    for transition in transitions:
        by_cell.setdefault(transition.get("cell_id", ""), []).append(transition)

    problems: list[tuple[str, str]] = []
    for cell_id in sorted(protected_ids):
        base = base_cells.get(cell_id)
        local = local_cells.get(cell_id)
        if base is None:
            continue
        if local is None:
            problems.append((cell_id, "row is absent from the local ledger"))
            continue
        if local == base:
            continue

        changed = sorted(field for field in set(base) | set(local) if base.get(field) != local.get(field))
        identity_changed = [field for field in changed if field in IDENTITY_FIELDS]
        if identity_changed:
            problems.append((cell_id, f"identity fields changed: {', '.join(identity_changed)}"))
            continue

        primary = local.get("primary_evidence_id", "")
        if primary in cohort_evidence_ids:
            problems.append((
                cell_id,
                f"this cohort claims it via {primary}; a cohort must not promote a row outside its own allowlist",
            ))
            continue

        accounted = any(
            primary and primary in _evidence_ids(transition)
            and transition.get("transition_id") not in cohort_transition_ids
            for transition in by_cell.get(cell_id, [])
        )
        if not accounted:
            problems.append((
                cell_id,
                f"changed ({', '.join(changed)}) with no recorded transition accounting for "
                f"primary_evidence_id={primary!r}",
            ))
    return problems


def unaccounted_provenance(
    *,
    cell_ids,
    local_cells: dict[str, dict[str, str]],
    transitions: list[dict[str, str]],
    cohort_transition_ids: set[str] = frozenset(),
) -> list[tuple[str, str]]:
    """Provenance check for cohorts whose CI path must not read git history.

    Same rule as :func:`unexplained_drift`, minus the base comparison: every named
    row's current ``primary_evidence_id`` must be named by a transition for that
    cell that does not belong to this cohort. Pair it with
    :func:`identity_digest` -- identity is pinned by the digest, provenance by
    this -- so the two together need no ``BASE_COMMIT`` lookup.
    """
    by_cell: dict[str, list[dict[str, str]]] = {}
    for transition in transitions:
        by_cell.setdefault(transition.get("cell_id", ""), []).append(transition)

    problems: list[tuple[str, str]] = []
    for cell_id in sorted(cell_ids):
        local = local_cells.get(cell_id)
        if local is None:
            problems.append((cell_id, "row is absent from the local ledger"))
            continue
        primary = local.get("primary_evidence_id", "")
        if not primary:
            problems.append((cell_id, "row has no primary_evidence_id"))
            continue
        accounted = any(
            primary in _evidence_ids(transition)
            and transition.get("transition_id") not in cohort_transition_ids
            for transition in by_cell.get(cell_id, [])
        )
        if not accounted:
            problems.append((cell_id, f"no recorded transition accounts for primary_evidence_id={primary!r}"))
    return problems


def describe(problems: list[tuple[str, str]], limit: int = 4) -> str:
    """One-line rendering of ``unexplained_drift`` output for a failure message."""
    shown = "; ".join(f"{cell_id}: {reason}" for cell_id, reason in problems[:limit])
    if len(problems) > limit:
        shown += f"; (+{len(problems) - limit} more)"
    return shown
