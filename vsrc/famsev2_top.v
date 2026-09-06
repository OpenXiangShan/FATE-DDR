/***************************************************************************************
* Copyright (c) 2021-2026 Beijing Institute of Open Source Chip (BOSC)
* Copyright (c) 2020-2026 Institute of Computing Technology, Chinese Academy of Sciences (ICT，CAS)
* 
* FATE is licensed under Mulan PSL v2.
* You can use this software according to the terms and conditions of the Mulan PSL v2.
* You may obtain a copy of Mulan PSL v2 at:
*          http://license.coscl.org.cn/MulanPSL2
*
* THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
* EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
* MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
*   
* See the Mulan PSL v2 for more details.
***************************************************************************************/

// famsev2_top.v
module famsev2_top (

    input           dfi_clk,
    input           mig_clk,
    input           rst_n,
    input           calDone,

    //////////////dfi cmd interface//////////////
    input   [3:0]   dfi_reset_n,
    input   [3:0]   dfi_cke,
    input   [3:0]   dfi_odt,
    input   [35:0]  dfi_address,
    input   [3:0]   dfi_ba,
    input   [3:0]   dfi_bg,
    input   [3:0]   dfi_cs_n,
    input   [1:0]   dfi_act_n,
    input   [1:0]   dfi_ras_n,
    input   [1:0]   dfi_cas_n,
    input   [1:0]   dfi_we_n,
    //////////////dfi rddata interface//////////////
    input           dfi_rddata_en,
    output  [255:0] dfi_rddata,
    output          dfi_rddata_valid,
    //////////////dfi wrdata interface//////////////
    input           dfi_wrdata_en,
    input   [255:0] dfi_wrdata,
    input   [31:0]  dfi_wrdata_mask,

    //////////////mig cmd interface//////////////
    output  [7:0]   mc_ACT_n,
    output  [135:0] mc_ADR,
    output  [15:0]  mc_BA,
    output  [15:0]  mc_BG,
    output  [15:0]  mc_CKE,
    output  [15:0]  mc_CS_n,
    output  [15:0]  mc_ODT,
    output  [1:0]   winRank,
    output          mcRdCAS,
    output          mcWrCAS,
    output  [1:0]   mcCasSlot,
    output          mcCasSlot2,
    output  [4:0]   winBuf,
    output          winInjTxn,
    //////////////mig rddata interface//////////////
    input           mig_rddata_en,
    input   [511:0] mig_rddata,
    input           per_rd_done,
    output          gt_data_ready,
    //////////////mig wrdata interface//////////////
    input           mig_wrdata_en,
    output  [511:0] mig_wrdata,
    output  [63:0]  mig_wrdata_mask
);

    // famsev2 inner signal
    wire            fm_cmdTaken;
    wire            fm_actReq;
    wire    [1:0]   fm_actBa;
    wire    [1:0]   fm_actBg;
    wire    [16:0]  fm_actRow;
    wire    [1:0]   fm_actRank;
    wire            fm_rdReq;
    wire    [1:0]   fm_rdBa;
    wire    [1:0]   fm_rdBg;
    wire    [9:0]   fm_rdCol;
    wire    [1:0]   fm_rdRank;
    wire            fm_wrReq;
    wire    [1:0]   fm_wrBa;
    wire    [1:0]   fm_wrBg;
    wire    [9:0]   fm_wrCol;
    wire    [1:0]   fm_wrRank;
    wire            fm_refReq;
    wire    [1:0]   fm_refRank;

    // DEBUG SIGNAL
    wire            debug_RD_error;
    wire            debug_sta_rst;
    wire            debug_sta_idl;
    wire            debug_act_cmd;
    wire            debug_act_wat;
    wire            debug_rda_cmd;
    wire            debug_rda_wat;
    wire            debug_wra_cmd;
    wire            debug_wra_wat;
    wire            debug_ref_cmd;
    wire            debug_ref_wat;
    wire            debug_zqs_cmd;
    wire            debug_zqs_wat;
    wire            debug_vat_cmd;
    wire            debug_vat_wat;
    wire            debug_vrd_cmd;
    wire            debug_vrd_wat;
    wire            debug_cmd_fifo_empty;

    cmd_buffer i_cmd_buffer(
        .dfi_clk(           dfi_clk),
        .mig_clk(           mig_clk),
        .rst_n(             rst_n),

        // dfi cmd interface
        .dfi_reset_n(       dfi_reset_n),
        .dfi_cke(           dfi_cke),
        .dfi_odt(           dfi_odt),
        .dfi_address(       dfi_address),
        .dfi_ba(            dfi_ba),
        .dfi_bg(            dfi_bg),
        .dfi_cs_n(          dfi_cs_n),
        .dfi_act_n(         dfi_act_n),
        .dfi_ras_n(         dfi_ras_n),
        .dfi_cas_n(         dfi_cas_n),
        .dfi_we_n(          dfi_we_n),

        // cmd info
        .fm_cmdTaken(       fm_cmdTaken),
        .fm_actReq(         fm_actReq),
        .fm_actBa(          fm_actBa),
        .fm_actBg(          fm_actBg),
        .fm_actRow(         fm_actRow),
        .fm_actRank(        fm_actRank),
        .fm_rdReq(          fm_rdReq),
        .fm_rdBa(           fm_rdBa),
        .fm_rdBg(           fm_rdBg),
        .fm_rdCol(          fm_rdCol),
        .fm_rdRank(         fm_rdRank),
        .fm_wrReq(          fm_wrReq),
        .fm_wrBa(           fm_wrBa),
        .fm_wrBg(           fm_wrBg),
        .fm_wrCol(          fm_wrCol),
        .fm_wrRank(         fm_wrRank),

        .debug_cmd_fifo_empty(  debug_cmd_fifo_empty)
    );

    wire            ctrl2driver_actReq;
    wire    [1:0]   ctrl2driver_actBa;
    wire    [1:0]   ctrl2driver_actBg;
    wire    [16:0]  ctrl2driver_actRow;
    wire    [1:0]   ctrl2driver_actRank;
    wire            ctrl2driver_rdaReq;
    wire    [1:0]   ctrl2driver_rdaBa;
    wire    [1:0]   ctrl2driver_rdaBg;
    wire    [9:0]   ctrl2driver_rdaCol;
    wire    [1:0]   ctrl2driver_rdaRank;
    wire            ctrl2driver_wraReq;
    wire    [1:0]   ctrl2driver_wraBa;
    wire    [1:0]   ctrl2driver_wraBg;
    wire    [9:0]   ctrl2driver_wraCol;
    wire    [1:0]   ctrl2driver_wraRank;
    wire            ctrl2driver_refReq;
    wire    [1:0]   ctrl2driver_refRank;
    wire            ctrl2driver_zqsReq;
    wire    [1:0]   ctrl2driver_zqsRank;
    
    wire            wrdata_filling;
    reg     [4:0]   wrdata_ready_cnt;   // we send write cmd after wrdata is ready.
    wire            rddata_ignore;      // we ignore rddata if there is a VT read.

    always @(negedge mig_clk) begin
        if (!rst_n) begin
            wrdata_ready_cnt <= 5'd0;
        end else if (wrdata_filling && !(fm_cmdTaken && fm_wrReq)) begin
            wrdata_ready_cnt <= wrdata_ready_cnt + 5'd1;
        end else if (!wrdata_filling && (fm_cmdTaken && fm_wrReq)) begin
            wrdata_ready_cnt <= wrdata_ready_cnt - 5'd1;
        end
    end

    famsev2_ctrl i_famsev2_ctrl(

        .mig_clk(           mig_clk),
        .rst_n(             rst_n && calDone),

        // cmd info
        .fm_cmdTaken(       fm_cmdTaken),
        .fm_actReq(         fm_actReq),
        .fm_actBa(          fm_actBa),
        .fm_actBg(          fm_actBg),
        .fm_actRow(         fm_actRow),
        .fm_actRank(        fm_actRank),
        .fm_rdReq(          fm_rdReq),
        .fm_rdBa(           fm_rdBa),
        .fm_rdBg(           fm_rdBg),
        .fm_rdCol(          fm_rdCol),
        .fm_rdRank(         fm_rdRank),
        .fm_wrReq(          fm_wrReq && (wrdata_ready_cnt > 0)),
        .fm_wrBa(           fm_wrBa),
        .fm_wrBg(           fm_wrBg),
        .fm_wrCol(          fm_wrCol),
        .fm_wrRank(         fm_wrRank),

        .actReq(            ctrl2driver_actReq),
        .actBa(             ctrl2driver_actBa),
        .actBg(             ctrl2driver_actBg),
        .actRow(            ctrl2driver_actRow),
        .actRank(           ctrl2driver_actRank),
        .rdaReq(            ctrl2driver_rdaReq),
        .rdaBa(             ctrl2driver_rdaBa),
        .rdaBg(             ctrl2driver_rdaBg),
        .rdaCol(            ctrl2driver_rdaCol),
        .rdaRank(           ctrl2driver_rdaRank),
        .wraReq(            ctrl2driver_wraReq),
        .wraBa(             ctrl2driver_wraBa),
        .wraBg(             ctrl2driver_wraBg),
        .wraCol(            ctrl2driver_wraCol),
        .wraRank(           ctrl2driver_wraRank),
        .refReq(            ctrl2driver_refReq),
        .refRank(           ctrl2driver_refRank),
        .zqsReq(            ctrl2driver_zqsReq),
        .zqsRank(           ctrl2driver_zqsRank),
        
        .rddata_ignore(     rddata_ignore),

        .debug_RD_error(        debug_RD_error),
        .debug_cmd_fifo_empty(  debug_cmd_fifo_empty),

        .debug_sta_rst(     debug_sta_rst),
        .debug_sta_idl(     debug_sta_idl),
        .debug_act_cmd(     debug_act_cmd),
        .debug_act_wat(     debug_act_wat),
        .debug_rda_cmd(     debug_rda_cmd),
        .debug_rda_wat(     debug_rda_wat),
        .debug_wra_cmd(     debug_wra_cmd),
        .debug_wra_wat(     debug_wra_wat),
        .debug_ref_cmd(     debug_ref_cmd),
        .debug_ref_wat(     debug_ref_wat),
        .debug_zqs_cmd(     debug_zqs_cmd),
        .debug_zqs_wat(     debug_zqs_wat),
        .debug_vat_cmd(     debug_vat_cmd),
        .debug_vat_wat(     debug_vat_wat),
        .debug_vrd_cmd(     debug_vrd_cmd),
        .debug_vrd_wat(     debug_vrd_wat)
    );

    mig_phy_driver i_mig_phy_driver(

        .actReq(            ctrl2driver_actReq),
        .actBa(             ctrl2driver_actBa),
        .actBg(             ctrl2driver_actBg),
        .actRow(            ctrl2driver_actRow),
        .actRank(           ctrl2driver_actRank),
        .rdaReq(            ctrl2driver_rdaReq),
        .rdaBa(             ctrl2driver_rdaBa),
        .rdaBg(             ctrl2driver_rdaBg),
        .rdaCol(            ctrl2driver_rdaCol),
        .rdaRank(           ctrl2driver_rdaRank),
        .wraReq(            ctrl2driver_wraReq),
        .wraBa(             ctrl2driver_wraBa),
        .wraBg(             ctrl2driver_wraBg),
        .wraCol(            ctrl2driver_wraCol),
        .wraRank(           ctrl2driver_wraRank),
        .refReq(            ctrl2driver_refReq),
        .refRank(           ctrl2driver_refRank),
        .zqsReq(            ctrl2driver_zqsReq),
        .zqsRank(           ctrl2driver_zqsRank),

        // mig phy cmd interface
        .mc_ACT_n(          mc_ACT_n),
        .mc_ADR(            mc_ADR),
        .mc_BA(             mc_BA),
        .mc_BG(             mc_BG),
        .mc_CKE(            mc_CKE),
        .mc_CS_n(           mc_CS_n),
        .mc_ODT(            ),          // generated by ddr4_v2_2_8_cal_mc_odt
        .winRank(           winRank),
        .mcRdCAS(           mcRdCAS),
        .mcWrCAS(           mcWrCAS),
        .mcCasSlot(         mcCasSlot),
        .mcCasSlot2(        mcCasSlot2),
        .winBuf(            winBuf),
        .winInjTxn(         winInjTxn)
    );

    // ODT controller (simplified, self-implemented)
    mig_phy_odt i_mig_phy_odt (
        .clk        (mig_clk),
        .rst_n      (rst_n),
        .winWrite   (mcWrCAS),
        .mc_ODT     (mc_ODT)
    );

    wrdata_buffer i_wrdata_buffer(
        .dfi_clk(           dfi_clk),
        .mig_clk(           mig_clk),
        .rst_n(             rst_n),

        // dfi wrdata interface
        .dfi_wrdata_en(     dfi_wrdata_en),
        .dfi_wrdata(        dfi_wrdata),
        .dfi_wrdata_mask(   dfi_wrdata_mask),

        // wrdata info
        .mig_wrdata_en(     mig_wrdata_en),
        .mig_wrdata(        mig_wrdata),
        .mig_wrdata_mask(   mig_wrdata_mask),
        
        .wrdata_filling(    wrdata_filling)
    );

    // DEBUG SIGNAL

    wire            debug_sync_fifo_wr_ack;
    wire            debug_sync_fifo_full;
    wire            debug_sync_fifo_wr_en;
    wire            debug_sync_fifo_rd_valid;
    wire            debug_sync_fifo_empty;
    wire            debug_sync_fifo_rd_en;

    wire            debug_async_fifo_wr_ack;
    wire            debug_async_fifo_full;
    wire            debug_async_fifo_wr_en;
    wire            debug_async_fifo_rd_valid;
    wire            debug_async_fifo_empty;
    wire            debug_async_fifo_rd_en;

    rddata_buffer i_rddata_buffer(
        .dfi_clk(           dfi_clk),
        .mig_clk(           mig_clk),
        .rst_n(             rst_n),

        // dfi rddata interface
        .dfi_rddata_en(     dfi_rddata_en),
        .dfi_rddata(        dfi_rddata),
        .dfi_rddata_valid(  dfi_rddata_valid),

        // rddata info
        .mig_rddata_en(     mig_rddata_en && !rddata_ignore),
        .mig_rddata(        mig_rddata),

        // DEBUG SIGNAL
        .debug_RD_error(            debug_RD_error),
        .debug_sync_fifo_wr_ack(    debug_sync_fifo_wr_ack),
        .debug_sync_fifo_full(      debug_sync_fifo_full),
        .debug_sync_fifo_wr_en(     debug_sync_fifo_wr_en),
        .debug_sync_fifo_rd_valid(  debug_sync_fifo_rd_valid),
        .debug_sync_fifo_empty(     debug_sync_fifo_empty),
        .debug_sync_fifo_rd_en(     debug_sync_fifo_rd_en),

        .debug_async_fifo_wr_ack(   debug_async_fifo_wr_ack),
        .debug_async_fifo_full(     debug_async_fifo_full),
        .debug_async_fifo_wr_en(    debug_async_fifo_wr_en),
        .debug_async_fifo_rd_valid( debug_async_fifo_rd_valid),
        .debug_async_fifo_empty(    debug_async_fifo_empty),
        .debug_async_fifo_rd_en(    debug_async_fifo_rd_en)

    );

    assign gt_data_ready = 1'd0;



    // debug
    wire    [16:0]  address_p0  = dfi_address[16:0];
    wire    [1:0]   ba_p0       = dfi_ba[1:0];
    wire    [1:0]   bg_p0       = dfi_bg[1:0];
    wire    [1:0]   cs_n_p0     = dfi_cs_n[1:0];
    wire            act_n_p0    = dfi_act_n[0];
    wire            ras_n_p0    = dfi_ras_n[0];
    wire            cas_n_p0    = dfi_cas_n[0];
    wire            we_n_p0     = dfi_we_n[0];
    // DDR Command Truth Table
    // ACT: cs_n = L, act_n = L, RowAddr valid
    // RD : cs_n = L, act_n = H, ras_n = H, cas_n = L, we_n = H
    // WR : cs_n = L, act_n = H, ras_n = H, cas_n = L, we_n = L
    wire    ACT_CMD = (cs_n_p0[1] == 0 || cs_n_p0[0] == 0) && act_n_p0 == 0;
    wire    RD_CMD  = (cs_n_p0[1] == 0 || cs_n_p0[0] == 0) && act_n_p0 == 1 && ras_n_p0 == 1 && cas_n_p0 == 0 && we_n_p0 == 1;
    wire    WR_CMD  = (cs_n_p0[1] == 0 || cs_n_p0[0] == 0) && act_n_p0 == 1 && ras_n_p0 == 1 && cas_n_p0 == 0 && we_n_p0 == 0;

    wire    rddata_en_and_no_VTT = mig_rddata_en && !rddata_ignore;

    ila_famse_top i_ila_famse_top(
        .clk(       mig_clk),
        .probe0(    dif_clk),

        .probe1(    ACT_CMD),
        .probe2(    RD_CMD),
        .probe3(    WR_CMD),

        .probe4(    dfi_rddata_en),
        .probe5(    dfi_rddata_valid),

        .probe6(    debug_sta_rst),
        .probe7(    debug_sta_idl),
        .probe8(    debug_act_cmd),
        .probe9(    debug_act_wat),
        .probe10(   debug_rda_cmd),
        .probe11(   debug_rda_wat),
        .probe12(   debug_wra_cmd),
        .probe13(   debug_wra_wat),
        .probe14(   debug_ref_cmd),
        .probe15(   debug_ref_wat),
        .probe16(   debug_zqs_cmd),
        .probe17(   debug_zqs_wat),
        .probe18(   debug_vat_cmd),
        .probe19(   debug_vat_wat),
        .probe20(   debug_vrd_cmd),
        .probe21(   debug_vrd_wat),

        .probe22(   fm_cmdTaken),
        .probe23(   fm_actReq),
        .probe24(   fm_rdReq),
        .probe25(   fm_wrReq),
        .probe26(   fm_cmdTaken),
        .probe27(   debug_cmd_fifo_empty),

        .probe28(   mig_rddata_en),
        .probe29(   rddata_ignore),
        .probe30(   rddata_en_and_no_VTT),

        .probe31(   debug_RD_error),
        .probe32(   debug_sync_fifo_wr_ack),
        .probe33(   debug_sync_fifo_full),
        .probe34(   debug_sync_fifo_wr_en),
        .probe35(   debug_sync_fifo_rd_valid),
        .probe36(   debug_sync_fifo_empty),
        .probe37(   debug_sync_fifo_rd_en),

        .probe38(   debug_async_fifo_wr_ack),
        .probe39(   debug_async_fifo_full),
        .probe40(   debug_async_fifo_wr_en),
        .probe41(   debug_async_fifo_rd_valid),
        .probe42(   debug_async_fifo_empty),
        .probe43(   debug_async_fifo_rd_en)

    );

endmodule
