import csv,collections,re
base="/private/tmp/claude-503/-Users-z3437171--claude-spares-spare-t7eZxY/4c45dda1-dd05-4a24-a138-9970e0359a32/scratchpad/drmr/docs/dev-log/parity-crosswalk-evidence-20261107/fuzz-gap-map/gap_map.tsv"
NUM=re.compile(r"(not positive definite|PosDef|NaN|non-?finite|Cholesky|singular|did not converge|line search|LAPACK|overflow|DomainError|sqrt will only)",re.I)
gm={r['cell_id']:r for r in csv.DictReader(open(base),delimiter='\t')}
aft={}
for l in open('regfuzz/after_all.txt'):
    p=l.rstrip('\n').split('\t')
    if p[0]=='R' and len(p)>=10: aft[p[2]]=p
def cls(p):
    s=p[3]
    if s in("FITS","NONCONVERGED","TIMEOUT"): return s,""
    et=p[4]; msg=p[6] or p[5]
    if s=="ERROR":
        if et=="MethodError": return "ERRORS","kwarg" if "keyword call" in msg else "MethodError"
        if et in("ArgumentError","ErrorException"):
            return ("ERRORS","numeric") if NUM.search(msg) else ("REFUSES",et)
        return "ERRORS",et
    return s,""
print("cells re-run:",len(aft),"of",len(gm))
tr=collections.Counter(); ll=[]; out=[]
for c,p in aft.items():
    g=gm[c]; bo=g['j_outcome']; ao,asub=cls(p)
    tr[(bo,ao)]+=1
    out.append((c,bo,g['j_sub'],ao,asub))
    if bo=='FITS' and ao=='FITS':
        ll.append((abs(float(g['j_ll'])-float(p[7])),c))
for k,v in sorted(tr.items()): print(k,v)
ll.sort(reverse=True)
print("FITS->FITS: n",len(ll),"max |dll|",ll[0] if ll else None,"n>1e-6",sum(d>1e-6 for d,_ in ll),"n>1e-9",sum(d>1e-9 for d,_ in ll))
print("regressions (FITS before, not FITS after):",[x for x in out if x[1]=='FITS' and x[3]!='FITS'])
closed=[x for x in out if x[1]!='FITS' and x[3]=='FITS']
print("closed:",len(closed))
print(collections.Counter((gm[x[0]]['family'],gm[x[0]]['kind'],x[2]) for x in closed))
rr=[x for x in out if gm[x[0]]['r_outcome']!='FITS' and x[3]=='FITS']
print("R refuses/errs, Julia fits:",len(rr),"(of which were already FITS before:",sum(x[1]=='FITS' for x in rr),")")
# cells that were refuse and R fits and still refuse by sig
still=[x for x in out if x[1] in('REFUSES','ERRORS') and x[3]!='FITS' and gm[x[0]]['r_outcome']=='FITS']
print("R fits, Julia still not fit:",len(still))
cnt=collections.Counter((gm[x[0]]['family'],gm[x[0]]['kind'],gm[x[0]]['q'],x[3]) for x in still)
for k,v in sorted(cnt.items()): print(k,v)
open('regfuzz/regression_table.tsv','w').write("cell_id\tbefore\tbefore_sub\tafter\tafter_sub\n"+"\n".join("\t".join(x) for x in out)+"\n")
print("not re-run:",[c for c in gm if c not in aft])
