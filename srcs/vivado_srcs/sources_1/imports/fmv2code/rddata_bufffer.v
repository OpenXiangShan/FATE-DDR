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

// rddata_buffer.v
module rddata_buffer (

    input           dfi_clk,
    input           mig_clk,
    input           rst_n,

    //////////////dfi rddata interface//////////////
    input           dfi_rddata_en,
    output  [255:0] dfi_rddata,
    output          dfi_rddata_valid,
    //////////////dfi rddata interface//////////////

    //////////////mig rddata interface//////////////
    input           mig_rddata_en,
    input   [512:0] mig_rddata,
    //////////////mig rddata interface//////////////

    // DEBUG SIGNAL
    output          debug_RD_error,

    output          debug_sync_fifo_wr_ack,
    output          debug_sync_fifo_full,
    output          debug_sync_fifo_wr_en,

    output          debug_sync_fifo_rd_valid,
    output          debug_sync_fifo_empty,
    output          debug_sync_fifo_rd_en,

    output          debug_async_fifo_wr_ack,
    output          debug_async_fifo_full,
    output          debug_async_fifo_wr_en,

    output          debug_async_fifo_rd_valid,
    output          debug_async_fifo_empty,
    output          debug_async_fifo_rd_en
);

    wire            dfi_rddata_en_dly;
    delay_n #(
        .N(         6)
    ) wrdata_en_dly (
        .clk(       dfi_clk),
        .rst_n(     rst_n),
        .datain(    dfi_rddata_en),
        .dataout(   dfi_rddata_en_dly)
    );
    
    wire            sync_fifo_wr_ack;
    wire            sync_fifo_full;
    wire            sync_fifo_wr_en = mig_rddata_en;
    wire    [511:0] sync_fifo_wr_data = mig_rddata;

    wire            sync_fifo_rd_valid;
    wire            sync_fifo_empty;
    wire            sync_fifo_rd_en = !sync_fifo_empty;
    wire    [511:0] sync_fifo_rd_data;
    
    sync_fifo # (
        .DATA_WIDTH(    512),
        .DEPTH(         16)
    ) rddata_sync_fifo (
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
    
    reg             sync_fifo_rd_valid_next;    // the next cycle of sync_fifo_rd_valid
    wire            first_filled = sync_fifo_rd_valid;
    wire            second_filled = sync_fifo_rd_valid_next;
    
    always @(posedge mig_clk) begin
        if (!rst_n) begin
            sync_fifo_rd_valid_next <= 1'd0;
        end else begin
            sync_fifo_rd_valid_next <= sync_fifo_rd_valid;
        end
    end
    
    wire            async_fifo_wr_ack;
    wire            async_fifo_full;
    wire            async_fifo_wr_en = first_filled || second_filled;
    wire    [255:0] async_fifo_wr_data = (first_filled)  ? sync_fifo_rd_data[255:0]   :
                                         (second_filled) ? sync_fifo_rd_data[511:256] : 256'd0;

    wire            async_fifo_rd_valid;
    wire            async_fifo_empty;
    wire            async_fifo_rd_en = !async_fifo_empty && dfi_rddata_en_dly;
    wire    [255:0] async_fifo_rd_data;
    
    (* mark_debug = "true" *) wire RD_ERROR = dfi_rddata_en_dly && async_fifo_empty;
    (* mark_debug = "true" *) reg  debugError;

    assign debug_RD_error = RD_ERROR;

    always @(posedge dfi_clk) begin
        if (!rst_n) begin
            debugError <= 1'd0;
        end else begin
            debugError <= RD_ERROR;
        end
    end

    async_fifo_rddata_only # (
        .DATA_WIDTH(    256),
        .DEPTH(         16)
    ) rddata_async_fifo (
        .wr_clk(        mig_clk),
        .wr_rst_n(      rst_n),
        .wr_en(         async_fifo_wr_en),
        .wr_data(       async_fifo_wr_data),
        .full(          async_fifo_full),
        .wr_ack(        async_fifo_wr_ack),

        .debug_RD_error(debug_RD_error),        // debug

        .rd_clk(        dfi_clk),
        .rd_rst_n(      rst_n),
        .rd_en(         async_fifo_rd_en),
        .rd_data(       async_fifo_rd_data),
        .empty(         async_fifo_empty),
        .rd_valid(      async_fifo_rd_valid)
    );

    assign dfi_rddata = async_fifo_rd_data;
    assign dfi_rddata_valid = async_fifo_rd_valid;

    // DEBUG SIGNAL
    assign debug_sync_fifo_wr_ack = sync_fifo_wr_ack;
    assign debug_sync_fifo_full = sync_fifo_full;
    assign debug_sync_fifo_wr_en = sync_fifo_wr_en;
    assign debug_sync_fifo_rd_valid = sync_fifo_rd_valid;
    assign debug_sync_fifo_empty = sync_fifo_empty;
    assign debug_sync_fifo_rd_en = sync_fifo_rd_en;

    assign debug_async_fifo_wr_ack = async_fifo_wr_ack;
    assign debug_async_fifo_full = async_fifo_full;
    assign debug_async_fifo_wr_en = async_fifo_wr_en;
    assign debug_async_fifo_rd_valid = async_fifo_rd_valid;
    assign debug_async_fifo_empty = async_fifo_empty;
    assign debug_async_fifo_rd_en = async_fifo_rd_en;

endmodule
