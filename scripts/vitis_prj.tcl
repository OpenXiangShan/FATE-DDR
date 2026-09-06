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
# Build a standalone MicroBlaze application and copy its ELF to a fixed path.
# argv: xsa_file application_sources workspace elf_output

proc fail {message} {
    puts stderr "ERROR: $message"
    exit 1
}

proc find_elf {root app_name} {
    set matches {}
    set pending [list $root]
    while {[llength $pending] > 0} {
        set directory [lindex $pending 0]
        set pending [lrange $pending 1 end]
        foreach entry [glob -nocomplain -directory $directory *] {
            if {[file isdirectory $entry]} {
                lappend pending $entry
            } elseif {[string equal -nocase [file extension $entry] ".elf"]} {
                lappend matches $entry
            }
        }
    }

    foreach elf $matches {
        set normalized [string map {\\ /} $elf]
        if {[string match "*/$app_name/*" $normalized]} {
            return $elf
        }
    }
    if {[llength $matches] > 0} {
        return [lindex $matches 0]
    }
    return ""
}

if {$argc != 4} {
    fail "Usage: xsct vitis_prj.tcl XSA APP_SRCS WORKSPACE ELF"
}

set xsa_file  [file normalize [lindex $argv 0]]
set source_dir [file normalize [lindex $argv 1]]
set workspace [file normalize [lindex $argv 2]]
set elf_output [file normalize [lindex $argv 3]]

set platform_name fpga_top
set app_name top
set domain_name standalone_domain

if {![file isfile $xsa_file]} {
    fail "XSA not found: $xsa_file"
}
if {![file isdirectory $source_dir]} {
    fail "Application source directory not found: $source_dir"
}

puts "XSA             : $xsa_file"
puts "Sources         : $source_dir"
puts "Vitis workspace : $workspace"
puts "ELF output      : $elf_output"

# A clean workspace makes the XSCT flow deterministic and avoids retaining a
# platform generated from an older XSA.
if {[file exists $workspace]} {
    file delete -force $workspace
}
file mkdir $workspace
file mkdir [file dirname $elf_output]

setws $workspace
platform create \
    -name $platform_name \
    -hw $xsa_file \
    -proc microblaze_0 \
    -os standalone \
    -out $workspace
platform active $platform_name
platform generate

app create \
    -name $app_name \
    -platform $platform_name \
    -domain $domain_name \
    -template {Empty Application}
importsources -name $app_name -path $source_dir
app build -name $app_name

set generated_elf [find_elf $workspace $app_name]
if {$generated_elf eq "" || ![file isfile $generated_elf]} {
    fail "Vitis build completed but no ELF was found under $workspace"
}
file copy -force $generated_elf $elf_output
if {![file isfile $elf_output]} {
    fail "Failed to create ELF output: $elf_output"
}

puts "Vitis build complete"
puts "ELF: $elf_output"
exit 0
