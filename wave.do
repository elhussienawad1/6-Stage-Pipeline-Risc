quietly WaveActivateNextPane {} 0

# ── Clock / Reset / Interrupt ─────────────────────────────────────────
add wave -divider "Control"
add wave -label "CLK"       sim:/processor/clk
add wave -label "RST"       sim:/processor/rst
add wave -label "Interrupt" sim:/processor/interrupt

# ── I/O Ports ─────────────────────────────────────────────────────────
add wave -divider "I/O"
add wave -label "IN_PORT"  -radix hex sim:/processor/input_port
add wave -label "OUT_PORT" -radix hex sim:/processor/output_port

# ── Program Counter ───────────────────────────────────────────────────
add wave -divider "PC"
add wave -label "PC" -radix hex sim:/processor/fetch_pc_out

# ── Register File (R0-R7) ─────────────────────────────────────────────
# These live inside the decode stage's register file.
# Adjust the path if your reg file instance name differs.
add wave -divider "Register File"
add wave -label "R0" -radix hex sim:/processor/U_DECODE/reg_file_inst/registers(0)
add wave -label "R1" -radix hex sim:/processor/U_DECODE/reg_file_inst/registers(1)
add wave -label "R2" -radix hex sim:/processor/U_DECODE/reg_file_inst/registers(2)
add wave -label "R3" -radix hex sim:/processor/U_DECODE/reg_file_inst/registers(3)
add wave -label "R4" -radix hex sim:/processor/U_DECODE/reg_file_inst/registers(4)
add wave -label "R5" -radix hex sim:/processor/U_DECODE/reg_file_inst/registers(5)
add wave -label "R6" -radix hex sim:/processor/U_DECODE/reg_file_inst/registers(6)
add wave -label "R7" -radix hex sim:/processor/U_DECODE/reg_file_inst/registers(7)

# ── Stack Pointer ─────────────────────────────────────────────────────
add wave -divider "SP"
add wave -label "SP" -radix hex sim:/processor/U_MEM_STAGE/sp_unit_inst/sp

# ── Flags (Z, N, C) ───────────────────────────────────────────────────
add wave -divider "Flags"
add wave -label "Zero"     sim:/processor/ex1ex2_zero_out
add wave -label "Negative" sim:/processor/ex1ex2_negative_out
add wave -label "Carry"    sim:/processor/ex1ex2_carry_out

# ── Writeback (what's being written back each cycle) ──────────────────
add wave -divider "Writeback"
add wave -label "WB_EN1"   sim:/processor/wb_write_en_1
add wave -label "WB_ADDR1" -radix unsigned sim:/processor/wb_write_addr_1
add wave -label "WB_DATA1" -radix hex sim:/processor/wb_write_data_1
add wave -label "WB_EN2"   sim:/processor/wb_write_en_2
add wave -label "WB_ADDR2" -radix unsigned sim:/processor/wb_write_addr_2
add wave -label "WB_DATA2" -radix hex sim:/processor/wb_write_data_2

WaveRestoreZoom {0 ns} {300 ns}
