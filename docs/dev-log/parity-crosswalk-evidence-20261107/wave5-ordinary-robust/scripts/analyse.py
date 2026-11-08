import csv, math, os, sys, statistics as st
def rd(p):
    with open(p) as f: return list(csv.DictReader(f))
def jfit(d, s):
    p=f"{d}/gauss_ord_s{s:03d}"
    ll=rd(p+"_ll.csv")[0]
    if ll["ll"]=="NA": return None
    rows=rd(p+".csv")
    est=[float(r["est"]) for r in rows]; se=[float(r["se"]) for r in rows]
    return dict(ll=float(ll["ll"]), conv=ll["converged"], est=est, se=se)
def rfit(d, s):
    p=f"{d}/r/gauss_ord_s{s:03d}"
    ll=rd(p+"_ll.csv")[0]; rows=rd(p+".csv")
    return dict(ll=float(ll["ll"]), est=[float(r["est"]) for r in rows], se=[float(r["se"]) for r in rows], conv=ll["convergence"])
def cmp(j, r):
    th=j["est"][-1]; rho_j=th/math.sqrt(1+th*th); rho_r=math.tanh(r["est"][-1])
    cd=[abs(a-b)/s for a,b,s in zip(j["est"][:-1], r["est"][:-1], r["se"][:-1])]
    return max(cd), abs(rho_j-rho_r), abs(j["ll"]-r["ll"])
out=[]
cfgs=[("1.10.12","d110","full300"),("1.10.12","d112","full300_j112"),("1.12.7","d110","full300"),("1.12.7","d112","full300_j112")]
summary=[]
for ver,dd,rdir in cfgs:
    v=ver.replace("1.","").split(".")[0]; v="110" if ver.startswith("1.10") else "112"
    n_base_fail=n_fix_fail=0; maxbase=0; nbase_ok=0; cd_all=[]; rho_all=[]; ll_all=[]; nconv=0; worst=None; notconv=[]
    ll_better=0
    for s in range(1,301):
        b=jfit(f"base{v}_{dd}",s); f=jfit(f"fix{v}_{dd}",s); r=rfit(rdir,s)
        if b is None: n_base_fail+=1
        if f is None: n_fix_fail+=1; continue
        if f["conv"]=="true": nconv+=1
        else: notconv.append(s)
        c,rh,l=cmp(f,r); cd_all.append((c,s)); rho_all.append((rh,s)); ll_all.append((l,s))
        dll = f["ll"]-r["ll"]
        rowb=None
        if b is not None:
            nbase_ok+=1
            dl=abs(b["ll"]-f["ll"]); dp=max(abs(x-y) for x,y in zip(b["est"],f["est"]))
            maxbase=max(maxbase,dl)
            out.append((ver,dd,s,"base_ok",b["ll"],f["ll"],dl,dp,f["ll"]-r["ll"],c,rh))
        else:
            out.append((ver,dd,s,"base_failed",float("nan"),f["ll"],float("nan"),float("nan"),f["ll"]-r["ll"],c,rh))
    mx=lambda L:max(L)
    summary.append((ver,dd,n_base_fail,n_fix_fail,nbase_ok,maxbase,nconv,mx(cd_all),mx(rho_all),mx(ll_all),sorted(cd_all)[-3:],notconv))
with open("agreement_per_seed.csv","w",newline="") as f:
    w=csv.writer(f); w.writerow(["julia","dataset","seed","baseline","ll_baseline","ll_fixed","abs_ll_fixed_minus_baseline","max_abs_par_fixed_minus_baseline","ll_fixed_minus_ll_R","max_coef_diff_in_R_SE","abs_rho_diff"]); w.writerows(out)
for s in summary: print(s)
