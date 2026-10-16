# 4-bit Array Multiplier: RTL to GDSII

## Team

- Name: Het Selarka
  Roll number: 2024102031
- Name: Shrenil Patel
  Roll number: 2024102061

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

The deliberate full-adder fault test and its failing result are recorded in
`report/error_injection.log`.
