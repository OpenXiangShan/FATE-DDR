##################################################################
# CHECK VIVADO VERSION
##################################################################

set scripts_vivado_version 2024.2
set current_vivado_version [version -short]

if { [string first $scripts_vivado_version $current_vivado_version] == -1 } {
  catch {common::send_msg_id "IPS_TCL-100" "ERROR" "This script was generated using Vivado <$scripts_vivado_version> and is being run in <$current_vivado_version> of Vivado. Please run the script in Vivado <$scripts_vivado_version> then open the design in Vivado <$current_vivado_version>. Upgrade the design by running \"Tools => Report => Report IP Status...\", then run write_ip_tcl to create an updated script."}
  return 1
}

##################################################################
# START
##################################################################

# To test this script, run the following commands from Vivado Tcl console:
# source ip_export_mig_phy_vcu128.tcl
# If there is no project opened, this script will create a
# project, but make sure you do not have an existing project
# in the current working folder.

set list_projs [get_projects -quiet]
if { $list_projs eq "" } {
  create_project dfim_by_famse_vcu128 dfim_by_famse_vcu128 -part xcvu37p-fsvh2892-2L-e
  set_property BOARD_PART xilinx.com:vcu128:part0:1.0 [current_project]
  set_property target_language Verilog [current_project]
  set_property simulator_language Mixed [current_project]
}

##################################################################
# CHECK IPs
##################################################################

set bCheckIPs 1
set bCheckIPsPassed 1
if { $bCheckIPs == 1 } {
  set list_check_ips { xilinx.com:ip:ddr4:2.2 }
  set list_ips_missing ""
  common::send_msg_id "IPS_TCL-1001" "INFO" "Checking if the following IPs exist in the project's IP catalog: $list_check_ips ."

  foreach ip_vlnv $list_check_ips {
  set ip_obj [get_ipdefs -all $ip_vlnv]
  if { $ip_obj eq "" } {
    lappend list_ips_missing $ip_vlnv
    }
  }

  if { $list_ips_missing ne "" } {
    catch {common::send_msg_id "IPS_TCL-105" "ERROR" "The following IPs are not found in the IP Catalog:\n  $list_ips_missing\n\nResolution: Please add the repository containing the IP(s) to the project." }
    set bCheckIPsPassed 0
  }
}

if { $bCheckIPsPassed != 1 } {
  common::send_msg_id "IPS_TCL-102" "WARNING" "Will not continue with creation of design due to the error(s) above."
  return 1
}

##################################################################
# CREATE IP mig_phy_vcu128
##################################################################

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

