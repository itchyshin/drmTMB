#!/usr/bin/env python3
"""Chunked, watchdog-supervised runner for the refusal-gap map.

Usage: driver.py <engine r|julia> <workers> <cell_timeout_s> <cells.tsv> <outdir> [--limit-ids FILE]
Each chunk (family x kind x estimator) is run in one runner process; a per-cell
watchdog kills a hung cell (recorded TIMEOUT) and a dead process (segfault, OOM,
abort) is recorded as PROCESS_DIED for the cell it was on; the chunk then resumes
at the next cell.  Only one new process per chunk resume.  One thread per process.
"""
import os, sys, time, signal, subprocess, threading, queue, collections

engine, workers, cell_timeout, cells_file, outdir = sys.argv[1], int(sys.argv[2]), float(sys.argv[3]), sys.argv[4], sys.argv[5]
limit = None
if len(sys.argv) > 7 and sys.argv[6] == "--limit-ids":
    limit = set(l.strip() for l in open(sys.argv[7]) if l.strip())
here = os.path.dirname(os.path.abspath(__file__))
os.makedirs(outdir, exist_ok=True)
ids = [l.split("\t")[0] for l in open(cells_file).read().splitlines()[1:]]
if limit is not None:
    ids = [i for i in ids if i in limit]
chunks = collections.OrderedDict()
for i in ids:
    f, k, lab, q, pat, cm, est = i.split("|")
    chunks.setdefault((f, k, est), []).append(i)
# biggest-risk chunks first (non-Gaussian structured) so stragglers start early
work = queue.Queue()
for key in sorted(chunks, key=lambda k: (k[0] == "gaussian", k[1] in ("ordinary",), k)):
    work.put(key)
env = dict(os.environ, OPENBLAS_NUM_THREADS="1", OMP_NUM_THREADS="1", JULIA_NUM_THREADS="1", MKL_NUM_THREADS="1",
           FUZZ_DATA=os.path.join(here, "data"))
lock = threading.Lock()
log = open(os.path.join(outdir, "driver.log"), "a")
def say(m):
    with lock:
        log.write(time.strftime("%H:%M:%S ") + m + "\n"); log.flush()

def cmd(idfile, start, out):
    if engine == "r":
        return ["Rscript", os.path.join(here, "run_r.R"), cells_file, idfile, str(start), out]
    jproj = os.environ["FUZZ_JULIA_PROJECT"]
    return ["julia", "--project=" + jproj, os.path.join(here, "run_julia.jl"), cells_file, idfile, str(start), out]

def parse(out):
    started, done = {}, {}
    if os.path.exists(out):
        for l in open(out, errors="replace"):
            p = l.rstrip("\n").split("\t")
            if p[0] == "S" and len(p) >= 3: started[int(p[1])] = p[2]
            elif p[0] == "R" and len(p) >= 3: done[int(p[1])] = p[2]
    return started, done

def run_chunk(key):
    name = "__".join(key).replace("|", "_")
    idl = chunks[key]
    idfile = os.path.join(outdir, name + ".ids"); out = os.path.join(outdir, name + ".out")
    open(idfile, "w").write("\n".join(idl) + "\n")
    start = 1
    # resume support: skip cells already resulted
    _, done = parse(out)
    while start in done: start += 1
    attempts = 0
    while start <= len(idl):
        attempts += 1
        if attempts > len(idl) + 5: break
        p = subprocess.Popen(cmd(idfile, start, out), env=env, stdout=open(out + ".stdout", "a"), stderr=subprocess.STDOUT,
                             start_new_session=True)
        last_size, last_change = -1, time.time()
        killed_for = None
        while p.poll() is None:
            time.sleep(2)
            sz = os.path.getsize(out) if os.path.exists(out) else 0
            if sz != last_size: last_size, last_change = sz, time.time()
            elif time.time() - last_change > cell_timeout:
                try: os.killpg(p.pid, signal.SIGKILL)
                except ProcessLookupError: pass
                p.wait(); killed_for = "TIMEOUT"; break
        started, done = parse(out)
        nxt = start
        while nxt in done: nxt += 1
        if nxt > len(idl):
            start = nxt; break
        # cell `nxt` was started but not finished
        cid = idl[nxt - 1]
        if killed_for == "TIMEOUT":
            row = ("TIMEOUT", "watchdog", "no result after %ds" % cell_timeout, "no result after %ds" % cell_timeout, "", "", "", "", "")
        else:
            rc = p.returncode
            row = ("PROCESS_DIED", "exit" + str(rc), "runner process died (exit code %s) while fitting this cell" % rc, "", "", "", "", "", "")
            if nxt not in started:  # died before reaching this cell (load failure): stop to avoid a loop
                row = ("RUNNER_ERROR", "startup", "runner died at startup (exit %s)" % rc, "", "", "", "", "", "")
        with open(out, "a") as f:
            f.write("S\t%d\t%s\n" % (nxt, cid))
            f.write("R\t%d\t%s\t%s\n" % (nxt, cid, "\t".join(row)))
        say("%s: cell %d %s -> %s" % (name, nxt, cid, row[0]))
        start = nxt + 1
    say("chunk done " + name)

def worker():
    while True:
        try: key = work.get_nowait()
        except queue.Empty: return
        try: run_chunk(key)
        except Exception as e: say("chunk failed %s: %r" % (key, e))

say("start engine=%s workers=%d cells=%d chunks=%d" % (engine, workers, len(ids), len(chunks)))
ts = [threading.Thread(target=worker) for _ in range(workers)]
for t in ts: t.start()
for t in ts: t.join()
say("all done")
