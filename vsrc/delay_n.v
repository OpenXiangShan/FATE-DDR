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

// delay_n.v
module delay_n #(
    parameter N = 6
) (
    input   clk,
    input   rst_n,
    input   datain,
    output  dataout
);
    
    reg [N+1:0] delay_line;
    reg         delay_out;
    
    always @(posedge clk) begin
        if (!rst_n) begin
            delay_line <= 0;
        end else begin
            delay_line <= { delay_line[N:0], datain };
        end
    end
    
    // delay line
    // t  : 0000_0000
    // t+1: 0000_0001
    // t+2: 0000_0010
    // t+3: 0000_0100
    // t+4: 0000_1000
    // t+5: 0001_0000
    // t+6: 0010_0000
    
    always @(posedge clk) begin
        if (!rst_n) begin
            delay_out <= 0;
        end else if (N >= 2) begin
            delay_out <= delay_line[N - 2];
        end else begin
            delay_out <= datain;
        end
    end
    
    assign  dataout = (N==0) ? datain : delay_out;

endmodule
