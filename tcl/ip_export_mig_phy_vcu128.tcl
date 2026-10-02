# Vivado 2024.2 IP configuration; keep in sync with the release XCI.
if {[version -short] ne "2024.2"} {
    error "FAMSE IP export requires Vivado 2024.2; found [version -short]"
}
if {[llength [get_projects -quiet]] == 0} {
    create_project famse_vcu128 famse_vcu128 -part xcvu37p-fsvh2892-2L-e
    set_property target_language Verilog [current_project]
}
if {[get_property PART [current_project]] ne "xcvu37p-fsvh2892-2L-e"} {
    error "mig_phy_vcu128 requires part xcvu37p-fsvh2892-2L-e"
}

set mig_phy_vcu128 [create_ip -name ddr4 -vendor xilinx.com -library ip -version 2.2 -module_name mig_phy_vcu128]

# User Parameters
set_property -dict [list \
  CONFIG.C0.BANK_GROUP_WIDTH {1} \
  CONFIG.C0.CS_WIDTH {2} \
  CONFIG.C0.DDR4_CasLatency {11} \
  CONFIG.C0.DDR4_CasWriteLatency {11} \
  CONFIG.C0.DDR4_Clamshell {true} \
  CONFIG.C0.DDR4_DataMask {DM_NO_DBI} \
  CONFIG.C0.DDR4_DataWidth {64} \
  CONFIG.C0.DDR4_InputClockPeriod {10000} \
  CONFIG.C0.DDR4_MemoryPart {MT40A512M16HA-075E} \
  CONFIG.C0.DDR4_TimePeriod {1250} \
  CONFIG.Phy_Only {Phy_Only_Single} \
  CONFIG.System_Clock {Differential} \
] [get_ips mig_phy_vcu128]

# Runtime Parameters
set_property -dict { 
  GENERATE_SYNTH_CHECKPOINT {1}
} $mig_phy_vcu128

##################################################################

