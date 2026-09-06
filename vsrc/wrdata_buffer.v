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

// wrdata_buffer.v
module wrdata_buffer (

    input           dfi_clk,
    input           mig_clk,
    input           rst_n,

    //////////////dfi wrdata interface//////////////
    input           dfi_wrdata_en,
    input   [255:0] dfi_wrdata,
    input   [31:0]  dfi_wrdata_mask,
    //////////////dfi wrdata interface//////////////

    //////////////mig wrdata interface//////////////
    input           mig_wrdata_en,
    output  [512:0] mig_wrdata,
    output  [64:0]  mig_wrdata_mask,
    //////////////mig wrdata interface//////////////
    
    output          wrdata_filling
);
    
    // dfi_wrdata_mask: 1 means wirte, 0 means not write
    // mig_wrdata_mask: 0 means wirte, 1 means not write
    
    wire            dfi_wrdata_en_dly;
    delay_n #(
        .N(         0)
    ) wrdata_en_dly (
        .clk(       dfi_clk),
        .rst_n(     rst_n),
        .datain(    dfi_wrdata_en),
        .dataout(   dfi_wrdata_en_dly)
    );
    
    wire            async_fifo_wr_ack;
    wire            async_fifo_full;
    wire            async_fifo_wr_en = dfi_wrdata_en_dly;
    wire    [287:0] async_fifo_wr_data = { dfi_wrdata_mask, dfi_wrdata };

    wire            async_fifo_rd_valid;
    wire            async_fifo_empty;
    wire            async_fifo_rd_en = !async_fifo_empty;
    wire    [287:0] async_fifo_rd_data;

    async_fifo # (
        .DATA_WIDTH(    256+32),
        .DEPTH(         16)
    ) wrdata_async_fifo (
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
    
    reg             wrtick_hi; // The second part of the data has been filled in.
    reg     [255:0] wrdata_hi;
    reg     [31:0]  wrmask_hi;
    reg             wrtick_lo; // The first part of the data has been filled in.
    reg     [255:0] wrdata_lo;
    reg     [31:0]  wrmask_lo;

    wire wrtickDone = wrtick_hi && wrtick_lo;
    
    always @(posedge mig_clk) begin
        if (!rst_n) begin
            wrtick_lo <= 1'd0;
            wrdata_lo <= 256'd0;
            wrmask_lo <= 32'd0;
        end else if (async_fifo_rd_valid && !wrtick_lo) begin
            wrtick_lo <= 1'd1;
            wrdata_lo <= async_fifo_rd_data[255:0];
            wrmask_lo <= async_fifo_rd_data[287:256];
        end else if (wrtickDone) begin
            wrtick_lo <= 1'd0;
            wrdata_lo <= 256'd0;
            wrmask_lo <= 32'd0;
        end
    end
    
    always @(posedge mig_clk) begin
        if (!rst_n) begin
            wrtick_hi <= 1'd0;
            wrdata_hi <= 256'd0;
            wrmask_hi <= 32'd0;
        end else if (async_fifo_rd_valid && wrtick_lo) begin
            wrtick_hi <= 1'd1;
            wrdata_hi <= async_fifo_rd_data[255:0];
            wrmask_hi <= async_fifo_rd_data[287:256];
        end else if (wrtickDone) begin
            wrtick_hi <= 1'd0;
            wrdata_hi <= 256'd0;
            wrmask_hi <= 32'd0;
        end
    end
    
    reg     [575:0] wrdata_info_in_fifo;
    
    // debug signals
    wire    [511:0] debug_wrdata        = wrdata_info_in_fifo[511:0];
    wire    [63:0]  debug_wrdata_mask   = wrdata_info_in_fifo[575:512];
    
    wire            sync_fifo_wr_ack;
    wire            sync_fifo_full;
    // write sync fifo if wrdata_info_in_fifo is not empty
    wire            sync_fifo_wr_en = wrdata_info_in_fifo != 576'd0;    
    wire    [577:0] sync_fifo_wr_data = wrdata_info_in_fifo;

    wire            sync_fifo_rd_valid;
    wire            sync_fifo_empty;
    // read sync fifo if the fifo is not empty and mig phy is ready to write
    wire            sync_fifo_rd_en = !sync_fifo_empty && mig_wrdata_en;
    wire    [575:0] sync_fifo_rd_data;

    sync_fifo # (
        .DATA_WIDTH(    512+64),
        .DEPTH(         16)
    ) wrdata_sync_fifo (
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
    
    always @(posedge mig_clk) begin
        if (!rst_n) begin
            wrdata_info_in_fifo <= 576'd0;
        end else if (wrtickDone) begin
            wrdata_info_in_fifo <= { wrmask_hi, wrmask_lo, wrdata_hi, wrdata_lo };
        end else if (sync_fifo_wr_en) begin
            wrdata_info_in_fifo <= 576'd0;
        end
    end
    
    assign mig_wrdata = sync_fifo_rd_data[511:0];
    assign mig_wrdata_mask = ~sync_fifo_rd_data[575:512];
    assign wrdata_filling = sync_fifo_wr_ack;

endmodule
