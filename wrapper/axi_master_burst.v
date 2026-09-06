// am.v
module am (
    input           clk,
    input           rst_n,
    input           test_start,
    output          test_complete,
    // AR
    output  [37:0]  araddr,
    output  [1:0]   arburst,
    output  [3:0]   arcache,
    output  [15:0]  arid,
    output  [7:0]   arlen,
    output          arlock,
    output  [2:0]   arprot,
    output  [3:0]   arqos,
    input           arready,
    output  [3:0]   arregion,
    output  [2:0]   arsize,
    output          arvalid,
    // R
    input   [255:0] rdata,
    input   [17:0]  rid,
    input           rlast,
    output          rready,
    input   [1:0]   rresp,
    input           rvalid,
    // AW
    output  [37:0]  awaddr,
    output  [1:0]   awburst,
    output  [3:0]   awcache,
    output  [17:0]  awid,
    output  [7:0]   awlen,
    output  [0:0]   awlock,
    output  [2:0]   awprot,
    output  [3:0]   awqos,
    input           awready,
    output  [3:0]   awregion,
    output  [2:0]   awsize,
    output          awvalid,
    // W
    output  [255:0] wdata,
    output          wlast,
    input           wready,
    output  [31:0]  wstrb,
    output          wvalid,
    // B
    input   [17:0]  bid,
    output          bready,
    input   [1:0]   bresp,
    input           bvalid
);
    // constant assignments
    assign arburst      = 'b0;                 // FIXED burst type (will be overridden by INCR behavior based on len)
    assign arcache      = 'b0;
    assign arid         = 'b0;
    assign arlen        = 8'h3f;               // burst length = 64 transfers (len = 64 - 1)
    assign arlock       = 'b0;
    assign arprot       = 'b1;
    assign arqos        = 'b0;
    assign arregion     = 'b0;
    assign arsize       = 3'h5;                // 32 bytes per transfer (256 bits)
    assign awburst      = 'b0;                 // INCR mode implied by len>0
    assign awcache      = 'b0;
    assign awid         = 'b0;
    assign awlen        = 8'h3f;               // burst length = 64 transfers
    assign awlock       = 'b0;
    assign awprot       = 'b1;
    assign awqos        = 'b0;
    assign awregion     = 'b0;
    assign awsize       = 3'h5;                // 32 bytes per transfer
    assign wstrb        = 32'hffffffff;        // all bytes valid

    // handshake signals
    wire aw_hs = awvalid && awready;
    wire w_hs  = wvalid && wready;
    wire b_hs  = bvalid && bready;
    wire ar_hs = arvalid && arready;
    wire r_hs  = rvalid && rready;

    // state (one hot)
    // waiting for aw_hs <---> state[4] = 1, state[else] = 0
    // waiting for w_hs  <---> state[3] = 1, state[else] = 0
    // waiting for b_hs  <---> state[2] = 1, state[else] = 0
    // waiting for ar_hs <---> state[1] = 1, state[else] = 0
    // waiting for r_hs  <---> state[0] = 1, state[else] = 0
    reg [4:0]   state;
    localparam AXI_TEST_IDEL     = 5'b00000;
    localparam WAITING_FOR_AW_HS = 5'b10000;
    localparam WAITING_FOR_W_HS  = 5'b01000;
    localparam WAITING_FOR_B_HS  = 5'b00100;
    localparam WAITING_FOR_AR_HS = 5'b00010;
    localparam WAITING_FOR_R_HS  = 5'b00001;
    localparam AXI_TEST_COMPLETE = 5'b11111;

    // Burst beat counter (0 to 63) shared between write and read bursts
    reg [5:0] burst_cnt;

    // Test cycle counter (number of completed write+read bursts)
    reg [31:0] TestCnt;
    localparam TOTAL_TEST_LOOPS = 50;         // easy to modify

    // Timeout parameters for R-channel
    localparam R_TIMEOUT_LIMIT = 1000;         // timeout after 1000 consecutive cycles without r_hs
    reg [9:0]  r_timeout_cnt;                  // counter (0 to 1023)
    reg        r_timeout_flag;                 // high when timeout occurs

    assign test_complete = (TestCnt == TOTAL_TEST_LOOPS) || r_timeout_flag;

    // Main state machine with burst support
    always @(posedge clk) begin
        if (!rst_n) begin
            state      <= AXI_TEST_IDEL;
            burst_cnt  <= 6'd0;
        end else if (test_complete) begin
            state <= AXI_TEST_COMPLETE;
        end else if (test_start && (state == AXI_TEST_IDEL)) begin
            state     <= WAITING_FOR_AW_HS;
            burst_cnt <= 6'd0;
        end else begin
            case (state)
                WAITING_FOR_AW_HS: begin
                    if (aw_hs) begin
                        state     <= WAITING_FOR_W_HS;
                        burst_cnt <= 6'd0;    // reset counter for write burst
                    end
                end
                WAITING_FOR_W_HS: begin
                    if (w_hs) begin
                        if (burst_cnt == 6'd63) begin
                            state     <= WAITING_FOR_B_HS;
                            burst_cnt <= 6'd0;
                        end else begin
                            burst_cnt <= burst_cnt + 6'd1;
                        end
                    end
                end
                WAITING_FOR_B_HS: begin
                    if (b_hs) begin
                        state     <= WAITING_FOR_AR_HS;
                        burst_cnt <= 6'd0;    // reset counter for read burst
                    end
                end
                WAITING_FOR_AR_HS: begin
                    if (ar_hs) begin
                        state     <= WAITING_FOR_R_HS;
                        burst_cnt <= 6'd0;
                    end
                end
                WAITING_FOR_R_HS: begin
                    if (r_hs) begin
                        if (rlast) begin      // last read beat
                            state     <= WAITING_FOR_AW_HS;
                            burst_cnt <= 6'd0;
                        end else begin
                            burst_cnt <= burst_cnt + 6'd1;
                        end
                    end
                end
                default: state <= AXI_TEST_IDEL;
            endcase
        end
    end

    // R-channel timeout counter
    // Counts only when waiting for r_hs and no handshake occurs
    always @(posedge clk) begin
        if (!rst_n) begin
            r_timeout_cnt  <= 10'd0;
            r_timeout_flag <= 1'b0;
        end else if (r_timeout_flag) begin
            // once timeout, keep flag and stop counting
            r_timeout_cnt <= r_timeout_cnt;
        end else if (state == WAITING_FOR_R_HS && !r_hs) begin
            if (r_timeout_cnt == R_TIMEOUT_LIMIT - 1) begin
                r_timeout_cnt  <= R_TIMEOUT_LIMIT;   // keep at limit
                r_timeout_flag <= 1'b1;
                $display("ERROR: R-channel timeout after %0d cycles without handshake @ %t",
                         R_TIMEOUT_LIMIT, $time);
            end else begin
                r_timeout_cnt <= r_timeout_cnt + 10'd1;
            end
        end else begin
            r_timeout_cnt <= 10'd0;
        end
    end

    // Test cycle counter
    always @(posedge clk) begin
        if (!rst_n) begin
            TestCnt <= 32'h0;
        end else if ((state == WAITING_FOR_R_HS) && r_hs && rlast) begin
            TestCnt <= TestCnt + 32'h1;
            $display("--- Test loop %0d completed @ %t ---", TestCnt + 1, $time);
        end
    end

    // Address pointer (incremented after each write+read loop)
    // Base address: 0x10400000, each burst covers 64 * 0x20 = 0x800 bytes
    reg [31:0]  meta;
    always @(posedge clk) begin
        if (!rst_n) begin
            meta <= 32'h10400000;
        end else if ((state == WAITING_FOR_R_HS) && r_hs && rlast) begin
            meta <= meta + 32'h800;            // next 256-bit aligned block
        end
    end

    // AXI channel handshake signals
    assign awvalid = (state == WAITING_FOR_AW_HS);
    assign wvalid  = (state == WAITING_FOR_W_HS);
    assign bready  = (state == WAITING_FOR_B_HS);
    assign arvalid = (state == WAITING_FOR_AR_HS);
    assign rready  = (state == WAITING_FOR_R_HS);

    // Address generation
    assign awaddr = (state == WAITING_FOR_AW_HS) ? {6'd0, meta} : 38'h0;
    assign araddr = (state == WAITING_FOR_AR_HS) ? {6'd0, meta} : 38'h0;

    // Write data: use (base address + burst offset) as data
    // Format: upper 224 bits are zero, lower 32 bits carry the address value
    wire [31:0] current_wr_addr;
    assign current_wr_addr = meta + {26'd0, burst_cnt, 5'd0}; // meta + burst_cnt*0x20
    assign wdata = (state == WAITING_FOR_W_HS) ? {224'd0, current_wr_addr} : 256'h0;

    // wlast asserted on the last write beat
    assign wlast = (state == WAITING_FOR_W_HS) && (burst_cnt == 6'd63);

    // Expected read data calculation (mirrors write data)
    wire [31:0] current_rd_addr;
    assign current_rd_addr = meta + {26'd0, burst_cnt, 5'd0};
    wire [255:0] expected_rdata;
    assign expected_rdata = {224'd0, current_rd_addr};

    // Read data check
    always @(posedge clk) begin
        if (rst_n && r_hs) begin
            if (rdata !== expected_rdata) begin
                $display("ERROR: Addr=%h, BurstCnt=%0d, Expected data=%h, Received data=%h @ %t",
                         meta, burst_cnt, expected_rdata, rdata, $time);
            end else begin
                $display("OK:    Addr=%h, BurstCnt=%0d, Data=%h @ %t",
                         meta, burst_cnt, rdata, $time);
            end
        end
    end

endmodule