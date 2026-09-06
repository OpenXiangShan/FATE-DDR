// dfi_master.v
module dfi_master (

    input           dfi_clk,
    input           rst_n,
    input           calDone,

    //////////////dfi cmd interface//////////////
    output  [3:0]   dfi_reset_n,
    output  [3:0]   dfi_cke,
    output  [3:0]   dfi_odt,
    output  [35:0]  dfi_address,
    output  [3:0]   dfi_ba,
    output  [3:0]   dfi_bg,
    output  [3:0]   dfi_cs_n,
    output  [1:0]   dfi_act_n,
    output  [1:0]   dfi_ras_n,
    output  [1:0]   dfi_cas_n,
    output  [1:0]   dfi_we_n,
    //////////////dfi rddata interface//////////////
    output          dfi_rddata_en,
    input   [255:0] dfi_rddata,
    input           dfi_rddata_valid,
    //////////////dfi wrdata interface//////////////
    output          dfi_wrdata_en,
    output  [255:0] dfi_wrdata,
    output  [31:0]  dfi_wrdata_mask

);

    assign dfi_reset_n  = 4'b1111;
    assign dfi_cke      = 4'b1111;
    assign dfi_odt      = 4'b0;

    reg [63:0] TestCnt;
    always @(posedge dfi_clk) begin
        if (!rst_n) begin
            TestCnt <= 64'd0;
        end else if (calDone) begin
            TestCnt <= TestCnt + 64'd1;
        end
    end

    assign test_complete = TestCnt >= 64'd200000;

    localparam ACT_CNT  = 6'b100000;
    localparam WR_CNT   = 6'b101010;
    localparam RD_CNT   = 6'b111000;

    assign dfi_rddata_en    = (TestCnt[5:0] == (RD_CNT + 'd6)) || (TestCnt[5:0] == (RD_CNT + 'd7));
    assign dfi_wrdata_en    = (TestCnt[5:0] == (WR_CNT + 'd4)) || (TestCnt[5:0] == (WR_CNT + 'd5));
    assign dfi_wrdata       = 256'hdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef0000000000000000 + TestCnt;
    assign dfi_wrdata_mask  = 32'hffffffff;

    wire ACT    = TestCnt[5:0] == ACT_CNT;
    wire WR     = TestCnt[5:0] == WR_CNT;
    wire RD     = TestCnt[5:0] == RD_CNT;

    wire    [16:0]  address_p0  = (ACT || WR || RD) ? {TestCnt[24:11], 3'd0} : 'd0;
    wire    [1:0]   ba_p0       = (ACT || WR || RD) ? TestCnt[7:6] : 'd0;
    wire    [1:0]   bg_p0       = (ACT || WR || RD) ? TestCnt[9:8] : 'd0;
    wire    [1:0]   cs_n_p0     = (ACT || WR || RD) ? (TestCnt[10] ? 2'b01 : 2'b10) : 2'b11;
    wire            act_n_p0    = !ACT;
    wire            ras_n_p0    = 1'd1;
    wire            cas_n_p0    = !(RD || WR);
    wire            we_n_p0     = !WR;

    wire    [16:0]  address_p1  = 'b0;
    wire    [1:0]   ba_p1       = 'b0;
    wire    [1:0]   bg_p1       = 'b0;
    wire    [1:0]   cs_n_p1     = 'b0;
    wire            act_n_p1    = 'b0;
    wire            ras_n_p1    = 'b0;
    wire            cas_n_p1    = 'b0;
    wire            we_n_p1     = 'b0;

    assign dfi_address  = {address_p1, address_p0};
    assign dfi_ba       = {ba_p1, ba_p0};
    assign dfi_bg       = {bg_p1, bg_p0};
    assign dfi_cs_n     = {cs_n_p1, cs_n_p0};
    assign dfi_act_n    = {act_n_p1, act_n_p0};
    assign dfi_ras_n    = {ras_n_p1, ras_n_p0};
    assign dfi_cas_n    = {cas_n_p1, cas_n_p0};
    assign dfi_we_n     = {we_n_p1, we_n_p0};
    

endmodule