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

// mig_phy_odt.v
module mig_phy_odt (
    input  wire        clk,
    input  wire        rst_n,      // active-low reset
    input  wire        winWrite,   // write CAS pulse (1 = write command)
    output wire [15:0] mc_ODT      // ODT pins waveform, 8 bits per fabric cycle
);

    // Fixed pulse pattern derived from original parameters:
    //   pulse = 32'hFFFFFFFF << (32 - 2*ODTWRDUR) = 32'hFFF00000
    //   bits[31:24] = 0xFF (first 8 bit-times high)
    //   bits[23:0]  = 24'hF00000 (next 4 bit-times high)
    localparam [23:0] PULSE_LOW24 = 24'hF00000;  // lower 24 bits of pulse
    localparam [7:0]  PULSE_HIGH8 = 8'hFF;       // high byte of pulse

    // Shift register holds the remaining ODT waveform for future cycles.
    // It stores the lower 24 bits of the current command's pulse and shifts
    // left by 8 bits every fabric cycle.
    reg [23:0] odt_shift;
    wire [23:0] odt_shift_next;

    // Next shift register value: old content shifted left by 8, OR'ed with
    // the new command's lower pulse if a write CAS is issued.
    assign odt_shift_next = {odt_shift[15:0], 8'b0}
                          | (winWrite ? PULSE_LOW24 : 24'h0);

    // Current cycle output byte before bit reversal: OR of the high 8 bits
    // from the shift register and the high byte of the current pulse.
    wire [7:0] odt_reverse = odt_shift[23:16]
                           | (winWrite ? PULSE_HIGH8 : 8'h0);

    // Reverse bit order to match XiPhy serialization (LSB first).
    assign mc_ODT[7:0] = {odt_reverse[0], odt_reverse[1],
                          odt_reverse[2], odt_reverse[3],
                          odt_reverse[4], odt_reverse[5],
                          odt_reverse[6], odt_reverse[7]};

    // ODT pin 1 is permanently disabled (ODTWR[1] = 0 in original config).
    assign mc_ODT[15:8] = 8'h00;

    // Synchronous update with active-low reset.
    always @(posedge clk) begin
        if (!rst_n)
            odt_shift <= 24'h0;
        else
            odt_shift <= odt_shift_next;
    end

endmodule