# Vivado 2024.2 IP configuration; keep in sync with the release XCI.
if {[version -short] ne "2024.2"} {
    error "FAMSE IP export requires Vivado 2024.2; found [version -short]"
}
if {[llength [get_projects -quiet]] == 0} {
    create_project famse_vu19p famse_vu19p -part xcvu19p-fsva3824-2-e
    set_property target_language Verilog [current_project]
}
if {[get_property PART [current_project]] ne "xcvu19p-fsva3824-2-e"} {
    error "mig_phy_vu19p requires part xcvu19p-fsva3824-2-e"
}

set mig_phy_vu19p [create_ip -name ddr4 -vendor xilinx.com -library ip -version 2.2 -module_name mig_phy_vu19p]

# User Parameters
set_property -dict [list \
  CONFIG.ADDN_UI_CLKOUT1_FREQ_HZ {40} \
  CONFIG.ADDN_UI_CLKOUT2_FREQ_HZ {13} \
  CONFIG.ADDN_UI_CLKOUT3_FREQ_HZ {None} \
  CONFIG.ADDN_UI_CLKOUT4_FREQ_HZ {200} \
  CONFIG.C0.DDR4_InputClockPeriod {12500} \
  CONFIG.C0.DDR4_MemoryPart {MTA16ATF2G64HZ-2G3} \
  CONFIG.C0.DDR4_MemoryType {SODIMMs} \
  CONFIG.C0.DDR4_TimePeriod {1250} \
  CONFIG.Phy_Only {Phy_Only_Single} \
] [get_ips mig_phy_vu19p]

# Runtime Parameters
set_property -dict { 
  GENERATE_SYNTH_CHECKPOINT {1}
} $mig_phy_vu19p

##################################################################

