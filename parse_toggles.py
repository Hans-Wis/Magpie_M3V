import re
from collections import defaultdict

uncovered = defaultdict(set)
with open('csr_uncovered_toggles.txt', 'r') as f:
    for line in f:
        match = re.search(r'o([^\[:]+)(?:\[(\d+)\])?(?::(\d+)->(\d+))?', line)
        if match:
            sig = match.group(1)
            bit = match.group(2)
            if bit is None:
                bit = 0
            else:
                bit = int(bit)
            uncovered[sig].add(bit)

for sig in sorted(uncovered.keys()):
    bits = sorted(list(uncovered[sig]))
    # Group bits into ranges
    ranges = []
    if not bits:
        continue
    start = bits[0]
    prev = bits[0]
    for i in range(1, len(bits)):
        if bits[i] == prev + 1:
            prev = bits[i]
        else:
            if start == prev:
                ranges.append(f"{start}")
            else:
                ranges.append(f"{start}:{prev}")
            start = bits[i]
            prev = bits[i]
    if start == prev:
        ranges.append(f"{start}")
    else:
        ranges.append(f"{start}:{prev}")
    print(f"{sig}: {', '.join(ranges)}")
