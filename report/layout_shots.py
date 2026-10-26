# Render the two Part D layout screenshots with KLayout (batch mode, no window).
# Run from the repository root inside the container:
#   klayout -zz -r report/layout_shots.py
import os
import pya

pdk = os.environ.get("PDK_ROOT", os.path.expanduser("~/.ciel")) + "/sky130A/libs.tech/klayout/tech/"

view = pya.LayoutView()
view.load_layout("pnr/mult_array.gds", True)
view.load_layer_props(pdk + "sky130A.lyp")
view.set_config("background-color", "#ffffff")
view.set_config("text-visible", "false")   # hide the net names, they cover everything
view.max_hier()

# 1) whole die
view.zoom_fit()
view.save_image("report/layout_full_die.png", 1600, 1600)

# 2) zoomed in on the logic: standard cell rows and metal wires (coordinates in µm)
view.zoom_box(pya.DBox(42, 62, 70, 86))
view.save_image("report/layout_zoom.png", 1600, 1371)
