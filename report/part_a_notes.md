# Part A evidence

## Hand multiplication example

Het Selarka's roll number ends in 1, so the specified example is A = 1 + 5 = 6 and B = 7.

```text
      0110  (6)
x     0111  (7)
------------
      0110  (A AND b[0], shifted 0)
     0110   (A AND b[1], shifted 1)
    0110    (A AND b[2], shifted 2)
   0000     (A AND b[3], shifted 3)
------------
  00101010  (42)
```

## Block diagram

```text
 a[3:0], b[3:0]
        |
        v
+------------------+       +-----------------------------------------+       +------------------+
| Input registers  | ----> | 16 AND gates + three rows of 4 FAs      | ----> | Output register  |
| 4 FFs for a      |       | Row 1: 4 FAs, Row 2: 4 FAs,             |       | 8 FFs for p      |
| 4 FFs for b      |       | Row 3: 4 FAs (12 full adders total)    |       |                  |
+------------------+       +-----------------------------------------+       +------------------+
```

The two register banks contain 16 flip-flops in total. Inputs are captured at one rising edge and
the corresponding product is captured at the following rising edge, giving a two-cycle latency.

## Verification

```sh
iverilog -g2012 -Wall -s tb_mult -o sim rtl/full_adder.v rtl/mult_array.v tb/tb_mult.v && vvp sim
```

Result: `PASS: 256 vectors checked, 0 errors`.

The waveform is written to `mult.vcd`; inspect the 6 x 7 transaction in GTKWave and mark the
two-cycle interval from input capture to product capture for the report screenshot.
