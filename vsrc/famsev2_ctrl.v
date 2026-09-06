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

// famsev2_ctrl.v
module famsev2_ctrl (

    input           mig_clk,
    input           rst_n,

    // cmd info
    output          fm_cmdTaken,

    input           fm_actReq,
    input   [1:0]   fm_actBa,
    input   [1:0]   fm_actBg,
    input   [16:0]  fm_actRow,
    input   [1:0]   fm_actRank,

    input           fm_rdReq,
    input   [1:0]   fm_rdBa,
    input   [1:0]   fm_rdBg,
    input   [9:0]   fm_rdCol,
    input   [1:0]   fm_rdRank,

    input           fm_wrReq,
    input   [1:0]   fm_wrBa,
    input   [1:0]   fm_wrBg,
    input   [9:0]   fm_wrCol,
    input   [1:0]   fm_wrRank,

    ////////////////////
    // to MIG PHY DRIVER
    ////////////////////

    // ACT CMD
    output          actReq,
    output  [1:0]   actBa,
    output  [1:0]   actBg,
    output  [16:0]  actRow,
    output  [1:0]   actRank,
    // RDA CMD
    output          rdaReq,  // Read with Auto Precharge
    output  [1:0]   rdaBa,
    output  [1:0]   rdaBg,
    output  [9:0]   rdaCol,
    output  [1:0]   rdaRank,
    // WRA CMD
    output          wraReq, // Write with Auto Precharge
    output  [1:0]   wraBa,
    output  [1:0]   wraBg,
    output  [9:0]   wraCol,
    output  [1:0]   wraRank,
    // REF CMD
    output          refReq,
    output  [1:0]   refRank,
    // ZQS CMD
    output          zqsReq,
    output  [1:0]   zqsRank,
    
    // to rddata_buff
    output          rddata_ignore,

    // DEBUG SIGNAL
    input           debug_RD_error,
    input           debug_cmd_fifo_empty,
    output          debug_sta_rst,
    output          debug_sta_idl,
    output          debug_act_cmd,
    output          debug_act_wat,
    output          debug_rda_cmd,
    output          debug_rda_wat,
    output          debug_wra_cmd,
    output          debug_wra_wat,
    output          debug_ref_cmd,
    output          debug_ref_wat,
    output          debug_zqs_cmd,
    output          debug_zqs_wat,
    output          debug_vat_cmd,
    output          debug_vat_wat,
    output          debug_vrd_cmd,
    output          debug_vrd_wat
);

    reg [16:0]  ActivatedRowMem[0:31];  // ActivatedRow = ActivatedRowMem[Rank, BG, BA];

    localparam STA_RET = 8'd0; // RESET
    localparam STA_IDL = 8'd1; // IDLE

    localparam ACT_CMD = 8'd10;
    localparam ACT_WAT = 8'd11;
    localparam RDA_CMD = 8'd20;
    localparam RDA_WAT = 8'd21;
    localparam WRA_CMD = 8'd30;
    localparam WRA_WAT = 8'd31;

    localparam REF_CMD = 8'd40;
    localparam REF_WAT = 8'd41;
    localparam ZQS_CMD = 8'd50;
    localparam ZQS_WAT = 8'd51;

    localparam VAT_CMD = 8'd100; // a VT read is triggered every 200 cycles without a read operation.
    localparam VAT_WAT = 8'd101; // 200 cycles equal to 1 us when MIG PHY run at 200MHZ
    localparam VRD_CMD = 8'd102;
    localparam VRD_WAT = 8'd103;
    
    reg     [31:0]  vtt_watch_dog;
    reg     [31:0]  ref_watch_dog;
    reg     [31:0]  zqs_watch_dog;
    
    localparam VTT_WATCH_DOG = 187;     // 200 - something
    localparam REF_WATCH_DOG = 600;     // 6 us (per Rank)
    localparam ZQS_WATCH_DOG = 60000;   // 60 ms (per Rank)
    
    wire    vtt_wd_ov = vtt_watch_dog >= VTT_WATCH_DOG;
    wire    ref_wd_ov = ref_watch_dog >= REF_WATCH_DOG;
    wire    zqs_wd_ov = zqs_watch_dog >= ZQS_WATCH_DOG;

    wire    [1:0]   wd_ov_cnt = vtt_wd_ov + ref_wd_ov + zqs_wd_ov;
    wire    WD_ERROR = wd_ov_cnt > 2'd1;    // two or three watchdog overflow is critical error

    reg     [7:0]   wait_cnt_act;
    reg     [7:0]   wait_cnt_rda;
    reg     [7:0]   wait_cnt_wra;
    reg     [7:0]   wait_cnt_ref;
    reg     [7:0]   wait_cnt_zqs;
    reg     [7:0]   wait_cnt_vat;
    reg     [7:0]   wait_cnt_vrd;
    
    localparam WAIT_CNT_ACT = 4;
    localparam WAIT_CNT_RDA = 18;   // RD + PRE = 12 + 6 = 18
    localparam WAIT_CNT_WRA = 13;   // WR + PRE = 7 + 6 = 13
    localparam WAIT_CNT_REF = 70;
    localparam WAIT_CNT_ZQS = 32;
    localparam WAIT_CNT_VAT = 9;
    localparam WAIT_CNT_VRD = 10;

    // localparam WAIT_CNT_ACT = 2;
    // localparam WAIT_CNT_RDA = 15;   // RD + PRE = 12 + 3 = 15
    // localparam WAIT_CNT_WRA = 10;   // WR + PRE = 7 + 3 = 10
    // localparam WAIT_CNT_REF = 70;
    // localparam WAIT_CNT_ZQS = 32;
    // localparam WAIT_CNT_VAT = 6;
    // localparam WAIT_CNT_VRD = 13;

    reg     [7:0]   state;
    wire    [7:0]   next_state;

    always @(posedge mig_clk) begin
        if (!rst_n) begin
            state <= STA_RET;
        end else begin
            state <= next_state;
        end
    end
    
    wire sta_rst = state == STA_RET;
    wire sta_idl = state == STA_IDL;
    wire act_cmd = state == ACT_CMD;
    wire act_wat = state == ACT_WAT;
    wire rda_cmd = state == RDA_CMD;
    wire rda_wat = state == RDA_WAT;
    wire wra_cmd = state == WRA_CMD;
    wire wra_wat = state == WRA_WAT;
    wire ref_cmd = state == REF_CMD;
    wire ref_wat = state == REF_WAT;
    wire zqs_cmd = state == ZQS_CMD;
    wire zqs_wat = state == ZQS_WAT;
    wire vat_cmd = state == VAT_CMD;
    wire vat_wat = state == VAT_WAT;
    wire vrd_cmd = state == VRD_CMD;
    wire vrd_wat = state == VRD_WAT;
    
    reg ActDone;
    always @(posedge mig_clk) begin
        if (!rst_n) begin
            ActDone <= 1'd0;
        end else if (act_cmd) begin
            ActDone <= 1'd1;
        end else if (rda_cmd || wra_cmd) begin
            ActDone <= 1'd0;
        end
    end
    
    reg VatDone;
    always @(posedge mig_clk) begin
        if (!rst_n) begin
            VatDone <= 1'd0;
        end else if (vat_cmd) begin
            VatDone <= 1'd1;
        end else if (vrd_cmd) begin
            VatDone <= 1'd0;
        end
    end

    wire famse_busy = vat_cmd || vat_wat || vrd_cmd || vrd_wat || VatDone || ref_cmd || ref_wat || zqs_cmd || zqs_wat;

    wire to_act_cmd = sta_idl && (fm_rdReq || fm_wrReq) && !ActDone && !vtt_wd_ov && !ref_wd_ov && !zqs_wd_ov;
    wire to_rda_cmd = sta_idl && fm_rdReq && ActDone;
    wire to_wra_cmd = sta_idl && fm_wrReq && ActDone;
    
    wire to_zqs_cmd = sta_idl && zqs_wd_ov && !ref_wd_ov && !vtt_wd_ov && !ActDone;
    wire to_ref_cmd = sta_idl && ref_wd_ov && !vtt_wd_ov && !ActDone;
    
    wire to_vat_cmd = sta_idl && vtt_wd_ov && !VatDone && !ActDone;
    wire to_vrd_cmd = sta_idl && vtt_wd_ov && VatDone;

    wire to_act_wat = act_cmd || act_wat && (wait_cnt_act < WAIT_CNT_ACT);
    wire to_rda_wat = rda_cmd || rda_wat && (wait_cnt_rda < WAIT_CNT_RDA);
    wire to_wra_wat = wra_cmd || wra_wat && (wait_cnt_wra < WAIT_CNT_WRA);
    wire to_ref_wat = ref_cmd || ref_wat && (wait_cnt_ref < WAIT_CNT_REF);
    wire to_zqs_wat = zqs_cmd || zqs_wat && (wait_cnt_zqs < WAIT_CNT_ZQS);
    wire to_vat_wat = vat_cmd || vat_wat && (wait_cnt_vat < WAIT_CNT_VAT);
    wire to_vrd_wat = vrd_cmd || vrd_wat && (wait_cnt_vrd < WAIT_CNT_VRD);

    wire to_sta_idl = act_wat && (wait_cnt_act == WAIT_CNT_ACT) ||
                      rda_wat && (wait_cnt_rda == WAIT_CNT_RDA) ||
                      wra_wat && (wait_cnt_wra == WAIT_CNT_WRA) ||
                      ref_wat && (wait_cnt_ref == WAIT_CNT_REF) ||
                      zqs_wat && (wait_cnt_zqs == WAIT_CNT_ZQS) ||
                      vat_wat && (wait_cnt_vat == WAIT_CNT_VAT) ||
                      vrd_wat && (wait_cnt_vrd == WAIT_CNT_VRD) || 
                      !fm_rdReq && !fm_wrReq && !zqs_wd_ov && !ref_wd_ov && !vtt_wd_ov ||
                      sta_rst;

    wire    [7:0]   next_state_is_act_cmd = ( to_act_cmd ) ? ACT_CMD : 8'd0;
    wire    [7:0]   next_state_is_rda_cmd = ( to_rda_cmd ) ? RDA_CMD : 8'd0;
    wire    [7:0]   next_state_is_wra_cmd = ( to_wra_cmd ) ? WRA_CMD : 8'd0;
    wire    [7:0]   next_state_is_ref_cmd = ( to_ref_cmd ) ? REF_CMD : 8'd0;
    wire    [7:0]   next_state_is_zqs_cmd = ( to_zqs_cmd ) ? ZQS_CMD : 8'd0;
    wire    [7:0]   next_state_is_vat_cmd = ( to_vat_cmd ) ? VAT_CMD : 8'd0;
    wire    [7:0]   next_state_is_vrd_cmd = ( to_vrd_cmd ) ? VRD_CMD : 8'd0;

    wire    [7:0]   next_state_is_act_wat = ( to_act_wat ) ? ACT_WAT : 8'd0;
    wire    [7:0]   next_state_is_rda_wat = ( to_rda_wat ) ? RDA_WAT : 8'd0;
    wire    [7:0]   next_state_is_wra_wat = ( to_wra_wat ) ? WRA_WAT : 8'd0;
    wire    [7:0]   next_state_is_ref_wat = ( to_ref_wat ) ? REF_WAT : 8'd0;
    wire    [7:0]   next_state_is_zqs_wat = ( to_zqs_wat ) ? ZQS_WAT : 8'd0;
    wire    [7:0]   next_state_is_vat_wat = ( to_vat_wat ) ? VAT_WAT : 8'd0;
    wire    [7:0]   next_state_is_vrd_wat = ( to_vrd_wat ) ? VRD_WAT : 8'd0;

    wire    [7:0]   next_state_is_sta_idl = ( to_sta_idl ) ? STA_IDL : 8'd0;

    assign next_state = next_state_is_act_cmd | next_state_is_act_wat |
                        next_state_is_rda_cmd | next_state_is_rda_wat |
                        next_state_is_wra_cmd | next_state_is_wra_wat |
                        next_state_is_ref_cmd | next_state_is_ref_wat |
                        next_state_is_zqs_cmd | next_state_is_zqs_wat |
                        next_state_is_vat_cmd | next_state_is_vat_wat |
                        next_state_is_vrd_cmd | next_state_is_vrd_wat | next_state_is_sta_idl;
    
    wire    [1:0]   rwBa    = (fm_rdReq) ? fm_rdBa :
                              (fm_wrReq) ? fm_wrBa : 2'd0;
    wire    [1:0]   rwBg    = (fm_rdReq) ? fm_rdBg :
                              (fm_wrReq) ? fm_wrBg : 2'd0;
    wire    [1:0]   rwRank  = (fm_rdReq) ? fm_rdRank :
                              (fm_wrReq) ? fm_wrRank : 2'd0;

    wire    [4:0]   ActRowIndex = (fm_rdReq) ? { fm_rdRank == 2'b01, fm_rdBg, fm_rdBa } :
                                  (fm_wrReq) ? { fm_wrRank == 2'b01, fm_wrBg, fm_wrBa } : 5'd0;
                              
    ////////////////////
    // to MIG PHY DRIVER
    ////////////////////
    assign actReq   = act_cmd || vat_cmd;
    assign actBa    = (act_cmd) ? rwBa : 2'd0;
    assign actBg    = (act_cmd) ? rwBg : 2'd0;
    assign actRow   = (act_cmd) ? ActivatedRowMem[ActRowIndex] : 17'd0;
    assign actRank  = (act_cmd) ? rwRank : 2'b10;
    // when vat_cmd, we activate the rank 0, bg 0, ba 0 and row 0
    
    assign rdaReq   = rda_cmd || vrd_cmd;
    assign rdaBa    = (rda_cmd) ? fm_rdBa : 2'd0;
    assign rdaBg    = (rda_cmd) ? fm_rdBg : 2'd0;
    assign rdaCol   = (rda_cmd) ? fm_rdCol : 10'd0;
    assign rdaRank  = (rda_cmd) ? fm_rdRank : 2'b10;
    // when vrd_cmd, we read the rank 0, bg 0, ba 0 and col 0
    
    assign wraReq   = wra_cmd;
    assign wraBa    = (wra_cmd) ? fm_wrBa : 2'd0;
    assign wraBg    = (wra_cmd) ? fm_wrBg : 2'd0;
    assign wraCol   = (wra_cmd) ? fm_wrCol : 10'd0;
    assign wraRank  = (wra_cmd) ? fm_wrRank : 2'b10;
    
    reg     [1:0]   refRankTurn;
    always @(posedge mig_clk) begin
        if (!rst_n) begin
            refRankTurn <= 2'b10;
        end else if (ref_cmd) begin
            refRankTurn <= ~refRankTurn;
        end
    end
    
    assign refReq   = ref_cmd;
    assign refRank  = refRankTurn;
    
    reg     [1:0]   zqsRankTurn;
    always @(posedge mig_clk) begin
        if (!rst_n) begin
            zqsRankTurn <= 2'b10;
        end else if (zqs_cmd) begin
            zqsRankTurn <= ~zqsRankTurn;
        end
    end
    
    assign zqsReq   = zqs_cmd;
    assign zqsRank  = zqsRankTurn;
    
    always @(posedge mig_clk) begin
        if (!rst_n) begin
            vtt_watch_dog <= 32'd0;
        end else if (vrd_cmd) begin
            vtt_watch_dog <= vtt_watch_dog - 32'd199;
        end else begin
            vtt_watch_dog <= vtt_watch_dog + 32'd1;
        end
    end
    
    always @(posedge mig_clk) begin
        if (!rst_n) begin
            ref_watch_dog <= 32'd137;
        end else if (ref_cmd) begin
            ref_watch_dog <= ref_watch_dog - (REF_WATCH_DOG - 1);
        end else begin
            ref_watch_dog <= ref_watch_dog + 32'd1;
        end
    end

    always @(posedge mig_clk) begin
        if (!rst_n) begin
            zqs_watch_dog <= ZQS_WATCH_DOG - 282;
        end else if (zqs_cmd) begin
            zqs_watch_dog <= zqs_watch_dog - (ZQS_WATCH_DOG - 1);
        end else begin
            zqs_watch_dog <= zqs_watch_dog + 32'd1;
        end
    end

    reg     [63:0]  mig_cnt;
    always @(posedge mig_clk) begin
        if (!rst_n) begin
            mig_cnt <= 64'd0;
        end else begin
            mig_cnt <= mig_cnt + 32'd1;
        end
    end

    always @(posedge mig_clk) begin
        if (!rst_n) begin
            wait_cnt_act <= 8'd0;
        end else if (act_wat) begin
            wait_cnt_act <= wait_cnt_act + 8'd1;
        end else if (wait_cnt_act > WAIT_CNT_ACT) begin
            wait_cnt_act <= 8'd0;
        end
    end

    always @(posedge mig_clk) begin
        if (!rst_n) begin
            wait_cnt_rda <= 8'd0;
        end else if (rda_wat) begin
            wait_cnt_rda <= wait_cnt_rda + 8'd1;
        end else if (wait_cnt_rda > WAIT_CNT_RDA) begin
            wait_cnt_rda <= 8'd0;
        end
    end

    always @(posedge mig_clk) begin
        if (!rst_n) begin
            wait_cnt_wra <= 8'd0;
        end else if (wra_wat) begin
            wait_cnt_wra <= wait_cnt_wra + 8'd1;
        end else if (wait_cnt_wra > WAIT_CNT_WRA) begin
            wait_cnt_wra <= 8'd0;
        end
    end

    always @(posedge mig_clk) begin
        if (!rst_n) begin
            wait_cnt_ref <= 8'd0;
        end else if (ref_wat) begin
            wait_cnt_ref <= wait_cnt_ref + 8'd1;
        end else if (wait_cnt_ref > WAIT_CNT_REF) begin
            wait_cnt_ref <= 8'd0;
        end
    end

    always @(posedge mig_clk) begin
        if (!rst_n) begin
            wait_cnt_zqs <= 8'd0;
        end else if (zqs_wat) begin
            wait_cnt_zqs <= wait_cnt_zqs + 8'd1;
        end else if (wait_cnt_zqs > WAIT_CNT_ZQS) begin
            wait_cnt_zqs <= 8'd0;
        end
    end

    always @(posedge mig_clk) begin
        if (!rst_n) begin
            wait_cnt_vat <= 8'd0;
        end else if (vat_wat) begin
            wait_cnt_vat <= wait_cnt_vat + 8'd1;
        end else if (wait_cnt_vat > WAIT_CNT_VAT) begin
            wait_cnt_vat <= 8'd0;
        end
    end

    always @(posedge mig_clk) begin
        if (!rst_n) begin
            wait_cnt_vrd <= 8'd0;
        end else if (vrd_wat) begin
            wait_cnt_vrd <= wait_cnt_vrd + 8'd1;
        end else if (wait_cnt_vrd > WAIT_CNT_VRD) begin
            wait_cnt_vrd <= 8'd0;
        end
    end
    
    wire            ActRank1 = fm_actRank == 2'b01;
    wire    [4:0]   ActRowMemIndex = { ActRank1, fm_actBg, fm_actBa };
    
    always @(posedge mig_clk) begin
        if (!rst_n) begin
            ActivatedRowMem[0] <= 17'd0;
            ActivatedRowMem[1] <= 17'd0;
            ActivatedRowMem[2] <= 17'd0;
            ActivatedRowMem[3] <= 17'd0;
            ActivatedRowMem[4] <= 17'd0;
            ActivatedRowMem[5] <= 17'd0;
            ActivatedRowMem[6] <= 17'd0;
            ActivatedRowMem[7] <= 17'd0;
            ActivatedRowMem[8] <= 17'd0;
            ActivatedRowMem[9] <= 17'd0;
            ActivatedRowMem[10] <= 17'd0;
            ActivatedRowMem[11] <= 17'd0;
            ActivatedRowMem[12] <= 17'd0;
            ActivatedRowMem[13] <= 17'd0;
            ActivatedRowMem[14] <= 17'd0;
            ActivatedRowMem[15] <= 17'd0;
            ActivatedRowMem[16] <= 17'd0;
            ActivatedRowMem[17] <= 17'd0;
            ActivatedRowMem[18] <= 17'd0;
            ActivatedRowMem[19] <= 17'd0;
            ActivatedRowMem[20] <= 17'd0;
            ActivatedRowMem[21] <= 17'd0;
            ActivatedRowMem[22] <= 17'd0;
            ActivatedRowMem[23] <= 17'd0;
            ActivatedRowMem[24] <= 17'd0;
            ActivatedRowMem[25] <= 17'd0;
            ActivatedRowMem[26] <= 17'd0;
            ActivatedRowMem[27] <= 17'd0;
            ActivatedRowMem[28] <= 17'd0;
            ActivatedRowMem[29] <= 17'd0;
            ActivatedRowMem[30] <= 17'd0;
            ActivatedRowMem[31] <= 17'd0;
        end else if (sta_idl && fm_actReq) begin
            ActivatedRowMem[ActRowMemIndex] <= fm_actRow;
        end
    end
    
    assign fm_cmdTaken = (sta_idl && fm_actReq) || rda_cmd || wra_cmd;
    
    reg     [31:0]   ignore_cnt;
    always @(posedge mig_clk) begin
        if (!rst_n) begin
            ignore_cnt <= 32'd21;
        end else if (vrd_cmd) begin
            ignore_cnt <= 32'd0;
        end else begin
            ignore_cnt <= ignore_cnt + 32'd1;
        end
    end
    // we ignore the rddata from mig phy during the 10th to 20th cycle after vrd_cmd
    assign rddata_ignore = ignore_cnt > 10 && ignore_cnt <= 20;

    // DEBUG SIGNAL
    assign debug_sta_rst = sta_rst;
    assign debug_sta_idl = sta_idl;
    assign debug_act_cmd = act_cmd;
    assign debug_act_wat = act_wat;
    assign debug_rda_cmd = rda_cmd;
    assign debug_rda_wat = rda_wat;
    assign debug_wra_cmd = wra_cmd;
    assign debug_wra_wat = wra_wat;
    assign debug_ref_cmd = ref_cmd;
    assign debug_ref_wat = ref_wat;
    assign debug_zqs_cmd = zqs_cmd;
    assign debug_zqs_wat = zqs_wat;
    assign debug_vat_cmd = vat_cmd;
    assign debug_vat_wat = vat_wat;
    assign debug_vrd_cmd = vrd_cmd;
    assign debug_vrd_wat = vrd_wat;

    ila_ctrl i_ila_ctrl(
        .clk(       mig_clk),

        .probe0(    fm_cmdTaken),
        .probe1(    fm_actReq),
        .probe2(    fm_rdReq),
        .probe3(    fm_wrReq),

        .probe4(    debug_RD_error),
        .probe5(    debug_cmd_fifo_empty),

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
        .probe21(   debug_vrd_wat)
    );

endmodule
