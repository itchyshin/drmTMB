import pathlib, hashlib, json, os, subprocess, datetime, time
R=pathlib.Path('/Users/z3437171/.codex/worktrees/sd-article-ml/drmTMB')
J=pathlib.Path('/Users/z3437171/.codex/worktrees/sd-article-ml-julia/DRM.jl')
OUT=pathlib.Path(__file__).resolve().parent
EX=OUT.parent
zob=OUT/'zeroonebeta.R'
zob.write_text((EX/'s3-zeroonebeta.R').read_text().replace(str(EX/'s3-zeroonebeta-results.rds'),str(OUT/'zeroonebeta-results.rds')))
JULIA='/Users/z3437171/.julia/juliaup/julia-1.13.0+0.aarch64.apple.darwin14/Julia-1.13.app/Contents/Resources/julia/bin/julia'
def snapshot():
    d={}
    for label,root,dirs in [('r',R,['R','src','tests/testthat']),('julia',J,['src'])]:
        for folder in dirs:
            for p in sorted((root/folder).rglob('*')):
                if p.is_file() and not p.is_symlink() and p.suffix.lower() in ('.r','.jl','.cpp','.h','.hpp','.cc','.c'):
                    d[label+'/'+p.relative_to(root).as_posix()]=hashlib.sha256(p.read_bytes()).hexdigest()
    for label,root,names in [('r',R,['DESCRIPTION','NAMESPACE','src/drmTMB.so']),('julia',J,['Project.toml','Manifest.toml'])]:
        for name in names:
            p=root/name
            if p.is_file(): d[label+'/'+name]=hashlib.sha256(p.read_bytes()).hexdigest()
    return d
before=snapshot()
metadata={'started_utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'before':before,'jobs':[]}
(OUT/'receipt.json').write_text(json.dumps(metadata,indent=2)+'\n')
env=os.environ.copy();env.update(OPENBLAS_NUM_THREADS='1',OMP_NUM_THREADS='1',JULIA_NUM_THREADS='1',NOT_CRAN='true',DRMTMB_JULIA_TESTS='true',JULIA_HOME=str(pathlib.Path(JULIA).parent),JULIA_PROJECT=str(J),DRM_JL_PATH=str(J))
code='pkgload::load_all(compile=FALSE,quiet=TRUE); '+ '; '.join('testthat::test_file("tests/testthat/'+x+'",reporter="summary",stop_on_failure=TRUE)' for x in ['test-julia-structured-stored-prediction.R','test-julia-conditional-prediction.R','test-julia-conditional-components.R','test-julia-b34-structured-fitted-bridge.R'])
jobs=[('structured-prediction',['Rscript','-e',code],{}),('gamma-article',['Rscript',str(EX/'article-gamma.R')],{'ARTICLE_OUT':str(OUT/'gamma-article')}),('zeroonebeta-probes',['Rscript',str(zob)],{}),('lss-receipt',['Rscript','tools/run-julia-phylo-labels-public.R',str(J),str(OUT/'lss-tip-identity-001.json')],{}),('stored-loglik-regression',[JULIA,'--startup-file=no','--project='+str(J),'-e','include('+json.dumps(str(J/'test/test_stored_loglik_at_optimum.jl'))+')'],{})]
for name,cmd,extra in jobs:
    assert snapshot()==before, 'source moved before '+name
    stamp=time.time(); print('START',name,datetime.datetime.now(datetime.timezone.utc).isoformat(),flush=True)
    with (OUT/(name+'.log')).open('w') as log:
        proc=subprocess.run(cmd,cwd=R,env=env|extra,stdout=log,stderr=subprocess.STDOUT)
    item={'input_script_sha256':{a:hashlib.sha256(pathlib.Path(a).read_bytes()).hexdigest() for a in cmd if len(a) < 200 and pathlib.Path(a).is_file()},'name':name,'command':cmd,'exit_code':proc.returncode,'elapsed_seconds':time.time()-stamp,'log_sha256':hashlib.sha256((OUT/(name+'.log')).read_bytes()).hexdigest()}
    metadata['jobs'].append(item);metadata['after']=snapshot();metadata['source_unchanged']=metadata['after']==before
    (OUT/'receipt.json').write_text(json.dumps(metadata,indent=2)+'\n'); print('END',name,item['exit_code'],round(item['elapsed_seconds'],2),flush=True)
    if proc.returncode or not metadata['source_unchanged']:raise SystemExit(1)
metadata['finished_utc']=datetime.datetime.now(datetime.timezone.utc).isoformat();metadata['status']='EXECUTIONS_COMPLETED_SOURCE_UNCHANGED'
(OUT/'receipt.json').write_text(json.dumps(metadata,indent=2)+'\n');print(metadata['status'],flush=True)
