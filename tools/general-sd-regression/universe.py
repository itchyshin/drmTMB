#!/usr/bin/env python3
"""Expand the pinned SD-regression denominator without claiming admission."""

from __future__ import annotations

import argparse
import csv
import itertools
import json
from collections import Counter
from pathlib import Path
from typing import Iterable


ROOT = Path(__file__).resolve().parents[2]
INPUT_DIR = ROOT / "docs/dev-log/general-sd-regression"
ENDPOINTS_PATH = INPUT_DIR / "family-endpoints.tsv"
MECHANISMS_PATH = INPUT_DIR / "mechanism-templates.tsv"
LINKS_PATH = INPUT_DIR / "family-links.tsv"
BLOCK_RULES_PATH = INPUT_DIR / "block-rules.tsv"
OUTPUT_PATH = INPUT_DIR / "required-rows.tsv"
SUMMARY_PATH = INPUT_DIR / "required-universe.md"
ENGINES = ("native", "Julia")
EXPECTED_ENDPOINTS = 54
EXPECTED_MECHANISMS = 25
EXPECTED_BLOCK_RULE_ROWS = 148
EXPECTED_BLOCK_RULE_IDS = {
    "J-biv-structured2", "J-biv-structured4-tagged-partitions", "J-biv-structured4-untagged",
    "O-biv-all4-I", "O-biv-all4-q8", "O-biv-mean-m", "O-biv-mean-m-q4-anchor",
    "O-biv-mean-m-q6-anchor", "O-biv-mean2-I", "O-biv-mean2-x", "O-biv-scale2-I",
    "O-biv-scale2-x", "O-cross-LS-I", "O-cross-LS-x", "O-multi-within",
    "O-multi-within-q3-anchor", "O2-within", "S-biv-all4-I",
    "S-biv-all4-blockdiag-mu", "S-biv-all4-blockdiag-sigma", "S-biv-all4-m",
    "S-biv-all4-m-q12-anchor", "S-biv-all4-m-q8-anchor", "S-biv-mean-I",
    "S-biv-mean-m", "S-biv-mean-m-q4-anchor", "S-biv-mean-m-q6-anchor",
    "S-biv-mean-x", "S-biv-scale-I", "S-uni-LS-I",
}
CROSS_ENDPOINT_BLOCKS = (
    "iid_labelled_cross_parameter", "phylo_labelled_block",
    "animal_labelled_block", "relmat_labelled_block",
    "spatial_coordinate_labelled_block",
)
# Canonical response/location link for every pinned family route. For ordinary
# base families this is the only admitted response-link variant; constructors
# can still specify distinct internal links for other dpars. Binomial is the
# explicit multi-link exception.
FAMILY_LINKS = {
    "gaussian": {"identity"}, "student": {"identity"},
    "skew_normal": {"identity"}, "lognormal": {"identity"},
    "gamma": {"log"}, "tweedie": {"log"}, "beta": {"logit"},
    "zero_one_beta": {"logit"}, "beta_binomial": {"logit"},
    "binomial": {"logit"}, "cumulative_logit": {"identity"},
    "poisson": {"log"}, "zi_poisson": {"log"},
    "nbinom2": {"log"}, "zi_nbinom2": {"log"},
    "truncated_nbinom2": {"log"}, "hurdle_nbinom2": {"log"},
    "biv_gaussian": {"identity"}, "biv_lognormal": {"identity"},
    "biv_student": {"identity"},
}
EXPECTED_LINKS = {
    (engine, family): (
        {"logit", "probit", "cloglog"} if family == "binomial"
        else links
    )
    for engine in ENGINES for family, links in FAMILY_LINKS.items()
}
EXPECTED_LINK_STATUS = {
    (engine, family, link): (
        "blocked_base_link" if engine == "Julia" and family == "binomial" and link in {"probit", "cloglog"}
        else "admitted"
    )
    for (engine, family), variants in EXPECTED_LINKS.items()
    for link in variants
}
EXPECTED_LINK_ORIGIN = {
    key: ("native_admitted_link_missing_from_julia_base" if status == "blocked_base_link"
          else "engine_admitted_link")
    for key, status in EXPECTED_LINK_STATUS.items()
}

ROW_FIELDS = (
    "row_key", "engine", "family_route", "dimension", "endpoint",
    "endpoint_members", "target_member", "member_coefs", "link_variant",
    "mechanism_id", "block_rule_id", "provider", "effect_type",
    "provider_input", "layout", "block_shape", "q_domain", "q_value",
    "partition_rule", "status", "status_reason", "source_evidence",
    "direct_sd_claim", "base_link_status", "link_union_origin",
)
KEY_FIELDS = (
    "engine", "family_route", "dimension", "endpoint", "endpoint_members",
    "target_member", "member_coefs", "link_variant", "mechanism_id",
    "block_rule_id", "provider", "effect_type", "provider_input", "layout",
    "block_shape", "q_domain", "q_value", "partition_rule",
)

# Each list is a finite representation of an existing mechanism family. A q-
# general coefficient block is one template; predictor counts remain open.
INPUTS = {
    "iid_intercept": ["group_factor"],
    "iid_numeric_slope": ["group_factor"],
    "iid_correlated_block": ["group_factor"],
    "iid_additive_terms": ["group_factors"],
    "iid_labelled_cross_parameter": ["group_factor"],
    "phylo_intercept": ["tree", "phylo_covariance_matrix", "phylo_precision_matrix"],
    "phylo_numeric_slope": ["tree"],
    "phylo_labelled_block": ["tree"],
    "animal_intercept": ["pedigree", "A_covariance", "Ainv_precision"],
    "animal_numeric_slope": ["pedigree", "A_covariance", "Ainv_precision"],
    "animal_labelled_block": ["pedigree", "A_covariance", "Ainv_precision"],
    "relmat_intercept": ["K_covariance", "Q_precision"],
    "relmat_numeric_slope": ["K_covariance", "Q_precision"],
    "relmat_labelled_block": ["K_covariance", "Q_precision"],
    "spatial_coordinate_intercept": ["coordinates"],
    "spatial_coordinate_slope": ["coordinates", "mesh_precision"],
    "spatial_coordinate_labelled_block": ["coordinates", "mesh_precision"],
    "spatial_mesh_intercept": ["mesh_precision_fixed_kappa"],
    "phylo_interaction_intercept": ["tree_pair"],
    "temporal_ar1": ["integer_time_series"],
    "temporal_ou": ["elapsed_time_series"],
    "temporal_homtoep": ["complete_equal_panel"],
    "paired_phylo_temporal_ou": ["tree_plus_elapsed_time"],
}

LAYOUTS = {
    "iid_additive_terms": ("crossed", "nested"),
    "simultaneous_iid_structured": ("additive_independent_pair",),
    "simultaneous_structured_structured": ("additive_independent_pair",),
    "paired_phylo_temporal_ou": ("same_species_group_additive_pair",),
}

# These are the only provider pairs named by the pinned source union. Julia's
# structured fitter accepts phylo/animal/relmat pairs; native grammar names the
# phylo + coordinate-spatial pair. The Julia spatial refusal is retained.
PAIRS = {
    "simultaneous_iid_structured": (
        ("iid", "group_factor", "phylo", "tree"),
        ("iid", "group_factor", "animal", "pedigree"),
        ("iid", "group_factor", "animal", "A_covariance"),
        ("iid", "group_factor", "animal", "Ainv_precision"),
        ("iid", "group_factor", "relmat", "K_covariance"),
        ("iid", "group_factor", "relmat", "Q_precision"),
    ),
    "simultaneous_structured_structured": (
        ("phylo", "tree", "animal", "pedigree"),
        ("phylo", "tree", "animal", "A_covariance"),
        ("phylo", "tree", "animal", "Ainv_precision"),
        ("phylo", "tree", "relmat", "K_covariance"),
        ("phylo", "tree", "relmat", "Q_precision"),
        ("animal", "pedigree", "relmat", "K_covariance"),
        ("animal", "pedigree", "relmat", "Q_precision"),
        ("animal", "A_covariance", "relmat", "K_covariance"),
        ("animal", "A_covariance", "relmat", "Q_precision"),
        ("animal", "Ainv_precision", "relmat", "K_covariance"),
        ("animal", "Ainv_precision", "relmat", "Q_precision"),
        ("phylo", "tree", "spatial", "coordinates"),
    ),
}


def read_tsv(path: Path) -> list[dict[str, str]]:
    with path.open(encoding="utf-8", newline="") as handle:
        return list(csv.DictReader(handle, delimiter="\t"))


def write_tsv(path: Path, rows: list[dict[str, str]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=ROW_FIELDS, delimiter="\t", lineterminator="\n")
        writer.writeheader()
        writer.writerows(rows)


def check_inputs(
    endpoints: list[dict[str, str]],
    mechanisms: list[dict[str, str]],
    links: list[dict[str, str]],
    block_rules: list[dict[str, str]],
) -> None:
    if len(endpoints) != EXPECTED_ENDPOINTS:
        raise ValueError(f"expected {EXPECTED_ENDPOINTS} endpoint rows, found {len(endpoints)}")
    endpoint_keys = [
        (row["family_route"], row["dimension"], row["endpoint"])
        for row in endpoints
    ]
    if len(endpoint_keys) != len(set(endpoint_keys)):
        raise ValueError("duplicate family/dimension/endpoint source row")
    if len(mechanisms) != EXPECTED_MECHANISMS:
        raise ValueError(f"expected {EXPECTED_MECHANISMS} mechanism templates, found {len(mechanisms)}")
    mechanism_ids = [row["template_id"] for row in mechanisms]
    if len(mechanism_ids) != len(set(mechanism_ids)):
        raise ValueError("duplicate mechanism template id")
    unknown = set(mechanism_ids) - (set(INPUTS) | set(PAIRS))
    missing = (set(INPUTS) | set(PAIRS)) - set(mechanism_ids)
    if unknown or missing:
        raise ValueError(f"mechanism expansion map drift: unknown={sorted(unknown)}, missing={sorted(missing)}")
    link_map: dict[tuple[str, str], set[str]] = {}
    link_keys = [(r["engine"], r["family_route"], r["link_variant"]) for r in links]
    if len(link_keys) != len(set(link_keys)):
        raise ValueError("duplicate engine/family/link source row")
    for row in links:
        if not row.get("base_link_status", "").strip() or not row.get("union_origin", "").strip():
            raise ValueError("link registry row lacks base-link status or union origin")
        link_map.setdefault((row["engine"], row["family_route"]), set()).add(row["link_variant"])
    expected_link_keys = set(EXPECTED_LINKS)
    actual_link_keys = set(link_map)
    if actual_link_keys != expected_link_keys:
        raise ValueError(
            f"link registry family coverage mismatch: missing={sorted(expected_link_keys-actual_link_keys)}, "
            f"extra={sorted(actual_link_keys-expected_link_keys)}"
        )
    for key, expected in EXPECTED_LINKS.items():
        if link_map.get(key) != expected:
            raise ValueError(f"link registry coverage mismatch for {key}: expected {sorted(expected)}, got {sorted(link_map.get(key, set()))}")
    for row in links:
        key = (row["engine"], row["family_route"], row["link_variant"])
        if row["base_link_status"] != EXPECTED_LINK_STATUS.get(key):
            raise ValueError(f"base-link status mismatch for {key}: expected {EXPECTED_LINK_STATUS.get(key)}, got {row['base_link_status']}")
        if row["union_origin"] != EXPECTED_LINK_ORIGIN.get(key):
            raise ValueError(f"link union origin mismatch for {key}")
    if set(row["engine"] for row in links) != set(ENGINES):
        raise ValueError("link registry must retain both engines")
    if len(block_rules) != EXPECTED_BLOCK_RULE_ROWS:
        raise ValueError(f"expected {EXPECTED_BLOCK_RULE_ROWS} block-dimension rules, found {len(block_rules)}")
    rule_keys = [(r["rule_id"], r["engine"], r["mechanism_id"], r["member_dpars"], r["coef_rule"], r["q_domain"], r["q_value"], r["partition_rule"]) for r in block_rules]
    if len(rule_keys) != len(set(rule_keys)):
        raise ValueError("duplicate block-dimension rule")
    rule_ids = {r["rule_id"] for r in block_rules}
    if rule_ids != EXPECTED_BLOCK_RULE_IDS:
        raise ValueError(f"block-dimension rule-id coverage mismatch: missing={sorted(EXPECTED_BLOCK_RULE_IDS-rule_ids)}, extra={sorted(rule_ids-EXPECTED_BLOCK_RULE_IDS)}")
    if set(r["engine"] for r in block_rules) - set(ENGINES):
        raise ValueError("unknown engine in block-dimension rules")
    if any(not row.get("source_pin", "").strip() for row in block_rules):
        raise ValueError("block rule missing source provenance")
    if any(r["q_domain"] == "symbolic" and not r["member_dpars"] for r in block_rules):
        raise ValueError("symbolic q rule lacks endpoint members")
    families = {row["family_route"] for row in endpoints}
    if len(families) != 20 or families != set(FAMILY_LINKS):
        raise ValueError(f"family/link route mismatch: expected {sorted(FAMILY_LINKS)}, got {sorted(families)}")


def links_for(engine: str, family: str, links: list[dict[str, str]]) -> list[str]:
    found = sorted({r["link_variant"] for r in links if r["engine"] == engine and r["family_route"] == family})
    if not found:
        raise ValueError(f"missing explicit link variant for {(engine, family)}")
    return found


def scalar_text(value: object) -> str:
    return str(value) if value is not None else ""


def row_key(row: dict[str, str]) -> str:
    return json.dumps([row[name] for name in KEY_FIELDS], ensure_ascii=False, separators=(",", ":"))


def pair_variants(template_id: str) -> Iterable[tuple[str, str]]:
    for pair in PAIRS[template_id]:
        if template_id == "simultaneous_iid_structured":
            iid_provider, iid_input, other_provider, other_input = pair
            yield f"{iid_provider}:{iid_input}+{other_provider}:{other_input}", "additive_independent_pair"
        else:
            provider1, input1, provider2, input2 = pair
            yield f"{provider1}:{input1}+{provider2}:{input2}", "additive_independent_pair"


def _set_partitions(items: tuple[str, ...]):
    """Yield canonical set partitions in deterministic order."""
    if not items:
        yield ()
        return
    first, *rest = items
    for partition in _set_partitions(tuple(rest)):
        yield ((first,),) + partition
        for i in range(len(partition)):
            yield partition[:i] + ((first,) + partition[i],) + partition[i + 1:]


def _rule_instances(rule: dict[str, str], family_endpoints: list[str]):
    members = tuple(rule["member_dpars"].split(",")) if rule["member_dpars"] != "*" else ()
    if not members:
        members = ("__CURRENT_ENDPOINT__",)
    if any(m not in family_endpoints and m != "__CURRENT_ENDPOINT__" for m in members):
        return []
    if members == ("__CURRENT_ENDPOINT__",):
        target_endpoints = family_endpoints
    else:
        target_endpoints = list(members)
    coef_rule = rule["coef_rule"]
    symbolic = coef_rule == "I,x1..xp"
    if symbolic:
        coef_values = ["I", "x1..xp"]
    elif ".." in coef_rule:
        # Finite anchor rows are already explicit; symbolic syntax occurs only
        # in the symbolic domain row above.
        return []
    else:
        coef_values = coef_rule.split(",")
    partitions = [rule["partition_rule"]]
    if rule["partition_rule"] == "all_15_set_partitions_when_tagged":
        partitions = ["tagged:" + "|".join("+".join(g) for g in part)
                      for part in _set_partitions(tuple(members))]
    qdomain, qvalue = rule["q_domain"], rule["q_value"]
    if qdomain == "symbolic":
        qdomain = "p>=2;q=1+p" if rule["rule_id"] == "O-multi-within" else "p>=1;q=2(1+p)" if "mean-m" in rule["rule_id"] else "p>=1;q=4(1+p)"
    result = []
    for part in partitions:
        for target in target_endpoints:
            for coef in coef_values:
                result.append((members, coef_values, qdomain, qvalue, part, target, coef))
    return result


def source_member_sets(
    family: str, mechanism: str, block_rules: list[dict[str, str]],
    family_endpoints: Iterable[str] | None = None,
) -> set[tuple[str, ...]]:
    """Return exact, source-shaped endpoint tuples for a family/mechanism."""
    if family_endpoints is None:
        family_endpoints = {
            row["endpoint"] for row in read_tsv(ENDPOINTS_PATH)
            if row["family_route"] == family
        }
    family_endpoints = set(family_endpoints)
    found = set()
    for rule in block_rules:
        if rule["mechanism_id"] != mechanism or rule["member_dpars"] in {"", "*"}:
            continue
        members = tuple(rule["member_dpars"].split(","))
        if set(members).issubset(family_endpoints) and len(members) >= 2:
            found.add(members)
    return found


def _build_rows(
    endpoints: list[dict[str, str]],
    mechanisms: list[dict[str, str]],
    links: list[dict[str, str]],
    block_rules: list[dict[str, str]],
) -> list[dict[str, str]]:
    by_id = {row["template_id"]: row for row in mechanisms}
    endpoint_map: dict[str, list[dict[str, str]]] = {}
    for ep in endpoints:
        endpoint_map.setdefault(ep["family_route"], []).append(ep)
    rows: list[dict[str, str]] = []
    link_registry = {
        (r["engine"], r["family_route"], r["link_variant"]): r
        for r in links
    }

    def append_row(engine, family, endpoint_row, endpoint_value, endpoint_members,
                   target_member, member_coefs, link, template_id, block_rule,
                   provider, effect, provider_input, layout, shape, qdomain,
                   qvalue, partition, status, reason, evidence):
        link_info = link_registry[(engine, family, link)]
        link_status = link_info["base_link_status"]
        if link_status == "blocked_base_link" and status != "structural_inapplicable":
            status = "blocked_base_plumbing"
            reason = (
                f"{engine} {family} {link} base link route is not admitted; "
                "this union row is retained as missing base plumbing. " + reason
            )
        row = {name: "" for name in ROW_FIELDS}
        row.update({
            "engine": engine, "family_route": family,
            "dimension": endpoint_row["dimension"], "endpoint": endpoint_value,
            "endpoint_members": endpoint_members, "target_member": target_member,
            "member_coefs": member_coefs, "link_variant": link,
            "mechanism_id": template_id, "block_rule_id": block_rule,
            "provider": provider, "effect_type": effect,
            "provider_input": provider_input, "layout": layout,
            "block_shape": shape, "q_domain": qdomain, "q_value": qvalue,
            "partition_rule": partition, "status": status,
            "status_reason": reason, "source_evidence": evidence,
            "direct_sd_claim": "none",
            "base_link_status": link_status,
            "link_union_origin": link_info["union_origin"],
        })
        row["row_key"] = row_key(row)
        rows.append(row)

    block_ids = {r["mechanism_id"] for r in block_rules}
    for family, family_rows in endpoint_map.items():
        family_endpoints = [r["endpoint"] for r in family_rows]
        endpoint_by_name = {r["endpoint"]: r for r in family_rows}
        for engine in ENGINES:
            for link in links_for(engine, family, links):
                for template_id, template in by_id.items():
                    evidence = template["Native_pin_evidence"] + " || " + template["Julia_pin_evidence"]
                    provider, effect = template["latent_primitive"], template["effect_type"]
                    if template_id in PAIRS:
                        for ep in family_rows:
                            for pair_label, layout in pair_variants(template_id):
                                status = "required"
                                reason = "additive q1 provider fields; direct-SD admission is not inferred"
                                if engine == "Julia" and ":spatial:" in pair_label:
                                    status = "blocked_base_plumbing"
                                    reason = "pinned Julia structured-pair resolver refuses spatial as one of two providers"
                                append_row(engine, family, ep, ep["endpoint"], "", "provider_pair", "I",
                                    link, template_id, "q1_additive_fields", pair_label, effect,
                                    pair_label, layout, "q=1 per provider", "q=1 per provider field", "1",
                                    "additive_provider_pair", status, reason, evidence)
                        continue
                    if template_id in block_ids:
                        applicable = [r for r in block_rules if r["engine"] == engine and r["mechanism_id"] == template_id]
                        rule_instances = []
                        for rule in applicable:
                            if rule["member_dpars"] == "*":
                                if template_id == "iid_correlated_block":
                                    rule_instances.extend((rule, ep, inst) for inst in _rule_instances(rule, family_endpoints)
                                                          for ep in [inst[5]])
                                continue
                            if set(rule["member_dpars"].split(",")).issubset(family_endpoints):
                                rule_instances.extend((rule, inst[5], inst) for inst in _rule_instances(rule, family_endpoints))
                        if template_id == "iid_correlated_block":
                            # Wildcard ordinary rules target each declared dpar independently.
                            rule_instances = []
                            for rule in applicable:
                                for inst in _rule_instances(rule, family_endpoints):
                                    rule_instances.append((rule, inst[5], inst))
                        if template_id in CROSS_ENDPOINT_BLOCKS and len(family_endpoints) > 1:
                            admitted = source_member_sets(
                                family, template_id, block_rules, family_endpoints
                            )
                            for size in range(2, len(family_endpoints) + 1):
                                for members in itertools.combinations(sorted(family_endpoints), size):
                                    if members in admitted:
                                        continue
                                    qvalue = str(len(members))
                                    for target in members:
                                        for inp in INPUTS[template_id]:
                                            status = "unresolved"
                                            reason = "candidate endpoint member set retained for scope; no source-admission or identifiability claim"
                                            if (inp == "mesh_precision" and template_id == "spatial_coordinate_labelled_block"
                                                    and engine == "native"):
                                                status = "blocked_base_plumbing"
                                                reason = "native mesh source route is q1-only; candidate higher-q labelled covariance plumbing is absent"
                                            elif inp == "mesh_precision" and template_id == "spatial_coordinate_labelled_block":
                                                status = "blocked_base_plumbing"
                                                reason = "pinned Julia route has no mesh spatial input"
                                            append_row(
                                                engine, family, endpoint_by_name[target], target,
                                                ",".join(members), f"{target}:I", "I", link,
                                                template_id,
                                                f"candidate-{template_id}-q{qvalue}", provider,
                                                effect, inp, "labelled_cross_parameter_block",
                                                f"q={qvalue};candidate_member_set",
                                                "candidate_fixed", qvalue,
                                                "unresolved_candidate", status, reason,
                                                evidence + " || candidate_contract=universe-root-review.md; source-admitted members are separately keyed by block_rule_id",
                                            )
                        if not rule_instances:
                            if len(family_endpoints) == 1:
                                fallback = [(family_endpoints[0], "none", "none", "none", "inapplicable", "0", "none", "no_matching_endpoint_tuple")]
                            else:
                                # Keep the prior unresolved family-level fallback row.
                                # The separate candidate expansion below enumerates finite
                                # endpoint subsets; neither absence of a rule nor this
                                # fallback is a structural or identifiability decision.
                                special_endpoints = {"nu", "zi", "hu", "zoi", "coi", "rho12"}
                                if any(d in special_endpoints for d in family_endpoints):
                                    fallback = [("block", ",".join(family_endpoints), "all_declared_dpars", "I,x1..xp", "q-shape_unresolved", "", "contract_exclusion_not_mathematical_inapplicability", "unresolved_exact_member_tuple")]
                                else:
                                    fallback = [("block", ",".join(family_endpoints), "all_declared_dpars", "I,x1..xp", "unresolved", "", "unreviewed_composition", "unreviewed_exact_endpoint_tuple")]
                            for endpoint_value, member_set, target, coefs, qdomain, qvalue, part, rule_id in fallback:
                                for inp in INPUTS[template_id]:
                                    if qdomain == "inapplicable":
                                        status = "structural_inapplicable"
                                        reason = "single-endpoint family has no cross-endpoint block"
                                    elif qdomain.startswith("q-shape_unresolved"):
                                        status = "unresolved"
                                        reason = "pinned block contract has no current covariance rule for the exact tuple; absence is not a mathematical exclusion"
                                    else:
                                        status = "unresolved"
                                        reason = "exact family endpoint tuple requires source review"
                                    append_row(engine, family, family_rows[0], endpoint_value, member_set, target,
                                        coefs, link, template_id, rule_id, provider, effect, inp,
                                        "labelled_cross_parameter_block", f"q={qvalue or qdomain}", qdomain, qvalue,
                                        part, status, reason,
                                        evidence + " || block_contract=docs/dev-log/general-sd-regression/block-dimension-contract.md:104-131")
                            continue
                        for rule, target_ep, inst in rule_instances:
                            members, coef_values, qdomain, qvalue, partition, target, coef = inst
                            if members == ("__CURRENT_ENDPOINT__",):
                                member_set = target_ep
                            else:
                                member_set = ",".join(members)
                            status = "unresolved"
                            reason = "source-shaped block/member/q row; base-cell and direct-SD inference remain open"
                            for inp in INPUTS[template_id]:
                                row_status, row_reason = status, reason
                                if (inp == "mesh_precision" and template_id == "spatial_coordinate_labelled_block"
                                        and engine == "native"):
                                    row_status = "blocked_base_plumbing"
                                    row_reason = "native mesh source route is q1-only; higher-q labelled covariance plumbing is absent"
                                elif inp == "mesh_precision" and template_id == "spatial_coordinate_labelled_block":
                                    row_status = "blocked_base_plumbing"
                                    row_reason = "pinned Julia route has no mesh spatial input"
                                elif inp in {"phylo_covariance_matrix", "phylo_precision_matrix"} and engine == "Julia":
                                    row_status = "blocked_base_plumbing"; row_reason = "Julia public phylo input requires a tree; matrix-input sibling retained but blocked"
                                elif inp == "mesh_precision" and engine == "Julia":
                                    row_status = "blocked_base_plumbing"; row_reason = "pinned Julia route has no mesh spatial input"
                                if (rule["rule_id"] == "J-biv-structured4-tagged-partitions"
                                        and engine == "native"):
                                    row_status = "blocked_base_plumbing"
                                    row_reason = "Julia q4 tag-partition shape is retained in the cross-engine union; native tagged-partition plumbing is absent"
                                if partition.startswith("tagged:"):
                                    # q4 total-axis partition is part of the exact row key.
                                    pass
                                shape = f"q={qvalue or qdomain};partition={partition}"
                                append_row(engine, family, endpoint_by_name[target], target, member_set,
                                    f"{target}:{coef}", ",".join(coef_values), link, template_id,
                                    rule["rule_id"], provider, effect, inp,
                                    "labelled_cross_parameter_block", shape, qdomain, qvalue,
                                    partition, row_status, row_reason,
                                    evidence + " || block_rule_source=" + rule["source_pin"])
                        continue
                    # Scalar or additive q1 mechanism.
                    for endpoint_row in family_rows:
                        ep = endpoint_row["endpoint"]
                        if template_id == "phylo_intercept": inputs = INPUTS[template_id]
                        else: inputs = INPUTS[template_id]
                        layouts = LAYOUTS.get(template_id, (template["layout_or_block"],))
                        slope = "slope" in template_id or template_id == "iid_numeric_slope"
                        coefs = "x1..xp" if slope else "I"
                        target = f"{ep}:{coefs}"
                        for inp, layout in itertools.product(inputs, layouts):
                            status = "required"
                            reason = "required q1 denominator cell; direct-SD admission is not inferred"
                            if inp in {"phylo_covariance_matrix", "phylo_precision_matrix"} and engine == "Julia":
                                status = "blocked_base_plumbing"; reason = "pinned Julia phylo public route requires a tree; matrix-input sibling retained but blocked"
                            elif inp in {"mesh_precision", "mesh_precision_fixed_kappa"} and engine == "Julia":
                                status = "blocked_base_plumbing"; reason = "pinned Julia route does not admit mesh spatial input"
                            elif inp in {"mesh_precision", "mesh_precision_fixed_kappa"} and template_id != "spatial_mesh_intercept":
                                status = "blocked_base_plumbing"; reason = "pinned native mesh evidence is limited to q1 Gaussian mu intercept"
                            elif inp == "mesh_precision_fixed_kappa" and (family != "gaussian" or ep != "mu"):
                                status = "blocked_base_plumbing"; reason = "pinned native mesh route is Gaussian mu intercept only"
                            elif template_id.startswith("temporal_") and engine == "native":
                                status = "blocked_base_plumbing"; reason = "native pinned grammar excludes temporal formula syntax"
                            elif template_id == "paired_phylo_temporal_ou" and engine == "native":
                                status = "blocked_base_plumbing"; reason = "native pinned grammar excludes phylo-temporal pair"
                            append_row(engine, family, endpoint_row, ep, ep, target, coefs, link,
                                template_id, "O1" if provider == "iid" else "S1/P-temporal", provider,
                                effect, inp, layout, "q=1", "q=1 per coefficient" if slope else "q=1",
                                "1", "independent", status, reason, evidence)
    rows.sort(key=lambda row: row["row_key"])
    return rows

def generate_rows(
    endpoints: list[dict[str, str]],
    mechanisms: list[dict[str, str]],
    links: list[dict[str, str]],
    block_rules: list[dict[str, str]],
) -> list[dict[str, str]]:
    check_inputs(endpoints, mechanisms, links, block_rules)
    rows = _build_rows(endpoints, mechanisms, links, block_rules)
    validate_rows(rows, endpoints, mechanisms, links, block_rules)
    return rows


def validate_rows(
    rows: list[dict[str, str]],
    endpoints: list[dict[str, str]],
    mechanisms: list[dict[str, str]],
    links: list[dict[str, str]],
    block_rules: list[dict[str, str]],
) -> None:
    keys = [row.get("row_key", "") for row in rows]
    if any(not key for key in keys) or len(keys) != len(set(keys)):
        raise ValueError("required rows contain an empty or duplicate row_key")
    if any(row.get("status") not in {"required", "unresolved", "structural_inapplicable", "blocked_base_plumbing"} for row in rows):
        raise ValueError("required rows contain an unsupported status")
    if any(row.get("direct_sd_claim") != "none" for row in rows):
        raise ValueError("denominator rows must not claim direct-SD support")
    # Rebuild the expected key set to detect dropped endpoints, engines, links,
    # input variants, or mechanism rows after expansion.
    expected = _build_rows(endpoints, mechanisms, links, block_rules)
    expected_by_key = {row["row_key"]: row for row in expected}
    expected_keys = set(expected_by_key)
    if set(keys) != expected_keys:
        missing = len(expected_keys - set(keys))
        extra = len(set(keys) - expected_keys)
        raise ValueError(f"required-row coverage mismatch: missing={missing}, extra={extra}")
    actual_by_key = {row["row_key"]: row for row in rows}
    if actual_by_key != expected_by_key:
        raise ValueError("required-row contents differ from the deterministic source expansion")


def summary_markdown(rows: list[dict[str, str]]) -> str:
    statuses = Counter(row["status"] for row in rows)
    by_engine = Counter(row["engine"] for row in rows)
    by_mechanism = Counter(row["mechanism_id"] for row in rows)
    non_block = sum(r["block_rule_id"] in {"O1", "S1/P-temporal", "q1_additive_fields"} for r in rows)
    candidate_rows = sum(r["block_rule_id"].startswith("candidate-") for r in rows)
    block_rows = len(rows) - non_block
    tagged_native = sum(
        r["engine"] == "native"
        and r["block_rule_id"] == "J-biv-structured4-tagged-partitions"
        and r["partition_rule"].startswith("tagged:")
        for r in rows
    )
    return "\n".join(
        [
            "# Required SD-regression denominator",
            "",
            "Generated from the pinned `family-endpoints.tsv`, `mechanism-templates.tsv`, and `family-links.tsv`. Each row names the canonical response/location link obligation for that family route; the link table distinguishes engine-admitted routes from union obligations whose base link is blocked. Internal links on scale/shape dpars remain family-specific. These rows define required scope, not current SD admission.",
            "",
            f"- Endpoint source rows: {EXPECTED_ENDPOINTS} across {len(FAMILY_LINKS)} family routes.",
            f"- Explicit family/link rows: {sum(len(v) for v in EXPECTED_LINKS.values())} (42 base-admitted engine-link rows plus 2 blocked Julia union obligations; no implicit default-link rows).",
            f"- Finite mechanism templates: {len(by_mechanism)}.",
            f"- Machine-readable source block rule rows: {EXPECTED_BLOCK_RULE_ROWS} across 30 named rules; rows also carry target_member, member_coefs, q_domain, q_value, and partition_rule.",
            f"- Old-to-new mapping: the prior 5,438-row snapshot comprised 4,950 non-block rows and 488 block-related rows. This revision retains {non_block} non-block rows and has {block_rows} block rows ({block_rows-candidate_rows} source-shaped/fallback rows plus {candidate_rows} explicit unresolved candidate rows), for {len(rows)} total rows ({len(rows)-5438:+d} versus that snapshot). The 1,440 Julia tagged-q4 rows have {tagged_native} exact native union counterparts marked blocked.",
            f"- Required rows: {len(rows)}.",
            f"- By engine: {', '.join(f'{key}={by_engine[key]}' for key in sorted(by_engine))}.",
            f"- By initial status: {', '.join(f'{key}={statuses[key]}' for key in sorted(statuses))}.",
            "- Direct-SD support promotions: 0; every row has `direct_sd_claim=none`.",
            f"- Explicit input-level simultaneous provider pairs: {sum(len(v) for v in PAIRS.values())}; the separate phylo+OU temporal layout is one additional named pair template.",
            "",
            "## Explicit expansions",
            "",
            "Animal rows distinguish pedigree, A covariance, and Ainv precision inputs. Related-matrix rows distinguish K covariance and Q precision. Spatial rows distinguish coordinate and mesh inputs. Phylogenetic intercept rows distinguish tree input from covariance/precision matrix candidates; native grammar calls matrix-input phylo a planned sibling (drmTMB `docs/design/01-formula-grammar.md:1100`), while Julia's pinned `_structured_group_index` requires a tree and its resolver calls `_phylo_correlation(tree)` (DRM.jl `src/gaussian_structured.jl:196-220`). No separate public Julia matrix-input phylo route was found; those required rows remain `blocked_base_plumbing`. Animal A/Ainv and phylo matrix inputs are separate providers and are never conflated. Matrix-input phylo is only expanded for the explicitly named intercept sibling.",
            "",
            "Additive iid terms are split into crossed and nested layouts. Simultaneous provider rows list explicit pinned pair labels; they do not generate arbitrary provider combinations. The `block-rules.tsv` source table enumerates source-shaped endpoint tuples, finite q classes, symbolic coefficient-count domains, and Julia tagged q4 partitions; Julia tagged partitions are mirrored into the native denominator as `blocked_base_plumbing`. In addition, each actual family endpoint set is expanded into finite canonical size-two-or-larger member subsets for cross-endpoint block mechanisms. Exact source-shaped rows retain their source rule ID; other member sets use a `candidate-` rule ID and remain unresolved (or blocked where a provider input is absent). This includes special endpoint candidates such as nu/zi/hu/zoi/coi/rho12 where declared; it makes no compatibility or identifiability claim. Single-endpoint families have no cross-endpoint block. The q1-only native mesh limit is recorded as blocked base plumbing, not structural inapplicability.",
            "",
            "## Review limits",
            "",
            "The initial statuses remain `required`, `unresolved`, `blocked_base_plumbing`, or explicit single-endpoint `structural_inapplicable`; no code path assigns `supported`. The 30 named block rules (148 engine/mechanism/domain rows) are expanded by provider into finite q anchors plus symbolic domains where the contract admits arbitrary numeric slopes. Cross-endpoint candidate rows are finite over each family's actual endpoint set and remain unresolved absent source admission. Base plumbing is still not fully classified per family/endpoint/provider/layout; spatial mesh slope/block math, native combined-provider fitted routes, estimator prerequisites, and source disagreements remain open. Julia's two-structured-provider fitter is Gaussian and supports phylo/animal/relmat pairs (DRM.jl `src/gaussian_structured.jl:203-224,236-260`); spatial pairings are refused (`src/gaussian_structured.jl:217-219,510-514`). Native temporal rows lack fitted base plumbing at the pinned snapshot (drmTMB `docs/design/01-formula-grammar.md:1226-1230`); Julia has AR1, OU, homogeneous Toeplitz, and one phylo+OU layout (DRM.jl `src/temporal.jl:1-20,53-78`). G0 remains open.",
            "",
        ]
    )


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=ROOT, help="repository root")
    args = parser.parse_args()
    input_dir = args.root / "docs/dev-log/general-sd-regression"
    rows = generate_rows(
        read_tsv(input_dir / "family-endpoints.tsv"),
        read_tsv(input_dir / "mechanism-templates.tsv"),
        read_tsv(input_dir / "family-links.tsv"),
        read_tsv(input_dir / "block-rules.tsv"),
    )
    write_tsv(input_dir / "required-rows.tsv", rows)
    (input_dir / "required-universe.md").write_text(summary_markdown(rows), encoding="utf-8")
    print(f"wrote {len(rows)} required rows to {input_dir / 'required-rows.tsv'}")


if __name__ == "__main__":
    main()
