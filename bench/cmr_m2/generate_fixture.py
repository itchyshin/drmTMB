#!/usr/bin/env python3
"""Generate the literal CMR M2 recovery-smoke datasets (SplitMix64-v1)."""
from __future__ import annotations
import csv
from pathlib import Path

OUT = Path(__file__).resolve().parent / "fixtures"
BASE = 20261006
STAGE_INDEX = 0
OCCASIONS = 5
INTERVALS = [1.0, 0.5, 1.5, 1.0]
N = 32

class SplitMix64:
    def __init__(self, seed: int):
        self.state = seed & ((1 << 64) - 1)
    def random(self) -> float:
        self.state = (self.state + 0x9E3779B97F4A7C15) & ((1 << 64) - 1)
        z = self.state
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & ((1 << 64) - 1)
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & ((1 << 64) - 1)
        z ^= z >> 31
        return (z >> 11) / float(1 << 53)

def logistic(x: float) -> float:
    if x >= 0:
        return 1.0 / (1.0 + pow(2.718281828459045, -x))
    e = pow(2.718281828459045, x)
    return e / (1.0 + e)

def write_csv(path: Path, header: list[str], rows: list[list[object]]) -> None:
    with path.open("w", newline="", encoding="utf-8") as f:
        w = csv.writer(f, lineterminator="\n")
        w.writerow(header)
        w.writerows(rows)

OUT.mkdir(parents=True, exist_ok=True)
history_rows: list[list[object]] = []
phi_rows: list[list[object]] = []
p_rows: list[list[object]] = []
seeds: list[dict[str, object]] = []

for cell_index, cell in enumerate(("survival_coefficients", "detection_coefficients"), start=1):
    for replicate in (1, 2):
        seed = BASE + 10_000_000 * STAGE_INDEX + 100_000 * cell_index + replicate
        rng = SplitMix64(seed)
        seeds.append({"cell": cell, "replicate": replicate, "seed": seed})
        for i in range(1, N + 1):
            ident = f"{cell[:3]}_{replicate:02d}_{i:03d}"
            # Balanced, fixed individual predictors. Four final-first histories
            # per dataset exercise the likelihood-one layout case.
            x = -0.5 if i % 2 else 0.5
            z = -0.5 if (i // 2) % 2 else 0.5
            first = OCCASIONS if i % 11 == 0 else (1 if i % 2 else 2)
            end = first if first == OCCASIONS else (4 if i % 7 == 0 else OCCASIONS)
            y: dict[int, int | str] = {t: 0 for t in range(1, OCCASIONS + 1)}
            observed: dict[int, int] = {t: 1 for t in range(1, OCCASIONS + 1)}
            y[first] = 1
            # Survey masks are drawn independently of latent survival.
            for t in range(first + 1, end + 1):
                observed[t] = int(rng.random() >= 0.08)
            alive = True
            for t in range(first, end):
                phi = logistic(1.20 - 0.45 * x) if cell == "survival_coefficients" else 0.80
                p = 0.60 if cell == "survival_coefficients" else logistic(0.10 + 0.65 * z)
                alive = alive and (rng.random() < phi ** INTERVALS[t - 1])
                if alive and observed[t + 1]:
                    y[t + 1] = int(rng.random() < p)
            for t in range(1, OCCASIONS + 1):
                cap = y[t] if observed[t] else ""
                history_rows.append([cell, replicate, ident, t, cap, observed[t], first, end, "years"])
            if first < OCCASIONS:
                for t in range(first, end):
                    phi_rows.append([cell, replicate, ident, t, t + 1, INTERVALS[t - 1], x])
                for t in range(first + 1, end + 1):
                    p_rows.append([cell, replicate, ident, t, z])

write_csv(OUT / "histories.csv",
          ["cell", "replicate", "id", "occasion", "capture", "observed", "first_capture", "admin_end", "units"], history_rows)
write_csv(OUT / "phi_predictors.csv",
          ["cell", "replicate", "id", "interval_start", "interval_end", "interval_length", "x_phi"], phi_rows)
write_csv(OUT / "p_predictors.csv",
          ["cell", "replicate", "id", "occasion", "z_p"], p_rows)
print(f"CMR_M2_FIXTURE_OK: {len(seeds)} datasets; {N} histories per dataset; {len(history_rows)} history rows")
for item in seeds:
    print(f"{item['cell']} replicate={item['replicate']} seed={item['seed']}")
