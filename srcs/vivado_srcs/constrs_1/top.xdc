################################################################################
# Copyright (c) 2021-2026 Beijing Institute of Open Source Chip (BOSC)
# Copyright (c) 2020-2026 Institute of Computing Technology, Chinese Academy of Sciences (ICT, CAS)
#
# YuQuan is licensed under Mulan PSL v2.
# You can use this software according to the terms and conditions of the Mulan PSL v2.
# You may obtain a copy of Mulan PSL v2 at:
#          http://license.coscl.org.cn/MulanPSL2
#
# THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
# EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
# MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
#
# See the Mulan PSL v2 for more details.
################################################################################

# main clock

# programmable clock pair1 : 100MHz
set_property PACKAGE_PIN CA16 [get_ports diff_clock_100M_n]
set_property PACKAGE_PIN CA17 [get_ports diff_clock_100M_p]
set_property IOSTANDARD LVDS [get_ports diff_clock_100M_n]
set_property IOSTANDARD LVDS [get_ports diff_clock_100M_p]


# programmable clock pair7 : 80MHz
set_property PACKAGE_PIN Y52 [get_ports diff_clock_80M_p]
set_property PACKAGE_PIN Y53 [get_ports diff_clock_80M_n]
set_property IOSTANDARD LVDS [get_ports diff_clock_80M_p]
set_property IOSTANDARD LVDS [get_ports diff_clock_80M_n]


set_clock_groups -name async_clk_100m_80m \
    -asynchronous \
    -group [get_clocks -include_generated_clocks clk_100m] \
    -group [get_clocks -include_generated_clocks clk_80m]

    

# DDR4
set_property PACKAGE_PIN AB51 [get_ports {ddr_ck_t[0]}]
set_property PACKAGE_PIN AA51 [get_ports {ddr_ck_t[1]}]

set_property PACKAGE_PIN AB52 [get_ports {ddr_ck_c[0]}]
set_property PACKAGE_PIN AA52 [get_ports {ddr_ck_c[1]}]

set_property PACKAGE_PIN V53  [get_ports {ddr_cke[0]}]
set_property PACKAGE_PIN AC45 [get_ports {ddr_cke[1]}]

set_property PACKAGE_PIN W56 [get_ports {ddr_cs_n[0]}]
set_property PACKAGE_PIN V54 [get_ports {ddr_cs_n[1]}]

set_property PACKAGE_PIN V56 [get_ports {ddr_odt[0]}]
set_property PACKAGE_PIN V55 [get_ports {ddr_odt[1]}]

set_property PACKAGE_PIN AB49 [get_ports {ddr_act_n}]

set_property PACKAGE_PIN AH58 [get_ports {ddr_dm_n[0]}]
set_property PACKAGE_PIN AC53 [get_ports {ddr_dm_n[1]}]
set_property PACKAGE_PIN AB61 [get_ports {ddr_dm_n[2]}]
set_property PACKAGE_PIN U56  [get_ports {ddr_dm_n[3]}]
set_property PACKAGE_PIN W60  [get_ports {ddr_dm_n[4]}]
set_property PACKAGE_PIN P57  [get_ports {ddr_dm_n[5]}]
set_property PACKAGE_PIN M53  [get_ports {ddr_dm_n[6]}]
set_property PACKAGE_PIN R52  [get_ports {ddr_dm_n[7]}]

set_property PACKAGE_PIN W51 [get_ports {ddr_bg[0]}]
set_property PACKAGE_PIN W55 [get_ports {ddr_bg[1]}]

set_property PACKAGE_PIN AB47 [get_ports {ddr_ba[0]}]
set_property PACKAGE_PIN Y54  [get_ports {ddr_ba[1]}]

set_property PACKAGE_PIN AC46 [get_ports {ddr_a[0]}]
set_property PACKAGE_PIN Y47  [get_ports {ddr_a[1]}]
set_property PACKAGE_PIN Y45  [get_ports {ddr_a[2]}]
set_property PACKAGE_PIN AA46 [get_ports {ddr_a[3]}]
set_property PACKAGE_PIN W53  [get_ports {ddr_a[4]}]
set_property PACKAGE_PIN W52  [get_ports {ddr_a[5]}]
set_property PACKAGE_PIN Y49  [get_ports {ddr_a[6]}]
set_property PACKAGE_PIN AA49 [get_ports {ddr_a[7]}]
set_property PACKAGE_PIN Y50  [get_ports {ddr_a[8]}]
set_property PACKAGE_PIN AA47 [get_ports {ddr_a[9]}]
set_property PACKAGE_PIN AC48 [get_ports {ddr_a[10]}]
set_property PACKAGE_PIN AA45 [get_ports {ddr_a[11]}]
set_property PACKAGE_PIN V51  [get_ports {ddr_a[12]}]
set_property PACKAGE_PIN AC51 [get_ports {ddr_a[13]}]
set_property PACKAGE_PIN AB46 [get_ports {ddr_a[14]}]
set_property PACKAGE_PIN AC49 [get_ports {ddr_a[15]}]
set_property PACKAGE_PIN AC50 [get_ports {ddr_a[16]}]

set_property PACKAGE_PIN Y48 [get_ports {ddr_reset_n}]

set_property PACKAGE_PIN AG59 [get_ports {ddr_dq[0]}]
set_property PACKAGE_PIN AF62 [get_ports {ddr_dq[1]}]
set_property PACKAGE_PIN AG61 [get_ports {ddr_dq[2]}]
set_property PACKAGE_PIN AF59 [get_ports {ddr_dq[3]}]
set_property PACKAGE_PIN AG58 [get_ports {ddr_dq[4]}]
set_property PACKAGE_PIN AF61 [get_ports {ddr_dq[5]}]
set_property PACKAGE_PIN AF60 [get_ports {ddr_dq[6]}]
set_property PACKAGE_PIN AE62 [get_ports {ddr_dq[7]}]
set_property PACKAGE_PIN AC55 [get_ports {ddr_dq[8]}]
set_property PACKAGE_PIN AB53 [get_ports {ddr_dq[9]}]
set_property PACKAGE_PIN AA57 [get_ports {ddr_dq[10]}]
set_property PACKAGE_PIN AB56 [get_ports {ddr_dq[11]}]
set_property PACKAGE_PIN AB54 [get_ports {ddr_dq[12]}]
set_property PACKAGE_PIN AA56 [get_ports {ddr_dq[13]}]
set_property PACKAGE_PIN AC56 [get_ports {ddr_dq[14]}]
set_property PACKAGE_PIN AB57 [get_ports {ddr_dq[15]}]
set_property PACKAGE_PIN AB59 [get_ports {ddr_dq[16]}]
set_property PACKAGE_PIN AA59 [get_ports {ddr_dq[17]}]
set_property PACKAGE_PIN AA62 [get_ports {ddr_dq[18]}]
set_property PACKAGE_PIN Y62  [get_ports {ddr_dq[19]}]
set_property PACKAGE_PIN AA60 [get_ports {ddr_dq[20]}]
set_property PACKAGE_PIN AB58 [get_ports {ddr_dq[21]}]
set_property PACKAGE_PIN AA61 [get_ports {ddr_dq[22]}]
set_property PACKAGE_PIN Y63  [get_ports {ddr_dq[23]}]
set_property PACKAGE_PIN T57  [get_ports {ddr_dq[24]}]
set_property PACKAGE_PIN R55  [get_ports {ddr_dq[25]}]
set_property PACKAGE_PIN P55  [get_ports {ddr_dq[26]}]
set_property PACKAGE_PIN R58  [get_ports {ddr_dq[27]}]
set_property PACKAGE_PIN T56  [get_ports {ddr_dq[28]}]
set_property PACKAGE_PIN P56  [get_ports {ddr_dq[29]}]
set_property PACKAGE_PIN R54  [get_ports {ddr_dq[30]}]
set_property PACKAGE_PIN R57  [get_ports {ddr_dq[31]}]
set_property PACKAGE_PIN U63  [get_ports {ddr_dq[32]}]
set_property PACKAGE_PIN W62  [get_ports {ddr_dq[33]}]
set_property PACKAGE_PIN W63  [get_ports {ddr_dq[34]}]
set_property PACKAGE_PIN V59  [get_ports {ddr_dq[35]}]
set_property PACKAGE_PIN V63  [get_ports {ddr_dq[36]}]
set_property PACKAGE_PIN V58  [get_ports {ddr_dq[37]}]
set_property PACKAGE_PIN U61  [get_ports {ddr_dq[38]}]
set_property PACKAGE_PIN U62  [get_ports {ddr_dq[39]}]
set_property PACKAGE_PIN N56  [get_ports {ddr_dq[40]}]
set_property PACKAGE_PIN N58  [get_ports {ddr_dq[41]}]
set_property PACKAGE_PIN K57  [get_ports {ddr_dq[42]}]
set_property PACKAGE_PIN L57  [get_ports {ddr_dq[43]}]
set_property PACKAGE_PIN M57  [get_ports {ddr_dq[44]}]
set_property PACKAGE_PIN M58  [get_ports {ddr_dq[45]}]
set_property PACKAGE_PIN N55  [get_ports {ddr_dq[46]}]
set_property PACKAGE_PIN K58  [get_ports {ddr_dq[47]}]
set_property PACKAGE_PIN K54  [get_ports {ddr_dq[48]}]
set_property PACKAGE_PIN J52  [get_ports {ddr_dq[49]}]
set_property PACKAGE_PIN J51  [get_ports {ddr_dq[50]}]
set_property PACKAGE_PIN M51  [get_ports {ddr_dq[51]}]
set_property PACKAGE_PIN M52  [get_ports {ddr_dq[52]}]
set_property PACKAGE_PIN L54  [get_ports {ddr_dq[53]}]
set_property PACKAGE_PIN L52  [get_ports {ddr_dq[54]}]
set_property PACKAGE_PIN L51  [get_ports {ddr_dq[55]}]
set_property PACKAGE_PIN P52  [get_ports {ddr_dq[56]}]
set_property PACKAGE_PIN T51  [get_ports {ddr_dq[57]}]
set_property PACKAGE_PIN U53  [get_ports {ddr_dq[58]}]
set_property PACKAGE_PIN U52  [get_ports {ddr_dq[59]}]
set_property PACKAGE_PIN P51  [get_ports {ddr_dq[60]}]
set_property PACKAGE_PIN P53  [get_ports {ddr_dq[61]}]
set_property PACKAGE_PIN N51  [get_ports {ddr_dq[62]}]
set_property PACKAGE_PIN T52  [get_ports {ddr_dq[63]}]

set_property PACKAGE_PIN AG62 [get_ports {ddr_dqs_t[0]}]
set_property PACKAGE_PIN AA54 [get_ports {ddr_dqs_t[1]}]
set_property PACKAGE_PIN Y59  [get_ports {ddr_dqs_t[2]}]
set_property PACKAGE_PIN T54  [get_ports {ddr_dqs_t[3]}]
set_property PACKAGE_PIN V60  [get_ports {ddr_dqs_t[4]}]
set_property PACKAGE_PIN M56  [get_ports {ddr_dqs_t[5]}]
set_property PACKAGE_PIN K52  [get_ports {ddr_dqs_t[6]}]
set_property PACKAGE_PIN N53  [get_ports {ddr_dqs_t[7]}]

set_property PACKAGE_PIN AG63 [get_ports {ddr_dqs_c[0]}]
set_property PACKAGE_PIN AA55 [get_ports {ddr_dqs_c[1]}]
set_property PACKAGE_PIN Y60  [get_ports {ddr_dqs_c[2]}]
set_property PACKAGE_PIN T55  [get_ports {ddr_dqs_c[3]}]
set_property PACKAGE_PIN V61  [get_ports {ddr_dqs_c[4]}]
set_property PACKAGE_PIN L56  [get_ports {ddr_dqs_c[5]}]
set_property PACKAGE_PIN K53  [get_ports {ddr_dqs_c[6]}]
set_property PACKAGE_PIN N54  [get_ports {ddr_dqs_c[7]}]


