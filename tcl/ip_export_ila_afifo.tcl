# Vivado 2024.2 IP configuration; keep in sync with the release XCI.
if {[version -short] ne "2024.2"} {
    error "FAMSE IP export requires Vivado 2024.2; found [version -short]"
}
if {[llength [get_projects -quiet]] == 0} {
    error "Open your target FPGA project before creating the shared FAMSE ILA IP"
}

set ila_afifo [create_ip -name ila -vendor xilinx.com -library ip -version 6.2 -module_name ila_afifo]

# User Parameters
set_property -dict [list \
  CONFIG.C_ADV_TRIGGER {true} \
  CONFIG.C_DATA_DEPTH {4096} \
  CONFIG.C_EN_STRG_QUAL {1} \
  CONFIG.C_INPUT_PIPE_STAGES {1} \
  CONFIG.C_NUM_OF_PROBES {22} \
  CONFIG.C_PROBE10_WIDTH {1} \
  CONFIG.C_PROBE11_WIDTH {8} \
  CONFIG.C_PROBE12_WIDTH {8} \
  CONFIG.C_PROBE13_WIDTH {8} \
  CONFIG.C_PROBE14_WIDTH {8} \
  CONFIG.C_PROBE15_WIDTH {8} \
  CONFIG.C_PROBE16_WIDTH {8} \
  CONFIG.C_PROBE17_WIDTH {8} \
  CONFIG.C_PROBE18_WIDTH {8} \
  CONFIG.C_PROBE19_WIDTH {8} \
  CONFIG.C_PROBE20_WIDTH {8} \
  CONFIG.C_PROBE21_WIDTH {8} \
] [get_ips ila_afifo]

# Runtime Parameters
set_property -dict { 
  GENERATE_SYNTH_CHECKPOINT {1}
} $ila_afifo

##################################################################

