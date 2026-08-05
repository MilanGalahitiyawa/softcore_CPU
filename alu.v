// ============================================================
//  ALU - 8-bit Arithmetic & Logic Unit
//  Supports: ADD, SUB, AND, OR, XOR, NOT, SHL, SHR
//
//  FIX: 'result' must be a wire, not a reg, because it is
//       driven by a continuous 'assign' statement.
// ============================================================
module alu (
    input  wire [7:0] a,
    input  wire [7:0] b,
    input  wire [2:0] op,
    output wire [7:0] result,      // <-- was 'reg', now 'wire'
    output wire       zero,
    output wire       carry,
    output wire       negative
);

    localparam ADD = 3'd0;
    localparam SUB = 3'd1;
    localparam AND = 3'd2;
    localparam OR  = 3'd3;
    localparam XOR = 3'd4;
    localparam NOT = 3'd5;
    localparam SHL = 3'd6;
    localparam SHR = 3'd7;

    reg [8:0] full_result;   // 9-bit to capture carry out

    always @(*) begin
        case (op)
            ADD: full_result = {1'b0, a} + {1'b0, b};
            SUB: full_result = {1'b0, a} - {1'b0, b};
            AND: full_result = {1'b0, a & b};
            OR:  full_result = {1'b0, a | b};
            XOR: full_result = {1'b0, a ^ b};
            NOT: full_result = {1'b0, ~a};
            SHL: full_result = {a[7], a[6:0], 1'b0};
            SHR: full_result = {a[0], 1'b0, a[7:1]};
            default: full_result = 9'd0;
        endcase
    end

    assign result   = full_result[7:0];
    assign carry    = full_result[8];
    assign zero     = (full_result[7:0] == 8'd0);
    assign negative = full_result[7];

endmodule
