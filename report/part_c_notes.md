# Part C evidence

## Commands

```sh
sta sta/sta.tcl                 # T = 10 ns (default in the script)
PERIOD=2.68 sta sta/sta.tcl     # re-run at T = Tmin
```

The clock period is a variable in `sta.tcl` (10 ns unless `PERIOD` is set). The saved report
`sta/mult_array_timing.rpt` is from the T = 10 ns run.

## Maximum frequency

- At T = 10 ns the worst setup slack is WNS = 7.324 ns.
- Tmin = T - WNS = 10 - 7.324 = 2.676 ns
- Fmax = 1000 / 2.676 = 373.7 MHz
- Re-run at T = 2.68 ns (Tmin rounded to 0.01 ns): worst slack = 0.004 ns, so the result checks
  out.

## Results table

| Metric | Value |
|--------|-------|
| Worst slack at T = 10 ns (ns) | 7.324 |
| Tmin (ns) | 2.676 (2.68 rounded) |
| Fmax (MHz) | 373.7 |
| Slack at T = Tmin (ns) | 0.004 (at T = 2.68 ns) |
| Critical path start point | input register flip-flop for b0 (clock pin) |
| Critical path end point | output register flip-flop for p6 (D pin) |
| Number of cells on the critical path | 9: the launching flip-flop + 8 logic gates (the capturing flip-flop p6 is the end point) |
| Latency (ns) = 2 x Tmin | 5.35 |
| Throughput (million results per second) | 373.7 (one result per clock cycle) |

## Cells on the critical path

From `sta/mult_array_timing.rpt` (T = 10 ns run):

| # | Cell | Delay (ns) | Arrival (ns) | What it computes | From full adder |
|---|------|-----------|--------------|------------------|-----------------|
| 1 | dfrtp_1 | 0.386 | 0.386 | b0 input flip-flop, clock to Q | - |
| 2 | and4_1 | 0.251 | 0.638 | a0b1 AND a1b0 = carry out of FA10 | FA10 (with its 2 AND gates) |
| 3 | nor3_1 | 0.217 | 0.855 | carry out of FA11 (first half) | FA11 |
| 4 | o21ai_0 | 0.173 | 1.028 | carry out of FA11 (second half) | FA11 |
| 5 | maj3_1 | 0.404 | 1.431 | carry out of FA12 | FA12 |
| 6 | xnor2_1 | 0.166 | 1.598 | sum of FA13 | FA13 |
| 7 | maj3_1 | 0.389 | 1.987 | carry out of FA22 | FA22 |
| 8 | maj3_1 | 0.380 | 2.367 | carry out of FA23 | FA23 |
| 9 | xnor3_1 | 0.175 | 2.542 | sum of FA33 = P6 | FA33 |
| | (p6 flip-flop) | setup 0.134 | | end point | - |

Arrival 2.542 ns + setup 0.134 ns = 2.676 ns = Tmin.

We matched each gate to a full adder by checking its inputs in the netlist: a maj3 cell is exactly
a full adder carry (majority of three), and an xnor2/xnor3 cell is a sum.

## Comparison with the 2N estimate

All 8 logic gates on the path come from full adders (the AND gates for FA10 are merged into the
and4 cell). They cover 7 full adder stages:

FA10 -> FA11 -> FA12 -> FA13 (whole carry chain of row 1, ending in its top sum bit)
-> FA22 -> FA23 (carry chain of row 2) -> FA33 (top sum bit of row 3).

That is 7 full adder delays against the estimate of about 2N = 8. The estimate is only
approximate, and it is a bit pessimistic here because:

- the first adder in each row has carry-in 0, so it is really a half adder; FA10 collapses into a
  single and4 gate, which also absorbs the partial product AND gates;
- after flattening, ABC rebuilds the logic with complex gates (maj3, xnor3, o21ai) instead of a
  fixed two-level full adder, so one full adder stage costs one or two gates.

Not every stage costs the same either: carry cells (maj3, about 0.38-0.40 ns) are the slowest, which
is why the longest path is the one that travels along carry chains.

## Other path in the report

The report also lists the reset path (rst_n to the asynchronous reset pin of a flip-flop,
"recovery check"). It has a lot of slack (9.228 ns at T = 10 ns) and does not limit the clock.
