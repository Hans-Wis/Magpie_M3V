#!/usr/bin/env python3
"""cq_host — ADR-0043: host-side CQ ring producer ABI (Coral libedgetpu role).

RING_OVERRUN is prevented by PRODUCER DISCIPLINE (ADR-0035 kept device-side
detection deferred): the producer never lets TAIL advance onto HEAD. This
module is the reference implementation of that contract:

  free entries = (HEAD - TAIL - 1) mod SIZE     (one slot always kept empty)
  push(descs)  -> refuses (CqFull) unless all descriptors fit
  commit()     -> fence_hook() FIRST (cache flush / memory barrier on a real
                  host: descriptors+payload must be visible to the NPU DMA
                  BEFORE the doorbell), THEN the TAIL doorbell write.

The mem/reg accessors are injected so the same producer drives a DV harness
(python model), a TB backdoor, or /dev/mem on silicon.
"""
from __future__ import annotations


class CqFull(Exception):
    pass


class CqProducer:
    def __init__(self, size, read_head, write_tail, write_slot, fence_hook=None):
        assert size and (size & (size - 1)) == 0, "ring size must be 2^n"
        self.size = size
        self._read_head = read_head
        self._write_tail = write_tail
        self._write_slot = write_slot
        self._fence = fence_hook or (lambda: None)
        self.tail = 0
        self._staged = 0
        self._log = []

    def free_entries(self):
        return (self._read_head() - self.tail - 1) % self.size

    def push(self, descs):
        """descs: list of 4-word descriptors. All-or-nothing; CqFull if not."""
        n = len(descs)
        if n > self.free_entries() - self._staged:
            raise CqFull(f"need {n}, free {self.free_entries() - self._staged}")
        for d in descs:
            assert len(d) == 4
            slot = (self.tail + self._staged) % self.size
            self._write_slot(slot, d)
            self._staged += 1
            self._log.append(("slot", slot))
        return n

    def commit(self):
        """fence -> doorbell. Returns the new TAIL."""
        self._fence()
        self._log.append(("fence",))
        self.tail = (self.tail + self._staged) % self.size
        self._staged = 0
        self._write_tail(self.tail)
        self._log.append(("doorbell", self.tail))
        return self.tail
