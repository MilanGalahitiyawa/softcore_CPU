// ============================================================
//  Data RAM - 256 x 8-bit synchronous
// ============================================================
module data_ram (
    input  wire       clk,
    input  wire       we,
    input  wire [7:0] addr,
    input  wire [7:0] wr_data,
    output reg  [7:0] rd_data
);

    reg [7:0] mem [0:255];
    integer i;

    initial begin
        for (i = 0; i < 256; i = i + 1)
            mem[i] = 8'd0;
        rd_data = 8'd0;
    end

    always @(posedge clk) begin
        if (we)
            mem[addr] <= wr_data;
        rd_data <= mem[addr];
    end

endmodule
