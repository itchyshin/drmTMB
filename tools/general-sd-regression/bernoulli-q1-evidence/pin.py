#!/usr/bin/env python3
"""Hash the source surface for the one-trial Bernoulli q1 receipt."""
from pathlib import Path
from hashlib import sha256
import sys

repo = Path.cwd().resolve()
julia = Path("/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-julia")
paths = []
for root in (repo / "R", repo / "src", julia / "src"):
    paths.extend(p for p in root.rglob("*") if p.is_file() and not p.is_symlink())
for p in (
    repo / "DESCRIPTION", repo / "NAMESPACE",
    repo / "tests/testthat/test-julia-binomial-sd.R",
    repo / "tests/testthat/helper-binomial-sd-regression.R",
    repo / "tests/testthat/helper-julia-bridge-path.R",
    julia / "Project.toml", julia / "Manifest.toml",
):
    paths.append(p)
paths.extend((repo / "tools/general-sd-regression/bernoulli-q1-evidence").glob("*"))
for path in sorted(set(paths)):
    if path.is_file() and not path.is_symlink():
        print(sha256(path.read_bytes()).hexdigest(), path)
