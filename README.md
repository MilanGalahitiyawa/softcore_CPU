# 8-Bit Soft-Core CPU - Basys 3 / Verilog

Educational 8-bit soft-core CPU for the Digilent **Basys 3** (Artix-7 `xc7a35tcpg236-1`).

**Status:** simulated and verified with Icarus Verilog - `PASS: R1=10 R2=20 R3=30`

---

## Bug fixes in this revision

| # | File | Problem | Fix |
|---|------|---------|-----|
| 1 | `alu.v` | `output reg result` driven by `assign` -> Synth 8-9315 | Changed to `output wire` |
| 2 | `cpu.v` | `reg ram_rd_data` connected to a module **output** port | Changed to `wire` |
| 3 | `cpu.v` | `8'hZZ` tri-state on internal debug signal | Removed; debug now taps the register file |
| 4 | `cpu.v` | **Timing bug** - register addresses latched with `<=` in the same cycle their data was read, so `rs1_data` was one instruction stale | Addresses are now combinational; FSM drops 4 states to 3 |
| 5 | `instr_rom.v` | `integer` declared inside a named block in `initial` | Moved to module scope |
| 6 | `top.v` | 7-seg logic clocked by a divided `slow_clk` reg (unconstrained clock domain) | All logic on 100 MHz `clk` with **clock enables** |

> **Rule of thumb for error 8-9315:** `assign` drives `wire`. `always` blocks drive `reg`. Never mix them on the same signal.

---

## Files

```
alu.v            8-bit ALU (ADD SUB AND OR XOR NOT SHL SHR) + flags
register_file.v  8 x 8-bit registers, R0 hardwired to 0, debug taps
instr_rom.v      256-byte instruction ROM with demo program
data_ram.v       256-byte synchronous data RAM
cpu.v            Control unit + datapath, 3-state FSM
top.v            Basys 3 wrapper: 7-seg, LEDs, clock enables
basys3.xdc       Pin constraints
cpu_tb.v         Testbench
```

---

## ISA (2 bytes per instruction)

**Byte 1:** `[7:5]` opcode - `[4:2]` rd - `[1]` use_imm - `[0]` unused
**Byte 2:** LOAD/JMP -> imm8 | ALU ops -> `[7:5]`=rs1 `[4:2]`=rs2 | STORE -> `[2:0]`=addr reg

| Opcode | Mnemonic | Operation |
|--------|----------|-----------|
| 000 | NOP | - |
| 001 | LOAD | rd = imm8 |
| 010 | ADD | rd = rs1 + rs2 |
| 011 | SUB | rd = rs1 - rs2 |
| 100 | AND | rd = rs1 & rs2 |
| 101 | OR | rd = rs1 \| rs2 |
| 110 | STORE | MEM[rs2] = rd |
| 111 | JMP | PC = imm8 |

---

## Demo program (in ROM)

```
LOAD  R1, 10
LOAD  R2, 20
ADD   R3, R1, R2     ; R3 = 30 = 0x1E
STORE R3, [R0]       ; MEM[0] = 30
JMP   0              ; loop
```

---

## Board controls

| Control | Effect |
|---------|--------|
| BTNC (U18) | Reset, restart from address 0 |
| SW = 00 | Show PC |
| SW = 01 | Show R1 (0x0A) |
| SW = 10 | Show R2 (0x14) |
| SW = 11 | Show R3 (0x1E) <- the ADD result |

The CPU is throttled to **~2 Hz** by a clock enable so you can watch the PC advance
on the display. To run at full 100 MHz, change `cpu_tick` in `top.v` to `1'b1`.

---

## Simulate

```bash
iverilog -o sim cpu_tb.v cpu.v alu.v register_file.v instr_rom.v data_ram.v
vvp sim
gtkwave cpu_tb.vcd     # optional
```

## Synthesise (Vivado)

1. Create RTL Project, part `xc7a35tcpg236-1`
2. Add all `.v` files (design sources), set **`top`** as top module
3. Add `basys3.xdc` as constraints
4. Synthesis -> Implementation -> Generate Bitstream -> Program Device

---

## Next steps

- Add `BEQ`/`BNE` using the Zero flag (already wired out of the ALU)
- Add a stack pointer with PUSH/POP
- Write a Python assembler that emits the ROM initialisation
- Add a UART peripheral
