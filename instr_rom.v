// ============================================================
//  Instruction ROM - 256 x 8-bit
//  FIX: 'integer i' moved to module scope. Declaring it inside a
//       named begin/end block within an initial is legal Verilog
//       but Vivado's synthesiser is fussy about it.
//
//  Encoding (2 bytes per instruction):
//    Byte1: [7:5]=opcode  [4:2]=rd  [1]=use_imm  [0]=unused
//    Byte2: LOAD/JMP -> imm8
//           ALU ops  -> [7:5]=rs1  [4:2]=rs2
//           STORE    -> [2:0]=address register
// ============================================================
module instr_rom (
    input  wire [7:0] addr,
    output wire [7:0] data
);

    reg [7:0] rom [0:255];
    integer i;

    initial begin
        for (i = 0; i < 256; i = i + 1)
            rom[i] = 8'b000_000_00;   // default NOP

        rom[0] = 8'b001_001_10;  // LOAD R1, imm
        rom[1] = 8'd10;          //   imm = 10

        rom[2] = 8'b001_010_10;  // LOAD R2, imm
        rom[3] = 8'd20;          //   imm = 20

        rom[4] = 8'b010_011_00;  // ADD  R3, ...
        rom[5] = 8'b001_010_00;  //   rs1=R1, rs2=R2   -> R3 = 30

        rom[6] = 8'b110_011_00;  // STORE R3 -> MEM[...]
        rom[7] = 8'b000_000_00;  //   address register = R0 (=0)

        rom[8] = 8'b111_000_10;  // JMP imm
        rom[9] = 8'd0;           //   target = 0 (loop forever)
    end

    assign data = rom[addr];

endmodule
