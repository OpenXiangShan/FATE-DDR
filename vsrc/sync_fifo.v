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

// sync_fifo.v
module sync_fifo #(
    parameter DATA_WIDTH = 256,
    parameter DEPTH      = 64
) (
    // Clock & Reset
    input                     clk,
    input                     rst_n,

    // Write port
    input                     wr_en,
    input [DATA_WIDTH-1:0]    wr_data,
    output                    full,
    output                    wr_ack,

    // Read port
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

    // =============================================================================
    // Update write pointer and read pointer
    // =============================================================================

    always @(posedge clk) begin
        if (!rst_n) begin
            wr_bin <= 'd0;
        end else if (wr_pulse) begin
            wr_bin <= wr_bin + 1'd1;
        end
    end

    always @(posedge clk) begin
        if (!rst_n) begin
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
    always @(posedge clk) begin
        if (wr_pulse) begin
            BANK[wr_addr] <= wr_data;
        end
    end

    // Read BANK
    reg [DATA_WIDTH-1:0] rd_data_reg;
    always @(posedge clk) begin
        if (rd_pulse) begin
            rd_data_reg <= BANK[rd_addr];
        end
    end
    assign rd_data = rd_data_reg;

    // debug signal
    wire [DATA_WIDTH-1:0] BANK_0 = BANK[0];
    wire [DATA_WIDTH-1:0] BANK_1 = BANK[1];
    wire [DATA_WIDTH-1:0] BANK_2 = BANK[2];
    wire [DATA_WIDTH-1:0] BANK_3 = BANK[3];
    wire [DATA_WIDTH-1:0] BANK_4 = BANK[4];
    wire [DATA_WIDTH-1:0] BANK_5 = BANK[5];
    wire [DATA_WIDTH-1:0] BANK_6 = BANK[6];
    wire [DATA_WIDTH-1:0] BANK_7 = BANK[7];


    // =============================================================================
    // Empty and full
    // =============================================================================
    assign empty = (wr_bin == rd_bin);

    assign full = (wr_bin[PTR_WIDTH]        != rd_bin[PTR_WIDTH]) &&
                (wr_bin[PTR_WIDTH-1:0]    == rd_bin[PTR_WIDTH-1:0]);

    // =============================================================================
    // Read valid and Write ack
    // =============================================================================

    reg valid;
    always @(posedge clk) begin
        if (!rst_n) begin
            valid <= 1'b0;
        end else begin
            valid <= rd_pulse;
        end
    end
    assign rd_valid = valid;

    reg ack;
    always @(posedge clk) begin
        if (!rst_n) begin
            ack <= 1'b0;
        end else begin
            ack <= wr_pulse;
        end
    end
    assign wr_ack = ack;

endmodule
