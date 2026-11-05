from pathlib import Path
import hashlib,json,subprocess,os,time,datetime,signal
R=Path('/Users/z3437171/.codex/worktrees/sd-article-ml/drmTMB')
J=Path('/Users/z3437171/.codex/worktrees/sd-article-ml-julia/DRM.jl')
OUT=Path(__file__).parent
B='/Users/z3437171/.julia/juliaup/julia-1.13.0+0.aarch64.apple.darwin14/Julia-1.13.app/Contents/Resources/julia/bin'
def snap():
 d={}
 for label,root,dirs in [('r',R,['R','src','tests/testthat']),('julia',J,['src'])]:
  for folder in dirs:
   for p in sorted((root/folder).rglob('*')):
    if p.is_file() and not p.is_symlink() and p.suffix.lower() in ('.r','.jl','.cpp','.h','.hpp','.cc','.c'):
     d[label+'/'+p.relative_to(root).as_posix()]=hashlib.sha256(p.read_bytes()).hexdigest()
 for label,root,names in [('r',R,['DESCRIPTION','NAMESPACE','src/drmTMB.so']),('julia',J,['Project.toml','Manifest.toml','test/test_iid_sd_quadrature_accuracy.jl'])]:
  for n in names: d[label+'/'+n]=hashlib.sha256((root/n).read_bytes()).hexdigest()
 return d
before=snap();cmd=['Rscript','tools/run-julia-phylo-labels-public.R',str(J),str(OUT/'lss-1cd-current.json')]
r={'started_utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'estimate_minutes':[2,5],'before':before,'command':cmd,'heads':{n:subprocess.check_output(['git','rev-parse','HEAD'],cwd=p,text=True).strip() for n,p in [('r',R),('julia',J)]}}
env=dict(os.environ,OPENBLAS_NUM_THREADS='1',OMP_NUM_THREADS='1',JULIA_NUM_THREADS='1',NOT_CRAN='true',DRMTMB_JULIA_TESTS='true',JULIA_HOME=B,JULIA_PROJECT=str(J),DRM_JL_PATH=str(J))
t=time.monotonic()
with (OUT/'lss-1cd-current.log').open('w') as log:
 proc=subprocess.Popen(cmd,cwd=R,env=env,stdout=log,stderr=subprocess.STDOUT,start_new_session=True)
 try: r['exit_code']=proc.wait(timeout=300)
 except subprocess.TimeoutExpired:
  os.killpg(proc.pid,signal.SIGTERM)
  try:proc.wait(timeout=10)
  except subprocess.TimeoutExpired:os.killpg(proc.pid,signal.SIGKILL);proc.wait()
  r['exit_code']='OVERRUN_STOPPED'
r['seconds']=time.monotonic()-t;r['after']=snap();r['source_unchanged']=r['before']==r['after'];r['status']='PASS' if r['exit_code']==0 and r['source_unchanged'] else 'NOT_ACCEPTED'
(OUT/'lss-1cd-refresh-guard.json').write_text(json.dumps(r,indent=2)+'\n')
print(r['status'],r['exit_code'],r['seconds'],r['source_unchanged'])
raise SystemExit(0 if r['status']=='PASS' else 1)
