# Phase 3.15 Branch-Predictor 2-Way (way1) Directed Lockstep Report

Status: pass

Result: bp_way1 full lockstep matched 102 commits (102 commits)

Deterministic aliasing-branch loop (brA@0x100 tag2 / brB@0x180 tag3, same BTB set 0) -> fills both predictor ways. FULL per-commit Spike lockstep (no trap). The --coverage island toggles the way1 read/predict path (rd_hit1 / predict_from_way1) that the random farm leaves cold.
