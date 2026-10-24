########################################################################
# 2026 AISSM Summer Course
# TASAD Flag-10 Superlint flow
########################################################################

##------------------ Do not modify this section ----------------------##
clear -all

config_rtlds -rule -enable  -domain {LINT}
config_rtlds -rule -disable -domain {DFT AUTO_FORMAL}

config_rtlds -rule -disable -category {NAMING}
config_rtlds -rule -disable -tag {
    IDN_NR_AMKY IDN_NR_CKYW IDN_NR_SVKY
    NAM_NR_REPU EXP_NR_OVFB IFC_NR_DGEL INS_NR_PODL
    MOD_NR_PGAT MOD_NO_IPRG FLP_NR_MXCS FLP_NO_ASRT
    REG_NR_RWRC INS_NR_INPR MOD_NS_GLGC OTP_NR_ASYA
}
##-------------------------------------------------------------------##

analyze -sv ./src/TASAD.sv
elaborate -bbox true -top TASAD

check_superlint -extract
