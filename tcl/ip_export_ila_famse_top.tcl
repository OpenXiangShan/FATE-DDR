# Vivado 2024.2 IP configuration; keep in sync with the release XCI.
if {[version -short] ne "2024.2"} {
    error "FAMSE IP export requires Vivado 2024.2; found [version -short]"
}
if {[llength [get_projects -quiet]] == 0} {
    error "Open your target FPGA project before creating the shared FAMSE ILA IP"
}

set ila_famse_top [create_ip -name ila -vendor xilinx.com -library ip -version 6.2 -module_name ila_famse_top]

# User Parameters
set_property -dict [list \
  CONFIG.C_ADV_TRIGGER {true} \
  CONFIG.C_DATA_DEPTH {4096} \
  CONFIG.C_EN_STRG_QUAL {1} \
  CONFIG.C_INPUT_PIPE_STAGES {1} \
  CONFIG.C_NUM_OF_PROBES {54} \
  CONFIG.C_PROBE36_WIDTH {16} \
  CONFIG.C_PROBE37_WIDTH {16} \
  CONFIG.C_PROBE38_WIDTH {256} \
  CONFIG.C_PROBE39_WIDTH {512} \
  CONFIG.C_PROBE40_WIDTH {256} \
  CONFIG.C_PROBE41_WIDTH {512} \
  CONFIG.C_PROBE42_WIDTH {32} \
  CONFIG.C_PROBE43_WIDTH {64} \
  CONFIG.C_PROBE44_WIDTH {16} \
  CONFIG.C_PROBE45_WIDTH {8} \
  CONFIG.C_PROBE46_WIDTH {136} \
  CONFIG.C_PROBE47_WIDTH {16} \
  CONFIG.C_PROBE48_WIDTH {1} \
  CONFIG.C_PROBE49_WIDTH {2} \
  CONFIG.C_PROBE50_WIDTH {5} \
  CONFIG.C_PROBE51_WIDTH {16} \
  CONFIG.C_PROBE52_WIDTH {16} \
  CONFIG.C_PROBE53_WIDTH {2} \
] [get_ips ila_famse_top]

# Runtime Parameters
set_property -dict { 
  GENERATE_SYNTH_CHECKPOINT {1}
} $ila_famse_top

##################################################################

