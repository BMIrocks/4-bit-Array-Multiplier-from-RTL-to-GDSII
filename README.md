# 4-bit Array Multiplier: RTL to GDSII

## Team

- Name: Het Selarka
  Roll number: 2024102031
- Name: Shrenil Patel
  Roll number: 2024102061

## Part 0 setup log

Repository skeleton created with the required `rtl/`, `tb/`, `synth/`, `sta/`, `pnr/`, and `report/` directories.

Environment validation is pending access to the IIC-OSIC-TOOLS Docker container. The required commands are:

```sh
iverilog -V | head -1
yosys -V
sta -version
echo $PDK_ROOT $PDK
```

## Part A verification log

```sh
iverilog -g2012 -Wall -s tb_mult -o sim rtl/full_adder.v rtl/mult_array.v tb/tb_mult.v && vvp sim
```

Result: `PASS: 256 vectors checked, 0 errors`.

The deliberate full-adder fault test and its failing result are recorded in
`report/error_injection.log`.
