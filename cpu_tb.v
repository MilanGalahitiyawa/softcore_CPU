`timescale 1ns/1ps

module cpu_tb;
    reg clk, rst, en;
    wire [7:0] dbg_pc, dbg_r1, dbg_r2, dbg_r3;

    cpu dut (
        .clk(clk), .rst(rst), .en(en),
        .dbg_pc(dbg_pc), .dbg_reg1(dbg_r1),
        .dbg_reg2(dbg_r2), .dbg_reg3(dbg_r3)
    );

    always #5 clk = ~clk;

    integer c;
    initial begin
        $dumpfile("cpu_tb.vcd");
        $dumpvars(0, cpu_tb);

        clk = 0; rst = 1; en = 1; c = 0;
        #20 rst = 0;

        $display("cyc   PC   R1   R2   R3");
        repeat (24) begin
            @(posedge clk);
            #1;
            c = c + 1;
            $display("%3d  %3d  %3d  %3d  %3d", c, dbg_pc, dbg_r1, dbg_r2, dbg_r3);
        end

        $display("");
        if (dbg_r1 == 8'd10 && dbg_r2 == 8'd20 && dbg_r3 == 8'd30)
            $display("PASS: R1=%0d R2=%0d R3=%0d", dbg_r1, dbg_r2, dbg_r3);
        else
            $display("FAIL: R1=%0d R2=%0d R3=%0d (expected 10/20/30)",
                     dbg_r1, dbg_r2, dbg_r3);
        $finish;
    end
endmodule
