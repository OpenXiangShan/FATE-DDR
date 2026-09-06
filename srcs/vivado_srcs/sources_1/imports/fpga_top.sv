/***************************************************************************************
* Copyright (c) 2021-2026 Beijing Institute of Open Source Chip (BOSC)
* Copyright (c) 2020-2026 Institute of Computing Technology, Chinese Academy of Sciences (ICT，CAS)
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
***************************************************************************************/

`timescale 1ns/1ps
`include "baiyang_parameters.svh"

module fpga_top (

    input                                                                        diff_clock_100M_n                ,
    input                                                                        diff_clock_100M_p                ,

    input diff_clock_80M_n,
    input diff_clock_80M_p,

    output [1:0]   ddr_ck_t,
    output [1:0]   ddr_ck_c,
    output [1:0]   ddr_cke,
    output [1:0]   ddr_cs_n,
    output [1:0]   ddr_odt,
    output         ddr_act_n,
    inout  [7:0]   ddr_dm_n,
    output [1:0]   ddr_bg,
    output [1:0]   ddr_ba,
    output [16:0]  ddr_a,
    output         ddr_reset_n,
    inout  [63:0]  ddr_dq,
    inout  [7:0]   ddr_dqs_t,
    inout  [7:0]   ddr_dqs_c
);

    // -------------------------------------------------------------------------
    // clock / reset
    // -------------------------------------------------------------------------
    wire                                                                         locked                      ;
    wire                                                                         cpu_clk                     ;
    wire                                                                         cpu_rst                     ;
    wire                                                                         cpu_rst_n                   ;

    reg                [                                           15: 0]        cnt                         ;

    always @(posedge cpu_clk or negedge locked) begin
        if (!locked)
            cnt <= 16'd0;
        else if (cnt <= 16'd3000)
            cnt <= cnt + 1'b1;
    end

    assign             cpu_rst                                          =        (cnt <= 16'd3000)           ;
    assign             cpu_rst_n                                        =        ~cpu_rst                    ;



    // -------------------------------------------------------------------------
    // MB minisys wires 
    // -------------------------------------------------------------------------
    wire               [                                           31: 0]        cpu2mc_araddr               ;
    wire               [                                            1: 0]        cpu2mc_arburst              ;
    wire               [                                            3: 0]        cpu2mc_arcache              ;
    wire               [                                            7: 0]        cpu2mc_arlen                ;
    wire               [                                            0: 0]        cpu2mc_arlock               ;
    wire               [                                            2: 0]        cpu2mc_arprot               ;
    wire               [                                            3: 0]        cpu2mc_arqos                ;
    wire                                                                         cpu2mc_arready              ;
    wire               [                                            3: 0]        cpu2mc_arregion             ;
    wire               [                                            2: 0]        cpu2mc_arsize               ;
    wire                                                                         cpu2mc_arvalid              ;

    wire               [                                           31: 0]        cpu2mc_awaddr               ;
    wire               [                                            1: 0]        cpu2mc_awburst              ;
    wire               [                                            3: 0]        cpu2mc_awcache              ;
    wire               [                                            7: 0]        cpu2mc_awlen                ;
    wire               [                                            0: 0]        cpu2mc_awlock               ;
    wire               [                                            2: 0]        cpu2mc_awprot               ;
    wire               [                                            3: 0]        cpu2mc_awqos                ;
    wire                                                                         cpu2mc_awready              ;
    wire               [                                            3: 0]        cpu2mc_awregion             ;
    wire               [                                            2: 0]        cpu2mc_awsize               ;
    wire                                                                         cpu2mc_awvalid              ;

    wire                                                                         cpu2mc_bready               ;
    wire               [                                            1: 0]        cpu2mc_bresp                ;
    wire                                                                         cpu2mc_bvalid               ;

    wire               [                                          255: 0]        cpu2mc_rdata                ;
    wire                                                                         cpu2mc_rlast                ;
    wire                                                                         cpu2mc_rready               ;
    wire               [                                            1: 0]        cpu2mc_rresp                ;
    wire                                                                         cpu2mc_rvalid               ;

    wire               [                                          255: 0]        cpu2mc_wdata                ;
    wire                                                                         cpu2mc_wlast                ;
    wire                                                                         cpu2mc_wready               ;
    wire               [                                           31: 0]        cpu2mc_wstrb                ;
    wire                                                                         cpu2mc_wvalid               ;

    wire                                                                         APB_M_0_clk                 ;
    wire                                                                         APB_M_0_rstn                ;
    wire               [                                           31: 0]        APB_M_0_paddr               ;
    wire                                                                         APB_M_0_penable             ;
    wire               [                                           31: 0]        APB_M_0_prdata              ;
    wire               [                                            0: 0]        APB_M_0_pready              ;
    wire               [                                            0: 0]        APB_M_0_psel                ;
    wire               [                                            0: 0]        APB_M_0_pslverr             ;
    wire               [                                           31: 0]        APB_M_0_pwdata              ;
    wire                                                                         APB_M_0_pwrite              ;


    mb_minisys_wrapper i_mb_minisys(
    .APB_M_0_clk                                     (APB_M_0_clk                    ),
    .APB_M_0_rstn                                    (APB_M_0_rstn                   ),
    .APB_M_0_paddr                                   (APB_M_0_paddr                  ),
    .APB_M_0_penable                                 (APB_M_0_penable                ),
    .APB_M_0_prdata                                  (APB_M_0_prdata                 ),
    .APB_M_0_pready                                  (APB_M_0_pready                 ),
    .APB_M_0_psel                                    (APB_M_0_psel                   ),
    .APB_M_0_pslverr                                 (APB_M_0_pslverr                ),
    .APB_M_0_pwdata                                  (APB_M_0_pwdata                 ),
    .APB_M_0_pwrite                                  (APB_M_0_pwrite                 ),

    .CLK_IN1_D_0_clk_n                               (diff_clock_100M_n                   ),
    .CLK_IN1_D_0_clk_p                               (diff_clock_100M_p                   ),

    .M02_AXI_araddr                                  (cpu2mc_araddr                  ),
    .M02_AXI_arburst                                 (cpu2mc_arburst                 ),
    .M02_AXI_arcache                                 (cpu2mc_arcache                 ),
    .M02_AXI_arlen                                   (cpu2mc_arlen                   ),
    .M02_AXI_arlock                                  (cpu2mc_arlock                  ),
    .M02_AXI_arprot                                  (cpu2mc_arprot                  ),
    .M02_AXI_arqos                                   (cpu2mc_arqos                   ),
    .M02_AXI_arready                                 (cpu2mc_arready                 ),
//    .M02_AXI_arregion                   (cpu2mc_arregion           ),
    .M02_AXI_arsize                                  (cpu2mc_arsize                  ),
    .M02_AXI_arvalid                                 (cpu2mc_arvalid                 ),

    .M02_AXI_awaddr                                  (cpu2mc_awaddr                  ),
    .M02_AXI_awburst                                 (cpu2mc_awburst                 ),
    .M02_AXI_awcache                                 (cpu2mc_awcache                 ),
    .M02_AXI_awlen                                   (cpu2mc_awlen                   ),
    .M02_AXI_awlock                                  (cpu2mc_awlock                  ),
    .M02_AXI_awprot                                  (cpu2mc_awprot                  ),
    .M02_AXI_awqos                                   (cpu2mc_awqos                   ),
    .M02_AXI_awready                                 (cpu2mc_awready                 ),
//    .M02_AXI_awregion                   (cpu2mc_awregion           ),
    .M02_AXI_awsize                                  (cpu2mc_awsize                  ),
    .M02_AXI_awvalid                                 (cpu2mc_awvalid                 ),

    .M02_AXI_bready                                  (cpu2mc_bready                  ),
    .M02_AXI_bresp                                   (cpu2mc_bresp                   ),
    .M02_AXI_bvalid                                  (cpu2mc_bvalid                  ),

    .M02_AXI_rdata                                   (cpu2mc_rdata                   ),
    .M02_AXI_rlast                                   (cpu2mc_rlast                   ),
    .M02_AXI_rready                                  (cpu2mc_rready                  ),
    .M02_AXI_rresp                                   (cpu2mc_rresp                   ),
    .M02_AXI_rvalid                                  (cpu2mc_rvalid                  ),

    .M02_AXI_wdata                                   (cpu2mc_wdata                   ),
    .M02_AXI_wlast                                   (cpu2mc_wlast                   ),
    .M02_AXI_wready                                  (cpu2mc_wready                  ),
    .M02_AXI_wstrb                                   (cpu2mc_wstrb                   ),
    .M02_AXI_wvalid                                  (cpu2mc_wvalid                  ),

    .complete                                        (1'b1                           ),
    .cpu_clk                                         (cpu_clk                        ),
    .cpu_rst_n                                       (cpu_rst_n                      ),
    .locked                                          (locked                         ) 
    );










    // ===================== Downstream DFI  =====================
    wire               [         (`MEMC_FREQ_RATIO*`MEMC_NUM_RANKS)-1: 0]        dfi_cke      ;
    wire               [         (`MEMC_FREQ_RATIO*`MEMC_NUM_RANKS)-1: 0]        dfi_odt      ;
    wire               [         (`MEMC_FREQ_RATIO*`MEMC_NUM_RANKS)-1: 0]        dfi_reset_n  ;
    wire               [         (`MEMC_FREQ_RATIO*`BY_RESET_WIDTH)-1: 0]        dfi_cs_n     ;


    logic              [    (`MEMC_FREQ_RATIO*`MEMC_DFI_ADDR_WIDTH)-1: 0]        dfi_address              ;
    logic              [         (`MEMC_FREQ_RATIO*`MEMC_BANK_BITS)-1: 0]        dfi_bank                    ;
    logic              [                           `MEMC_FREQ_RATIO-1: 0]        dfi_ras_n                   ;
    logic              [                           `MEMC_FREQ_RATIO-1: 0]        dfi_cas_n                   ;
    logic              [                           `MEMC_FREQ_RATIO-1: 0]        dfi_we_n                    ;
    logic              [                           `MEMC_FREQ_RATIO-1: 0]        dfi_act_n                   ;
    logic              [           (`MEMC_FREQ_RATIO*`MEMC_BG_BITS)-1: 0]        dfi_bg                      ;
    
    
    logic              [             (`MEMC_DFI_TOTAL_DATAEN_WIDTH-1): 0]        dfi_wrdata_en            ;
    logic              [               (`MEMC_DFI_TOTAL_DATA_WIDTH-1): 0]        dfi_wrdata                  ;
    logic              [                                           31: 0]        dfi_wdata_cs_n              ;
    logic              [               (`MEMC_DFI_TOTAL_MASK_WIDTH-1): 0]        dfi_wrdata_mask             ;

    logic              [             (`MEMC_DFI_TOTAL_DATAEN_WIDTH-1): 0]        dfi_rddata_en            ;
    logic              [               (`MEMC_DFI_TOTAL_DATA_WIDTH-1): 0]        dfi_rddata                  ;
    logic              [                                           31: 0]        dfi_rddata_cs_n             ;
    logic              [                                            7: 0]        dfi_rddata_valid            ;
    
    logic                                                                        dfi_init_complete           ;
    logic                                                                        dfi_init_start              ;

    wire c0_init_calib_complete;
    wire dfi_clk = cpu_clk;

    // Synchronize the MIG calibration-complete level into the mc_top clock
    // domain. The source is generated by the DDR/MIG clock, while mc_top
    // runs from the 25 MHz dfi_clk.
    (* ASYNC_REG = "TRUE" *) logic calib_done_sync1;
    (* ASYNC_REG = "TRUE" *) logic calib_done_sync2;
    always_ff @(posedge dfi_clk or negedge cpu_rst_n) begin
        if (!cpu_rst_n) begin
            calib_done_sync1 <= 1'b0;
            calib_done_sync2 <= 1'b0;
        end else begin
            calib_done_sync1 <= c0_init_calib_complete;
            calib_done_sync2 <= calib_done_sync1;
        end
    end
    logic init_rstn_mc;
    always_ff @(posedge APB_M_0_clk or negedge APB_M_0_rstn) begin
        if(~APB_M_0_rstn) begin
            init_rstn_mc <= 1'b0;
        end else if ((APB_M_0_paddr[15:0] == 16'h0058) && APB_M_0_psel && APB_M_0_pwrite && ~APB_M_0_pready) begin
            init_rstn_mc <= 1'b1;
        end
    end

    //Baiyang-MC
 mc_top    u_mc_top(
   .io_clk                                          (dfi_clk                       ),
   .io_rst                                          (!init_rstn_mc                     ),
   .io_phy_cal_done                                 (calib_done_sync2                ) ,

   .io_awio_awid                                    ('b0                            ),
   .io_awio_awaddr                                  ({4'b0,(cpu2mc_awaddr - 32'h8000_0000)}),
   .io_awio_awlen                                   (cpu2mc_awlen                   ),
   .io_awio_awsize                                  (cpu2mc_awsize                  ),
   .io_awio_awburst                                 (cpu2mc_awburst                 ),
   .io_awio_awuser                                  ('b0                            ),
   .io_awio_awqos                                   (cpu2mc_awqos                   ),
   .io_awio_awvalid                                 (cpu2mc_awvalid                 ),
   .io_awio_awready                                 (cpu2mc_awready                 ),


   .io_wio_wuser                                    ('b0                            ),
   .io_wio_wdata                                    (cpu2mc_wdata                   ),
   .io_wio_wstrb                                    (cpu2mc_wstrb                   ),
   .io_wio_wlast                                    (cpu2mc_wlast                   ),
   .io_wio_wvalid                                   (cpu2mc_wvalid                  ),
   .io_wio_wready                                   (cpu2mc_wready                  ),

   .io_bio_bid                                      (                               ),
   .io_bio_bresp                                    (cpu2mc_bresp                   ),
   .io_bio_buser                                    (                               ),
   .io_bio_bvalid                                   (cpu2mc_bvalid                  ),
   .io_bio_bready                                   (cpu2mc_bready                  ),


   .io_ario_araddr                                  ({4'b0,(cpu2mc_araddr - 32'h8000_0000)}),
   .io_ario_arlen                                   (cpu2mc_arlen                   ),
   .io_ario_arsize                                  (cpu2mc_arsize                  ),
   .io_ario_arburst                                 (cpu2mc_arburst                 ),
   .io_ario_aruser                                  ('b0                            ),
   .io_ario_arqos                                   (cpu2mc_arqos                   ),
   .io_ario_arvalid                                 (cpu2mc_arvalid                 ),
   .io_ario_arready                                 (cpu2mc_arready                 ),

   .io_rio_rid                                      (                               ),
   .io_rio_ruser                                    (                               ),
   .io_rio_rdata                                    (cpu2mc_rdata                   ),
   .io_rio_rresp                                    (cpu2mc_rresp                   ),
   .io_rio_rlast                                    (cpu2mc_rlast                   ),
   .io_rio_rvalid                                   (cpu2mc_rvalid                  ),
   .io_rio_rready                                   (cpu2mc_rready                  ),

   .io_apbio_pclk                                   (APB_M_0_clk                    ),
   .io_apbio_presetn                                (APB_M_0_rstn                   ),
   .io_apbio_paddr                                  (APB_M_0_paddr[11:0]            ),
   .io_apbio_pwdata                                 (APB_M_0_pwdata                 ),
   .io_apbio_pwrite                                 (APB_M_0_pwrite                 ),
   .io_apbio_psel                                   (APB_M_0_psel                   ),
   .io_apbio_penable                                (APB_M_0_penable                ),
   .io_apbio_pready                                 (APB_M_0_pready                 ),
   .io_apbio_prdata                                 (APB_M_0_prdata                 ),
   .io_apbio_pslverr                                (APB_M_0_pslverr                ),

   .io_dfi_dfictrl_dfi_cke_0_0                      (dfi_cke[0]      ),
   .io_dfi_dfictrl_dfi_cke_0_1                      (dfi_cke[1]      ),
   .io_dfi_dfictrl_dfi_cke_1_0                      (dfi_cke[2]      ),
   .io_dfi_dfictrl_dfi_cke_1_1                      (dfi_cke[3]      ),
   .io_dfi_dfictrl_dfi_odt_0_0                      (dfi_odt[0]      ),
   .io_dfi_dfictrl_dfi_odt_0_1                      (dfi_odt[1]      ),
   .io_dfi_dfictrl_dfi_odt_1_0                      (dfi_odt[2]      ),
   .io_dfi_dfictrl_dfi_odt_1_1                      (dfi_odt[3]      ),
   .io_dfi_dfictrl_dfi_reset_n_0_0                  (dfi_reset_n[0]  ),
   .io_dfi_dfictrl_dfi_reset_n_0_1                  (dfi_reset_n[1]  ),
   .io_dfi_dfictrl_dfi_reset_n_1_0                  (dfi_reset_n[2]  ),
   .io_dfi_dfictrl_dfi_reset_n_1_1                  (dfi_reset_n[3]  ),
   .io_dfi_dfictrl_dfi_cs_n_0_0                     (dfi_cs_n[0]     ),
   .io_dfi_dfictrl_dfi_cs_n_0_1                     (dfi_cs_n[1]     ),
   .io_dfi_dfictrl_dfi_cs_n_1_0                     (dfi_cs_n[2]     ),
   .io_dfi_dfictrl_dfi_cs_n_1_1                     (dfi_cs_n[3]     ),

   .io_dfi_dfictrl_dfi_address_0                    (dfi_address[17:0]           ),
   .io_dfi_dfictrl_dfi_address_1                    (dfi_address[35:18]          ),
   .io_dfi_dfictrl_dfi_bank_0                       (dfi_bank[1:0]   ),
   .io_dfi_dfictrl_dfi_bank_1                       (dfi_bank[3:2]   ),
   .io_dfi_dfictrl_dfi_ras_n_0                      (dfi_ras_n[0]                   ),
   .io_dfi_dfictrl_dfi_ras_n_1                      (dfi_ras_n[1]                   ),
   .io_dfi_dfictrl_dfi_cas_n_0                      (dfi_cas_n[0]                   ),
   .io_dfi_dfictrl_dfi_cas_n_1                      (dfi_cas_n[1]                   ),
   .io_dfi_dfictrl_dfi_we_n_0                       (dfi_we_n[0]                    ),
   .io_dfi_dfictrl_dfi_we_n_1                       (dfi_we_n[1]                    ),
   .io_dfi_dfictrl_dfi_act_n_0                      (dfi_act_n[0]                   ),
   .io_dfi_dfictrl_dfi_act_n_1                      (dfi_act_n[1]                   ),
   .io_dfi_dfictrl_dfi_bg_0                         (dfi_bg[1:0]                    ),
   .io_dfi_dfictrl_dfi_bg_1                         (dfi_bg[3:2]                    ),


   .io_dfi_dfiwrdata_dfi_wrdata_en                  (dfi_wrdata_en ),
   .io_dfi_dfiwrdata_dfi_wdata                      (dfi_wrdata                     ),
   .io_dfi_dfiwrdata_dfi_wdata_cs_n                 (dfi_wdata_cs_n                 ),
   .io_dfi_dfiwrdata_dfi_wdata_mask                 (dfi_wrdata_mask                ),
   .io_dfi_dfirddata_dfi_rddata_en                  (dfi_rddata_en ),
   .io_dfi_dfirddata_dfi_rddata                     (dfi_rddata                     ),
   .io_dfi_dfirddata_dfi_rddata_cs_n                (dfi_rddata_cs_n                ),
   .io_dfi_dfirddata_dfi_rddata_valid               ({2{dfi_rddata_valid}}          ),

   .io_dfi_dfirddata_dfi_rddata_dbi_n               ('b1                            ),
   .io_dfi_dfiupdate_dfi_ctrlupd_req                (                               ),
   .io_dfi_dfiupdate_dfi_ctrlupd_ack                (                               ),
   .io_dfi_dfiupdate_dfi_phyupd_req                 (                               ),
   .io_dfi_dfiupdate_dfi_phyupd_type                (                               ),
   .io_dfi_dfiupdate_dfi_phyupd_ack                 (                               ),
   .io_dfi_dfistatus_dfi_data_byte_disable          (                               ),
   .io_dfi_dfistatus_dfi_dram_clk_disable           (                               ),
   .io_dfi_dfistatus_dfi_freq_ratio                 (                               ),
   .io_dfi_dfistatus_dfi_init_start                 (dfi_init_start                 ),
   .io_dfi_dfistatus_dfi_init_complete              (dfi_init_complete              ),
   .io_dfi_dfistatus_dfi_parity_in                  (                               ),
   .io_dfi_dfistatus_dfi_alert_n                    (                               ),
   .io_dfi_dfitraining_dfi_rdlvl_req                (                               ),
   .io_dfi_dfitraining_dfi_phy_rdlvl_cs_n           (                               ),
   .io_dfi_dfitraining_dfi_rdlvl_en                 (                               ),
   .io_dfi_dfitraining_dfi_rdlvl_resp               (                               ),
   .io_dfi_dfitraining_dfi_rdlvl_gate_req           (                               ),
   .io_dfi_dfitraining_dfi_phy_rdlvl_gate_cs_n      (                               ),
   .io_dfi_dfitraining_dfi_rdlvl_gate_en            (                               ),
   .io_dfi_dfitraining_dfi_wrlvl_req                (                               ),
   .io_dfi_dfitraining_dfi_phy_wrlvl_cs_n           (                               ),
   .io_dfi_dfitraining_dfi_wrlvl_en                 (                               ),
   .io_dfi_dfitraining_dfi_wrlvl_strobe             (                               ),
   .io_dfi_dfitraining_dfi_wrlvl_resp               (                               ),
   .io_dfi_dfitraining_dfi_lvl_pattern              (                               ),
   .io_dfi_dfitraining_dfi_lvl_periodic             (                               ),
   .io_dfi_dfitraining_dfi_phylvl_req_cs_n          (                               ),
   .io_dfi_dfitraining_dfi_phylvl_ack_cs_n          (                               ),
   .io_dfi_dfilp_dfi_lp_ctrl_req                    (                               ),
   .io_dfi_dfilp_dfi_lp_data_req                    (                               ),
   .io_dfi_dfilp_dfi_lp_wakeup                      (                               ),
   .io_dfi_dfilp_dfi_lp_ack                         (                               )
);






    wire mig_clk;
    reg [1:0] famse_rst_sync_n;
    always @(posedge mig_clk or negedge cpu_rst_n) begin
        if (!cpu_rst_n) begin
            famse_rst_sync_n <= 2'b00;
        end else begin
            famse_rst_sync_n <= {famse_rst_sync_n[0], 1'b1};
        end
    end
    wire famse_rst_n = famse_rst_sync_n[1];
    //////////////mig cmd interface//////////////
    wire  [7:0]   mc_ACT_n;
    wire  [135:0] mc_ADR;
    wire  [15:0]  mc_BA;
    wire  [15:0]  mc_BG;
    wire  [15:0]  mc_CKE;
    wire  [15:0]  mc_CS_n;
    wire  [15:0]  mc_ODT;
    wire  [1:0]   winRank;
    wire          mcRdCAS;
    wire          mcWrCAS;
    wire  [1:0]   mcCasSlot;
    wire          mcCasSlot2;
    wire  [4:0]   winBuf;
    wire          winInjTxn;
    //////////////mig rddata interface//////////////
    wire           mig_rddata_en;
    wire   [511:0] mig_rddata;
    wire           per_rd_done;
    wire           gt_data_ready;
    //////////////mig wrdata interface//////////////
    wire           mig_wrdata_en;
    wire  [511:0] mig_wrdata;
    wire  [63:0]  mig_wrdata_mask;



famsev2_top u_famsev2_top(      
    .dfi_clk                    (dfi_clk),        
    .mig_clk                    (mig_clk),        
    .rst_n                      (famse_rst_n),
    .calDone                    (c0_init_calib_complete),

    //////////////dfi cmd interface/////////////                 
    .dfi_reset_n                (dfi_reset_n),                 
    .dfi_cke                    (dfi_cke),             
    .dfi_odt                    (dfi_odt),             
    .dfi_address                (dfi_address),                 
    .dfi_ba                     (dfi_bank),            
    .dfi_bg                     (dfi_bg),            
    .dfi_cs_n                   (dfi_cs_n),              
    .dfi_act_n                  (dfi_act_n),               
    .dfi_ras_n                  (dfi_ras_n),               
    .dfi_cas_n                  (dfi_cas_n),               
    .dfi_we_n                   (dfi_we_n),
    //////////////dfi rddata interface//////////////
    .dfi_rddata_en              (dfi_rddata_en[0]),
    .dfi_rddata                 (dfi_rddata),
    .dfi_rddata_valid           (dfi_rddata_valid),
    //////////////dfi wrdata interface//////////////
    .dfi_wrdata_en              (dfi_wrdata_en[0]),
    .dfi_wrdata                 (dfi_wrdata),
    .dfi_wrdata_mask            (dfi_wrdata_mask),

    //////////////mig cmd interface/////////////           
    .mc_ACT_n                   (mc_ACT_n),       
    .mc_ADR                     (mc_ADR),     
    .mc_BA                      (mc_BA),    
    .mc_BG                      (mc_BG),    
    .mc_CKE                     (mc_CKE),     
    .mc_CS_n                    (mc_CS_n),      
    .mc_ODT                     (mc_ODT),     
    .winRank                    (winRank),      
    .mcRdCAS                    (mcRdCAS),      
    .mcWrCAS                    (mcWrCAS),      
    .mcCasSlot                  (mcCasSlot),        
    .mcCasSlot2                 (mcCasSlot2),         
    .winBuf                     (winBuf),     
    .winInjTxn                  (winInjTxn),
    //////////////mig rddata interface/////////////    
    .mig_rddata_en              (mig_rddata_en), 
    .mig_rddata                 (mig_rddata),
    .per_rd_done                (per_rd_done),
    .gt_data_ready              (gt_data_ready),
    //////////////mig wrdata interface//////////////
    .mig_wrdata_en              (mig_wrdata_en),
    .mig_wrdata                 (mig_wrdata),
    .mig_wrdata_mask            (mig_wrdata_mask)
);


ddr4_0 u_ddr4_0 (
    .sys_rst                (cpu_rst),
    .c0_sys_clk_p           (diff_clock_80M_p),
    .c0_sys_clk_n           (diff_clock_80M_n),
    .c0_init_calib_complete (c0_init_calib_complete),
    .tCWL                   (),
    .mc_ACT_n               (mc_ACT_n),
    .mc_ADR                 (mc_ADR),
    .mc_BA                  (mc_BA),
    .mc_BG                  (mc_BG),
    .mc_CKE                 (mc_CKE),
    .mc_CS_n                (mc_CS_n),
    .mc_ODT                 (mc_ODT),
    .mcRdCAS                (mcRdCAS),
    .mcWrCAS                (mcWrCAS),
    .mcCasSlot              (mcCasSlot),
    .mcCasSlot2             (mcCasSlot2),
    .winBuf                 (winBuf),
    .winRank                (winRank),
    .per_rd_done            (per_rd_done),
    .rdData                 (mig_rddata),
    .rdDataEn               (mig_rddata_en),
    .winInjTxn              (winInjTxn),
    .gt_data_ready          (gt_data_ready),
    .wrDataEn               (mig_wrdata_en),
    .wrData                 (mig_wrdata),
    .wrDataMask             (mig_wrdata_mask),
    .c0_ddr4_act_n          (ddr_act_n),
    .c0_ddr4_adr            (ddr_a),
    .c0_ddr4_ba             (ddr_ba),
    .c0_ddr4_bg             (ddr_bg),
    .c0_ddr4_cke            (ddr_cke),
    .c0_ddr4_odt            (ddr_odt),
    .c0_ddr4_cs_n           (ddr_cs_n),
    .c0_ddr4_ck_t           (ddr_ck_t),
    .c0_ddr4_ck_c           (ddr_ck_c),
    .c0_ddr4_reset_n        (ddr_reset_n),
    .c0_ddr4_dm_dbi_n       (ddr_dm_n),
    .c0_ddr4_dq              (ddr_dq),
    .c0_ddr4_dqs_c           (ddr_dqs_c),
    .c0_ddr4_dqs_t           (ddr_dqs_t),
    .dBufAdr                (5'b0),
    .winRmw                 (1'b0),
    .dbg_clk                (),
    .dbg_bus                (),
    .c0_ddr4_ui_clk         (mig_clk),
    .c0_ddr4_ui_clk_sync_rst(),
    .addn_ui_clkout1        (),
    .addn_ui_clkout2        (),
    .rdDataAddr             (),
    .rdDataEnd              (),
    .rmw_rd_done            (),
    .wrDataAddr             ()
);

endmodule

    
