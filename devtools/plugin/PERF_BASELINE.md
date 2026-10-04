# Plugin perf baseline (post module split)

Recorded 2026-10-04 right after the `vex/*.inc` module split (commit 613e5e2) was verified
equivalent to the pre-split single file (bca944c). Use it to spot regressions: re-run the same
command and compare.

## Command

```
VEX_SERVER=<serverE> python3 devtools/server/run_test.py --port 27095 --map zm_vex_laboratory \
  --seconds 300 --bots 31 --commands devtools/server/sessions/full_session.txt --no-debug --no-rebuild \
  --cmd "30 stats" --cmd "60 stats" ... --cmd "300 stats"
```

Host: 4 vCPU Intel Xeon @ 2.80 GHz, headless HLDS (ReHLDS/ReGameDLL + ReAPI, AMXX 1.10),
maxplayers 32, server default fps (~100). Process sampled with `ps` every 5 s.

## Results

| metric | value |
|---|---|
| server `stats` FPS (9 samples, t=30..270 s) | avg 97.5, min 91.7, max 100.9 |
| server `stats` CPU % | 9.0 - 11.0 (avg 10.0) |
| hlds_linux CPU time after 300 s | 32 s (~10.7 % of one core) |
| hlds_linux RSS | 61.7 MB (flat: 61716 -> 61732 KB) |
| entities (vexprobe) | max 426, typical 370-417 |
| gameplay | 7 rounds, 30 kills, 57 infections, bosses/nemesis/hivequeen rounds included |
| AMXX run-time errors / FATAL / crash | 0 / 0 / no |

Plugin build: 312251 bytes, 0 errors / 0 warnings (code 890008, data 485124 bytes).

## Notes

- `--no-debug` loads the plugin without the AMXX debug flag, so the harness' per-forward
  timing table (`max ... ms`) is not produced; for that use a debug run. Debug run reference
  (480 s, 16 bots, full_session): worst forwards plugin_cfg 7.2 ms (1x), task_LoadConfig 7.0 ms
  (1x), fw_CmdStart 2.4 ms, task_Tick 2.0 ms.
- Bots are the dominant CPU cost at 31 players; FPS dips (~92) line up with mass-infection /
  round transitions.
