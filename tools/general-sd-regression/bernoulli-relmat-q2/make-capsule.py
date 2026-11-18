from __future__ import annotations

import gzip
import hashlib
import io
import json
import tarfile
from pathlib import Path

root = Path.cwd()
outdir = root / "tools/general-sd-regression/bernoulli-relmat-q2"
paths = [
    "R/drmTMB.R",
    "R/methods.R",
    "R/profile.R",
    "src/drmTMB.cpp",
    "src/drm_count_kernels.h",
    "src/drm_numeric.h",
    "src/drm_response_kernels.h",
    "src/init.c",
    "src/meuwissen_luo.c",
    "tests/testthat/test-binomial-relmat-q2-sd.R",
    "man/simulate.drmTMB.Rd",
    "tools/general-sd-regression/bernoulli-relmat-q2/PLAN.md",
    "tools/general-sd-regression/bernoulli-relmat-q2/design-advisory.md",
    "tools/general-sd-regression/bernoulli-relmat-q2/example.R",
    "tools/general-sd-regression/bernoulli-relmat-q2/make-capsule.py",
]
manifest = {path: hashlib.sha256((root / path).read_bytes()).hexdigest()
            for path in paths}
(outdir / "source-manifest.json").write_text(
    json.dumps(manifest, indent=2, sort_keys=True) + "\n")
with (outdir / "source-capsule.tar.gz").open("wb") as raw:
    with gzip.GzipFile(fileobj=raw, mode="wb", filename="", mtime=0) as gz:
        with tarfile.open(fileobj=gz, mode="w") as archive:
            for path in paths:
                data = (root / path).read_bytes()
                info = tarfile.TarInfo(path)
                info.size = len(data)
                info.mtime = 0
                info.mode = 0o644
                info.uid = info.gid = 0
                info.uname = info.gname = ""
                archive.addfile(info, io.BytesIO(data))
