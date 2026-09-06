`include "DWC_ddr_umctl2_all_includes.svh"
module ddr4_wrapper (
ddr_ck_t,
ddr_ck_c,
ddr_cke,
ddr_cs_n,
ddr_odt,
ddr_act_n,
ddr_dm_n,
ddr_bg,
ddr_ba,
ddr_a,
ddr_reset_n,
ddr_dq,
ddr_dqs_t,
ddr_dqs_c,
ddr_par, // unused
ddr_alert_n, // unused
ddr_ten, // unused

core_ddrc_core_clk,
core_ddrc_rstn,
aresetn_0,              
aclk_0,                 
awid_0,                 
awaddr_0,               
awlen_0,                
awsize_0,               
awburst_0,              
awlock_0,               
awcache_0,              
awprot_0,               
awuser_0,               
awvalid_0,              
awready_0,              
awqos_0,                
awregion_0,             
wdata_0,                
wstrb_0,                
wlast_0,                
wvalid_0,               
wready_0,               
wuser_0,                
bid_0,                  
bresp_0,                
buser_0,                
bvalid_0,               
bready_0,               
arid_0,                 
araddr_0,               
arlen_0,                
arsize_0,               
arburst_0,              
arlock_0,               
arcache_0,              
arprot_0,               
aruser_0,               
arvalid_0,              
arready_0,              
arqos_0,                
arregion_0,             
rid_0,                  
rdata_0,                
rresp_0,                
ruser_0,                
rlast_0,                
rvalid_0,               
rready_0,               

mc_scanmode,
mc_scan_resetn,

bist_mode,
bist_mux,
bist_start,
bist_complete,
bist_error,
bscan_TDI,
bscan_TDO,
bscan_clockDR,
bscan_mode,
bscan_shiftDR,
bscan_updateDR,
ddr_plllock,
phy_scanclk,
phy_scanrstn,
phy_scanen,
phy_scanmode,
phy_scanin,
phy_scanout,
pclk,
presetn,
paddr_mc,
pwdata_mc,
pwrite_mc,
psel_mc,
penable_mc,
pready_mc,
prdata_mc,
pslverr_mc,
paddr_phy,
pwdata_phy,
pwrite_phy,
psel_phy,
penable_phy,
pready_phy,
prdata_phy,
bist_dfi_init_start,

axi_bus_rst_n,
rzq,
dft_mode,
dft_lgc_rstn,
scan_mode,
dft_glb_gt_se,
dfi_init_complete,
phy_bist_mode,
bist_dfi_frequency,
bist_bufferen_core,
///////////////////mig ///////////
sys_rst,
ddr_clk,
c0_ddr4_ui_clk_sync_rst,
c0_init_calib_complete,
addn_ui_clkout1,
addn_ui_clkout2

);
parameter NPORTS = `UMCTL2_A_NPORTS; // Number of ports   
parameter UMCTL2_WDATARAM_DW = `UMCTL2_WDATARAM_DW;
parameter UMCTL2_WDATARAM_AW = `UMCTL2_WDATARAM_AW;
parameter UMCTL2_WDATARAM_DEPTH = `UMCTL2_WDATARAM_DEPTH;
parameter UMCTL2_RDATARAM_DW = `UMCTL2_RDATARAM_DW;
parameter UMCTL2_RDATARAM_AW = `UMCTL2_RDATARAM_AW;
parameter UMCTL2_RDATARAM_DEPTH = `UMCTL2_RDATARAM_DEPTH;
parameter UMCTL2_DATARAM_PAR_DW = `UMCTL2_DATARAM_PAR_DW;
parameter UMCTL2_WDATARAM_PAR_DW = `UMCTL2_WDATARAM_PAR_DW;
parameter AXI_IDW = `UMCTL2_A_IDW; // AXI a*id width
parameter AXI_ADDRW = `UMCTL2_AXI_ADDRW; // AXI a*addr width
parameter AXI_LENW = `UMCTL2_A_LENW; // AXI a*len width
parameter AXI_USERW = `UMCTL2_AXI_USER_WIDTH_INT;
parameter OCPAR_ADDR_PARITY_WIDTH = `UMCTL2_OCPAR_ADDR_PARITY_W;
localparam AXI_SIZEW  = `UMCTL2_AXI_SIZE_WIDTH; // AXI a*size width
localparam AXI_BURSTW = `UMCTL2_AXI_BURST_WIDTH; // AXI a*burst width
localparam AXI_LOCKW  = `UMCTL2_AXI_LOCK_WIDTH; // AXI a*lock fixed width (2)
localparam AXI_CACHEW = `UMCTL2_AXI_CACHE_WIDTH; // AXI a*cache width
localparam AXI_PROTW  = `UMCTL2_AXI_PROT_WIDTH; // AXI a*prot width
localparam AXI_RESPW  = `UMCTL2_AXI_RESP_WIDTH; // AXI *resp width
localparam AXI_QOSW   = `UMCTL2_A_QOSW; // AXI a*qos width
localparam XPI_RAQD_LG2_0 = (`UMCTL2_A_TYPE_0==2) ? `UMCTL_LOG2(`UMCTL2_AHB_RAQD_0) : `UMCTL_LOG2(`UMCTL2_AXI_RAQD_0);
localparam XPI_WAQD_LG2_0 = (`UMCTL2_A_TYPE_0==2) ? `UMCTL_LOG2(`UMCTL2_AHB_WAQD_0) : `UMCTL_LOG2(`UMCTL2_AXI_WAQD_0);
output [1:0] ddr_ck_t   ;
output [1:0] ddr_ck_c   ;
output [1:0] ddr_cke    ;
output [1:0] ddr_cs_n   ;
output [1:0] ddr_odt    ;

output        ddr_act_n  ;
inout  [7:0] ddr_dm_n   ;
output [1:0] ddr_bg     ;
output [1:0] ddr_ba     ;
output [16:0] ddr_a      ;
output        ddr_reset_n;
inout  [63:0] ddr_dq     ;
inout  [7:0] ddr_dqs_t  ;
inout  [7:0] ddr_dqs_c  ;
output        ddr_par    ; // unused
input         ddr_alert_n; // unused
output        ddr_ten    ; // unused
input 		  core_ddrc_core_clk;
input 		  core_ddrc_rstn    ;
   //----------------------------------------------- 
   // AXI Interface
   //-----------------------------------------------
// AXI Port 0 Global Signals (clock, reset, low-power)
input                                aresetn_0;
input                                aclk_0;
// AXI Port 0 Write Address Channel
input [`UMCTL2_A_IDW-1:0]            awid_0;
input [`UMCTL2_A_ADDRW-1:0]          awaddr_0;
input [`UMCTL2_A_LENW-1:0]           awlen_0;
input [2:0]                          awsize_0;
input [1:0]                          awburst_0;
input [`UMCTL2_AXI_LOCK_WIDTH_0-1:0] awlock_0;
input [3:0]                          awcache_0;
input [2:0]                          awprot_0;
input [AXI_USERW-1:0]                awuser_0;
input                                awvalid_0;
output                               awready_0;
input [3:0]                          awqos_0;
input [3:0]                          awregion_0;
// AXI Port 0 Write Data Channel
input [`UMCTL2_PORT_DW_0-1:0]        wdata_0;
input [`UMCTL2_PORT_NBYTES_0-1:0]    wstrb_0;
input                                wlast_0;
input                                wvalid_0;
output                               wready_0;
input [AXI_USERW-1:0]                wuser_0;
// AXI Port 0 Write Response Channel
output [`UMCTL2_A_IDW-1:0]           bid_0;
output [AXI_RESPW-1:0]               bresp_0;
output [AXI_USERW-1:0]               buser_0;
output                               bvalid_0;
input                                bready_0;
// AXI Port 0 Read Address Channel
input [`UMCTL2_A_IDW-1:0]            arid_0;
input [`UMCTL2_A_ADDRW-1:0]          araddr_0;
input [`UMCTL2_A_LENW-1:0]           arlen_0;
input [AXI_SIZEW-1:0]                arsize_0;
input [AXI_BURSTW-1:0]               arburst_0;
input [`UMCTL2_AXI_LOCK_WIDTH_0-1:0] arlock_0;
input [AXI_CACHEW-1:0]               arcache_0;
input [AXI_PROTW-1:0]                arprot_0;
input [AXI_USERW-1:0]                aruser_0;
input                                arvalid_0;
output                               arready_0;
input [AXI_QOSW-1:0]                 arqos_0;
input [`UMCTL2_AXI_REGION_WIDTH-1:0] arregion_0;
// AXI Port 0 Read Data Channel
output [`UMCTL2_A_IDW-1:0]           rid_0;
output [`UMCTL2_PORT_DW_0-1:0]       rdata_0;
output [AXI_RESPW-1:0]               rresp_0;
output [AXI_USERW-1:0]               ruser_0;
output                               rlast_0;
output                               rvalid_0;
input                                rready_0;

input  		           				bist_bufferen_core;
output 		           				ddr_plllock  ;



input  		   						mc_scanmode   ;
input  		   						mc_scan_resetn;

input  		   						bist_mode    ;
input  		   						bist_mux     ;
input  		   						bist_start   ;
output 		   						bist_complete;
output 		   						bist_error   ;
input  		   						bscan_TDI     ;
output 		   						bscan_TDO     ;
input  		   						bscan_clockDR ;
input  		   						bscan_mode    ;
input  		   						bscan_shiftDR ;
input  		   						bscan_updateDR;
input          						phy_scanclk ;
input          						phy_scanrstn;
input          						phy_scanen  ;
input          						phy_scanmode;
input  [164:0] 						phy_scanin  ;
output [164:0] 						phy_scanout ;

input         						pclk       ;
input         						presetn    ;
input  [15:0] 						paddr_mc   ;
input  [15:0] 						paddr_phy  ;
input  [31:0] 						pwdata_mc  ;
input  [31:0] 						pwdata_phy ;
input         						pwrite_mc  ;
input         						pwrite_phy ;
input         						psel_mc    ;
input         						psel_phy   ;
input         						penable_mc     ;
input         						penable_phy    ;
output        						pready_mc  ;
output        						pready_phy ;
output [31:0] 						prdata_mc  ;
output [31:0] 						prdata_phy ;
output        						pslverr_mc ;
input         						bist_dfi_init_start;

inout                               rzq;

input                               dft_mode;
input                               dft_lgc_rstn;
input                               scan_mode;
input                               dft_glb_gt_se;
output                              dfi_init_complete;
output                              axi_bus_rst_n;
input                               phy_bist_mode;
input  [4:0]                        bist_dfi_frequency;
///////////////////mig////////////////////////
input                               sys_rst;
input                               ddr_clk;
output                              addn_ui_clkout1;
output                              addn_ui_clkout2;
output                              c0_ddr4_ui_clk_sync_rst;
output                              c0_init_calib_complete;
assign pready_phy = 1'b0;
	wire [4:0]                           dBufAdr;
	wire [511:0]                         wrData;
	wire [63:0]                          wrDataMask;
	wire [511:0]                         rdData;
	wire [4:0]                           rdDataAddr;
	wire [0:0]                           rdDataEn;
	wire [0:0]                           rdDataEnd;
	wire [0:0]                           per_rd_done;
	wire [0:0]                           rmw_rd_done;
	wire [4:0]                           wrDataAddr;
	wire [0:0]                           wrDataEn;
	wire [7:0]                           mc_ACT_n;
	wire [135:0]                         mc_ADR;
	wire [15:0]                          mc_BA;
	wire [15:0]                          mc_BG;
	wire [15:0]                          mc_CKE;
	wire [15:0]                          mc_CS_n;
	wire [15:0]                          mc_ODT;
	wire [0:0]                           mcRdCAS;
	wire [0:0]                           mcWrCAS;
	wire [0:0]                           winInjTxn;
	wire [0:0]                           winRmw;
	wire [4:0]                           winBuf;
	wire [1:0]                           winRank;
	wire [5:0]                           tCWL;
	wire                                 dbg_clk;
	wire                                 c0_wr_rd_complete;
  	wire                                 c0_ddr4_clk;
  	wire                                 c0_ddr4_rst;
  	// Debug Bus
  	wire [511:0]                         dbg_bus;        
	wire                                 c0_ddr4_reset_n_int;
	wire                                 c0_ddr4_ui_clk;

////////////////mig end////////////////////////////
wire                                axi_bus_rst_n;

logic [UMCTL2_RDATARAM_DW-1:0]      rdataram_dout_0;
logic [3:0]                         rdataram_P0_0_DQ;
logic [UMCTL2_RDATARAM_DW-1:0]      rdataram_din_0;
logic                               rdataram_wr_0;
logic                               rdataram_re_0;
logic [UMCTL2_RDATARAM_AW-1:0]      rdataram_raddr_0;
logic [UMCTL2_RDATARAM_AW-1:0]      rdataram_waddr_0;
logic [UMCTL2_WDATARAM_DW-1:0]      wdataram_dout;
logic [UMCTL2_WDATARAM_DW-1:0]      wdataram_din;
logic [UMCTL2_WDATARAM_DW/8-1:0]    wdataram_mask;
logic                               wdataram_wr;
logic                               wdataram_re;
logic [UMCTL2_WDATARAM_AW-1:0]      wdataram_raddr;
logic [UMCTL2_WDATARAM_AW-1:0]      wdataram_waddr;
logic [UMCTL2_WDATARAM_DW-1:0]      wdataram_mask_bit;

logic [1:0]                                                 dfi_freq_ratio        ; // unused
logic [`UMCTL2_SHARED_AC_EN:0]                              dfi_phyupd_req        ; // unused
logic [`UMCTL2_SHARED_AC_EN:0]                              dfi_phyupd_ack        ; // unused
logic [(`UMCTL2_NUM_DATA_CHANNEL*`UMCTL2_SHARED_AC_EN)+1:0] dfi_phyupd_type       ; // unused
logic [`UMCTL2_SHARED_AC_EN:0]                              dfi_ctrlupd_ack       ; // unused
logic [`UMCTL2_SHARED_AC_EN:0]                              dfi_ctrlupd_ack2      ; // unused
logic [`UMCTL2_SHARED_AC_EN:0]                              dfi_ctrlupd_req       ; // unused
logic [`MEMC_FREQ_RATIO-1:0]                                dfi_parity_in         ; // unused
logic [`MEMC_FREQ_RATIO-1:0]                                dfi_alert_n           ; // unused
logic                                                       dfi_geardown_en       ; // unused
logic                                                       dfi_alert_err_intr    ; // unused
logic                                                       ctl_idle              ; // unused
logic [ (`MEMC_FREQ_RATIO*`MEMC_DFI_ADDR_WIDTH)-1:0] mc_dfi_address    ;                                      
logic [ `MEMC_FREQ_RATIO-1:0]                        dfi_act_n         ;               
logic [ (`MEMC_FREQ_RATIO*`MEMC_BANK_BITS)-1:0]      dfi_bank          ;                                 
logic [ (`MEMC_FREQ_RATIO*`MEMC_BG_BITS)-1:0]        dfi_bg            ;                               
logic [ `MEMC_FREQ_RATIO-1:0]                        dfi_cas_n         ;               
logic [ `MEMC_FREQ_RATIO-1:0]                        dfi_ras_n         ;               
logic [ `MEMC_FREQ_RATIO-1:0]                        dfi_we_n          ;               
logic [ (`MEMC_FREQ_RATIO*`MEMC_NUM_RANKS)-1:0]      mc_dfi_cke        ;                                 
logic [ (`MEMC_FREQ_RATIO*`MEMC_NUM_RANKS)-1:0]      mc_dfi_cs_n       ;                                                                     
logic [ (`MEMC_FREQ_RATIO*`MEMC_NUM_RANKS)-1:0]      mc_dfi_odt        ;                                 
logic [ (`MEMC_FREQ_RATIO*`UMCTL2_RESET_WIDTH)-1:0]  dfi_reset_n       ;                                     
logic [ `MEMC_DFI_TOTAL_DATA_WIDTH -1:0]             dfi_wrdata        ;                          
logic [ `MEMC_DFI_TOTAL_MASK_WIDTH -1:0]             dfi_wrdata_mask   ;                          
logic [ `MEMC_DFI_TOTAL_DATAEN_WIDTH -1:0]           mc_dfi_wrdata_en  ;                            
logic [ `MEMC_DFI_TOTAL_DATA_WIDTH -1:0]             dfi_rddata        ;                          
logic [ `MEMC_DFI_TOTAL_DATAEN_WIDTH -1:0]           mc_dfi_rddata_en  ;                            
logic												 dfi_rddata_valid  ;
logic [ `MEMC_DFI_TOTAL_DATA_WIDTH/8-1:0]            dfi_rddata_dbi    ;                           
logic [ (`MEMC_NUM_CLKS<<`UMCTL2_SHARED_AC_EN)-1:0]            dfi_dram_clk_disable     ;
logic                                                          dfi_init_complete        ;
logic                                                          dfi_init_start           ;
logic [  4:0]                                                  dfi_frequency            ;
logic [ `UMCTL2_SHARED_AC_EN:0]                                dfi_lp_req               ;
logic [ `UMCTL2_SHARED_AC_EN:0]                                dfi_lp_ack               ;
logic [ (`UMCTL2_NUM_DATA_CHANNEL*`UMCTL2_SHARED_AC_EN*2)+3:0] dfi_lp_wakeup            ;
logic                                                          dfi_phymstr_req          ;
logic                                                          dfi_phymstr_ack          ;
logic [ `MEMC_NUM_RANKS-1:0]                                   dfi_phymstr_cs_state     ;
logic                                                          dfi_phymstr_state_sel    ;
logic [1:0]                                                    dfi_phymstr_type         ;
logic [ `UMCTL2_APB_DW-1:0]                                    mc_prdata                ;
logic                                                          phy_bufferen_core        ;
logic [1:0]                                                    phy_dfi_act_n            ;
logic [ 39:0]                                                  phy_dfi_address          ;
logic [ (`MEMC_FREQ_RATIO*`MEMC_BANK_BITS)-1:0]                phy_dfi_bank             ;
logic [ (`MEMC_FREQ_RATIO*`MEMC_BG_BITS)-1:0]                  phy_dfi_bg               ;
logic [ `MEMC_FREQ_RATIO-1:0]                                  phy_dfi_ras_n            ;
logic [ `MEMC_FREQ_RATIO-1:0]                                  phy_dfi_cas_n            ;
logic [ `MEMC_FREQ_RATIO-1:0]                                  phy_dfi_we_n             ;
logic [ (`MEMC_FREQ_RATIO*`MEMC_NUM_RANKS)-1:0]                phy_dfi_cke              ;
logic [ (`MEMC_FREQ_RATIO*`MEMC_NUM_RANKS)-1:0]                phy_dfi_cs_n             ;
logic [ (`MEMC_FREQ_RATIO*`MEMC_NUM_RANKS)-1:0]                phy_dfi_odt              ;
logic [ 1:0]                                                   phy_dfi_reset_n          ;
logic [ `MEMC_DFI_TOTAL_DATA_WIDTH -1:0]                       phy_dfi_wrdata           ;
logic [ `MEMC_DFI_TOTAL_DATAEN_WIDTH -1:0]                     phy_dfi_wrdata_en        ;
logic [ `MEMC_DFI_TOTAL_MASK_WIDTH -1:0]                       phy_dfi_wrdata_mask      ;
logic [ `MEMC_DFI_TOTAL_DATAEN_WIDTH -1:0]                     phy_dfi_rddata_en        ;
logic [ (`MEMC_NUM_CLKS<<`UMCTL2_SHARED_AC_EN)-1:0]            phy_dfi_dram_clk_disable ;
logic [ 4:0]                                                   phy_dfi_frequency        ;
logic                                                          phy_dfi_init_start       ;
logic [ `UMCTL2_SHARED_AC_EN:0]                                phy_dfi_lp_req           ;
logic [ (`UMCTL2_NUM_DATA_CHANNEL*`UMCTL2_SHARED_AC_EN*2)+3:0] phy_dfi_lp_wakeup        ;

logic                               awpoison_intr_0                              ;
logic                               arpoison_intr_0                              ;
logic [XPI_RAQD_LG2_0:0]            raq_wcount_0                                 ;
logic                               raq_pop_0                                    ;
logic                               raq_push_0                                   ;
logic                               raq_split_0                                  ;
logic [XPI_WAQD_LG2_0:0]            waq_wcount_0                                 ;
logic                               waq_pop_0                                    ;
logic                               waq_push_0                                   ;
logic                               waq_split_0                                  ;
logic                               csysreq_0                                    ;
logic                               csysack_0                                    ;
logic                               cactive_0                                    ;
logic		           				csysreq_ddrc                                 ;
logic		           				csysack_ddrc                                 ;
logic		           				cactive_ddrc                                 ;
logic [1:0]           				stat_ddrc_reg_selfref_type                   ;
logic [6:0] 						lpr_credit_cnt                               ;
logic [6:0] 						hpr_credit_cnt                               ;
logic [6:0] 						wr_credit_cnt                                ;
logic [`MEMC_MRR_DATA_TOTAL_DATA_WIDTH-1:0] 						hif_mrr_data ;
logic 								hif_mrr_data_valid                           ;
logic                               init_rstn_mc                                 ;
logic                               o_presetn                                    ;
logic                               o_core_ddrc_rstn                             ;
logic                               o_aresetn_0                                  ;
logic                               phy_bist_mode                                ;
logic                               bist_bufferen_core                           ;
logic [  4:0]                       bist_dfi_frequency                           ;
wire gt_data_ready;
wire [1: 0]		   			       mcCasSlot                                     ;
wire 							   mcCasSlot2                                    ;
generate
	genvar i,j;
	for (i = 0; i < (UMCTL2_WDATARAM_DW/8); i=(i+1)) begin:wdataram_mask_bit_init
		assign wdataram_mask_bit[i*8+0] = wdataram_mask[i];
		assign wdataram_mask_bit[i*8+1] = wdataram_mask[i];
		assign wdataram_mask_bit[i*8+2] = wdataram_mask[i];
		assign wdataram_mask_bit[i*8+3] = wdataram_mask[i];
		assign wdataram_mask_bit[i*8+4] = wdataram_mask[i];
		assign wdataram_mask_bit[i*8+5] = wdataram_mask[i];
		assign wdataram_mask_bit[i*8+6] = wdataram_mask[i];
		assign wdataram_mask_bit[i*8+7] = wdataram_mask[i];
	end
endgenerate
assign ddr_par           = 1'b0; // unused
assign ddr_ten           = 1'b0; // unused
assign dfi_phymstr_type      = 2'b00;
assign dfi_phymstr_req       = 1'b0;
assign dfi_phymstr_state_sel = 1'b0;
assign dfi_phymstr_cs_state  = 2'b00;

assign phy_bufferen_core        =  phy_bist_mode  ? bist_bufferen_core  : 1'b1                                                        ;
assign phy_dfi_act_n            =  phy_bist_mode  ? 2'b00               : dfi_act_n                                                   ;
assign phy_dfi_address          =  phy_bist_mode  ? {40{1'b0}}          : {2'b00, mc_dfi_address[35:18], 2'b00, mc_dfi_address[17:0]} ;
assign phy_dfi_bank             =  phy_bist_mode  ? {6{1'b0}}           : dfi_bank                                                    ;
assign phy_dfi_bg               =  phy_bist_mode  ? {4{1'b0}}           : dfi_bg                                                      ;
assign phy_dfi_ras_n            =  phy_bist_mode  ? 2'b00               : 2'h3                                                        ;
assign phy_dfi_cas_n            =  phy_bist_mode  ? 2'b00               : 2'h3                                                        ;
assign phy_dfi_we_n             =  phy_bist_mode  ? 2'b00               : 2'h3                                                        ;
assign phy_dfi_cke              =  phy_bist_mode  ? {4{1'b0}}           : mc_dfi_cke                                                  ;
assign phy_dfi_cs_n             =  phy_bist_mode  ? {4{1'b0}}           : mc_dfi_cs_n                                                 ;
assign phy_dfi_odt              =  phy_bist_mode  ? {4{1'b0}}           : mc_dfi_odt                                                  ;
assign phy_dfi_reset_n          =  phy_bist_mode  ? 2'b00               : {dfi_reset_n[2],dfi_reset_n[0]}                             ;
assign phy_dfi_wrdata           =  phy_bist_mode  ? {256{1'b0}}         : dfi_wrdata                                                  ;
assign phy_dfi_wrdata_en        =  phy_bist_mode  ? {16{1'b0}}          : mc_dfi_wrdata_en                                            ;
assign phy_dfi_wrdata_mask      =  phy_bist_mode  ? {32{1'b0}}          : dfi_wrdata_mask                                             ;
assign phy_dfi_rddata_en        =  phy_bist_mode  ? {16{1'b0}}          : mc_dfi_rddata_en                                            ;
assign phy_dfi_dram_clk_disable =  phy_bist_mode  ? 1'b0                : dfi_dram_clk_disable                                        ;
assign phy_dfi_frequency        =  phy_bist_mode  ? bist_dfi_frequency  : dfi_frequency                                               ;
assign phy_dfi_init_start       =  phy_bist_mode  ? bist_dfi_init_start : dfi_init_start                                              ;     
assign phy_dfi_lp_req           =  phy_bist_mode  ? 1'b0                : dfi_lp_req                                                  ;
assign phy_dfi_lp_wakeup        =  phy_bist_mode  ? {4{1'b0}}           : dfi_lp_wakeup                                               ;

assign rdataram_dout_0[UMCTL2_RDATARAM_DW-1] = rdataram_P0_0_DQ[0];

assign dfi_alert_n        = 2'b11;
assign dfi_phyupd_req     = 1'b0;
assign dfi_ctrlupd_ack    = 1'b0;
assign dfi_phyupd_type    = 2'b00;

// always_ff @(posedge pclk or negedge presetn) begin
//     if(~presetn) begin
//         init_rstn_mc <= 1'b0;
//     end else if ((paddr_mc == 16'h0ff4) && psel_mc && ~pwrite_mc && pready_mc) begin
//         init_rstn_mc <= 1'b1;
//     end
// end
// reg [17:0] dfi_clk_counter;
// always_ff @(posedge core_ddrc_core_clk or negedge core_ddrc_rstn) begin
// 	if(~core_ddrc_rstn) begin
// 		dfi_clk_counter <= 0;
// 	end else if(dfi_init_start) begin
// 		dfi_clk_counter <= dfi_clk_counter + 1;
// 	end
// 	else
// 		dfi_clk_counter <= dfi_clk_counter;
// end
// always_ff @(posedge core_ddrc_core_clk or negedge core_ddrc_rstn) begin 
// 	if(~core_ddrc_rstn) begin
// 		dfi_init_complete <= 0;
// 	end else if (dfi_clk_counter==1178)begin
// 		dfi_init_complete <= 1;
// 	end
// end

assign dfi_lp_ack = 1'b0;
ddr_crg ddr_crg_i (
.dft_mode                           (dft_mode           ),
.dft_lgc_rstn                       (dft_lgc_rstn       ),
.scan_mode                          (scan_mode          ),
.dft_glb_gt_se                      (dft_glb_gt_se      ),
.core_ddrc_core_clk                 (core_ddrc_core_clk ),
.core_ddrc_rstn                     (core_ddrc_rstn     ),
.aclk_0                             (aclk_0             ),
.aresetn_0                          (aresetn_0          ),
.pclk                               (pclk               ),
.presetn                            (presetn            ),
.init_rstn_mc                       (init_rstn_mc       ),
.o_core_ddrc_rstn                   (o_core_ddrc_rstn   ),    
.o_aresetn_0                        (o_aresetn_0        ),    
.axi_bus_rst_n                      (axi_bus_rst_n      ),    
.o_presetn                          (o_presetn          ) );


wire ref_cmd = mc_dfi_cs_n != 15 && dfi_act_n == 3 && dfi_ras_n !=3 && dfi_cas_n != 3 && dfi_we_n == 3;
reg [63:0] ref_cnt;
always @(posedge core_ddrc_core_clk) begin
	if(!o_core_ddrc_rstn) begin
		ref_cnt <= 0;
	end else if(ref_cmd) begin
		ref_cnt <= ref_cnt + 64'h1;
	end
end

reg apb_cfg_done;
reg apb_cfg_done_dly;
always @(posedge core_ddrc_core_clk) begin
	if(!o_core_ddrc_rstn) begin
		apb_cfg_done_dly <= 0;
	end else begin
		apb_cfg_done_dly <= apb_cfg_done;
	end
end

wire test_start = apb_cfg_done && !apb_cfg_done_dly;
wire test_complete;

	wire          cpu_awready;
    wire           cpu_awvalid;
    wire [13:0]    cpu_awid;
    wire [35:0]    cpu_awaddr;
    wire [7:0]     cpu_awlen;
    wire [2:0]     cpu_awsize;
    wire [1:0]     cpu_awburst;
    wire           cpu_awlock;
    wire [3:0]     cpu_awcache;
    wire [2:0]     cpu_awprot;
    wire [3:0]     cpu_awqos;

    wire          cpu_wready;
    wire           cpu_wvalid;
    wire [255:0]   cpu_wdata;
    wire [31:0]    cpu_wstrb;
    wire           cpu_wlast;

    wire           cpu_bready;
    wire          cpu_bvalid;
    wire  [13:0]  cpu_bid;
    wire  [1:0]   cpu_bresp;

    wire          cpu_arready;
    wire           cpu_arvalid;
    wire [13:0]    cpu_arid;
    wire [35:0]    cpu_araddr;
    wire [7:0]     cpu_arlen;
    wire [2:0]     cpu_arsize;
    wire [1:0]     cpu_arburst;
    wire           cpu_arlock;
    wire [3:0]     cpu_arcache;
    wire [2:0]     cpu_arprot;
    wire [3:0]     cpu_arqos;

    wire           cpu_rready;
    wire          cpu_rvalid;
    wire  [13:0]  cpu_rid;
    wire  [255:0] cpu_rdata;
    wire  [1:0]   cpu_rresp;
    wire          cpu_rlast;

am yecr_axi_master(
	.clk(			core_ddrc_core_clk),
	.rst_n(			o_core_ddrc_rstn),
    .test_start(	test_start),
    .test_complete(	test_complete),
    // AR
    .araddr(		cpu_araddr),
    .arburst(		cpu_arburst),
    .arcache(		cpu_arcache),
    .arid(			cpu_arid),
    .arlen(			cpu_arlen),
    .arlock(		cpu_arlock),
    .arprot(		cpu_arprot),
    .arqos(			cpu_arqos),
    .arready(		cpu_arready),
    .arregion(		),
    .arsize(		cpu_arsize),
    .arvalid(		cpu_arvalid),
    // R
    .rdata(			cpu_rdata),
    .rid(			cpu_rid),
    .rlast(			cpu_rlast),
    .rready(		cpu_rready),
    .rresp(			cpu_rresp),
    .rvalid(		cpu_rvalid),
    // AW
    .awaddr(		cpu_awaddr),
    .awburst(		cpu_awburst),
    .awcache(		cpu_awcache),
    .awid(			cpu_awid),
    .awlen(			cpu_awlen),
    .awlock(		cpu_awlock),
    .awprot(		cpu_awprot),
    .awqos(			cpu_awqos),
    .awready(		cpu_awready),
    .awregion(		),
    .awsize(		cpu_awsize),
    .awvalid(		cpu_awvalid),
    // W
    .wdata(			cpu_wdata),
    .wlast(			cpu_wlast),
    .wready(		cpu_wready),
    .wstrb(			cpu_wstrb),
    .wvalid(		cpu_wvalid),
    // B
    .bid(			cpu_bid),
    .bready(		cpu_bready),
    .bresp(			cpu_bresp),
    .bvalid(		cpu_bvalid)
);

reg c0_init_calib_complete_r1;
reg c0_init_calib_complete_r2;
assign dfi_init_complete = c0_init_calib_complete_r2;

always_ff @(posedge core_ddrc_core_clk or negedge core_ddrc_rstn) begin
    if (!core_ddrc_rstn) begin
        c0_init_calib_complete_r1 <= 1'b0;
        c0_init_calib_complete_r2 <= 1'b0;
    end else begin
        c0_init_calib_complete_r1 <= c0_init_calib_complete;
        c0_init_calib_complete_r2 <= c0_init_calib_complete_r1;
    end
end

always_ff @(posedge pclk or negedge presetn) begin
    if (!presetn) begin
        init_rstn_mc <= 1'b0;
    end else if ((paddr_mc == 16'h0058) && psel_mc && pwrite_mc && !pready_mc) begin
        init_rstn_mc <= 1'b1;
    end
end

always_ff @(posedge pclk or negedge presetn) begin
    if (!presetn) begin
        apb_cfg_done <= 1'b0;
    end else if ((paddr_mc == 16'h0ff4) && psel_mc && pwrite_mc && !pready_mc) begin
        apb_cfg_done <= 1'b1;
    end
end

BY_mc_top i_BY_mc_top (
    .io_clk(core_ddrc_core_clk),
    .io_rst(!o_core_ddrc_rstn),

    // AXI Write Channel
    .io_axi_wch_aw_ready(cpu_awready),
    .io_axi_wch_aw_valid(cpu_awvalid),
    .io_axi_wch_aw_bits_id(cpu_awid),
    .io_axi_wch_aw_bits_addr(cpu_awaddr),
    .io_axi_wch_aw_bits_len(cpu_awlen),
    .io_axi_wch_aw_bits_size(cpu_awsize),
    .io_axi_wch_aw_bits_burst(cpu_awburst),
    .io_axi_wch_aw_bits_lock(cpu_awlock),
    .io_axi_wch_aw_bits_cache(cpu_awcache),
    .io_axi_wch_aw_bits_prot(cpu_awprot),
    .io_axi_wch_aw_bits_qos(cpu_awqos),

    .io_axi_wch_w_ready(cpu_wready),
    .io_axi_wch_w_valid(cpu_wvalid),
    .io_axi_wch_w_bits_data(cpu_wdata),
    .io_axi_wch_w_bits_strb(cpu_wstrb),
    .io_axi_wch_w_bits_last(cpu_wlast),

    .io_axi_wch_b_ready(cpu_bready),
    .io_axi_wch_b_valid(cpu_bvalid),
    .io_axi_wch_b_bits_id(cpu_bid),
    .io_axi_wch_b_bits_resp(cpu_bresp),

    // AXI Read Channel
    .io_axi_rch_ar_ready(cpu_arready),
    .io_axi_rch_ar_valid(cpu_arvalid),
    .io_axi_rch_ar_bits_id(cpu_arid),
    .io_axi_rch_ar_bits_addr(cpu_araddr),
    .io_axi_rch_ar_bits_len(cpu_arlen),
    .io_axi_rch_ar_bits_size(cpu_arsize),
    .io_axi_rch_ar_bits_burst(cpu_arburst),
    .io_axi_rch_ar_bits_lock(cpu_arlock),
    .io_axi_rch_ar_bits_cache(cpu_arcache),
    .io_axi_rch_ar_bits_prot(cpu_arprot),
    .io_axi_rch_ar_bits_qos(cpu_arqos),

    .io_axi_rch_r_ready(cpu_rready),
    .io_axi_rch_r_valid(cpu_rvalid),
    .io_axi_rch_r_bits_id(cpu_rid),
    .io_axi_rch_r_bits_data(cpu_rdata),
    .io_axi_rch_r_bits_resp(cpu_rresp),
    .io_axi_rch_r_bits_last(cpu_rlast),

    // DFI Control Signals 2T dfi [1:0]
    .io_dfi_0_dfictrl_dfi_address_0(mc_dfi_address[16:0]),
    .io_dfi_0_dfictrl_dfi_address_1(mc_dfi_address[35:19]),
    .io_dfi_0_dfictrl_dfi_bank_0(dfi_bank[1:0]),
    .io_dfi_0_dfictrl_dfi_bank_1(dfi_bank[3:2]),
    .io_dfi_0_dfictrl_dfi_ras_n_0(dfi_ras_n[0]),
    .io_dfi_0_dfictrl_dfi_ras_n_1(dfi_ras_n[1]),
    .io_dfi_0_dfictrl_dfi_cas_n_0(dfi_cas_n[0]),
    .io_dfi_0_dfictrl_dfi_cas_n_1(dfi_cas_n[1]),
    .io_dfi_0_dfictrl_dfi_we_n_0(dfi_we_n[0]),
    .io_dfi_0_dfictrl_dfi_we_n_1(dfi_we_n[1]),
    .io_dfi_0_dfictrl_dfi_cs_n_0_0(mc_dfi_cs_n[0]),
    .io_dfi_0_dfictrl_dfi_cs_n_0_1(mc_dfi_cs_n[1]),
    .io_dfi_0_dfictrl_dfi_cs_n_1_0(mc_dfi_cs_n[2]),
    .io_dfi_0_dfictrl_dfi_cs_n_1_1(mc_dfi_cs_n[3]),
    .io_dfi_0_dfictrl_dfi_act_n_0(dfi_act_n[0]),
    .io_dfi_0_dfictrl_dfi_act_n_1(dfi_act_n[1]),
    .io_dfi_0_dfictrl_dfi_bg_0(dfi_bg[1:0]),
    .io_dfi_0_dfictrl_dfi_bg_1(dfi_bg[3:2]),
    .io_dfi_0_dfictrl_dfi_cid(),
    .io_dfi_0_dfictrl_dfi_cke_0_0(mc_dfi_cke[0]),
    .io_dfi_0_dfictrl_dfi_cke_0_1(mc_dfi_cke[1]),
    .io_dfi_0_dfictrl_dfi_cke_1_0(mc_dfi_cke[2]),
    .io_dfi_0_dfictrl_dfi_cke_1_1(mc_dfi_cke[3]),
    .io_dfi_0_dfictrl_dfi_odt_0_0(mc_dfi_odt[0]),
    .io_dfi_0_dfictrl_dfi_odt_0_1(mc_dfi_odt[1]),
    .io_dfi_0_dfictrl_dfi_odt_1_0(mc_dfi_odt[2]),
    .io_dfi_0_dfictrl_dfi_odt_1_1(mc_dfi_odt[3]),
    .io_dfi_0_dfictrl_dfi_reset_n_0_0(dfi_reset_n[0]),
    .io_dfi_0_dfictrl_dfi_reset_n_0_1(dfi_reset_n[1]),
    .io_dfi_0_dfictrl_dfi_reset_n_1_0(dfi_reset_n[2]),
    .io_dfi_0_dfictrl_dfi_reset_n_1_1(dfi_reset_n[3]),

    // DFI Write Data
    .io_dfi_0_dfiwrdata_dfi_wrdata_en(mc_dfi_wrdata_en),
    .io_dfi_0_dfiwrdata_dfi_wdata(dfi_wrdata),
    .io_dfi_0_dfiwrdata_dfi_wdata_cs_n(),
    .io_dfi_0_dfiwrdata_dfi_wdata_mask(dfi_wrdata_mask),

    // DFI Read Data
    .io_dfi_0_dfirddata_dfi_rddata_en(mc_dfi_rddata_en),
    .io_dfi_0_dfirddata_dfi_rddata(dfi_rddata),
    .io_dfi_0_dfirddata_dfi_rddata_cs_n(),
    .io_dfi_0_dfirddata_dfi_rddata_valid({16{dfi_rddata_valid}}),
    .io_dfi_0_dfirddata_dfi_rddata_dbi_n(32'hFFFF_FFFF),

    // DFI Update
    .io_dfi_0_dfiupdate_dfi_ctrlupd_req(dfi_ctrlupd_req),
    .io_dfi_0_dfiupdate_dfi_ctrlupd_ack(1'b0),
    .io_dfi_0_dfiupdate_dfi_phyupd_req(1'b0),
    .io_dfi_0_dfiupdate_dfi_phyupd_type(2'b00),
    .io_dfi_0_dfiupdate_dfi_phyupd_ack(dfi_phyupd_ack),

    // DFI Status
    .io_dfi_0_dfistatus_dfi_data_byte_disable(),
    .io_dfi_0_dfistatus_dfi_dram_clk_disable(dfi_dram_clk_disable),
    .io_dfi_0_dfistatus_dfi_freq_ratio(dfi_freq_ratio),
    .io_dfi_0_dfistatus_dfi_init_start(dfi_init_start),
    .io_dfi_0_dfistatus_dfi_init_complete(c0_init_calib_complete_r2),
    .io_dfi_0_dfistatus_dfi_parity_in(dfi_parity_in),
    .io_dfi_0_dfistatus_dfi_alert_n(2'b11),

    // APB Register Interface
    .io_apb_pclk(pclk),
    .io_apb_presetn(presetn),
    .io_apb_paddr(paddr_mc[11:0]),
    .io_apb_pwdata(pwdata_mc),
    .io_apb_pwrite(pwrite_mc),
    .io_apb_psel(psel_mc),
    .io_apb_penable(penable_mc),
    .io_apb_pready(pready_mc),
    .io_apb_prdata(prdata_mc),
    .io_apb_pslverr(pslverr_mc),

    // PHY init done flag
    .io_Phy_init_done_0(c0_init_calib_complete_r2)
);

famsev2_top i_famsev2_top (

    .dfi_clk(			core_ddrc_core_clk),
    .mig_clk(			c0_ddr4_ui_clk),
    .rst_n(				o_aresetn_0),
    .calDone(           c0_init_calib_complete),

    //////////////dfi cmd interface//////////////
    .dfi_reset_n(		dfi_reset_n),
    .dfi_cke(			mc_dfi_cke),
    .dfi_odt(			mc_dfi_odt),
    .dfi_address(		mc_dfi_address),
    .dfi_ba(			dfi_bank),
    .dfi_bg(			dfi_bg),
    .dfi_cs_n(			mc_dfi_cs_n),
    .dfi_act_n(			dfi_act_n),
    .dfi_ras_n(			dfi_ras_n),
    .dfi_cas_n(			dfi_cas_n),
    .dfi_we_n(			dfi_we_n),
    //////////////dfi rddata interface//////////////
    .dfi_rddata_en(		mc_dfi_rddata_en),
    .dfi_rddata(		dfi_rddata),
    .dfi_rddata_valid(	dfi_rddata_valid),
    //////////////dfi wrdata interface//////////////
    .dfi_wrdata_en(		mc_dfi_wrdata_en),
    .dfi_wrdata(		dfi_wrdata),
    .dfi_wrdata_mask(	dfi_wrdata_mask),

    //////////////mig cmd interface//////////////
    .mc_ACT_n(			mc_ACT_n),
    .mc_ADR(			mc_ADR),
    .mc_BA(				mc_BA),
    .mc_BG(				mc_BG),
    .mc_CKE(			mc_CKE),
    .mc_CS_n(			mc_CS_n),
    .mc_ODT(			mc_ODT),
    .winRank(			winRank),
    .mcRdCAS(			mcRdCAS),
    .mcWrCAS(			mcWrCAS),
    .mcCasSlot(			mcCasSlot),
    .mcCasSlot2(		mcCasSlot2),
    .winBuf(			winBuf),
    //////////////mig rddata interface//////////////
    .mig_rddata_en(		rdDataEn),
    .mig_rddata(		rdData),
    .per_rd_done(		per_rd_done),
    .gt_data_ready(		gt_data_ready),
    .winInjTxn(			winInjTxn),
    //////////////mig wrdata interface//////////////
    .mig_wrdata_en(		wrDataEn),
    .mig_wrdata(		wrData),
    .mig_wrdata_mask(	wrDataMask)
);


//===========================================================================
//                         MIG PHY ONLY instantiation
//===========================================================================

ddr4_0 u_ddr4_0
    (
     .sys_rst              (sys_rst),
	 .c0_sys_clk_i  	   (ddr_clk),
     .c0_ddr4_ui_clk       (c0_ddr4_ui_clk),
     .c0_ddr4_ui_clk_sync_rst (c0_ddr4_ui_clk_sync_rst),
     .c0_init_calib_complete (c0_init_calib_complete),
     .addn_ui_clkout1 	   (addn_ui_clkout1),
	 .addn_ui_clkout2 	   (addn_ui_clkout2),
     .dbg_clk              (dbg_clk),
     .c0_ddr4_act_n        (ddr_act_n),
     .c0_ddr4_adr          (ddr_a[16:0]),
     .c0_ddr4_ba           (ddr_ba),
     .c0_ddr4_bg           (ddr_bg),
     .c0_ddr4_cke          (ddr_cke),
     .c0_ddr4_odt          (ddr_odt),
     .c0_ddr4_cs_n         (ddr_cs_n),
     .c0_ddr4_ck_t         (ddr_ck_t),
     .c0_ddr4_ck_c         (ddr_ck_c),
     .c0_ddr4_reset_n      (ddr_reset_n),
     .c0_ddr4_dm_dbi_n     (ddr_dm_n),
     .c0_ddr4_dq           (ddr_dq),
     .c0_ddr4_dqs_c        (ddr_dqs_c),
     .c0_ddr4_dqs_t        (ddr_dqs_t),

     .dBufAdr              (5'b0),
     .wrData               (wrData),
     .wrDataMask           (wrDataMask),

     .rdData               (rdData),
     .rdDataAddr           (rdDataAddr),
     .rdDataEn             (rdDataEn),
     .rdDataEnd            (rdDataEnd),
     .per_rd_done          (per_rd_done),
     .rmw_rd_done          (rmw_rd_done),
     .wrDataAddr           (wrDataAddr),
     .wrDataEn             (wrDataEn),

     .mc_ACT_n             (mc_ACT_n),
     .mc_ADR               (mc_ADR),
     .mc_BA                (mc_BA),
     .mc_BG                (mc_BG),
     // DRAM CKE. 8 bits for each DRAM pin. The mc_CKE signal is always set to '1'.
     .mc_CKE               (mc_CKE),
     .mc_CS_n              (mc_CS_n),
     .mc_ODT               (mc_ODT),
     // CAS command slot select. Slot0 is enabled for example design.
     .mcCasSlot            (mcCasSlot),
     // CAS slot 2 select.  mcCasSlot2 serves a similar purpose as the mcCasSlot[1:0] signal, but mcCasSlot2 is used in timing 
     // critical logic in the Phy. Slot0 is enabled for example design.
     .mcCasSlot2           (mcCasSlot2),
     .mcRdCAS              (mcRdCAS),
     .mcWrCAS              (mcWrCAS),
     // Optional read command type indication. The winInjTxn signal is set to '0' for example design.
     .winInjTxn            (winInjTxn),
     // Optional read command type indication. The winRmw signal is set to '0' for example design.
     .winRmw               ({1{1'b0}}),
     // Update VT Tracking. The gt_data_ready signal is set to '0' in this example design.
     // This signal must be asserted periodically to keep the DQS Gate aligned as voltage and temperature drift.
     // For more information, Refer to PG150 document.
     .gt_data_ready        (gt_data_ready),
     .winBuf               (winBuf),
     .winRank              (winRank),
     .tCWL                 (tCWL),
     // Debug Port
     .dbg_bus         (dbg_bus)                                             
     
     );
endmodule