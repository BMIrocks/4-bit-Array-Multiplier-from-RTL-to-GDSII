# Part D evidence

## Command

```sh
cd pnr
librelane config.json
```

Each run writes `pnr/runs/RUN_<date>_<time>/`. The final GDS and metrics were copied from
`runs/RUN_2026-10-26_15-15-59/final/` to `pnr/mult_array.gds` and `pnr/metrics.json`.

## Clock period and runs

Starting value: 1.2 x Tmin = 1.2 x 2.676 = 3.21 ns, rounded up to the next 0.5 ns = 3.5 ns.

LibreLane checks timing at three process corners: typical (tt, 25 °C, 1.80 V), slow (ss, 100 °C,
1.60 V) and fast (ff, -40 °C, 1.95 V). The overall setup slack `timing__setup__ws` in metrics.json
is the worst of all corners, which is always the slow corner here. We used that value for the
"setup slack >= 0" rule and raised the clock period by 0.5 ns after every failing run:

| Run | Folder | CLOCK_PERIOD (ns) | Setup slack, worst corner (ns) | Setup slack, typical corner (ns) | DRC | LVS | Result |
|-----|--------|-------------------|-------------------------------|----------------------------------|-----|-----|--------|
| 1 | RUN_2026-10-26_15-09-20 | 3.5 | -1.617 | 0.808 | 0 | 0 | setup fails |
| 2 | RUN_2026-10-26_15-11-17 | 4.0 | -1.107 | 1.257 | 0 | 0 | setup fails |
| 3 | RUN_2026-10-26_15-12-54 | 4.5 | -0.638 | 1.797 | 0 | 0 | setup fails |
| 4 | RUN_2026-10-26_15-14-31 | 5.0 | -0.106 | 2.309 | 0 | 0 | setup fails |
| 5 | RUN_2026-10-26_15-15-59 | 5.5 | 0.120 | 2.693 | 0 | 0 | passes (final) |

Every run was DRC and LVS clean; only setup timing at the slow corner failed. At the typical corner
(the one used in Part C) the first run at 3.5 ns already had positive slack.

## Results table

| Metric | Value |
|--------|-------|
| CLOCK_PERIOD used (ns) | 5.5 |
| Number of runs needed | 5 |
| Core area (µm²) | 17 759.5 (die area 150 x 150 = 22 500) |
| Cells after synthesis (from Part B) | 65 |
| Cells after place and route | 340 (`design__instance__count`; plus 1 559 fill and decap cells that are not counted there, 1 899 in total) |
| Kinds of cells added | tap cells, buffers (clock tree and timing repair), decap cells, fill cells |
| Wirelength (µm) | 2 571 |
| Setup slack (ns) | 0.120 (worst corner, slow); 2.693 at the typical corner |
| Post-route Fmax (MHz) | 1000 / (5.5 - 0.120) = 185.9 (worst corner); 1000 / (5.5 - 2.693) = 356.3 (typical corner) |
| Fmax from Part C (MHz) | 373.7 (typical corner, no wires) |
| DRC errors | 0 (Magic 0, KLayout 0, router 0) |
| LVS errors | 0 |

Other checks in the final run: antenna check passed, no max slew / max capacitance / max fanout
violations, hold slack positive at every corner (worst 0.129 ns).

## Post-route Fmax compared with Part C

To compare like with like, use the typical corner, the only corner Part C looked at:
356.3 MHz after routing against 373.7 MHz before, about 5 % lower. The reasons:

- Part C had no wires at all. After routing every net has real resistance and capacitance
  (extracted from the layout), so every gate drives a heavier load and switches more slowly.
- The clock is no longer ideal: it goes through a clock tree of buffers, so it arrives at the
  flip-flops with some skew.
- LibreLane runs its own synthesis (71 cells instead of our 65, different gate choices) and then
  resizes and buffers the netlist, so the critical path is not exactly the same one as in Part C.

The worst-corner figure, 185.9 MHz, is about half of the Part C value. That drop is mostly not
caused by the layout: slow transistors at 100 °C and 1.6 V are much slower than typical ones at
25 °C and 1.8 V. A chip has to work at all corners, which is why the flow signs off on the worst one
and why the clock period had to go up to 5.5 ns.

## Cell count after synthesis and after place and route

The flow's own synthesis gives 71 cells (16 flip-flops + 55 logic), 6 more than our Part B script,
because LibreLane uses a different ABC script and excludes some cells (for example the low-power
`lpflow` cells our Part B result used). The 340 placed cells break down as:

| Kind | Count | Cell names | Why it is needed |
|------|-------|-----------|------------------|
| Flip-flops | 16 | dfrtp_1 (9), dfrtp_2 (2), dfrtp_4 (5) | the design itself; some were upsized for timing |
| Logic gates | 55 | a21o, and3, xnor2, nand2, ... | the design itself |
| Tap cells | 245 | tapvpwrvgnd_1 | connect the n-well and substrate to VPWR/VGND at regular intervals to prevent latch-up |
| Clock tree buffers | 4 | clkbuf_16, clkbuf_4 | drive the clock to all 16 flip-flops with low skew |
| Timing repair / input-output buffers | 20 | buf_1, buf_2, clkbuf_1 | isolate the input and output pins, fix slew and load, speed up slow nets |

Added on top, not included in the 340:

| Kind | Count | Cell names | Why it is needed |
|------|-------|-----------|------------------|
| Decap cells | 1 295 | decap_3/4/6/8 (391), ef decap_12 (904) | small capacitors between VPWR and VGND that keep the supply steady when many gates switch at once |
| Fill cells | 264 | fill_1 (219), fill_2 (45) | fill the remaining gaps so every row is continuous (wells and power rails must not have breaks) |

The die is very small but still mostly empty: the cells use only 7.2 % of the core area, which is
why there are so many decap and fill cells.

## Warnings in the flow log (checked, harmless)

- 441 lint warnings: all are `TIMESCALEMOD`, because our RTL files have a `timescale` line and the
  library's empty cell models do not. No effect on the result.
- No SDC file given: the flow uses its default constraints built from CLOCK_PORT and CLOCK_PERIOD.
- IR drop: no voltage source location given; only matters when building a full chip.

## Tools used by the flow

Yosys (synthesis), OpenROAD (floorplan, placement, clock tree, routing, extraction, timing),
Magic (DRC, GDS stream-out, extraction for LVS), KLayout (DRC, GDS stream-out and XOR check),
Netgen (LVS).
