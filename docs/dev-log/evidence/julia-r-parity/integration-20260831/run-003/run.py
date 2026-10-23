import sys,os,subprocess,time,json,hashlib,signal
from pathlib import Path
root=Path(__file__).resolve().parent.parent;out=Path(__file__).resolve().parent
mode=sys.argv[1]
commands={"r-regression":["Rscript","--vanilla",str(out/"r-regression.R")],"ayumi-batch":["Rscript","--vanilla","tools/run-julia-ayumi-batch.R",str(root/"DRM.jl"),str(out/"ayumi-batch.json")]}
commands["one-session"]=["Rscript","--vanilla",str(out/"one-session.R"),str(root/"DRM.jl"),str(out/"one-session.json")]
cmd=commands[mode];cwd=root/"drmTMB"
def manifest():
 d={}
 for repo,patterns in [(root/"DRM.jl",["src/**/*.jl","test/**/*.jl","Project.toml","Manifest.toml"]),(cwd,["R/*.R","tests/testthat/*.R","src/drmTMB.so","DESCRIPTION","NAMESPACE"])]:
  for pattern in patterns:
   for p in repo.glob(pattern):
    if p.is_file():d[str(p)]=hashlib.sha256(p.read_bytes()).hexdigest()
 return d
heads={p.name:subprocess.check_output(["git","-C",str(p),"rev-parse","HEAD"],text=True).strip() for p in [root/"DRM.jl",cwd]}
before=manifest();start=time.time();env=dict(os.environ,R_PROFILE_USER="/dev/null",OPENBLAS_NUM_THREADS="1",JULIA_PKG_PRECOMPILE_AUTO="0")
with (out/(mode+".log")).open("x") as log:
 p=subprocess.Popen(cmd,cwd=cwd,stdout=log,stderr=subprocess.STDOUT,env=env,start_new_session=True)
 timedout=False
 try:code=p.wait(timeout=600)
 except subprocess.TimeoutExpired:
  timedout=True;os.killpg(p.pid,signal.SIGTERM)
  try:code=p.wait(timeout=10)
  except subprocess.TimeoutExpired:os.killpg(p.pid,signal.SIGKILL);code=p.wait()
after=manifest();result=dict(command=cmd,heads=heads,elapsed=time.time()-start,exit_code=code,timeout=timedout,source_before=before,source_after=after,source_unchanged=before==after,scope="bounded integration regression; reused R DLL, not fresh package build")
(out/(mode+"-process.json")).write_text(json.dumps(result,indent=2)+"\n")
print(json.dumps({k:v for k,v in result.items() if k not in ("source_before","source_after")},indent=2))
sys.exit(0 if code==0 and before==after and not timedout else 1)
