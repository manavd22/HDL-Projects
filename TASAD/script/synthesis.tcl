########################################################################
# 2026 AISSM Summer Course
# TASAD Flag-10 synthesis flow
########################################################################

file mkdir ./syn
file mkdir ./reports/synthesis

source ./script/.synopsys_dc.setup

analyze -format sverilog ./src/TASAD.sv
elaborate TASAD
current_design TASAD
link
uniquify

set_fix_multiple_port_nets -all -buffer_constants [get_designs *]
source ./script/DC.sdc

check_design > ./reports/synthesis/check_design_rpt.txt

compile -map_effort high
compile -incremental_mapping

change_names -rules verilog -hierarchy

report_timing \
    -path full \
    -delay max \
    -nworst 10 \
    -max_paths 10 \
    -significant_digits 3 \
    -sort_by group \
    > ./reports/synthesis/timing_max_rpt.txt

report_timing \
    -path full \
    -delay min \
    -nworst 10 \
    -max_paths 10 \
    -significant_digits 3 \
    -sort_by group \
    > ./reports/synthesis/timing_min_rpt.txt

report_area -hierarchy -nosplit \
    > ./reports/synthesis/area_rpt.txt
report_power -analysis_effort low \
    > ./reports/synthesis/power_rpt.txt
report_qor \
    > ./reports/synthesis/qor_rpt.txt
report_constraint -all_violators -significant_digits 4 \
    > ./reports/synthesis/constraint_violators_rpt.txt

write_file -format verilog -hierarchy -output ./syn/TASAD_syn.v
write_sdf -version 2.1 -context verilog ./syn/TASAD_syn.sdf
write_sdc ./syn/TASAD_syn.sdc

exit
