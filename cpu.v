// ============================================================
//  Top-level CPU: Control Unit + Datapath
//
//  FIXES vs. first version:
//   1. ram_rd_data was a 'reg' driven by a module output -> now wire
//   2. Removed tri-state (8'hZZ) debug output - not synthesisable
//      as internal logic. Debug now comes from register_file taps.
//   3. TIMING BUG: register addresses were latched with <= in the
//      same cycle their data was consumed, so rs1_data/rs2_data
//      were one instruction stale. Addresses are now COMBINATIONAL,
//      so the async-read register file returns valid data in the
//      same cycle. This also let the FSM drop from 4 states to 3.
//
//  FSM: FETCH -> FETCH2 -> EXECUTE -> (back to FETCH)
// ============================================================
module cpu (
    input  wire       clk,
    input  wire       rst,
    input  wire       en,          // clock enable (slow tick for board demo)
    output wire [7:0] dbg_pc,
    output wire [7:0] dbg_reg1,
    output wire [7:0] dbg_reg2,
    output wire [7:0] dbg_reg3
);

    // ---- Opcodes ----
    localparam OP_NOP   = 3'd0;
    localparam OP_LOAD  = 3'd1;
    localparam OP_ADD   = 3'd2;
    localparam OP_SUB   = 3'd3;
    localparam OP_AND   = 3'd4;
    localparam OP_OR    = 3'd5;
    localparam OP_STORE = 3'd6;
    localparam OP_JMP   = 3'd7;

    // ---- ALU ops ----
    localparam ALU_ADD = 3'd0;
    localparam ALU_SUB = 3'd1;
    localparam ALU_AND = 3'd2;
    localparam ALU_OR  = 3'd3;

    // ---- FSM states ----
    localparam S_FETCH  = 2'd0;
    localparam S_FETCH2 = 2'd1;
    localparam S_EXEC   = 2'd2;

    reg [7:0] pc;
    reg [7:0] ir;
    reg [7:0] ir2;
    reg [1:0] state;

    wire [2:0] opcode = ir[7:5];
    wire [2:0] rd     = ir[4:2];

    wire [7:0] rom_data;
    wire [7:0] rs1_data, rs2_data;
    wire [7:0] alu_result;
    wire       alu_zero, alu_carry, alu_neg;
    wire [7:0] ram_rd_data;          // <-- was 'reg', now wire

    // ---- COMBINATIONAL control + address decode ----
    reg  [2:0] rs1_addr, rs2_addr;
    reg  [2:0] alu_op;
    reg  [7:0] wr_data;
    reg        reg_we, ram_we;

    always @(*) begin
        // safe defaults
        rs1_addr = 3'd0;
        rs2_addr = 3'd0;
        alu_op   = ALU_ADD;
        wr_data  = 8'd0;
        reg_we   = 1'b0;
        ram_we   = 1'b0;

        case (opcode)
            OP_LOAD: begin
                wr_data = ir2;
                reg_we  = (state == S_EXEC) && en;
            end
            OP_ADD, OP_SUB, OP_AND, OP_OR: begin
                rs1_addr = ir2[7:5];
                rs2_addr = ir2[4:2];
                case (opcode)
                    OP_ADD: alu_op = ALU_ADD;
                    OP_SUB: alu_op = ALU_SUB;
                    OP_AND: alu_op = ALU_AND;
                    default: alu_op = ALU_OR;
                endcase
                wr_data = alu_result;
                reg_we  = (state == S_EXEC) && en;
            end
            OP_STORE: begin
                rs1_addr = rd;          // value to store
                rs2_addr = ir2[2:0];    // address register
                ram_we   = (state == S_EXEC) && en;
            end
            default: ; // NOP, JMP use defaults
        endcase
    end

    // ---- Submodules ----
    instr_rom rom0 (
        .addr(pc),
        .data(rom_data)
    );

    register_file rf0 (
        .clk     (clk),
        .rst     (rst),
        .we      (reg_we),
        .rd_addr (rd),
        .rs1_addr(rs1_addr),
        .rs2_addr(rs2_addr),
        .wr_data (wr_data),
        .rs1_data(rs1_data),
        .rs2_data(rs2_data),
        .dbg_r1  (dbg_reg1),
        .dbg_r2  (dbg_reg2),
        .dbg_r3  (dbg_reg3)
    );

    alu alu0 (
        .a       (rs1_data),
        .b       (rs2_data),
        .op      (alu_op),
        .result  (alu_result),
        .zero    (alu_zero),
        .carry   (alu_carry),
        .negative(alu_neg)
    );

    data_ram ram0 (
        .clk    (clk),
        .we     (ram_we),
        .addr   (rs2_data),
        .wr_data(rs1_data),
        .rd_data(ram_rd_data)
    );

    assign dbg_pc = pc;

    // ---- Sequential FSM ----
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pc    <= 8'd0;
            ir    <= 8'd0;
            ir2   <= 8'd0;
            state <= S_FETCH;
        end else if (en) begin
            case (state)
                S_FETCH: begin
                    ir    <= rom_data;
                    pc    <= pc + 8'd1;
                    state <= S_FETCH2;
                end
                S_FETCH2: begin
                    ir2   <= rom_data;
                    pc    <= pc + 8'd1;
                    state <= S_EXEC;
                end
                S_EXEC: begin
                    if (opcode == OP_JMP)
                        pc <= ir2;
                    state <= S_FETCH;
                end
                default: state <= S_FETCH;
            endcase
        end
    end

endmodule
