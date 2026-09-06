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

// mig_phy_driver.v
// only combinational logic
module mig_phy_driver (
    // ACT CMD
    input           actReq,
    input   [1:0]   actBa,
    input   [1:0]   actBg,
    input   [16:0]  actRow,
    input   [1:0]   actRank,
    // RDA CMD
    input           rdaReq,  // Read with Auto Precharge
    input   [1:0]   rdaBa,
    input   [1:0]   rdaBg,
    input   [9:0]   rdaCol,
    input   [1:0]   rdaRank,
    // WRA CMD
    input           wraReq, // Write with Auto Precharge
    input   [1:0]   wraBa,
    input   [1:0]   wraBg,
    input   [9:0]   wraCol,
    input   [1:0]   wraRank,
    // REF CMD
    input           refReq,
    input   [1:0]   refRank,
    // ZQS CMD
    input           zqsReq,
    input   [1:0]   zqsRank,

    // mig phy cmd interface
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
    output          winInjTxn
);

    // mc_CS_n (16-bit), it is an extremely ugly design by mig phy, no choice but to accept it.
    // +-------+-------+-------+-------+-------+-------+-------+-------+-------+-------+-------+-------+-------+-------+-------+-------+-------+
    // |  bit  |  15   |  14   |  13   |  12   |  11   |  10   |   9   |   8   |   7   |   6   |   5   |   4   |   3   |   2   |   1   |   0   |
    // +-------+-------+-------+-------+-------+-------+-------+-------+-------+-------+-------+-------+-------+-------+-------+-------+-------+
    // | slots |     slot3     |     slot2     |     slot1     |     slot0     |     slot3     |     slot2     |     slot1     |     slot0     |
    // +-------+-------+-------+-------+-------+-------+-------+-------+-------+-------+-------+-------+-------+-------+-------+-------+-------+
    // |       |                            cs_n[1]                            |                            cs_n[0]                            |
    // +-------+-------+-------+-------+-------+-------+-------+-------+-------+-------+-------+-------+-------+-------+-------+-------+-------+
    // we only use slot0.
    
    assign mc_CS_n  = (actReq) ? { 6'b111111, actRank[1], actRank[1], 6'b111111, actRank[0], actRank[0] } :
                      (rdaReq) ? { 6'b111111, rdaRank[1], rdaRank[1], 6'b111111, rdaRank[0], rdaRank[0] } :
                      (wraReq) ? { 6'b111111, wraRank[1], wraRank[1], 6'b111111, wraRank[0], wraRank[0] } :
                      (refReq) ? { 6'b111111, refRank[1], refRank[1], 6'b111111, refRank[0], refRank[0] } :
                      (zqsReq) ? { 6'b111111, zqsRank[1], zqsRank[1], 6'b111111, zqsRank[0], zqsRank[0] } : 16'hffff;
    
    // Similar mapping rules to mc_CS_n
    assign mc_BA    = (actReq) ? { 6'b111111, actBa[1], actBa[1], 6'b111111, actBa[0], actBa[0] } :
                      (rdaReq) ? { 6'b111111, rdaBa[1], rdaBa[1], 6'b111111, rdaBa[0], rdaBa[0] } :
                      (wraReq) ? { 6'b111111, wraBa[1], wraBa[1], 6'b111111, wraBa[0], wraBa[0] } : 16'd0;

    assign mc_BG    = (actReq) ? { 6'b111111, actBg[1], actBg[1], 6'b111111, actBg[0], actBg[0] } :
                      (rdaReq) ? { 6'b111111, rdaBg[1], rdaBg[1], 6'b111111, rdaBg[0], rdaBg[0] } :
                      (wraReq) ? { 6'b111111, wraBg[1], wraBg[1], 6'b111111, wraBg[0], wraBg[0] } : 16'd0;

    assign mc_ACT_n = (actReq) ? 8'b11111100 : 8'b11111111;

    // DDR Command Truth Table
    // actReq, ACT: cs_n = L, act_n = L, RowAddr valid
    // rdaReq, RDA: cs_n = L, act_n = H, ras_n = H, cas_n = L, we_n = H, ap = H
    // wraReq, WRA: cs_n = L, act_n = H, ras_n = H, cas_n = L, we_n = L, ap = H
    // refReq, REF: cs_n = L, act_n = H, ras_n = L, cas_n = L, we_n = H
    // zqsReq, ZQS: cs_n = L, act_n = H, ras_n = H, cas_n = H, we_n = H
    wire ras_n   = rdaReq || wraReq || zqsReq;      // ADR_16
    wire cas_n   = zqsReq;                          // ADR_15
    wire we_n    = rdaReq || refReq || zqsReq;      // ADR_14
    wire ap      = rdaReq || wraReq;                // ADR_10

    assign mc_ADR = (actReq) ? { 6'b111111, actRow[16], actRow[16], 
                                 6'b111111, actRow[15], actRow[15],
                                 6'b111111, actRow[14], actRow[14],
                                 6'b111111, actRow[13], actRow[13],
                                 6'b111111, actRow[12], actRow[12], 
                                 6'b111111, actRow[11], actRow[11],
                                 6'b111111, actRow[10], actRow[10],
                                 6'b111111, actRow[9], actRow[9],
                                 6'b111111, actRow[8], actRow[8],
                                 6'b111111, actRow[7], actRow[7],
                                 6'b111111, actRow[6], actRow[6],
                                 6'b111111, actRow[5], actRow[5],
                                 6'b111111, actRow[4], actRow[4],
                                 6'b111111, actRow[3], actRow[3],
                                 6'b111111, actRow[2], actRow[2],
                                 6'b111111, actRow[1], actRow[1],
                                 6'b111111, actRow[0], actRow[0] } :
                    (rdaReq) ? { 6'b111111, ras_n, ras_n, 
                                 6'b111111, cas_n, cas_n,
                                 6'b111111, we_n, we_n,
                                 6'b111111, 2'b11,
                                 6'b111111, 2'b11,
                                 6'b111111, 2'b11,
                                 6'b111111, ap, ap,
                                 6'b111111, rdaCol[9], rdaCol[9],
                                 6'b111111, rdaCol[8], rdaCol[8],
                                 6'b111111, rdaCol[7], rdaCol[7],
                                 6'b111111, rdaCol[6], rdaCol[6],
                                 6'b111111, rdaCol[5], rdaCol[5],
                                 6'b111111, rdaCol[4], rdaCol[4],
                                 6'b111111, rdaCol[3], rdaCol[3],
                                 6'b111111, rdaCol[2], rdaCol[2],
                                 6'b111111, rdaCol[1], rdaCol[1],
                                 6'b111111, rdaCol[0], rdaCol[0] } :
                    (wraReq) ? { 6'b111111, ras_n, ras_n, 
                                 6'b111111, cas_n, cas_n,
                                 6'b111111, we_n, we_n,
                                 6'b111111, 2'b11,
                                 6'b111111, 2'b11,
                                 6'b111111, 2'b11,
                                 6'b111111, ap, ap,
                                 6'b111111, wraCol[9], wraCol[9],
                                 6'b111111, wraCol[8], wraCol[8],
                                 6'b111111, wraCol[7], wraCol[7],
                                 6'b111111, wraCol[6], wraCol[6],
                                 6'b111111, wraCol[5], wraCol[5],
                                 6'b111111, wraCol[4], wraCol[4],
                                 6'b111111, wraCol[3], wraCol[3],
                                 6'b111111, wraCol[2], wraCol[2],
                                 6'b111111, wraCol[1], wraCol[1],
                                 6'b111111, wraCol[0], wraCol[0] } :
                    (refReq || zqsReq) ? { 
                                 6'b111111, ras_n, ras_n, 
                                 6'b111111, cas_n, cas_n,
                                 6'b111111, we_n, we_n,
                                 6'b111111, 2'b11,
                                 6'b111111, 2'b11, 
                                 6'b111111, 2'b11,
                                 6'b111111, ap, ap,
                                 6'b111111, 2'b11,
                                 6'b111111, 2'b11,
                                 6'b111111, 2'b11,
                                 6'b111111, 2'b11,
                                 6'b111111, 2'b11,
                                 6'b111111, 2'b11,
                                 6'b111111, 2'b11,
                                 6'b111111, 2'b11,
                                 6'b111111, 2'b11,
                                 6'b111111, 2'b11 } : 136'd0;


    // xxxRank[0] == 0 means Rank0 valid
    // xxxRank[1] == 0 means Rank1 valid
    // so that xxxRank must be 2'b10 or 2'b01
    // it would be illagel if xxxRank equals 2'b00 
    // and it is no cmd if xxxRank equals 2'b11 

    // winRank == 0 means Rank0 valid
    // winRank == 1 means Rank1 valid
    // winRank == 2 means Rank2 valid
    // winRank == 3 means Rank3 valid
    // read pg150 or pg353 for more details
    assign winRank = (rdaReq && rdaRank == 2'b01) ? 2'd1 :
                     (wraReq && wraRank == 2'b01) ? 2'd1 : 2'd0;

    assign mcRdCAS = rdaReq;
    assign mcWrCAS = wraReq;

    // const
    assign mc_ODT = 16'd0; // generated by ddr4_v2_2_8_cal_mc_odt
    assign mc_CKE = 16'hffff;
    assign mcCasSlot = 2'd0;
    assign mcCasSlot2 = 1'd0;
    assign winBuf = 5'd0;
    assign winInjTxn = 1'd0;

endmodule
