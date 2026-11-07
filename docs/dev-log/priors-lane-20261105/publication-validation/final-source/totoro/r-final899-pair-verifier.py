import ast,csv,hashlib,math,pathlib,subprocess
base=pathlib.Path("/home/snakagaw/hsq_work/drm-priors-20261105-01a1ad0b")
rroot=base/"r-final899-clean-src"; jroot=base/"julia-final727-src"; e=base/"evidence"
assert subprocess.check_output(["git","-C",str(rroot),"rev-parse","HEAD"],text=True).strip()=="8998056d75b9e1fe9d66264cb4ae35e025535e21"
for root,manifest in [(rroot,e/"r-final899-code-test-blobs.txt"),(jroot,e/"julia-final727-code-test-blobs.txt")]:
 for line in manifest.read_text().splitlines():
  expected,name=line.split(" ",1)
  actual=subprocess.check_output(["git","hash-object",str(root/name)],text=True).strip()
  assert actual==expected, name
source=(rroot/"docs/dev-log/priors-lane-20261105/verify-evidence.py").read_text()
node=next(n for n in ast.parse(source).body if isinstance(n,ast.FunctionDef) and n.name=="check_pairs")
ns={"math":math}; exec(compile(ast.Module(body=[node],type_ignores=[]),"check_pairs","exec"),ns)
check=ns["check_pairs"]
rows=list(csv.DictReader((e/"r-final899-live-pair.csv").open()))
check(rows)
assert "LIVE_PRIOR_PAIR_PASS" in (e/"r-final899-live-pair.log").read_text()
bad=[dict(r) for r in rows]; bad[0]["coef_max_abs"]="0.01"
for mutant in [bad,rows[:-1]]:
 try: check(mutant)
 except AssertionError: pass
 else: raise AssertionError("pair verifier accepted mutant")
print("PAIR_RECEIPT_SOURCE_BINDING_PASS R=8998056d75b9e1fe9d66264cb4ae35e025535e21 Julia=727ac08590749aef2165337e1e6391b0894f6d6c")
print("PAIR_VERIFIER_NEGATIVE_CONTROLS_PASS 2/2")
