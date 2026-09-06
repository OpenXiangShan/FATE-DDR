get_ips
set ip_obj [get_ips ddr4_0]
write_ip_tcl -force $ip_obj ./ip_export_mig_phy.tcl

get_ips
set ip_obj [get_ips ila_afifo]
write_ip_tcl -force $ip_obj ./ip_export_ila_afifo.tcl

get_ips
set ip_obj [get_ips ila_ctrl]
write_ip_tcl -force $ip_obj ./ip_export_ila_ctrl.tcl

get_ips
set ip_obj [get_ips ila_famse_top]
write_ip_tcl -force $ip_obj ./ip_export_ila_famse_top.tcl
