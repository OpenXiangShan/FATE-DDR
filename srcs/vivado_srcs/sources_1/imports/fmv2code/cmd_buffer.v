/*
 * Copyright (c) 2021-2026 Beijing Institute of Open Source Chip (BOSC)
 * Copyright (c) 2020-2026 Institute of Computing Technology, Chinese Academy of Sciences (ICT, CAS)
 *
 * YuQuan is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 *
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
 * EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
 * MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 *
 * See the Mulan PSL v2 for more details.
 */

// cmd_buffer.v
module cmd_buffer (

    input           dfi_clk,
    input           mig_clk,
    input           rst_n,

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
    //////////////dfi cmd interface//////////////

    // cmd info
    input           fm_cmdTaken,
    // ACT CMD
    output          fm_actReq,
    output  [1:0]   fm_actBa,
    output  [1:0]   fm_actBg,
    output  [16:0]  fm_actRow,
    output  [1:0]   fm_actRank,
    // RDA CMD
    output          fm_rdReq,
    output  [1:0]   fm_rdBa,
    output  [1:0]   fm_rdBg,
    output  [9:0]   fm_rdCol,
    output  [1:0]   fm_rdRank,
    // WRA CMD
    output          fm_wrReq,
    output  [1:0]   fm_wrBa,
    output  [1:0]   fm_wrBg,
    output  [9:0]   fm_wrCol,
    output  [1:0]   fm_wrRank
);  

    // dfi_reset_n, we do not care
    // dfi_cke, we do not care
    // dfi_odt, we do not care

    wire    [16:0]  address_p0  = dfi_address[16:0];    // only 17 bit
    wire    [1:0]   ba_p0       = dfi_ba[1:0];
    wire    [1:0]   bg_p0       = dfi_bg[1:0];
    wire    [1:0]   cs_n_p0     = dfi_cs_n[1:0];
    wire            act_n_p0    = dfi_act_n[0];
    wire            ras_n_p0    = dfi_ras_n[0];
    wire            cas_n_p0    = dfi_cas_n[0];
    wire            we_n_p0     = dfi_we_n[0];

    wire    [16:0]  address_p1  = dfi_address[34:18];   // only 17 bit
    wire    [1:0]   ba_p1       = dfi_ba[3:2];
    wire    [1:0]   bg_p1       = dfi_bg[3:2];
    wire    [1:0]   cs_n_p1     = dfi_cs_n[3:2];
    wire            act_n_p1    = dfi_act_n[1];
    wire            ras_n_p1    = dfi_ras_n[1];
    wire            cas_n_p1    = dfi_cas_n[1];
    wire            we_n_p1     = dfi_we_n[1];

    // DDR Command Truth Table
    // ACT: cs_n = L, act_n = L, RowAddr valid
    // RD : cs_n = L, act_n = H, ras_n = H, cas_n = L, we_n = H
    // WR : cs_n = L, act_n = H, ras_n = H, cas_n = L, we_n = L
    wire    ACT_CMD = (cs_n_p0[1] == 0 || cs_n_p0[0] == 0) && act_n_p0 == 0;
    wire    RD_CMD  = (cs_n_p0[1] == 0 || cs_n_p0[0] == 0) && act_n_p0 == 1 && ras_n_p0 == 1 && cas_n_p0 == 0 && we_n_p0 == 1;
    wire    WR_CMD  = (cs_n_p0[1] == 0 || cs_n_p0[0] == 0) && act_n_p0 == 1 && ras_n_p0 == 1 && cas_n_p0 == 0 && we_n_p0 == 0;

    wire    [31:0]  ACT_IN  = (ACT_CMD) ? { ACT_CMD, 1'd0, ba_p0, bg_p0, cs_n_p0, 7'd0,  address_p0 }       : 32'd0;
    wire    [31:0]  RD_IN   = (RD_CMD)  ? { RD_CMD,  1'd0, ba_p0, bg_p0, cs_n_p0, 14'd0, address_p0[9:0] }  : 32'd0;
    wire    [31:0]  WR_IN   = (WR_CMD)  ? { WR_CMD,  1'd0, ba_p0, bg_p0, cs_n_p0, 14'd0, address_p0[9:0] }  : 32'd0;

    wire            async_fifo_wr_ack;
    wire            async_fifo_full;
    wire            async_fifo_wr_en = ACT_CMD || RD_CMD || WR_CMD; // write async fifo if there is a cmd in dfi interface
    wire    [95:0]  async_fifo_wr_data = { ACT_IN, RD_IN, WR_IN };

    wire            async_fifo_rd_valid;
    wire            async_fifo_empty;
    // wire            async_fifo_rd_en = !async_fifo_empty;           // read async fifo if the fifo is not empty
    wire    [95:0]  async_fifo_rd_data;

    reg [1:0] async_rd_gap;
    wire async_fifo_rd_en = !async_fifo_empty && (async_rd_gap == 2'd0);
    // Attention:
    // Due to the timing issue, 
    // in the scenario of slow writing and fast reading, 
    // there should be a two-clock cycle interval between each two reads.
    always @(posedge mig_clk or negedge rst_n) begin
        if (!rst_n) begin
            async_rd_gap <= 2'd0;
        end else if (async_fifo_rd_en) begin
            async_rd_gap <= 2'd2;
        end else if (async_rd_gap > 0) begin
            async_rd_gap <= async_rd_gap - 1'd1;
        end
    end

    async_fifo # (
        .DATA_WIDTH(    32+32+32),
        .DEPTH(         16)
    ) cmd_async_fifo (
        .wr_clk(        dfi_clk),
        .wr_rst_n(      rst_n),
        .wr_en(         async_fifo_wr_en),
        .wr_data(       async_fifo_wr_data),
        .full(          async_fifo_full),
        .wr_ack(        async_fifo_wr_ack),

        .rd_clk(        mig_clk),
        .rd_rst_n(      rst_n),
        .rd_en(         async_fifo_rd_en),
        .rd_data(       async_fifo_rd_data),
        .empty(         async_fifo_empty),
        .rd_valid(      async_fifo_rd_valid)
    );

    reg     [95:0]  cmd_info_in_fifo;
    reg     [95:0]  cmd_info_to_ctrl;

    // debug signals
    wire    [31:0]  act_info        = cmd_info_in_fifo[95:64];
    wire    [31:0]  rd_info         = cmd_info_in_fifo[63:32];
    wire    [31:0]  wr_info         = cmd_info_in_fifo[31:0];
    wire            debug_actReq    = act_info[31];
    wire    [1:0]   debug_actBa     = act_info[29:28];
    wire    [1:0]   debug_actBg     = act_info[27:26];
    wire    [1:0]   debug_actRank   = act_info[25:24];
    wire    [16:0]  debug_actRow    = act_info[16:0];
    wire            debug_rdReq     = rd_info[31];
    wire    [1:0]   debug_rdBa      = rd_info[29:28];
    wire    [1:0]   debug_rdBg      = rd_info[27:26];
    wire    [1:0]   debug_rdRank    = rd_info[25:24];
    wire    [9:0]   debug_rdCol     = rd_info[9:0];
    wire            debug_wrReq     = wr_info[31];
    wire    [1:0]   debug_wrBa      = wr_info[29:28];
    wire    [1:0]   debug_wrBg      = wr_info[27:26];
    wire    [1:0]   debug_wrRank    = wr_info[25:24];
    wire    [9:0]   debug_wrCol     = wr_info[9:0];

    reg [1:0] sync_rd_gap;

    wire            sync_fifo_wr_ack;
    wire            sync_fifo_full;
    // write sync fifo if cmd_info_in_fifo is not empty
    wire            sync_fifo_wr_en = cmd_info_in_fifo != 96'd0;    
    wire    [95:0]  sync_fifo_wr_data = cmd_info_in_fifo;

    wire            sync_fifo_rd_valid;
    wire            sync_fifo_empty;
    // read sync fifo if the fifo is not empty and cmd_info_to_ctrl has been taken
    wire            sync_fifo_rd_en = !sync_fifo_empty && cmd_info_to_ctrl == 96'd0 && (sync_rd_gap == 2'd0);
    wire    [95:0]  sync_fifo_rd_data;

    always @(posedge mig_clk or negedge rst_n) begin
        if (!rst_n) begin
            sync_rd_gap <= 2'd0;
        end else if (sync_fifo_rd_en) begin
            sync_rd_gap <= 2'd2;
        end else if (sync_rd_gap > 0) begin
            sync_rd_gap <= sync_rd_gap - 1'd1;
        end
    end

    sync_fifo # (
        .DATA_WIDTH(    32+32+32),
        .DEPTH(         16)
    ) cmd_sync_fifo (
        .clk(           mig_clk),
        .rst_n(         rst_n),

        .wr_en(         sync_fifo_wr_en),
        .wr_data(       sync_fifo_wr_data),
        .full(          sync_fifo_full),
        .wr_ack(        sync_fifo_wr_ack),

        .rd_en(         sync_fifo_rd_en),
        .rd_data(       sync_fifo_rd_data),
        .empty(         sync_fifo_empty),
        .rd_valid(      sync_fifo_rd_valid)
    );

    wire    [31:0]  ACT_OUT = cmd_info_to_ctrl[95:64];
    wire    [31:0]  RD_OUT  = cmd_info_to_ctrl[63:32];
    wire    [31:0]  WR_OUT  = cmd_info_to_ctrl[31:0];

    assign fm_actReq    = ACT_OUT[31];
    assign fm_actBa     = ACT_OUT[29:28];
    assign fm_actBg     = ACT_OUT[27:26];
    assign fm_actRank   = ACT_OUT[25:24];
    assign fm_actRow    = ACT_OUT[16:0];

    assign fm_rdReq     = RD_OUT[31];
    assign fm_rdBa      = RD_OUT[29:28];
    assign fm_rdBg      = RD_OUT[27:26];
    assign fm_rdRank    = RD_OUT[25:24];
    assign fm_rdCol     = RD_OUT[9:0];

    assign fm_wrReq     = WR_OUT[31];
    assign fm_wrBa      = WR_OUT[29:28];
    assign fm_wrBg      = WR_OUT[27:26];
    assign fm_wrRank    = WR_OUT[25:24];
    assign fm_wrCol     = WR_OUT[9:0];


    always @(posedge mig_clk) begin
        if (!rst_n) begin
            cmd_info_in_fifo <= 96'd0;
        end else if (async_fifo_rd_en) begin
            cmd_info_in_fifo <= async_fifo_rd_data;
        end else if (sync_fifo_wr_en) begin
            cmd_info_in_fifo <= 96'd0;  // cmd_info has been written to sync_fifo
        end
    end

    always @(posedge mig_clk) begin
        if (!rst_n) begin
            cmd_info_to_ctrl <= 96'd0;
        end else if (sync_fifo_rd_valid) begin
            cmd_info_to_ctrl <= sync_fifo_rd_data;
        end else if (fm_cmdTaken) begin
            cmd_info_to_ctrl <= 96'd0;  // cmd_info has been taken by famsev2_ctrl
        end
    end

    // fifos should not be full
    wire fatal_error = async_fifo_full || sync_fifo_full;


endmodule
