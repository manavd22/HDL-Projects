########################################################################
# 2026 AISSM Summer Course
# TASAD Flag-10 dual-clock constraints
########################################################################

# Keep these periods consistent with sim/clock_config.vh.
set CLK1_PERIOD 640.0
set CLK2_PERIOD 10.0

create_clock -name clk1 -period $CLK1_PERIOD [get_ports clk1]
create_clock -name clk2 -period $CLK2_PERIOD [get_ports clk2]

# clk1 and clk2 are independent clock domains.
set_clock_groups -asynchronous -group {clk1} -group {clk2}

set_dont_touch_network [all_clocks]
set_fix_hold           [all_clocks]
set_clock_uncertainty  0.1 [all_clocks]
set_clock_latency      0.5 [all_clocks]
set_ideal_network          [all_clocks]

# Input interfaces
set_input_delay 1.0 -clock clk1 [get_ports Q]
set_input_delay 1.0 -clock clk2 [get_ports K]
set_input_transition 0.05 [get_ports {Q K}]

# Output interfaces
set_output_delay 1.0 -clock clk1 [get_ports {A valid Qbusy}]
set_output_delay 1.0 -clock clk2 [get_ports Kbusy]
set_load 1.0 [all_outputs]

# rst is a synchronous active-low control sampled in both clock domains.
# It is excluded from normal functional timing analysis.
set_false_path -from [get_ports rst]

set_operating_conditions -max slow -min fast
set auto_wire_load_selection
set_max_fanout 16 [current_design]
