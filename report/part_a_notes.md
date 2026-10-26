# Part A evidence

## Hand multiplication example

Het Selarka's roll number ends in 1, so the specified example is A = 1 + 5 = 6 and B = 7.

```text
               0 1 1 0       A = 6
             x 0 1 1 1       B = 7
       ---------------
               0 1 1 0       pp0 = A AND b0 (b0 = 1)
             0 1 1 0         pp1 = A AND b1 (b1 = 1), shifted 1
           0 1 1 0           pp2 = A AND b2 (b2 = 1), shifted 2
         0 0 0 0             pp3 = A AND b3 (b3 = 0), shifted 3
       ---------------
       0 0 1 0 1 0 1 0       P = 42
```

The same multiplication worked through the array, row by row:

| Row | What it adds | Sum, carry out | Product bit | Passed to next row |
|-----|--------------|----------------|-------------|--------------------|
| 0 | PP0 = 0110 (AND gates only) | - | P0 = 0 | 0011 |
| 1 | PP1 = 0110 + 0011 | sum 1001, carry 0 | P1 = 1 | 0100 |
| 2 | PP2 = 0110 + 0100 | sum 1010, carry 0 | P2 = 0 | 0101 |
| 3 | PP3 = 0000 + 0101 | sum 0101, carry 0 | P3 = 1 | P7..P4 = 0010 |

In each row the lowest sum bit is a finished product bit; the other three sum bits and the carry
out move down to the next row. P = 0010 1010 = 42 = 6 x 7.

## Block diagram

`report/block_diagram.png` shows every gate: the 8 input
flip-flops (a3..a0, b3..b0), the 16 AND gates, the 12 full adders FA10 to FA33 with their carry
chains and diagonal sum connections, and the 8 output flip-flops p7..p0.

The two registers contain 16 flip-flops in total. The inputs are captured at one rising edge and
the product is captured at the next rising edge, giving a latency of two clock cycles.

## Waveform (6 x 7)

In the testbench, A = 6 and B = 7 are applied at 2090 ns (on a falling edge). They are captured
into the input register at the rising edge at 2095 ns (edge 1), and the output P changes from 36
to 42 at the next rising edge, 2105 ns (edge 2). So the latency is 2 clock edges.

### Why P usually shows the previous product in the waveform

When reading the waveform, P most of the time looks like A x (B - 1) instead of A x B, for
example a = 6, b = 5 next to p = 24. This is not an error; it is the 2-cycle latency.

The testbench holds each input pair for 20 ns (two clock cycles). The pair is captured at the
first rising edge (5 ns after it is applied) and the product reaches the output register at the
second rising edge (15 ns after it is applied). So for the first 15 ns of every pair, P still
holds the product of the previous pair, and because B counts up by one, that looks like
A x (B - 1). Only in the last 5 ns, between the second rising edge and the next input change, do
A, B and P on the screen belong to the same multiplication (2105 ns to 2110 ns for 6 x 7).

We checked this on all 239 changes of P in mult.vcd: every value equals A x B of the inputs
captured at the previous rising edge. The testbench does the same check at the right moment for
all 256 pairs, and the fault test above shows that it does catch real errors.

`gtkwave report/mult_6x7.gtkw` (run from the repository root after `vvp sim`) opens this part of
the waveform with clk, rst_n, a, b and p shown in decimal, with marker A on edge 1 and marker B on
edge 2.

## Verification

```sh
iverilog -g2012 -Wall -s tb_mult -o sim rtl/full_adder.v rtl/mult_array.v tb/tb_mult.v && vvp sim
```

Result: `PASS: 256 vectors checked, 0 errors`.

The waveform is written to `mult.vcd`; inspect the 6 x 7 transaction in GTKWave and mark the
two-cycle interval from input capture to product capture for the report screenshot.
