module axi_master (
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
    // const
    assign arburst      = 'b0;
    assign arcache      = 'b0;
    assign arid         = 'b0;
    assign arlen        = 'b0;
    assign arlock       = 'b0;
    assign arprot       = 'b1;
    assign arqos        = 'b0;
    assign arregion     = 'b0;
    assign arsize       = 'h5;
    assign awburst      = 'b0;
    assign awcache      = 'b0;
    assign awid         = 'b0;
    assign awlen        = 'b0;
    assign awlock       = 'b0;
    assign awprot       = 'b1;
    assign awqos        = 'b0;
    assign awregion     = 'b0;
    assign awsize       = 'h5;
    assign wstrb        = 32'hffffffff;

    // handshake signal
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

    reg[31:0] TestCnt;
    always @(posedge clk) begin
        if(!rst_n) begin
            TestCnt <= 32'h0;
        end else if(r_hs) begin
            TestCnt <= TestCnt + 32'h1;
        end
    end

    assign test_complete = TestCnt == 32'd300;
    
    always @(posedge clk) begin
        if(!rst_n) begin
            state <= AXI_TEST_IDEL;
            
        end else if(test_complete) begin
            state <= AXI_TEST_COMPLETE;
        end else if(test_start) begin
            state <= WAITING_FOR_AW_HS;

        end else if(aw_hs) begin
            state <= WAITING_FOR_W_HS;
        end else if(w_hs) begin
            state <= WAITING_FOR_B_HS;
        end else if(b_hs) begin
            state <= WAITING_FOR_AR_HS;
        end else if(ar_hs) begin
            state <= WAITING_FOR_R_HS;
        end else if(r_hs) begin
            state <= WAITING_FOR_AW_HS;
        end
    end

    // // meta (inc number)
    // // mem[meta] = meta
    // reg [31:0]  meta;
    // always @(posedge clk) begin
    //     if(!rst_n) begin
    //         meta <= 32'h10400000;
    //     end else if(r_hs) begin
    //         meta <= meta + 32'h40;
    //     end
    // end

    // meta (random number)
    // mem[meta] = meta
    reg [31:0] meta;
    reg [23:0] lfsr;  // 24-bit LFSR for better randomness
    
    // LFSR feedback: x^24 + x^23 + x^22 + x^17 + 1
    // This is a maximal-length polynomial with period 2^24-1
    wire lfsr_feedback = lfsr[23] ^ lfsr[22] ^ lfsr[21] ^ lfsr[16];
    wire [23:0] lfsr_next = {lfsr[22:0], lfsr_feedback};
    
    // Complex initial seed for better randomness pattern
    wire [23:0] lfsr_seed = 24'h89ABCD;
    
    // Constants for address calculation
    localparam ADDR_BASE  = 32'h10000000;  // Base address
    localparam ADDR_UPPER = 32'h50000000;  // Upper bound (exclusive)
    localparam ADDR_ALIGN = 6;             // Alignment shift (0x40 = 2^6)
    
    // Reg for index calculation - moved outside always block
    reg [19:0] index;
    
    always @(posedge clk) begin
        if (!rst_n) begin
            // Initialize meta to 0x10400000 as required
            // 0x10400000 = 0x10000000 + 0x400000
            // 0x400000 / 0x40 = 0x10000 (65536) index offset
            meta <= 32'h10400000;
            lfsr <= lfsr_seed;  // Initialize with complex seed
            index <= 20'h0;
        end else if (r_hs) begin
            // Update LFSR, avoiding all-zero state
            lfsr <= (lfsr_next == 24'd0) ? lfsr_seed : lfsr_next;
            
            // Generate random address within 0x10000000-0x50000000
            // Use bits 22:3 of LFSR (20 bits) for index, ensuring 0x40 alignment
            // The 20-bit index is then left-shifted by 6 bits (multiply by 0x40)
            // Address = BASE + (index << 6)
            // This yields addresses from 0x10000000 to 0x4FFFFFC0
            
            // Create 20-bit index from LFSR bits
            // Using non-consecutive bits to break up patterns
            // index[19:0] = {lfsr[23:20], lfsr[15:8], lfsr[7:4], lfsr[3:0]}
            index <= {lfsr_next[23:20], lfsr_next[15:8], lfsr_next[7:4], lfsr_next[3:0]};
            
            // Generate address with 0x40 alignment
            // The address calculation automatically ensures 0x40 alignment
            // because we left shift the index by 6 bits
            meta <= ADDR_BASE + {index, 6'b0};
        end
    end

    // generated ready and valid for axi handshake
    assign awvalid = state == WAITING_FOR_AW_HS;
    assign wvalid  = state == WAITING_FOR_W_HS;
    assign bready  = state == WAITING_FOR_B_HS;
    assign arvalid = state == WAITING_FOR_AR_HS;
    assign rready  = state == WAITING_FOR_R_HS;

    // generated addr and data for axi transaction
    assign awaddr = state == WAITING_FOR_AW_HS ? meta : 'h0;
    assign wdata  = state == WAITING_FOR_W_HS ? meta : 'h0;
    assign araddr = state == WAITING_FOR_AR_HS ? meta : 'h0;
    
    // else
    assign wlast = w_hs;

    // check
    always @(posedge clk) begin 
        if(!rst_n) begin
            if(r_hs) begin
                $display ("ERROR: Expected data=%h, Received data=%h @ %t" ,meta, rdata, $time);
            end
        end
    end

endmodule

