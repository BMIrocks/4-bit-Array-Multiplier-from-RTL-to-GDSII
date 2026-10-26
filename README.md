# 4-bit Array Multiplier: RTL to GDSII

## Team

- Name: Het Selarka
  Roll number: 2024102031
- Name: Shrenil Patel
  Roll number: 2024102066

## Part 0 setup log

Repository skeleton created with the required `rtl/`, `tb/`, `synth/`, `sta/`, `pnr/`, and `report/` directories.

We used the official LibreLane Docker image instead of IIC-OSIC-TOOLS (low disk
space and a slow network made the 4 GB image impractical). It contains the same
tools: Yosys, OpenSTA, OpenROAD, Magic, Netgen, KLayout and Icarus Verilog.

```sh
# LibreLane launcher and the SKY130 PDK (version pinned by LibreLane 2.4.13)
python3 -m venv ~/.venvs/librelane
~/.venvs/librelane/bin/pip install librelane==2.4.13
~/.venvs/librelane/bin/ciel enable --pdk-family sky130 0fe599b2afb6708d281543108caf8310912f54af
docker pull ghcr.io/librelane/librelane:2.4.13
```

Tools are run inside the container through a small wrapper `~/.local/bin/eda`
that mounts the current folder and the PDK and sets `PDK_ROOT=~/.ciel`, `PDK=sky130A`:

```sh
docker run --rm -it -u "$(id -u):$(id -g)" \
  -v "$HOME/.ciel:$HOME/.ciel" -e PDK_ROOT="$HOME/.ciel" -e PDK=sky130A \
  -v "$PWD:$PWD" -w "$PWD" ghcr.io/librelane/librelane:2.4.13 "$@"
```

Tool check (`eda bash`, then):

```sh
iverilog -V | head -1      # Icarus Verilog 12.0
yosys -V                   # Yosys 0.46
sta -version               # 2.6.0
echo $PDK_ROOT $PDK        # /home/het/.ciel sky130A
```

LibreLane smoke test: `~/.venvs/librelane/bin/librelane --dockerized --pdk-root ~/.ciel --smoke-test`

## Part A verification log

```sh
iverilog -g2012 -Wall -s tb_mult -o sim rtl/full_adder.v rtl/mult_array.v tb/tb_mult.v && vvp sim
```

Result: `PASS: 256 vectors checked, 0 errors`.

Waveform of the 6 x 7 example (A = last digit of Het's roll number + 5 = 6, B = 7):

```sh
gtkwave report/mult_6x7.gtkw     # opens mult.vcd with markers on the two clock edges
```

Fault test: `assign sum = a ^ b ^ cin;` in `rtl/full_adder.v` was temporarily changed to
`assign sum = a ^ b;`, the same simulation command was run again, and the change was undone.

Result: `FAIL: 256 vectors checked, 95 errors` (recorded in `report/error_injection.log`).

## Part B synthesis commands

Run from the repository root inside the container (`eda bash`):

```sh
yosys -c synth/synth.tcl
CELLS=$PDK_ROOT/sky130A/libs.ref/sky130_fd_sc_hd/verilog
iverilog -g2012 -DFUNCTIONAL -DUNIT_DELAY=#1 -o gls tb/tb_mult.v \
  $CELLS/primitives.v $CELLS/sky130_fd_sc_hd.v synth/mult_array_netlist.v
vvp gls
```

Result: 65 cells, 16 flip-flops, 751.97 µm², netlist simulation
`PASS: 256 vectors checked, 0 errors`.

The first netlist run failed (239 errors) because the testbench checked P 1 ns after the
clock edge, the same instant the flip-flop models (1 ns delay) update. The check was moved
to 4 ns after the edge; RTL simulation, netlist simulation and the fault test were re-run.
Details in `report/part_b_notes.md`.

## Part C static timing analysis commands

Run from the repository root inside the container (`eda bash`):

```sh
sta sta/sta.tcl                 # T = 10 ns: worst slack 7.324 ns
PERIOD=2.68 sta sta/sta.tcl     # T = Tmin: worst slack 0.004 ns
sta sta/sta.tcl                 # back to T = 10 ns so the saved report is the 10 ns one
```

Tmin = 10 - 7.324 = 2.676 ns, Fmax = 373.7 MHz. Critical path: b0 input flip-flop to p6
output flip-flop, 9 cells. Details in `report/part_c_notes.md`.

## Part D place and route commands

Run inside the container (`eda bash`):

```sh
cd pnr
librelane config.json
```

CLOCK_PERIOD started at 1.2 x Tmin = 3.21 ns, rounded up to 3.5 ns, and was raised by 0.5 ns
after every run that failed setup timing (worst corner, `timing__setup__ws`):

| Run | Folder | CLOCK_PERIOD (ns) | Setup slack (ns) | DRC | LVS | Result |
|-----|--------|-------------------|------------------|-----|-----|--------|
| 1 | RUN_2026-10-26_15-09-20 | 3.5 | -1.617 | 0 | 0 | fail |
| 2 | RUN_2026-10-26_15-11-17 | 4.0 | -1.107 | 0 | 0 | fail |
| 3 | RUN_2026-10-26_15-12-54 | 4.5 | -0.638 | 0 | 0 | fail |
| 4 | RUN_2026-10-26_15-14-31 | 5.0 | -0.106 | 0 | 0 | fail |
| 5 | RUN_2026-10-26_15-15-59 | 5.5 | 0.120 | 0 | 0 | pass |

```sh
cp runs/RUN_2026-10-26_15-15-59/final/metrics.json .
cp runs/RUN_2026-10-26_15-15-59/final/gds/mult_array.gds .
```

Layout viewing (outside the container; `layout` is a small wrapper that runs KLayout from
the same image with the SKY130 layer colours):

```sh
layout pnr/mult_array.gds
```

Details in `report/part_d_notes.md`.

## Report

```sh
cd report
pdflatex report.tex && pdflatex report.tex     # builds report/report.pdf
```

The GTKWave screenshot of the 6 x 7 example is `report/waveform_6x7.png`.
