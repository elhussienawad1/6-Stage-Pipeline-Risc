vlib work
vmap work work

vcom -2008 one_bit_adder.vhd
vcom -2008 ripple_adder.vhd
vcom -2008 carry_select_adder.vhd
vcom -2008 alu.vhd
vcom -2008 ccr.vhd
vcom -2008 execute_1.vhd
vcom -2008 execute_1_tb.vhd

vsim -t 1ns work.execute_1_tb

log -r /*

add wave -divider "=== CLOCK / RESET ==="
add wave -radix binary      /execute_1_tb/clk
add wave -radix binary      /execute_1_tb/rst

add wave -divider "=== ALU CONTROL ==="
add wave -radix symbolic    /execute_1_tb/alu_operation
add wave -radix binary      /execute_1_tb/alu_src
add wave -radix binary      /execute_1_tb/alu_passthrough
add wave -radix binary      /execute_1_tb/set_carry

add wave -divider "=== REGISTER INPUTS ==="
add wave -radix decimal     /execute_1_tb/r_rs1
add wave -radix decimal     /execute_1_tb/r_rs2
add wave -radix decimal     /execute_1_tb/imm

add wave -divider "=== FORWARDING ==="
add wave -radix symbolic    /execute_1_tb/forward_a
add wave -radix symbolic    /execute_1_tb/forward_b
add wave -radix decimal     /execute_1_tb/ex1_ex2_result
add wave -radix decimal     /execute_1_tb/ex2_mem_result
add wave -radix decimal     /execute_1_tb/mem_wb_result

add wave -divider "=== CCR CONTROL ==="
add wave -radix binary      /execute_1_tb/flag_enable
add wave -radix binary      /execute_1_tb/store_ccr
add wave -radix binary      /execute_1_tb/restore_ccr

add wave -divider "=== OUTPUTS ==="
add wave -radix decimal     /execute_1_tb/alu_result
add wave -radix binary      /execute_1_tb/zero
add wave -radix binary      /execute_1_tb/negative
add wave -radix binary      /execute_1_tb/carry

run -all

echo "============================================"
echo "Simulation complete - see transcript above"
echo "============================================"