`timescale 1ps/1ps

module async_fifo_tb;

// FIFO Configuration
parameter DATA_WIDTH = 256;
parameter DEPTH      = 64;

// =============================================================================
// 🔴 切换模式：1=快写慢读  0=慢写快读
// =============================================================================
parameter TEST_FAST_WRITE_SLOW_READ = 1; 

// Clock ratio 26.6 : 1
parameter FAST_CLK_PERIOD  = 2000;     // 500MHz
parameter SLOW_CLK_PERIOD  = 53200;    // 18.79MHz

// -----------------------------------------------------------------------------
// 自动分配时钟
// -----------------------------------------------------------------------------
localparam WR_CLK_PERIOD = TEST_FAST_WRITE_SLOW_READ ? FAST_CLK_PERIOD : SLOW_CLK_PERIOD;
localparam RD_CLK_PERIOD = TEST_FAST_WRITE_SLOW_READ ? SLOW_CLK_PERIOD : FAST_CLK_PERIOD;

// Write Port
reg                     wr_clk;
reg                     wr_rst_n;
reg                     wr_en;
reg [DATA_WIDTH-1:0]    wr_data;
wire                    full;
wire                    wr_ack;

// Read Port
reg                     rd_clk;
reg                     rd_rst_n;
reg                     rd_en;
wire [DATA_WIDTH-1:0]   rd_data;
wire                    empty;
wire                    rd_valid;

// Test variables
reg [7:0]               test_cnt;
reg                     test_pass;
reg                     rd_done;

// 🔥 随机延迟配置（读完成 → 等待随机时间再写下一个）
integer                 RAND_DELAY_MIN = 10000;
integer                 RAND_DELAY_MAX = 100000;
integer                 rand_delay;

// Instantiate FIFO
async_fifo #(
    .DATA_WIDTH (DATA_WIDTH),
    .DEPTH      (DEPTH)
) u_fifo (
    .wr_clk     (wr_clk),
    .wr_rst_n   (wr_rst_n),
    .wr_en      (wr_en),
    .wr_data    (wr_data),
    .full       (full),
    .wr_ack     (wr_ack),

    .rd_clk     (rd_clk),
    .rd_rst_n   (rd_rst_n),
    .rd_en      (rd_en),
    .rd_data    (rd_data),
    .empty      (empty),
    .rd_valid   (rd_valid)
);

// -----------------------------------------------------------------------------
// Clock generation
// -----------------------------------------------------------------------------
initial begin
    wr_clk = 1'b0;
    forever #(WR_CLK_PERIOD/2) wr_clk = ~wr_clk;
end

initial begin
    rd_clk = 1'b0;
    forever #(RD_CLK_PERIOD/2) rd_clk = ~rd_clk;
end

// -----------------------------------------------------------------------------
// Reset
// -----------------------------------------------------------------------------
initial begin
    wr_rst_n = 1'b0;
    rd_rst_n = 1'b0;
    #200000;
    wr_rst_n = 1'b1;
    rd_rst_n = 1'b1;
end

// -----------------------------------------------------------------------------
// Test main：读完 → 随机延迟 → 再写下一个
// -----------------------------------------------------------------------------
initial begin
    wr_en      = 1'b0;
    wr_data    = 'd0;
    rd_en      = 1'b0;
    test_cnt   = 'd0;
    test_pass  = 1'b1;
    rd_done    = 1'b1;

    wait(wr_rst_n && rd_rst_n);
    #50000;

    $display("===========================================================");
    if(TEST_FAST_WRITE_SLOW_READ)
        $display("  TEST MODE: FAST WRITE + SLOW READ");
    else
        $display("  TEST MODE: SLOW WRITE + FAST READ");
    $display("  🔒 RULE: READ DONE → RANDOM DELAY → WRITE NEXT");
    $display("===========================================================");

    for(test_cnt = 0; test_cnt < 200; test_cnt = test_cnt + 1) begin
        // ==============================================
        // 🔥 1. 等待上一次读完成
        // ==============================================
        wait(rd_done);
        rd_done = 1'b0;

        // ==============================================
        // 🔥 2. 生成随机延迟并等待
        // ==============================================
        rand_delay = RAND_DELAY_MIN + {$random} % (RAND_DELAY_MAX - RAND_DELAY_MIN);
        $display("[%0t] READ DONE → WAIT RANDOM DELAY = %0d ps", $time, rand_delay);
        #rand_delay;

        // ==============================================
        // 3. 开始写
        // ==============================================
        wr_data = 32'h1234_5678 + test_cnt;

        @(posedge wr_clk);
        #100;
        if(!full) begin
            wr_en = 1'b1;
            $display("[%0t] WRITE DATA [%0d] = 0x%0h", $time, test_cnt, wr_data);
        end
        @(posedge wr_clk);
        #100;
        wr_en = 1'b0;

        wait(wr_ack);
        $display("[%0t] WRITE ACK ASSERTED", $time);

        // --------------------------
        // Read
        // --------------------------
        @(posedge rd_clk);
        @(posedge rd_clk);
        #1;
        if(!empty) begin
            rd_en = 1'b1;
            $display("[%0t] READ DATA [%0d] = 0x%0h", $time, test_cnt, rd_data);

            if(rd_data !== wr_data) begin
                $display("[%0t] ERROR: DATA MISMATCH!", $time);
                test_pass = 1'b0;
            end
        end
        else begin
            $display("[%0t] ERROR: FIFO STILL EMPTY!", $time);
            test_pass = 1'b0;
        end

        @(posedge rd_clk);
        #1;
        rd_en = 1'b0;

        // 读完成
        rd_done = 1'b1;
    end

    #200000;

    $display("===========================================================");
    if(test_pass)
        $display("✅ TEST PASSED! READ DONE → RANDOM DELAY → WRITE");
    else
        $display("❌ TEST FAILED!");
    $display("===========================================================");

    $finish;
end

// -----------------------------------------------------------------------------
// Waveform
// -----------------------------------------------------------------------------
initial begin
    $fsdbDumpfile("wave.fsdb");
    $fsdbDumpvars(0, async_fifo_tb);
    $fsdbDumpflush();
end

endmodule