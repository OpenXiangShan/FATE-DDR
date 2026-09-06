// ddr_wrapper.v
module ddr_wrapper (
    input           sys_rst,
    input           sys_clk_p,
    input           sys_clk_n,
    // iob<>DDR4 signals
    output          ddr4_act_n,
    output  [16:0]  ddr4_adr,
    output  [1:0]   ddr4_ba,
    output  [1:0]   ddr4_bg,
    output  [1:0]   ddr4_cke,
    output  [1:0]   ddr4_odt,
    output  [1:0]   ddr4_cs_n,
    output  [1:0]   ddr4_ck_t,
    output  [1:0]   ddr4_ck_c,
    output          ddr4_reset_n,
    inout  [7:0]    ddr4_dm_dbi_n,
    inout  [63:0]   ddr4_dq,
    inout  [7:0]    ddr4_dqs_c,
    inout  [7:0]    ddr4_dqs_t,
    output          init_calib_complete,
    output          data_compare_error
);

    wire    [4:0]   dBufAdr;
    wire    [511:0] wrData;
    wire    [63:0]  wrDataMask;
    wire    [511:0] rdData;
    wire    [4:0]   rdDataAddr;
    wire    [0:0]   rdDataEn;
    wire    [0:0]   rdDataEnd;
    wire    [0:0]   per_rd_done;
    wire    [0:0]   rmw_rd_done;
    wire    [4:0]   wrDataAddr;
    wire    [0:0]   wrDataEn;
    wire    [7:0]   mc_ACT_n;
    wire    [135:0] mc_ADR;
    wire    [15:0]  mc_BA;
    wire    [15:0]  mc_BG;
    wire    [15:0]  mc_CKE;
    wire    [15:0]  mc_CS_n;
    wire    [15:0]  mc_ODT;
    wire    [0:0]   mcRdCAS;
    wire    [0:0]   mcWrCAS;
    wire    [0:0]   winInjTxn;
    wire    [0:0]   winRmw;
    wire    [4:0]   winBuf;
    wire    [1:0]   winRank;
    wire    [5:0]   tCWL;
    wire    [1: 0]  mcCasSlot;
    wire            mcCasSlot2;
    wire            gt_data_ready;
    wire            ddr4_clk;
    wire            ddr4_rst;

    wire ddr4_reset_n_int;
    assign ddr4_reset_n = ddr4_reset_n_int;
    assign data_compare_error = 'd0;

    wire sys_clk_i;
    wire sys_clk_o;

    IBUFDS # (
        .IBUF_LOW_PWR(          "FALSE")
    ) u_ibufg_sys_clk (
        .I(                     sys_clk_p),
        .IB(                    sys_clk_n),
        .O(                     sys_clk_i)
    );

    assign sys_clk_o = sys_clk_i;



    wire            dfi_clk;
    wire            mig_clk;
    wire            rst_n;
    wire            calDone;
    wire    [3:0]   dfi_reset_n;
    wire    [3:0]   dfi_cke;
    wire    [3:0]   dfi_odt;
    wire    [35:0]  dfi_address;
    wire    [3:0]   dfi_ba;
    wire    [3:0]   dfi_bg;
    wire    [3:0]   dfi_cs_n;
    wire    [1:0]   dfi_act_n;
    wire    [1:0]   dfi_ras_n;
    wire    [1:0]   dfi_cas_n;
    wire    [1:0]   dfi_we_n;
    wire            dfi_rddata_en;
    wire    [255:0] dfi_rddata;
    wire            dfi_rddata_valid;
    wire            dfi_wrdata_en;
    wire    [255:0] dfi_wrdata;
    wire    [31:0]  dfi_wrdata_mask;

    dfi_master i_dfi_master (
        .dfi_clk(               dfi_clk),
        .rst_n(                 rst_n),
        .calDone(               calDone),
        .dfi_reset_n(           dfi_reset_n),
        .dfi_cke(               dfi_cke),
        .dfi_odt(               dfi_odt),
        .dfi_address(           dfi_address),
        .dfi_ba(                dfi_ba),
        .dfi_bg(                dfi_bg),
        .dfi_cs_n(              dfi_cs_n),
        .dfi_act_n(             dfi_act_n),
        .dfi_ras_n(             dfi_ras_n),
        .dfi_cas_n(             dfi_cas_n),
        .dfi_we_n(              dfi_we_n),
        .dfi_rddata_en(         dfi_rddata_en),
        .dfi_rddata(            dfi_rddata),
        .dfi_rddata_valid(      dfi_rddata_valid),
        .dfi_wrdata_en(         dfi_wrdata_en),
        .dfi_wrdata(            dfi_wrdata),
        .dfi_wrdata_mask(       dfi_wrdata_mask)
    );

    famsev2_top i_famsev2_top (

        .dfi_clk(               dfi_clk),
        .mig_clk(			    mig_clk),
        .rst_n(				    rst_n),
        .calDone(               calDone),

        //////////////dfi cmd interface//////////////
        .dfi_reset_n(		    dfi_reset_n),
        .dfi_cke(			    dfi_cke),
        .dfi_odt(			    dfi_odt),
        .dfi_address(		    dfi_address),
        .dfi_ba(			    dfi_ba),
        .dfi_bg(			    dfi_bg),
        .dfi_cs_n(			    dfi_cs_n),
        .dfi_act_n(			    dfi_act_n),
        .dfi_ras_n(			    dfi_ras_n),
        .dfi_cas_n(			    dfi_cas_n),
        .dfi_we_n(			    dfi_we_n),
        //////////////dfi rddata interface//////////////
        .dfi_rddata_en(		    dfi_rddata_en),
        .dfi_rddata(		    dfi_rddata),
        .dfi_rddata_valid(	    dfi_rddata_valid),
        //////////////dfi wrdata interface//////////////
        .dfi_wrdata_en(		    dfi_wrdata_en),
        .dfi_wrdata(		    dfi_wrdata),
        .dfi_wrdata_mask(	    dfi_wrdata_mask),

        //////////////mig cmd interface//////////////
        .mc_ACT_n(			    mc_ACT_n),
        .mc_ADR(			    mc_ADR),
        .mc_BA(				    mc_BA),
        .mc_BG(				    mc_BG),
        .mc_CKE(			    mc_CKE),
        .mc_CS_n(			    mc_CS_n),
        .mc_ODT(			    mc_ODT),
        .winRank(			    winRank),
        .mcRdCAS(			    mcRdCAS),
        .mcWrCAS(			    mcWrCAS),
        .mcCasSlot(			    mcCasSlot),
        .mcCasSlot2(		    mcCasSlot2),
        .winBuf(			    winBuf),
        //////////////mig rddata interface//////////////
        .mig_rddata_en(		    rdDataEn),
        .mig_rddata(		    rdData),
        .per_rd_done(		    per_rd_done),
        .gt_data_ready(		    gt_data_ready),
        .winInjTxn(			    winInjTxn),
        //////////////mig wrdata interface//////////////
        .mig_wrdata_en(		    wrDataEn),
        .mig_wrdata(		    wrData),
        .mig_wrdata_mask(	    wrDataMask)
    );

    reg [4:0] clk_cnt;
    reg dfi_tick;
    always @(posedge mig_clk) begin
        if (!rst_n) begin
            clk_cnt <= 5'd0;
            dfi_tick <= 1'b1;
        end else if(clk_cnt == 5'd9) begin
            clk_cnt <= 5'd0;
            dfi_tick <= ~dfi_tick;
        end else begin
            clk_cnt <= clk_cnt + 1'b1;
        end
    end

    assign  dfi_clk = dfi_tick;
    assign  mig_clk = ddr4_clk;
    assign  rst_n   = ~ddr4_rst;
    assign  calDone = init_calib_complete;

    MIG_PHY u_MIG_PHY (
        .sys_rst(               sys_rst),
        .sys_clk_i(             sys_clk_o),

        .ddr4_ui_clk(           ddr4_clk),
        .ddr4_ui_clk_sync_rst(  ddr4_rst),
        .init_calib_complete(   init_calib_complete),

        .ddr4_act_n(            ddr4_act_n),
        .ddr4_adr(              ddr4_adr),
        .ddr4_ba(               ddr4_ba),
        .ddr4_bg(               ddr4_bg),
        .ddr4_cke(              ddr4_cke),
        .ddr4_odt(              ddr4_odt),
        .ddr4_cs_n(             ddr4_cs_n),
        .ddr4_ck_t(             ddr4_ck_t),
        .ddr4_ck_c(             ddr4_ck_c),
        .ddr4_reset_n(          ddr4_reset_n_int),
        .ddr4_dm_dbi_n(         ddr4_dm_dbi_n),
        .ddr4_dq(               ddr4_dq),
        .ddr4_dqs_c(            ddr4_dqs_c),
        .ddr4_dqs_t(            ddr4_dqs_t),

        .dBufAdr(               5'b0),
        .wrData(                wrData),
        .wrDataMask(            wrDataMask),
        .rdData(                rdData),
        .rdDataAddr(            rdDataAddr),
        .rdDataEn(              rdDataEn),
        .rdDataEnd(             rdDataEnd),
        .per_rd_done(           per_rd_done),
        .rmw_rd_done(           rmw_rd_done),
        .wrDataAddr(            wrDataAddr),
        .wrDataEn(              wrDataEn),
        .mc_ACT_n(              mc_ACT_n),
        .mc_ADR(                mc_ADR),
        .mc_BA(                 mc_BA),
        .mc_BG(                 mc_BG),
        // DRAM CKE. 8 bits for each DRAM pin. The mc_CKE signal is always set to '1'.
        .mc_CKE(                mc_CKE),
        .mc_CS_n(               mc_CS_n),
        .mc_ODT(                mc_ODT),
        // CAS command slot select. Slot0 is enabled for example design.
        .mcCasSlot(             mcCasSlot),
        // CAS slot 2 select.  mcCasSlot2 serves a similar purpose as the mcCasSlot[1:0] signal, but mcCasSlot2 is used in timing 
        // critical logic in the Phy. Slot0 is enabled for example design.
        .mcCasSlot2(            mcCasSlot2),
        .mcRdCAS(               mcRdCAS),
        .mcWrCAS(               mcWrCAS),
        // Optional read command type indication. The winInjTxn signal is set to '0' for example design.
        .winInjTxn(             winInjTxn),
        // Optional read command type indication. The winRmw signal is set to '0' for example design.
        .winRmw(                {1{1'b0}}),
        // Update VT Tracking. The gt_data_ready signal is set to '0' in this example design.
        // This signal must be asserted periodically to keep the DQS Gate aligned as voltage and temperature drift.
        // For more information, Refer to PG150 document.
        .gt_data_ready(         gt_data_ready),
        .winBuf(                winBuf),
        .winRank(               winRank), 
        .tCWL(                  tCWL)
    );

endmodule