"""Independent finite death-time enumeration; contains no forward recursion."""
import itertools, math, random, csv, argparse
from pathlib import Path

def probability(y, phi, p, first=0):
    n = len(y)
    result = 0.0
    for death in range(first+1, n+1):
        mass = 1.0
        for t in range(first, n-1):
            if t+1 < death: mass *= phi[t]
            elif t+1 == death: mass *= 1.0-phi[t]
        for t in range(first+1,n):
            if y[t] == -1: continue
            if t < death: mass *= p[t] if y[t] else 1.0-p[t]
            elif y[t] == 1: mass = 0.0
        result += mass
    return result

def main():
    phi=[.8,.6];p=[.91,.3,.4]
    known={'100':.6256,'101':.1344,'110':.1824,'111':.0576,'1?1':.192}
    for h,q in known.items():
        assert abs(probability([int(x) if x!='?' else -1 for x in h],phi,p)-q)<1e-14
    assert abs(probability([0,1,0],phi,p,1)-.76)<1e-14
    assert abs(probability([0,1,1],phi,p,1)-.24)<1e-14
    assert probability([0,0,1],phi,p,2)==1
    rng=random.Random(1903)
    rows=[]
    for n in range(2,7):
        for scenario in range(6):
            phi=[rng.uniform(.05,.95) for _ in range(n-1)]
            p=[rng.uniform(.05,.95) for _ in range(n)]
            if scenario==0: phi=[1.]*(n-1)
            if scenario==1: p=[0.]*n
            if scenario==2: p=[1.]*n
            if scenario==3: phi=[0.]*(n-1)
            for f in range(n):
                total=0
                for suffix in itertools.product([0,1],repeat=n-f-1):
                    y=[0]*f+[1]+list(suffix)
                    q=probability(y,phi,p,f);total+=q
                    rows.append([''.join(map(str,y)),f+1,','.join(format(x,'.17g') for x in phi),','.join(format(x,'.17g') for x in p),format(q,'.17g')])
                assert abs(total-1)<1e-12
    for h,q in known.items():rows.append([h,1,'.8,.6','.91,.3,.4',format(q,'.17g')])
    # Deliberately wrong constructions must disagree with known answers.
    assert abs(.8*(1-.3)*(1-.4)-known['100'])>.1
    assert abs(.91*known['101']-known['101'])>.001
    assert abs(1-known['100'])>.1
    parser=argparse.ArgumentParser()
    parser.add_argument('--output', type=Path, default=Path('oracle-fixtures.tsv'))
    out=parser.parse_args().output
    with out.open('w') as f:
        w=csv.writer(f,delimiter='\t',lineterminator='\n');w.writerow(['history','first','phi','p','probability']);w.writerows(rows)
    print(f'CMR_ORACLE_OK: {len(rows)} independent enumeration fixtures; normalization and wrong-model controls verified')

if __name__=='__main__':main()
