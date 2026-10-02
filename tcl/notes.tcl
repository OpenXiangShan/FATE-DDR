# Export IPs present in the current project using their stable names.
foreach name {mig_phy_vu19p mig_phy_vcu128 ila_afifo ila_ctrl ila_famse_top} {
    set ip [get_ips -quiet $name]
    if {[llength $ip] == 1} {
        write_ip_tcl -force $ip [file join [file dirname [info script]] [format "ip_export_%s.tcl" $name]]
    }
}
