#/***************************************************************************************
#* Copyright (c) 2021-2026 Beijing Institute of Open Source Chip (BOSC)
#* Copyright (c) 2020-2026 Institute of Computing Technology, Chinese Academy of Sciences (ICT, CAS)
#*
#* YuQuan is licensed under Mulan PSL v2.
#* You can use this software according to the terms and conditions of the Mulan PSL v2.
#* You may obtain a copy of Mulan PSL v2 at:
#*          http://license.coscl.org.cn/MulanPSL2
#*
#* THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
#* EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
#* MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
#*
#* See the Mulan PSL v2 for more details.
#***************************************************************************************/
# Build the Vivado project and export fixed-location XSA and BIT artifacts.
# argv: vivado_sources project_directory xsa_output bit_output ?jobs?

proc fail {message} {
    puts stderr "ERROR: $message"
    exit 1
}

proc require_directory {path description} {
    if {![file isdirectory $path]} {
        fail "$description not found: $path"
    }
}

proc require_file {path description} {
    if {![file isfile $path]} {
        fail "$description not found: $path"
    }
}

proc check_run {run_name} {
    set run [get_runs $run_name]
    set status [get_property STATUS $run]
    puts "$run_name status: $status"
    if {![string match "*Complete*" $status]} {
        fail "$run_name did not complete successfully: $status"
    }
}

if {$argc < 4 || $argc > 5} {
    fail "Usage: vivado -source vivado_prj.tcl -tclargs VIVADO_SRCS PRJ_DIR XSA BIT ?JOBS?"
}

set source_dir  [file normalize [lindex $argv 0]]
set project_dir [file normalize [lindex $argv 1]]
set xsa_output  [file normalize [lindex $argv 2]]
set bit_output  [file normalize [lindex $argv 3]]
set jobs 8
if {$argc == 5} {
    set jobs [lindex $argv 4]
}
if {![string is integer -strict $jobs] || $jobs < 1} {
    fail "JOBS must be a positive integer: $jobs"
}

set project_name vivado_prj
set part_name xcvu19p-fsva3824-2-e
set top_name fpga_top
set sources_root [file join $source_dir sources_1]
set imports_dir [file join $sources_root imports]
set bd_file [file join $sources_root bd mb_minisys mb_minisys.bd]
set constraints_file [file join $source_dir constrs_1 top.xdc]

require_directory $source_dir "Vivado source directory"
require_directory $imports_dir "RTL source directory"
require_file $bd_file "Block design"
require_file $constraints_file "Constraint file"

set rtl_files [list \
    [file join $imports_dir fpga_top.sv] \
    [file join $imports_dir parameters baiyang_parameters.svh] \
    [file join $imports_dir baiyang mc_top.sv]]
foreach pattern [list *.v *.sv] {
    foreach source [glob -nocomplain -directory [file join $imports_dir fmv2code] $pattern] {
        lappend rtl_files $source
    }
}
foreach source $rtl_files {
    require_file $source "RTL source"
}

set ip_files {}
foreach ip_dir [glob -nocomplain -types d -directory [file join $sources_root ip] *] {
    foreach ip_file [glob -nocomplain -directory $ip_dir *.xci] {
        lappend ip_files $ip_file
    }
}
if {[llength $ip_files] == 0} {
    fail "No top-level XCI files found under [file join $sources_root ip]"
}

puts "Vivado sources : $source_dir"
puts "Project        : $project_dir"
puts "Part           : $part_name"
puts "XSA output     : $xsa_output"
puts "BIT output     : $bit_output"
puts "Parallel jobs  : $jobs"

# Always recreate the generated project. Source and artifact directories remain
# outside project_dir and are not modified.
if {[file exists $project_dir]} {
    file delete -force $project_dir
}
file mkdir $project_dir
file mkdir [file dirname $xsa_output]
file mkdir [file dirname $bit_output]

create_project $project_name $project_dir -part $part_name -force
set_property target_language Verilog [current_project]
set_property simulator_language Mixed [current_project]
set_property source_mgmt_mode All [current_project]

# Import sources into vivado_prj.srcs instead of referencing the release tree.
# This lets Vivado keep all managed sources and generated output under the
# project directory.
import_files -force -flat -fileset sources_1 $rtl_files
import_files -force -fileset sources_1 $ip_files
import_files -force -fileset sources_1 [list $bd_file]
import_files -force -fileset constrs_1 [list $constraints_file]

set header [get_files -quiet baiyang_parameters.svh]
if {[llength $header] != 1} {
    fail "Unable to identify baiyang_parameters.svh in the project"
}
set_property file_type {Verilog Header} $header
set_property is_global_include true $header
set imported_header_path [get_property NAME $header]
set_property include_dirs [list [file dirname $imported_header_path]] [get_filesets sources_1]

set bd_object [get_files -quiet mb_minisys.bd]
if {[llength $bd_object] != 1} {
    fail "Unable to identify the imported mb_minisys.bd"
}
generate_target all $bd_object
set wrapper_files [make_wrapper -files $bd_object -top]
add_files -norecurse -fileset sources_1 $wrapper_files

# Only generate the four top-level IPs added above. get_files *.xci also
# returns XCI files owned by mb_minisys; Vivado rejects generating those
# nested sub-designs independently from their parent BD.
set top_ip_objects {}
foreach ip_file $ip_files {
    set ip_object [get_files -quiet [file tail $ip_file]]
    if {[llength $ip_object] != 1} {
        fail "Unable to identify imported top-level IP: [file tail $ip_file]"
    }
    lappend top_ip_objects $ip_object
}
generate_target all $top_ip_objects

set_property top $top_name [get_filesets sources_1]
update_compile_order -fileset sources_1

launch_runs synth_1 -jobs $jobs
wait_on_run synth_1
check_run synth_1

launch_runs impl_1 -to_step write_bitstream -jobs $jobs
wait_on_run impl_1
check_run impl_1
open_run impl_1

set generated_bit [file join [get_property DIRECTORY [get_runs impl_1]] ${top_name}.bit]
require_file $generated_bit "Generated bitstream"
file copy -force $generated_bit $bit_output

write_hw_platform -fixed -include_bit -force $xsa_output
require_file $xsa_output "Exported XSA"

puts "Vivado build complete"
puts "XSA: $xsa_output"
puts "BIT: $bit_output"
close_project
exit 0
