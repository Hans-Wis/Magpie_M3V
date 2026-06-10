import re
import sys

def parse_info(info_file, target_files):
    stats = {}
    current_file = None
    for line in open(info_file):
        line = line.strip()
        if line.startswith("SF:"):
            current_file = None
            for target in target_files:
                if target in line:
                    current_file = target
                    if current_file not in stats:
                        stats[current_file] = {'total': 0, 'hit': 0, 'uncovered': []}
                    break
        elif current_file and line.startswith("DA:"):
            parts = line[3:].split(',')
            lineno = int(parts[0])
            hits = int(parts[1])
            stats[current_file]['total'] += 1
            if hits > 0:
                stats[current_file]['hit'] += 1
            else:
                stats[current_file]['uncovered'].append(lineno)
    return stats

def parse_dat(dat_file, target_files):
    stats = {}
    # C 'fpathllinennodettogglepage...osignal:0->1hhier' 1
    for line in open(dat_file):
        if not line.startswith("C '"): continue
        match = re.search(r"f([^]+).*ttoggle.*o([^]+).*' (\d+)", line)
        if match:
            path, signal, hits = match.groups()
            hits = int(hits)
            current_file = None
            for target in target_files:
                if target in path:
                    current_file = target
                    break
            if current_file:
                if current_file not in stats:
                    stats[current_file] = {'total': 0, 'hit': 0, 'uncovered': []}
                stats[current_file]['total'] += 1
                if hits > 0:
                    stats[current_file]['hit'] += 1
                else:
                    stats[current_file]['uncovered'].append(signal)
    return stats

targets = ["idu.v", "cdec.v", "csr.v", "ras.v", "bp.v", "ifu.v"]
info_stats = parse_info("combined.info", targets)

import glob

def parse_dat_multi(target_files):
    stats = {}
    dat_files = glob.glob("flow/v2_pipeline/phase_04_*/coverage.dat")
    for dat_file in dat_files:
        for line in open(dat_file):
            if not line.startswith("C '"): continue
            match = re.search(r"f([^]+).*ttoggle.*o([^]+).*' (\d+)", line)
            if match:
                path, signal, hits = match.groups()
                hits = int(hits)
                current_file = None
                for target in target_files:
                    if target in path:
                        current_file = target
                        break
                if current_file:
                    if current_file not in stats:
                        stats[current_file] = {}
                    if signal not in stats[current_file]:
                        stats[current_file][signal] = 0
                    stats[current_file][signal] += hits
    
    final_stats = {}
    for f, signals in stats.items():
        total = len(signals)
        hit = sum(1 for h in signals.values() if h > 0)
        uncovered = [s for s, h in signals.items() if h == 0]
        final_stats[f] = {'total': total, 'hit': hit, 'uncovered': uncovered}
    return final_stats

targets = ["idu.v", "cdec.v", "csr.v", "ras.v", "bp.v", "ifu.v"]
info_stats = parse_info("combined.info", targets)
dat_stats = parse_dat_multi(targets)

print("--- Line Coverage ---")
for f in targets:
    s = info_stats.get(f, {'total': 0, 'hit': 0, 'uncovered': []})
    print(f"{f}: {s['hit']}/{s['total']} ({s['hit']/s['total']*100:.1f}%) Uncovered: {s['uncovered'][:10]}")

print("\n--- Toggle Coverage ---")
for f in targets:
    s = dat_stats.get(f, {'total': 0, 'hit': 0, 'uncovered': []})
    total = s['total']
    if total > 0:
        print(f"{f}: {s['hit']}/{total} ({s['hit']/total*100:.1f}%) Uncovered: {s['uncovered'][:10]}")
    else:
        print(f"{f}: No data")
