`timescale 1ns/1ps

module sync_fifo_tb;

// =============================================================================
// Parameters
// =============================================================================
parameter DATA_WIDTH = 32;
parameter DEPTH      = 8;
parameter CLK_PERIOD = 10;  // 100MHz clock

// =============================================================================
// Signals
// =============================================================================
reg                      clk;
reg                      rst_n;
reg                      wr_en;
reg  [DATA_WIDTH-1:0]    wr_data;
wire                     full;
wire                     wr_ack;
reg                      rd_en;
wire [DATA_WIDTH-1:0]    rd_data;
wire                     empty;
wire                     rd_valid;

// Testbench signals
integer                  cycle_count = 0;
integer                  write_num = 0;
integer                  read_num = 0;
integer                  expected_data = 32'h8000_0000;
reg                      read_phase = 0;

// =============================================================================
// DUT Instantiation
// =============================================================================
sync_fifo #(
    .DATA_WIDTH(DATA_WIDTH),
    .DEPTH(DEPTH)
) dut (
    .clk      (clk),
    .rst_n    (rst_n),
    .wr_en    (wr_en),
    .wr_data  (wr_data),
    .full     (full),
    .wr_ack   (wr_ack),
    .rd_en    (rd_en),
    .rd_data  (rd_data),
    .empty    (empty),
    .rd_valid (rd_valid)
);

// =============================================================================
// Clock Generation
// =============================================================================
initial begin
    clk = 1'b0;
    forever #(CLK_PERIOD/2) clk = ~clk;
end

// =============================================================================
// Test Sequence
// =============================================================================
initial begin
    $display("\n================================================");
    $display("Starting Simple Synchronous FIFO Testbench");
    $display("FIFO Configuration: DATA_WIDTH=%0d, DEPTH=%0d", DATA_WIDTH, DEPTH);
    $display("Test Pattern: Write one, read one, repeat");
    $display("================================================\n");
    
    // Initialize signals
    wr_en = 0;
    rd_en = 0;
    wr_data = 0;
    
    // Apply reset
    $display("[Cycle %0d] Applying reset", cycle_count);
    rst_n = 0;
    repeat(5) @(posedge clk);
    rst_n = 1;
    @(posedge clk);
    $display("Reset released. empty=%b, full=%b", empty, full);
    
    // Test 1: Write one, read one, repeat 8 times
    $display("\n[Test 1] Write one, read one (8 times)");
    repeat(8) begin
        // Write one
        @(posedge clk);
        wr_en = 1;
        wr_data = expected_data;
        expected_data = expected_data + 4;
        write_num = write_num + 1;
        cycle_count = cycle_count + 1;
        
        $display("[Cycle %0d] Writing: wr_en=1, wr_data=0x%h, full=%b, wr_ack=%b", 
                 cycle_count, wr_data, full, wr_ack);
        
        @(posedge clk);
        wr_en = 0;
        cycle_count = cycle_count + 1;
        $display("[Cycle %0d] Write done: full=%b, wr_ack=%b", 
                 cycle_count, full, wr_ack);
        
        // Read one
        @(posedge clk);
        rd_en = 1;
        cycle_count = cycle_count + 1;
        $display("[Cycle %0d] Reading: rd_en=1, empty=%b, rd_valid=%b, rd_data=0x%h", 
                 cycle_count, empty, rd_valid, rd_data);
        
        @(posedge clk);
        rd_en = 0;
        cycle_count = cycle_count + 1;
        $display("[Cycle %0d] Read done: empty=%b, rd_valid=%b, rd_data=0x%h", 
                 cycle_count, empty, rd_valid, rd_data);
        
        // Check data
        if (rd_valid) begin
            if (rd_data !== (expected_data - 4)) begin
                $error("[Cycle %0d] DATA MISMATCH! Expected: 0x%h, Got: 0x%h", 
                       cycle_count, expected_data - 4, rd_data);
            end else begin
                $display("[Cycle %0d] Data OK: 0x%h", cycle_count, rd_data);
                read_num = read_num + 1;
            end
        end
    end
    
    // Wait a few cycles
    repeat(5) @(posedge clk);
    cycle_count = cycle_count + 5;
    $display("\n[Cycle %0d] After first test: empty=%b, full=%b", cycle_count, empty, full);
    
    // Test 2: Fill the FIFO completely
    $display("\n[Test 2] Fill FIFO completely");
    while (!full) begin
        @(posedge clk);
        wr_en = 1;
        wr_data = expected_data;
        expected_data = expected_data + 4;
        write_num = write_num + 1;
        cycle_count = cycle_count + 1;
        
        $display("[Cycle %0d] Writing: wr_en=1, wr_data=0x%h, full=%b, wr_ack=%b", 
                 cycle_count, wr_data, full, wr_ack);
        
        @(posedge clk);
        wr_en = 0;
        cycle_count = cycle_count + 1;
        $display("[Cycle %0d] Write done: full=%b, wr_ack=%b", 
                 cycle_count, full, wr_ack);
    end
    
    $display("\n[Cycle %0d] FIFO is now FULL. empty=%b, full=%b", cycle_count, empty, full);
    
    // Try to write one more (should fail)
    @(posedge clk);
    wr_en = 1;
    wr_data = 32'hDEADBEEF;
    cycle_count = cycle_count + 1;
    $display("[Cycle %0d] Attempting overflow write: wr_en=1, wr_data=0x%h, full=%b, wr_ack=%b", 
             cycle_count, wr_data, full, wr_ack);
    
    @(posedge clk);
    wr_en = 0;
    cycle_count = cycle_count + 1;
    $display("[Cycle %0d] After overflow attempt: full=%b, wr_ack=%b", 
             cycle_count, full, wr_ack);
    
    // Test 3: Empty the FIFO completely
    $display("\n[Test 3] Empty FIFO completely");
    while (!empty) begin
        @(posedge clk);
        rd_en = 1;
        cycle_count = cycle_count + 1;
        $display("[Cycle %0d] Reading: rd_en=1, empty=%b, rd_valid=%b, rd_data=0x%h", 
                 cycle_count, empty, rd_valid, rd_data);
        
        @(posedge clk);
        rd_en = 0;
        cycle_count = cycle_count + 1;
        $display("[Cycle %0d] Read done: empty=%b, rd_valid=%b, rd_data=0x%h", 
                 cycle_count, empty, rd_valid, rd_data);
        
        if (rd_valid) begin
            $display("[Cycle %0d] Read data: 0x%h", cycle_count, rd_data);
            read_num = read_num + 1;
        end
    end
    
    $display("\n[Cycle %0d] FIFO is now EMPTY. empty=%b, full=%b", cycle_count, empty, full);
    
    // Try to read one more (should fail)
    @(posedge clk);
    rd_en = 1;
    cycle_count = cycle_count + 1;
    $display("[Cycle %0d] Attempting underflow read: rd_en=1, empty=%b, rd_valid=%b, rd_data=0x%h", 
             cycle_count, empty, rd_valid, rd_data);
    
    @(posedge clk);
    rd_en = 0;
    cycle_count = cycle_count + 1;
    $display("[Cycle %0d] After underflow attempt: empty=%b, rd_valid=%b", 
             cycle_count, empty, rd_valid);
    
    // Summary
    $display("\n================================================");
    $display("TEST SUMMARY");
    $display("================================================");
    $display("Total writes attempted: %0d", write_num);
    $display("Total reads successful: %0d", read_num);
    $display("Final empty: %b", empty);
    $display("Final full:  %b", full);
    $display("================================================\n");
    
    // Finish simulation
    #100;
    $finish;
end

// =============================================================================
// Cycle Counter
// =============================================================================
always @(posedge clk) begin
    if (rst_n) begin
        cycle_count = cycle_count + 1;
    end
end

// =============================================================================
// Waveform Dumping
// =============================================================================
initial begin
    $fsdbDumpfile("wave.fsdb");
    $fsdbDumpvars(0, sync_fifo_tb);
    $fsdbDumpflush();
end

// =============================================================================
// Monitor
// =============================================================================
always @(posedge clk) begin
    if (rst_n) begin
        // Monitor illegal conditions
        if (full && wr_ack) begin
            $error("[Cycle %0d] ILLEGAL: Write acknowledged when FIFO is full!", cycle_count);
        end
        
        if (empty && rd_valid) begin
            $error("[Cycle %0d] ILLEGAL: Read valid when FIFO is empty!", cycle_count);
        end
        
        // Monitor that full and empty are never both 1
        if (full && empty) begin
            $error("[Cycle %0d] ILLEGAL: FIFO is both full and empty!", cycle_count);
        end
    end
end

endmodule