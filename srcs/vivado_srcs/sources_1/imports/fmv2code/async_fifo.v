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

// Attention:
// Due to the timing issue, in the scenario of slow writing and fast reading, there should be a two-clock cycle interval between each two reads.
module async_fifo #(
    parameter DATA_WIDTH = 256,
    parameter DEPTH      = 64
) (
    // Write port
    input                     wr_clk,
    input                     wr_rst_n,
    input                     wr_en,
    input [DATA_WIDTH-1:0]    wr_data,
    output                    full,
    output                    wr_ack,

    // Read port
    input                     rd_clk,
    input                     rd_rst_n,
    input                     rd_en,
    output [DATA_WIDTH-1:0]   rd_data,
    output                    empty,
    output                    rd_valid
);

    // =============================================================================
    // Critical signal
    // =============================================================================

    localparam PTR_WIDTH = $clog2(DEPTH);

    wire wr_pulse = wr_en && !full;
    wire rd_pulse = rd_en && !empty;

    // extra bit for full/empty detection
    reg [PTR_WIDTH:0] wr_bin;   
    reg [PTR_WIDTH:0] rd_bin;

    // synchronization to another domain for the full/empty flag
    wire [PTR_WIDTH:0] rd_gray = rd_bin ^ (rd_bin >> 1);
    wire [PTR_WIDTH:0] wr_gray = wr_bin ^ (wr_bin >> 1);

    // =============================================================================
    // Update wirte pointer and read pointer
    // =============================================================================

    always @(posedge wr_clk) begin
        if (!wr_rst_n) begin
            wr_bin <= 'd0;
        end else if (wr_pulse) begin
            wr_bin <= wr_bin + 1'd1;
        end
    end

    always @(posedge rd_clk) begin
        if (!rd_rst_n) begin
            rd_bin <= 'd0;
        end else if (rd_pulse) begin
            rd_bin <= rd_bin + 1'd1;
        end
    end

    // =============================================================================
    // Write BANK and read BANK
    // =============================================================================

    reg [DATA_WIDTH-1:0] BANK [0:DEPTH-1];
    wire [PTR_WIDTH-1:0] wr_addr = wr_bin[PTR_WIDTH-1:0];
    wire [PTR_WIDTH-1:0] rd_addr = rd_bin[PTR_WIDTH-1:0];

    // Write BANK
    always @(posedge wr_clk) begin
        if (wr_pulse) begin
            BANK[wr_addr] <= wr_data;
        end
    end

    // Read BANK (combinational read)
    assign rd_data = BANK[rd_addr];

    // =============================================================================
    // Write pointer synchronization to read domain for the empty flag
    // =============================================================================
    reg [PTR_WIDTH:0] wr_gray_sync1;
    reg [PTR_WIDTH:0] wr_gray_sync2;

    always @(posedge rd_clk) begin
        if (!rd_rst_n) begin
            wr_gray_sync1 <= 'd0;
            wr_gray_sync2 <= 'd0;
        end else begin
            wr_gray_sync1 <= wr_gray;
            wr_gray_sync2 <= wr_gray_sync1;
        end
    end

    assign empty = (wr_gray_sync2 == rd_gray);

    // =============================================================================
    // Read pointer synchronization to write domain for the full flag
    // =============================================================================
    reg [PTR_WIDTH:0] rd_gray_sync1;
    reg [PTR_WIDTH:0] rd_gray_sync2;

    always @(posedge wr_clk) begin
        if (!wr_rst_n) begin
            rd_gray_sync1 <= 'd0;
            rd_gray_sync2 <= 'd0;
        end else begin
            rd_gray_sync1 <= rd_gray;
            rd_gray_sync2 <= rd_gray_sync1;
        end
    end

    assign full = (wr_gray[PTR_WIDTH]       != rd_gray_sync2[PTR_WIDTH]) &&
                  (wr_gray[PTR_WIDTH-1]     != rd_gray_sync2[PTR_WIDTH-1]) &&
                  (wr_gray[PTR_WIDTH-2:0]   == rd_gray_sync2[PTR_WIDTH-2:0]);

    // =============================================================================
    // Read valid and Write ack
    // =============================================================================
    assign rd_valid = rd_pulse;

    reg ack;
    always @(posedge wr_clk) begin
        if (!wr_rst_n) begin
            ack <= 1'b0;
        end else begin
            ack <= wr_pulse;
        end
    end
    assign wr_ack = ack;

endmodule

module async_fifo_rddata_only #(
    parameter DATA_WIDTH = 256,
    parameter DEPTH      = 64
) (
    // Write port
    input                     wr_clk,
    input                     wr_rst_n,
    input                     wr_en,
    input [DATA_WIDTH-1:0]    wr_data,
    output                    full,
    output                    wr_ack,

    input                     debug_RD_error,

    // Read port
    input                     rd_clk,
    input                     rd_rst_n,
    input                     rd_en,
    output [DATA_WIDTH-1:0]   rd_data,
    output                    empty,
    output                    rd_valid
);

    // =============================================================================
    // Critical signal
    // =============================================================================

    localparam PTR_WIDTH = $clog2(DEPTH);

    wire wr_pulse = wr_en && !full;
    wire rd_pulse = rd_en && !empty;

    // extra bit for full/empty detection
    reg [PTR_WIDTH:0] wr_bin;   
    reg [PTR_WIDTH:0] rd_bin;

    // synchronization to another domain for the full/empty flag
    wire [PTR_WIDTH:0] rd_gray = rd_bin ^ (rd_bin >> 1);
    wire [PTR_WIDTH:0] wr_gray = wr_bin ^ (wr_bin >> 1);
    
    // It would be unstable if wirte fifo at the posedge of rd_clk exactly
    // so add a register of wr_gray to fix it
    reg  [PTR_WIDTH:0] wr_gray_reg;
    always @(posedge wr_clk) begin
        if (!wr_rst_n) begin
            wr_gray_reg <= 'd0;
        end else begin
            wr_gray_reg <= wr_gray;
        end
    end

    // =============================================================================
    // Update wirte pointer and read pointer
    // =============================================================================

    always @(posedge wr_clk) begin
        if (!wr_rst_n) begin
            wr_bin <= 'd0;
        end else if (wr_pulse) begin
            wr_bin <= wr_bin + 1'd1;
        end
    end

    always @(posedge rd_clk) begin
        if (!rd_rst_n) begin
            rd_bin <= 'd0;
        end else if (rd_pulse) begin
            rd_bin <= rd_bin + 1'd1;
        end
    end

    // =============================================================================
    // Write BANK and read BANK
    // =============================================================================

    reg [DATA_WIDTH-1:0] BANK [0:DEPTH-1];
    wire [PTR_WIDTH-1:0] wr_addr = wr_bin[PTR_WIDTH-1:0];
    wire [PTR_WIDTH-1:0] rd_addr = rd_bin[PTR_WIDTH-1:0];

    // Write BANK
    always @(posedge wr_clk) begin
        if (wr_pulse) begin
            BANK[wr_addr] <= wr_data;
        end
    end

    // Read BANK (combinational read)
    assign rd_data = BANK[rd_addr];

    // =============================================================================
    // Write pointer synchronization to read domain for the empty flag
    // =============================================================================
    reg [PTR_WIDTH:0] wr_gray_sync1;
    reg [PTR_WIDTH:0] wr_gray_sync2;

    always @(posedge rd_clk) begin
        if (!rd_rst_n) begin
            wr_gray_sync1 <= 'd0;
            wr_gray_sync2 <= 'd0;
        end else begin
            wr_gray_sync1 <= wr_gray_reg;
            wr_gray_sync2 <= wr_gray_sync1;
        end
    end

    assign empty = (wr_gray_sync2 == rd_gray);

    // =============================================================================
    // Read pointer synchronization to write domain for the full flag
    // =============================================================================
    reg [PTR_WIDTH:0] rd_gray_sync1;
    reg [PTR_WIDTH:0] rd_gray_sync2;

    always @(posedge wr_clk) begin
        if (!wr_rst_n) begin
            rd_gray_sync1 <= 'd0;
            rd_gray_sync2 <= 'd0;
        end else begin
            rd_gray_sync1 <= rd_gray;
            rd_gray_sync2 <= rd_gray_sync1;
        end
    end

    assign full = 0;
    // assign full = (wr_gray[PTR_WIDTH]       != rd_gray_sync2[PTR_WIDTH]) &&
    //               (wr_gray[PTR_WIDTH-1]     != rd_gray_sync2[PTR_WIDTH-1]) &&
    //               (wr_gray[PTR_WIDTH-2:0]   == rd_gray_sync2[PTR_WIDTH-2:0]);

    // =============================================================================
    // Read valid and Write ack
    // =============================================================================
    assign rd_valid = rd_pulse;

    reg ack;
    always @(posedge wr_clk) begin
        if (!wr_rst_n) begin
            ack <= 1'b0;
        end else begin
            ack <= wr_pulse;
        end
    end
    assign wr_ack = ack;

/*
    ila_afifo i_ila_afifo(
        .clk(       wr_clk),

        .probe0(    debug_RD_error),

        .probe1(    wr_rst_n),
        .probe2(    wr_en),
        .probe3(    full),
        .probe4(    wr_ack),

        .probe5(    rd_rst_n),
        .probe6(    rd_en),
        .probe7(    empty),
        .probe8(    rd_valid),

        .probe9(    wr_pulse),
        .probe10(   rd_pulse),

        .probe11(   {3'd0, wr_bin}),
        .probe12(   {3'd0, rd_bin}),
        .probe13(   {3'd0, rd_gray}),
        .probe14(   {3'd0, wr_gray}),
        .probe15(   {4'd0, wr_addr}),
        .probe16(   {4'd0, rd_addr}),
        .probe17(   {3'd0, wr_gray_sync1}),
        .probe18(   {3'd0, wr_gray_sync2}),
        .probe19(   {3'd0, rd_gray_sync1}),
        .probe20(   {3'd0, rd_gray_sync2}),

        .probe21(   {3'd0, wr_gray_reg})

    );*/

endmodule
