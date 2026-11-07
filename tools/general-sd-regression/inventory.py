#!/usr/bin/env python3
"""Build a pinned, source-backed inventory for general random-effect SD work.

The inventory deliberately reports axis marginals and explicit source routes;
it does not manufacture a compatible family x endpoint x provider crossproduct.
All repository contents are read with ``git show <resolved-sha>:<path>`` so a
dirty checkout (notably the paired DRM.jl checkout) cannot silently alter the
receipt.
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import io
import json
import re
import subprocess
from pathlib import Path
from typing import Any


GIT = "/Library/Developer/CommandLineTools/usr/bin/git"
LEDGER = "docs/dev-log/dashboard/capability-ledger/cells.tsv"
JULIA_REGISTRY = "R/julia-family-registry.R"
SCALE_FORMULAS = "R/random-effect-scale-formulas.R"
DRMTMB_SOURCE = "R/drmTMB.R"
BRIDGE_SOURCE = "R/julia-bridge.R"
FORMULA_DOC = "docs/design/01-formula-grammar.md"
NATIVE_BASE_PIN = "d89db50975d96d9c2bcb13046453ae34c7fcf49b"
JULIA_BASE_PIN = "b1832c7a686decf4e3d7a06ad8382bf164b9d8d4"


def git(repo: Path, *args: str) -> str:
    result = subprocess.run(
        [GIT, "-C", str(repo), *args],
        check=True,
        text=True,
        capture_output=True,
    )
    return result.stdout.strip()


def resolve_pin(repo: Path, revision: str) -> str:
    return git(repo, "rev-parse", "--verify", f"{revision}^{{commit}}")


def read_pinned(repo: Path, sha: str, path: str) -> str:
    return git(repo, "show", f"{sha}:{path}")


def parse_tsv(source: str) -> list[dict[str, str]]:
    return list(csv.DictReader(io.StringIO(source), delimiter="\t"))


def parse_julia_registry(source: str) -> list[dict[str, Any]]:
    """Read the registry's one-row-per-family declarations, failing closed."""
    rows: list[dict[str, Any]] = []
    pattern = re.compile(r'spec\("([a-z0-9_]+)"\s*,\s*predictor_dpars\s*=\s*([^,\n]+(?:\([^\n]*?\))?)')
    for match in pattern.finditer(source):
        family, predictor_expr = match.groups()
        row_start = match.start()
        row_end = source.find("\n    spec(", match.end())
        if row_end < 0:
            row_end = len(source)
        block = source[row_start:row_end]
        predictor_match = re.search(
            r'predictor_dpars\s*=\s*("\*"|c\([^\n]*\))', block
        )
        if predictor_match:
            predictor_expr = predictor_match.group(1)
        rows.append(
            {
                "family": family,
                "predictor_dpars": "*" if '"*"' in predictor_expr else sorted(set(re.findall(r'"([a-z0-9_]+)"', predictor_expr))),
                "flags": {
                    flag: bool(re.search(rf"\b{flag}\s*=\s*TRUE", block))
                    for flag in (
                        "fe",
                        "phylo_only",
                        "locscale_phylo",
                        "slope_phylo",
                        "dispersionless",
                        "structured",
                    )
                },
            }
        )
    if not rows:
        raise ValueError("Julia family registry contained no parseable family rows")
    families = [row["family"] for row in rows]
    if len(families) != len(set(families)):
        raise ValueError("Julia family registry has duplicate family rows")
    return rows


def axis_values(rows: list[dict[str, str]], key: str) -> list[str]:
    return sorted({row[key] for row in rows if row.get(key) and row[key] != "na"})


def count_axis(rows: list[dict[str, str]], key: str) -> dict[str, int]:
    out: dict[str, int] = {}
    for value in axis_values(rows, key):
        out[value] = sum(row.get(key) == value for row in rows)
    return out


def registry_family_coverage(
    family_routes: list[str], registry_families: set[str], aliases: dict[str, str] | None = None
) -> list[dict[str, str | None]]:
    """Keep unmatched families explicit for follow-up structural review."""
    aliases = aliases or {}
    return [
        {
            "family_route": family,
            "status": "structural_reviewed" if aliases.get(family, family) in registry_families else "required",
            "registry_family": aliases.get(family, family) if aliases.get(family, family) in registry_families else None,
        }
        for family in sorted(set(family_routes))
    ]


def parse_family_builders(source: str) -> list[dict[str, str]]:
    """Extract the native model-type to family-builder dispatch table."""
    start = source.find("spec <- switch(")
    if start < 0:
        raise ValueError("Native family builder switch was not found")
    end = source.find("\n  )\n\n  # check_drm", start)
    if end < 0:
        raise ValueError("Native family builder switch could not be bounded")
    block = source[start:end]
    rows = [
        {"family_type": family, "builder": builder}
        for family, builder in re.findall(
            r"(?m)^\s{4}([a-z0-9_]+)\s*=\s*(drm_build_[a-z0-9_]+_spec)\(",
            block,
        )
    ]
    if not rows:
        raise ValueError("Native family builder switch contained no rows")
    return rows


def source_ref(path: str, text: str, needle: str) -> dict[str, str]:
    lines = text.splitlines()
    for number, line in enumerate(lines, 1):
        if needle in line:
            return {"path": path, "line": str(number), "evidence": line.strip()}
    raise ValueError(f"Expected source evidence not found: {path}: {needle}")


def unverified_native_changes(repo: Path, baseline: str) -> dict[str, Any]:
    """Hash candidate working-tree files separately from the pinned inventory."""
    changed = set(filter(None, git(repo, "diff", "--name-only").splitlines()))
    untracked = set(filter(None, git(repo, "ls-files", "--others", "--exclude-standard").splitlines()))
    candidates = {
        "R/drmTMB.R", "src/drmTMB.cpp",
        "tests/testthat/helper-binomial-sd-regression.R",
        "tests/testthat/test-binomial-random-effect-scale.R",
        "tests/testthat/test-binomial-sd-integration.R",
    }
    files = []
    for path in sorted((changed | untracked) & candidates):
        data = (repo / path).read_bytes()
        files.append({"path": path, "sha256": hashlib.sha256(data).hexdigest(),
                      "worktree_state": "untracked" if path in untracked else "modified"})
    return {
        "status": "unverified_worktree_changes",
        "baseline_commit": baseline,
        "candidate": "binomial mu direct-SD predictor path, including sd(Subject) ~ urbanization integration tests",
        "files": files,
        "excluded_from_pinned_counts": True,
        "note": "Hashes identify the current candidate only; this is not source review, test evidence, or a supported-capability claim.",
    }


def inspect_inventory(
    native_repo: Path,
    native_revision: str,
    julia_repo: Path,
    julia_revision: str,
) -> dict[str, Any]:
    native_sha = resolve_pin(native_repo, native_revision)
    julia_sha = resolve_pin(julia_repo, julia_revision)
    ledger_text = read_pinned(native_repo, native_sha, LEDGER)
    ledger_rows = parse_tsv(ledger_text)
    surface = [row for row in ledger_rows if row["axis"] == "model_surface"]
    if not surface:
        raise ValueError(f"No model_surface rows in {LEDGER}")

    registry_text = read_pinned(native_repo, native_sha, JULIA_REGISTRY)
    registry = parse_julia_registry(registry_text)
    scale_text = read_pinned(native_repo, native_sha, SCALE_FORMULAS)
    native_text = read_pinned(native_repo, native_sha, DRMTMB_SOURCE)
    bridge_text = read_pinned(native_repo, native_sha, BRIDGE_SOURCE)
    formula_text = read_pinned(native_repo, native_sha, FORMULA_DOC)
    julia_lss_path = "src/gaussian_lss.jl"
    julia_lss_text = read_pinned(julia_repo, julia_sha, julia_lss_path)
    native_builders = parse_family_builders(native_text)

    # A source-backed, deliberately partial set of direct-SD routes. These
    # labels are exact lanes found in the public grammar and family builders.
    direct_routes = [
        {
            "engine": "tmb",
            "family": "gaussian",
            "endpoint": "mu",
            "provider": "iid",
            "effect": "random_intercept",
            "block": "q1",
            "status": "structural_reviewed",
            "source": source_ref(DRMTMB_SOURCE, native_text, "sd_mu_targets <- parse_sd_mu_entries(sd_mu_entries, mu_re$terms)"),
        },
        {
            "engine": "tmb",
            "family": "gaussian",
            "endpoint": "mu",
            "provider": "phylo",
            "effect": "structured_intercept",
            "block": "q1",
            "status": "structural_reviewed",
            "source": source_ref(SCALE_FORMULAS, scale_text, "sd(group, level = \"phylogenetic\") ~ predictors"),
        },
        {
            "engine": "tmb",
            "family": "beta",
            "endpoint": "mu",
            "provider": "phylo",
            "effect": "structured_intercept",
            "block": "q1",
            "status": "structural_reviewed",
            "source": source_ref(DRMTMB_SOURCE, native_text, "ordinary group-level scale models need separate recovery tests"),
        },
        {
            "engine": "tmb",
            "family": "biv_gaussian",
            "endpoint": "mu1/mu2",
            "provider": "iid or phylo",
            "effect": "random_intercept",
            "block": "q1 per endpoint",
            "status": "structural_reviewed",
            "source": source_ref(SCALE_FORMULAS, scale_text, "`sd1(group) ~ predictors` and `sd2(group) ~ predictors`"),
        },
        {
            "engine": "julia",
            "family": "gaussian",
            "endpoint": "mu",
            "provider": "iid",
            "effect": "random_intercept",
            "block": "q1 LSS; multiple iid components also route through LSS",
            "status": "structural_reviewed",
            "source": source_ref(julia_lss_path, julia_lss_text, "Plain `sd(g)` targets the iid `(1 | g)` intercept"),
        },
        {
            "engine": "julia",
            "family": "gaussian",
            "endpoint": "mu",
            "provider": "phylo",
            "effect": "structured_intercept",
            "block": "q1 LSS; may combine with iid components",
            "status": "structural_reviewed",
            "source": source_ref(julia_lss_path, julia_lss_text, "sd_phylo(species) ~ x"),
        },
        {
            "engine": "julia",
            "family": "gaussian",
            "endpoint": "mu",
            "provider": "multiple iid and/or phylo components",
            "effect": "random_intercepts",
            "block": "multi-component LSS",
            "status": "structural_reviewed",
            "source": source_ref(julia_lss_path, julia_lss_text, "**Multi-component models**"),
        },
    ]

    # Explicit family-level refusal strings in native family builders. These
    # are missing SD-regression routes, not all possible compatible cells.
    gate_phrases = (
        "Random-effect scale formulae are not implemented for",
        "Random-effect scale formulae are not implemented for binomial",
    )
    family_gates: list[dict[str, str]] = []
    seen: set[str] = set()
    native_lines = native_text.splitlines()
    for line_no, line in enumerate(native_lines, 1):
        if any(phrase in line for phrase in gate_phrases):
            family_match = re.search(r"for \{\.fn ([^}]+)\}|for (binomial|Poisson)", line)
            family = next((value for value in family_match.groups() if value), "unspecified") if family_match else "unspecified"
            family = {"Gamma": "gamma", "Poisson": "poisson"}.get(family, family)
            context = " ".join(native_lines[line_no - 1 : min(line_no + 1, len(native_lines))]).strip()
            key = (family, line.strip())
            if str(key) not in seen:
                seen.add(str(key))
                family_gates.append(
                    {
                        "family": family,
                        "scope": "ordinary/group-level direct SD formula; check adjacent code context for exceptions",
                        "status": "missing",
                        "source": f"{DRMTMB_SOURCE}:{line_no}",
                        "message": line.strip(),
                        "context": context,
                    }
                )

    model_families = axis_values(surface, "family_route")
    builder_families = [row["family_type"] for row in native_builders]
    registry_families = {row["family"] for row in registry}
    family_aliases = {
        "hurdle_nbinom2": "truncated_nbinom2",
        "zi_nbinom2": "nbinom2",
        "zi_poisson": "poisson",
    }
    registry_coverage = registry_family_coverage(
        sorted(set(model_families) | set(builder_families)),
        registry_families,
        aliases=family_aliases,
    )
    direct_native_families = {
        row["family"] for row in direct_routes if row["engine"] == "tmb"
    }
    gated_families = {row["family"] for row in family_gates}
    family_sd_review = []
    all_native_families = sorted(set(model_families) | set(builder_families))
    for family in all_native_families:
        family_gate_route = family_aliases.get(family, family)
        if family in direct_native_families:
            status = "structural_reviewed"
        elif family_gate_route in gated_families:
            status = "missing"
        else:
            status = "required"
        family_sd_review.append(
            {
                "family_route": family,
                "status": status,
                "scope_note": (
                    "At least one exact direct-SD route is found; this does not imply all endpoints/providers/effects."
                    if status == "structural_reviewed"
                    else "Explicit native family-builder SD refusal found; inspect route-specific exceptions."
                    if status == "missing"
                    else "No route-level direct-SD conclusion generated; manual source classification remains required."
                ),
            }
        )

    # Ensure the report is anchored to specific source text, not just filenames.
    direct_gate = source_ref(DRMTMB_SOURCE, native_text, "Random-effect scale formulae are not implemented for {.fn student} models yet.")
    julia_lss = source_ref(julia_lss_path, julia_lss_text, "function _drm_gaussian_lss_multi")

    return {
        "schema_version": 1,
        "pins": {
            "drmTMB": {"commit": native_sha, "requested_revision": native_revision},
            "DRM.jl": {"commit": julia_sha, "requested_revision": julia_revision, "checkout_read_mode": "git show only; worktree files not read"},
        },
        "provenance": {
            "native_ledger": {"path": LEDGER, "sha256": hashlib.sha256(ledger_text.encode()).hexdigest(), "rows": len(ledger_rows)},
            "julia_registry": {"path": JULIA_REGISTRY, "family_rows": len(registry)},
            "sources": [LEDGER, JULIA_REGISTRY, SCALE_FORMULAS, DRMTMB_SOURCE, BRIDGE_SOURCE, FORMULA_DOC, "src/gaussian_lss.jl"],
        },
        "native_model_surface": {
            "rows": len(surface),
            "ledger_rows": [
                {
                    key: row.get(key, "")
                    for key in (
                        "cell_id", "family_route", "family_type", "route_variant",
                        "route_modifier", "dpar", "effect_type", "structure_provider",
                        "dimension", "q_gate", "estimator", "capability_status",
                        "work_status", "evidence_tier", "test_gate", "primary_evidence_id",
                        "updated_commit",
                    )
                }
                for row in surface
            ],
            "axes": {
                key: {"values": axis_values(surface, key), "row_counts": count_axis(surface, key)}
                for key in ("family_route", "dpar", "effect_type", "structure_provider", "dimension", "q_gate", "estimator", "capability_status", "work_status")
            },
            "warning": "Marginal axis values are not a compatible crossproduct; original ledger rows are the evidence units.",
        },
        "native_distribution_builders": native_builders,
        "native_family_route_aliases": family_aliases,
        "julia_family_registry": registry,
        "registry_family_coverage": registry_coverage,
        "direct_sd_routes": direct_routes,
        "family_level_native_sd_gates": family_gates,
        "native_family_sd_review": family_sd_review,
        "structural_review": {
            "status": "structural_reviewed",
            "direct_sd_entry_parser": source_ref(DRMTMB_SOURCE, native_text, "parse_sd_mu_entry <- function(entry, mu_terms)"),
            "julia_formula_shape_gate": source_ref(BRIDGE_SOURCE, bridge_text, "is_lss <- grepl(\"^sd(_phylo)?\\\\([^()]+\\\\)$\""),
            "julia_lss_module": julia_lss,
            "scale_formula_docs": source_ref(SCALE_FORMULAS, scale_text, "Non-Gaussian"),
            "limits": [
                "No full family x endpoint x provider x effect x block x engine crossproduct is inferred.",
                "Unmatched Julia registry routes remain required inventory work; absence from a registry is not proof of structural incompatibility.",
                "Endpoint-specific covariance, slopes, crossed/nested terms, temporal effects, and provider interactions require per-cell structural review.",
            ],
        },
        "unverified_native_worktree_candidate": unverified_native_changes(native_repo, native_sha),
    }


def render_markdown(inventory: dict[str, Any]) -> str:
    native = inventory["native_model_surface"]
    lines = [
        "# General random-effect SD inventory",
        "",
        f"Pinned drmTMB `{inventory['pins']['drmTMB']['commit']}` and DRM.jl `{inventory['pins']['DRM.jl']['commit']}`.",
        "The paired DRM.jl source was read through `git show` at its recorded commit; dirty or untracked checkout files were not read.",
        "",
        "This is a reproducible source inventory, not a complete Cartesian product. Marginal family, endpoint, provider, effect, dimension, q, and estimator lists do not imply all combinations are supported.",
        "",
        f"The native capability ledger contains {inventory['provenance']['native_ledger']['rows']} rows ({native['rows']} on `model_surface`) and {len(native['axes']['family_route']['values'])} represented family routes. The native family dispatcher contains {len(inventory['native_distribution_builders'])} builders.",
        f"The Julia family registry contains {len(inventory['julia_family_registry'])} rows; {sum(row['status'] == 'required' for row in inventory['registry_family_coverage'])} native builder/ledger family names lack a Julia-registry mapping after aliases. This mapping count does not measure direct-SD support.",
        f"Native family-level direct-SD review status: {sum(row['status'] == 'structural_reviewed' for row in inventory['native_family_sd_review'])} has at least one explicit route, {sum(row['status'] == 'missing' for row in inventory['native_family_sd_review'])} has an explicit family-builder refusal, and {sum(row['status'] == 'required' for row in inventory['native_family_sd_review'])} remain unclassified.",
        "",
        "## Direct SD routes found",
        "",
        "| Engine | Family | Endpoint | Provider/effect | Block | Status | Evidence |",
        "|---|---|---|---|---|---|---|",
    ]
    for row in inventory["direct_sd_routes"]:
        src = row["source"]
        lines.append(
            f"| {row['engine']} | {row['family']} | {row['endpoint']} | {row['provider']} / {row['effect']} | {row['block']} | {row['status']} | `{src['path']}:{src['line']}` |"
        )
    lines += [
        "",
        "## Status meanings",
        "",
        "`structural_reviewed` means the pinned source path or explicit formula declaration was inspected. It does not mean simulation recovery, interval calibration, inference readiness, or all sibling cells passed.",
        "`missing` means a pinned native family builder has an explicit SD-formula refusal (with route-specific exceptions retained in adjacent source context). `required` means the family route lacks a direct-SD classification or a Julia registry mapping; it remains unresolved rather than assumed unsupported.",
        "",
        "## Known scope boundary",
        "",
        "The generated output retains every ledger row and registry family list as source data. It does not turn the marginal axes into a full crossproduct. Endpoint-specific covariance blocks, random slopes, crossed/nested effects, temporal structures, provider interactions, and engine parity need explicit per-cell source review before a route can be marked supported or missing.",
        "",
        f"Native family builders with explicit SD-formula refusal text found: {len(inventory['family_level_native_sd_gates'])}. See the JSON for each source line.",
        f"Current native checkout candidate: `{inventory['unverified_native_worktree_candidate']['status']}`; its hashes are separate from both pinned baselines and do not alter capability counts.",
        "",
    ]
    return "\n".join(lines)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--native-repo", type=Path, default=Path(__file__).resolve().parents[2])
    parser.add_argument("--native-revision", default=NATIVE_BASE_PIN)
    parser.add_argument("--julia-repo", type=Path, required=True)
    parser.add_argument("--julia-revision", default=JULIA_BASE_PIN)
    parser.add_argument("--output-dir", type=Path, required=True)
    args = parser.parse_args()
    inventory = inspect_inventory(
        args.native_repo,
        args.native_revision,
        args.julia_repo,
        args.julia_revision,
    )
    args.output_dir.mkdir(parents=True, exist_ok=True)
    (args.output_dir / "inventory.json").write_text(
        json.dumps(inventory, indent=2, sort_keys=True) + "\n", encoding="utf-8"
    )
    (args.output_dir / "inventory.md").write_text(render_markdown(inventory), encoding="utf-8")
    print(
        f"Wrote {args.output_dir}/inventory.json and inventory.md; "
        f"native model_surface={inventory['native_model_surface']['rows']}, "
        f"families={len(inventory['native_model_surface']['axes']['family_route']['values'])}, "
        f"Julia registry={len(inventory['julia_family_registry'])}, "
        f"unmatched={sum(row['status'] == 'required' for row in inventory['registry_family_coverage'])}"
    )


if __name__ == "__main__":
    main()
