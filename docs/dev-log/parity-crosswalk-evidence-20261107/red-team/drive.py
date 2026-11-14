#!/usr/bin/env python3
# watchdog driver: python3 drive.py engine out.tsv lo hi [timeout]  (1-based inclusive indices into cells.tsv)
import subprocess, sys, time, os
RT = os.path.dirname(os.path.abspath(__file__))
engine, out, lo, hi = sys.argv[1], sys.argv[2], int(sys.argv[3]), int(sys.argv[4])
TO = float(sys.argv[5]) if len(sys.argv) > 5 else 120
cells = [l.rstrip("\n").split("\t") for l in open(f"{RT}/cells.tsv")][1:]
def ndone(): return sum(1 for _ in open(out)) if os.path.exists(out) else 0
ENV = dict(os.environ, JULIA_NUM_THREADS="1", OPENBLAS_NUM_THREADS="1", OMP_NUM_THREADS="1")
open(out, "a").close()
def record(c, status, note, secs=""):
    with open(out, "a") as f:
        f.write("\t".join([c[0], engine, status, "", "", "NaN", "", str(secs), "", "", "", note]) + "\n")
while lo + ndone() <= hi:
    k = lo + ndone()
    if os.path.exists(out + ".ready"): os.remove(out + ".ready")
    cmd = ["nice", "-n", "10"] + (["Rscript", f"{RT}/r_worker.R", f"{RT}/cells.tsv", str(k), out, str(hi)] if engine == "R"
        else ["julia", "+1.10.12", f"--project={RT}/env", f"{RT}/j_worker.jl", f"{RT}/cells.tsv", str(k), out, str(hi)])
    p = subprocess.Popen(cmd, env=ENV, stdout=open(out + ".stdout", "a"), stderr=subprocess.STDOUT)
    while p.poll() is None and not os.path.exists(out + ".ready"):
        time.sleep(1)   # warm-up is not time-boxed
    seen = ndone(); last = time.time(); killed = False
    while p.poll() is None:
        time.sleep(1); n = ndone()
        if n != seen: seen = n; last = time.time()
        if time.time() - last > TO:
            p.kill(); p.wait(); killed = True; break
    kk = lo + ndone()
    if kk > hi: break
    if killed:
        record(cells[kk - 1], "hang", f"killed after {int(TO)} s without finishing", int(TO))
    elif p.returncode != 0:
        record(cells[kk - 1], "crash", f"worker exited with code {p.returncode}")
    if p.poll() is None: p.kill()
