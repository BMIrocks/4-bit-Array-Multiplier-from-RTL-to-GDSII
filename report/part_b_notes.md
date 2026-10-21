# Part B evidence

## Synthesis

```sh
yosys -c synth/synth.tcl
```

Outputs: `synth/mult_array_netlist.v` and `synth/mult_array_stat.rpt`.

## Results table

| Metric | Value |
|--------|-------|
| Total number of cells | 65 |
| Number of flip-flops | 16 (sky130_fd_sc_hd__dfrtp_1) |
| Total cell area (µm²) | 751.97 |
| Flip-flop area (µm²) | 16 x 25.024 = 400.38 |
| Flip-flop area (% of total) | 53.24 % |
| The 3 most-used cell types and their counts | dfrtp_1: 16, nand2_1: 7, then a four-way tie at 5 each: a21oi_1, nor2_1, xnor2_1, xor2_1 |
| Netlist simulation result | PASS: 256 vectors checked, 0 errors |

Full cell list from the report:

| Cell | Count | Cell | Count |
|------|-------|------|-------|
| dfrtp_1 (D flip-flop, async reset) | 16 | maj3_1 (majority of 3) | 4 |
| nand2_1 | 7 | a22oi_1 | 3 |
| a21oi_1 | 5 | and4_1 | 3 |
| nor2_1 | 5 | and2_0 | 2 |
| xnor2_1 | 5 | nor3_1 | 2 |
| xor2_1 | 5 | xnor3_1 | 2 |
| lpflow_isobufsrc_1 | 2 | a211oi_1, nand3_1, o21a_1, o21ai_0 | 1 each |

So the logic (everything except the flip-flops) is 65 - 16 = 49 cells.

Notes on the result:

- None of the 12 full adders survives as a block. `synth -flatten` removes the full adder
  module boundaries, and ABC then rebuilds the whole AND array + adder network from scratch with
  the gates it finds cheapest. ABC also reports that it ignores multi-output cells such as the
  library full adder `sky130_fd_sc_hd__fa_1`, so it could never use one even if it wanted to.
- The full adder functions are still visible in the cell mix: maj3 is exactly a carry
  (majority of three inputs), and xor2/xnor2/xnor3 build the sum bits.
- `lpflow_isobufsrc_1` is a cell from the low-power group of the library (an isolation buffer,
  logically A AND NOT B). ABC picked it simply because it implements that function in one cell.
  The LibreLane flow in Part D blocks these cells, so they will not appear there.

## Gate-level simulation

```sh
CELLS=$PDK_ROOT/sky130A/libs.ref/sky130_fd_sc_hd/verilog
iverilog -g2012 -DFUNCTIONAL -DUNIT_DELAY=#1 -o gls tb/tb_mult.v \
  $CELLS/primitives.v $CELLS/sky130_fd_sc_hd.v synth/mult_array_netlist.v
vvp gls
```

Result: `PASS: 256 vectors checked, 0 errors`.

### Problem found and fixed

The first netlist simulation printed `FAIL: 256 vectors checked, 239 errors`, while the RTL
simulation passed. Every wrong value was the product of the previous input pair (for example
a = 15, b = 15 gave 210 = 15 x 14).

Cause: with `-DUNIT_DELAY=#1` every flip-flop cell model has a 1 ns clock-to-output delay, so P
changes 1 ns after the rising edge. The testbench originally checked P exactly 1 ns after the edge
(`#1`), at the same instant, and the simulator read P before it updated. In RTL the flip-flops
have no delay, so the same check worked there.

Fix: the testbench now checks 4 ns after the second rising edge. That is after the 1 ns cell delay
and still before the inputs change at the next falling edge (5 ns after the rising edge). After
the change, RTL and netlist simulation both print PASS, and the full adder fault test still prints
`FAIL: 256 vectors checked, 95 errors`, so the testbench still detects real errors. The design
itself was not changed.
