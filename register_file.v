// ============================================================
//  Register File - 8 x 8-bit registers (R0-R7)
//  R0 is hardwired to 0. Asynchronous read, synchronous write.
//  Adds dedicated debug read ports for R1/R2/R3.
// ============================================================
module register_file (
    input  wire       clk,
    input  wire       rst,
    input  wire       we,
    input  wire [2:0] rd_addr,
    input  wire [2:0] rs1_addr,
    input  wire [2:0] rs2_addr,
    input  wire [7:0] wr_data,
    output wire [7:0] rs1_data,
    output wire [7:0] rs2_data,
    // Debug taps (do not affect CPU operation)
    output wire [7:0] dbg_r1,
    output wire [7:0] dbg_r2,
    output wire [7:0] dbg_r3
);

    reg [7:0] regs [0:7];
    integer i;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < 8; i = i + 1)
                regs[i] <= 8'd0;
        end else if (we && rd_addr != 3'd0) begin
            regs[rd_addr] <= wr_data;
        end
    end

    assign rs1_data = (rs1_addr == 3'd0) ? 8'd0 : regs[rs1_addr];
    assign rs2_data = (rs2_addr == 3'd0) ? 8'd0 : regs[rs2_addr];

    assign dbg_r1 = regs[1];
    assign dbg_r2 = regs[2];
    assign dbg_r3 = regs[3];

endmodule
