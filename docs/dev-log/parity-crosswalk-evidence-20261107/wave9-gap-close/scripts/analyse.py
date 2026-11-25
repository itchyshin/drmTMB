# Wave-9 agreement analysis. Thresholds FIXED BEFORE the results were read (written into the plan first):
#   T1 |dLL| <= 1e-4
#   T2 mean/sigma coefficients: flag if |d| > 5e-3 absolute OR |d|/SE_R > 0.02
#   T3 SD / correlation parameters (log-SD, SD coefficients, atanh rho): flag if |d| > 0.02
#   T4 any non-finite SE in either engine
#   T5 boundary / convergence: any log-SD parameter < -6, |atanh rho| > 4, Julia converged=false, R opt$convergence != 0,
#      R pdHess FALSE or is_converged FALSE
#   T6 (informational) SE ratio Julia/R for mean coefficients outside [0.9, 1.1]
import csv, math, sys, collections
shapes = {l.split('\t')[0]: l.strip().split('\t')[1] for l in open('shapes.txt') if l.strip()}
def load(fn):
    out = {}
    for l in open(fn):
        f = l.rstrip('\n').split('\t')
        out[(f[0], int(f[1]))] = f
    return out
J = load('res/julia_all.tsv'); R = load('res/r_all.tsv')
rows = []; flagged = []
def fl(s): return [float(v) for v in s.split(',')] if s else []
for key in sorted(J, key=lambda k: (k[0], k[1])):
    j, r = J[key], R[key]
    sid, seed = key
    rec = dict(shape=sid, cell=shapes[sid], seed=seed)
    if j[2] != 'OK' or r[2] != 'OK':
        rec.update(status=f"J:{j[2]} R:{r[2]}"); rows.append(rec); flagged.append((rec, ['NOFIT'])); continue
    llJ, llR = float(j[3]), float(r[3])
    thJ, thR = fl(j[5]), fl(r[5]); seJ, seR = fl(j[6]), fl(r[6])
    names = r[7].split(';')
    assert len(thJ) == len(thR) == len(names), (key, len(thJ), len(thR))
    dll = llJ - llR
    cls = ['mu' if (n == 'beta_mu' or n == 'beta_sigma') else 'sd' for n in names]   # log_sd_*, beta_sd_*, eta_cor_* -> sd class
    d = [a - b for a, b in zip(thJ, thR)]
    max_abs_mu = max([abs(x) for x, c in zip(d, cls) if c == 'mu'] or [0])
    max_se_mu = max([abs(x) / s for x, s, c in zip(d, seR, cls) if c == 'mu' and s > 0 and math.isfinite(s)] or [0])
    max_abs_sd = max([abs(x) for x, c in zip(d, cls) if c == 'sd'] or [0])
    nonfinJ = sum(1 for v in seJ if not math.isfinite(v)); nonfinR = sum(1 for v in seR if not math.isfinite(v))
    ratios = [a / b for a, b, c in zip(seJ, seR, cls) if c == 'mu' and b > 0 and math.isfinite(a) and math.isfinite(b)]
    maxratio = max([abs(math.log(x)) for x in ratios] or [0]); sr_flag = any(x < 0.9 or x > 1.1 for x in ratios)
    bound = []
    for n, v in zip(names, thR):
        if n.startswith('log_sd') and v < -6: bound.append('R_logsd<-6')
        if n.startswith('eta_cor') and abs(v) > 4: bound.append('R_|rho|>4')
    for n, v in zip(names, thJ):
        pass
    # Julia boundary: positional SD params
    for n, v in zip(names, thJ):
        if (n.startswith('log_sd') or n.startswith('beta_sd')) and v < -6: bound.append('J_logsd<-6')
        if n.startswith('eta_cor') and abs(v) > 4: bound.append('J_|rho|>4')
    conv_flags = []
    if j[4] != 'true': conv_flags.append('J_unconverged')
    if r[4] != '0': conv_flags.append('R_unconverged')
    if 'pdHess=FALSE' in r[8]: conv_flags.append('R_pdHess=FALSE')
    if 'is_converged=FALSE' in r[8]: conv_flags.append('R_is_converged=FALSE')
    f = []
    if abs(dll) > 1e-4: f.append('T1')
    if max_abs_mu > 5e-3 or max_se_mu > 0.02: f.append('T2')
    if max_abs_sd > 0.02: f.append('T3')
    if nonfinJ or nonfinR: f.append('T4')
    if bound or conv_flags: f.append('T5')
    rec.update(status='OK', llJ=llJ, llR=llR, dll=dll, max_abs_mu=max_abs_mu, max_se_mu=max_se_mu, max_abs_sd=max_abs_sd,
               nonfinJ=nonfinJ, nonfinR=nonfinR, se_ratio_flag=int(sr_flag), max_log_se_ratio=maxratio,
               boundary=';'.join(sorted(set(bound))), conv=';'.join(conv_flags), flags=','.join(f), secsJ=j[9], secsR=r[9])
    rows.append(rec)
    if f: flagged.append((rec, f))
cols = ['shape','cell','seed','status','llJ','llR','dll','max_abs_mu','max_se_mu','max_abs_sd','nonfinJ','nonfinR','se_ratio_flag','max_log_se_ratio','boundary','conv','flags','secsJ','secsR']
with open('res/agreement_per_fit.tsv', 'w') as f:
    f.write('\t'.join(cols) + '\n')
    for r in rows: f.write('\t'.join(str(r.get(c, '')) for c in cols) + '\n')
# per-shape summary
print("shape\tcell\tn\tmax|dLL|\tmax|dmu|\tmax dmu/SE_R\tmax|dSD|\tnonfinSE(J/R)\tflagged\tseed0_dLL")
by = collections.defaultdict(list)
for r in rows: by[r['shape']].append(r)
summ = []
for sid in sorted(by):
    rs = [r for r in by[sid] if r['status'] == 'OK']
    line = (sid, shapes[sid], len(rs), f"{max(abs(r['dll']) for r in rs):.2e}", f"{max(r['max_abs_mu'] for r in rs):.2e}",
            f"{max(r['max_se_mu'] for r in rs):.2e}", f"{max(r['max_abs_sd'] for r in rs):.2e}",
            f"{sum(r['nonfinJ'] for r in rs)}/{sum(r['nonfinR'] for r in rs)}", sum(1 for r in rs if r['flags']), f"{[r for r in rs if r['seed']==0][0]['dll']:.1e}")
    print('\t'.join(map(str, line))); summ.append(line)
print("\nFLAGGED fits:")
for rec, f in flagged:
    print(rec['shape'], rec['cell'], 'seed', rec['seed'], f, 'dLL=%.2e' % rec.get('dll', float('nan')), 'mu=%.2e' % rec.get('max_abs_mu', 0), 'sd=%.2e' % rec.get('max_abs_sd', 0),
          rec.get('boundary', ''), rec.get('conv', ''), 'nonfin J/R', rec.get('nonfinJ'), rec.get('nonfinR'))
print("\nSE-ratio informational flags (T6):", sum(r.get('se_ratio_flag', 0) for r in rows), "of", len(rows))
