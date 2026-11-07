"""Hash the implementation and prior tests without reading build products."""
from pathlib import Path
import hashlib
import json
import sys
root = Path(sys.argv[1]).resolve()
patterns = ['R/*.R', 'src/*.cpp', 'src/*.h', 'src/*.c', 'DESCRIPTION', 'NAMESPACE',
            'tests/testthat/test-fixed-effect-priors.R',
            'tests/testthat/test-fixed-priors-workflow.R']
files = sorted({p for pattern in patterns for p in root.glob(pattern) if p.is_file()},
               key=lambda p: p.relative_to(root).as_posix())
rows = [{'path': p.relative_to(root).as_posix(),
         'sha256': hashlib.sha256(p.read_bytes()).hexdigest()} for p in files]
canonical = ''.join(f"{r['sha256']}  {r['path']}\n" for r in rows)
print(json.dumps({'aggregate_sha256': hashlib.sha256(canonical.encode()).hexdigest(),
                  'files': rows}, indent=2))
