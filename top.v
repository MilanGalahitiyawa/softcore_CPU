// ============================================================
//  Basys 3 Top-Level Wrapper
//
//  FIX: the 7-seg multiplexer previously ran off a generated
//       'slow_clk' reg. Driving logic from a divided reg creates
//       an unconstrained clock domain and Vivado will complain.
//       Everything now runs on the 100 MHz clk with CLOCK ENABLES.
//
//  clk      : 100 MHz  (W5)
//  rst_btn  : BTNC     (U18), active high
//  sw[1:0]  : select which value to display
// ============================================================
module top (
    input  wire        clk,
    input  wire        rst_btn,
    input  wire [1:0]  sw,
    output wire [15:0] led,
    output wire [6:0]  seg,
    output wire        dp,
    output wire [3:0]  an
);

    // ---- Refresh tick for 7-seg mux (~1 kHz) ----
    reg [16:0] refresh_cnt;
    wire       refresh_tick = (refresh_cnt == 17'd99_999);

    always @(posedge clk) begin
        if (rst_btn)            refresh_cnt <= 17'd0;
        else if (refresh_tick)  refresh_cnt <= 17'd0;
        else                    refresh_cnt <= refresh_cnt + 1'b1;
    end

    // ---- CPU tick (~2 Hz) so you can watch it execute ----
    reg [25:0] cpu_cnt;
    wire       cpu_tick = (cpu_cnt == 26'd24_999_999);

    always @(posedge clk) begin
        if (rst_btn)         cpu_cnt <= 26'd0;
        else if (cpu_tick)   cpu_cnt <= 26'd0;
        else                 cpu_cnt <= cpu_cnt + 1'b1;
    end

    // ---- CPU ----
    wire [7:0] dbg_pc, dbg_r1, dbg_r2, dbg_r3;

    cpu cpu0 (
        .clk     (clk),
        .rst     (rst_btn),
        .en      (cpu_tick),
        .dbg_pc  (dbg_pc),
        .dbg_reg1(dbg_r1),
        .dbg_reg2(dbg_r2),
        .dbg_reg3(dbg_r3)
    );

    // ---- Select displayed byte ----
    reg [7:0] disp_byte;
    always @(*) begin
        case (sw)
            2'b00:   disp_byte = dbg_pc;
            2'b01:   disp_byte = dbg_r1;
            2'b10:   disp_byte = dbg_r2;
            default: disp_byte = dbg_r3;
        endcase
    end

    // ---- 7-seg digit scan ----
    reg [1:0] digit_sel;
    always @(posedge clk) begin
        if (rst_btn)           digit_sel <= 2'd0;
        else if (refresh_tick) digit_sel <= digit_sel + 1'b1;
    end

    reg [3:0] nibble;
    reg [3:0] an_reg;
    always @(*) begin
        case (digit_sel)
            2'd0:    begin an_reg = 4'b1110; nibble = disp_byte[3:0]; end
            2'd1:    begin an_reg = 4'b1101; nibble = disp_byte[7:4]; end
            default: begin an_reg = 4'b1111; nibble = 4'd0;           end
        endcase
    end

    // ---- Hex to 7-seg (common anode, active low, order gfedcba) ----
    reg [6:0] seg_reg;
    always @(*) begin
        case (nibble)
            4'h0: seg_reg = 7'b1000000;
            4'h1: seg_reg = 7'b1111001;
            4'h2: seg_reg = 7'b0100100;
            4'h3: seg_reg = 7'b0110000;
            4'h4: seg_reg = 7'b0011001;
            4'h5: seg_reg = 7'b0010010;
            4'h6: seg_reg = 7'b0000010;
            4'h7: seg_reg = 7'b1111000;
            4'h8: seg_reg = 7'b0000000;
            4'h9: seg_reg = 7'b0010000;
            4'hA: seg_reg = 7'b0001000;
            4'hB: seg_reg = 7'b0000011;
            4'hC: seg_reg = 7'b1000110;
            4'hD: seg_reg = 7'b0100001;
            4'hE: seg_reg = 7'b0000110;
            default: seg_reg = 7'b0001110;
        endcase
    end

    assign seg = seg_reg;
    assign an  = an_reg;
    assign dp  = 1'b1;
    assign led = {8'd0, disp_byte};

endmodule
