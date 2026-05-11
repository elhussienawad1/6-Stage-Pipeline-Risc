# =============================================================================
# run_tb.do  –  ModelSim automation script for processor_tb
#
# Usage (in ModelSim transcript):
#   do run_tb.do
# =============================================================================

# ── 1. Create / reset working library ────────────────────────────────────────
if { [file exists work] } {
    vdel -lib work -all
}
vlib work
vmap work work

# ── 2. Compile all design files (order: primitives first) ─────────────────────
set src_dir [file dirname [info script]]

proc vcom_file { f } {
    upvar src_dir d
    set path [file join $d $f]
    if { ![file exists $path] } {
        puts "WARNING: $path not found – skipping"
        return
    }
    vcom -2008 -work work $path
}

vcom_file one_bit_adder.vhd
vcom_file ripple_adder.vhd
vcom_file n_bit_adder.vhd
vcom_file carry_select_adder.vhd
vcom_file my_dff.vhd
vcom_file my_ndff.vhd
vcom_file pc.vhd
vcom_file sp.vhd
vcom_file sp_unit.vhd
vcom_file alu.vhd
vcom_file ccr.vhd
vcom_file register_file.vhd
vcom_file memory.vhd
vcom_file sign_extend.vhd
vcom_file decode.vhd
vcom_file control_unit.vhd
vcom_file fetch.vhd
vcom_file f_d_reg.vhd
vcom_file id_ex1_reg.vhd
vcom_file execute_1.vhd
vcom_file ex1_ex2_forwarding.vhd
vcom_file execute_2.vhd
vcom_file ex2_mem_forwarding.vhd
vcom_file mem_stage.vhd
vcom_file mem_wb_forwarding.vhd
vcom_file writeback.vhd
vcom_file forwarding_unit.vhd
vcom_file hazard_unit.vhd
vcom_file processor.vhd
vcom_file processor_tb.vhd

# ── 3. Start simulation ───────────────────────────────────────────────────────
vsim -t 1ns work.processor_tb

# ── 4. Set up wave window ─────────────────────────────────────────────────────
add wave -divider "--- TB ---"
add wave /processor_tb/clk
add wave /processor_tb/rst
add wave /processor_tb/interrupt
add wave -radix hex /processor_tb/input_port
add wave -radix hex /processor_tb/output_port
add wave /processor_tb/cycle_count

add wave -divider "--- FETCH ---"
add wave -radix hex /processor_tb/DUT/fetch_pc_out
add wave -radix hex /processor_tb/DUT/fetch_instruction_d

add wave -divider "--- IF/ID register ---"
add wave -radix hex /processor_tb/DUT/fd_instruction_q
add wave -radix hex /processor_tb/DUT/fd_pc_q

add wave -divider "--- DECODE ---"
add wave -radix bin  /processor_tb/DUT/dec_opcode_out
add wave -radix unsigned /processor_tb/DUT/dec_rs_out
add wave -radix unsigned /processor_tb/DUT/dec_rt_out
add wave -radix unsigned /processor_tb/DUT/dec_rd_out
add wave -radix hex /processor_tb/DUT/dec_readdata1
add wave -radix hex /processor_tb/DUT/dec_readdata2
add wave -radix hex /processor_tb/DUT/dec_immediate_out

add wave -divider "--- CONTROL UNIT ---"
add wave /processor_tb/DUT/cu_alu_op
add wave /processor_tb/DUT/cu_alu_src
add wave /processor_tb/DUT/cu_reg1_write
add wave /processor_tb/DUT/cu_mem_read
add wave /processor_tb/DUT/cu_mem_write
add wave /processor_tb/DUT/cu_branch
add wave /processor_tb/DUT/cu_branch_type

add wave -divider "--- HAZARD UNIT ---"
add wave /processor_tb/DUT/hz_rst_if_id
add wave /processor_tb/DUT/hz_rst_id_ex1
add wave /processor_tb/DUT/hz_enable_if_id
add wave /processor_tb/DUT/hz_enable_id_ex1
add wave /processor_tb/DUT/hz_pc_enable

add wave -divider "--- FORWARDING UNIT ---"
add wave /processor_tb/DUT/fwd_forward_a
add wave /processor_tb/DUT/fwd_forward_b

add wave -divider "--- EX1 ---"
add wave -radix hex /processor_tb/DUT/ex1_alu_result
add wave /processor_tb/DUT/ex1_zero
add wave /processor_tb/DUT/ex1_negative
add wave /processor_tb/DUT/ex1_carry

add wave -divider "--- EX1/EX2 pipeline register ---"
add wave -radix hex /processor_tb/DUT/ex1ex2_alu_result_out
add wave -radix unsigned /processor_tb/DUT/ex1ex2_rdst_out
add wave /processor_tb/DUT/ex1ex2_zero_out
add wave /processor_tb/DUT/ex1ex2_carry_out
add wave /processor_tb/DUT/ex1ex2_negative_out

add wave -divider "--- EX2 (branch) ---"
add wave /processor_tb/DUT/ex2_pc_src
add wave -radix hex /processor_tb/DUT/ex2_address

add wave -divider "--- EX2/MEM pipeline register ---"
add wave -radix hex /processor_tb/DUT/ex2mem_alu_result_out
add wave -radix hex /processor_tb/DUT/ex2mem_address_out
add wave -radix unsigned /processor_tb/DUT/ex2mem_rdst_out
add wave /processor_tb/DUT/ex2mem_mem_read_out
add wave /processor_tb/DUT/ex2mem_mem_write_out

add wave -divider "--- MEMORY STAGE ---"
add wave -radix hex /processor_tb/DUT/mem_address_wire
add wave -radix hex /processor_tb/DUT/mem_writedata_wire
add wave /processor_tb/DUT/mem_re_wire
add wave /processor_tb/DUT/mem_we_wire
add wave -radix hex /processor_tb/DUT/mem_output_sig

add wave -divider "--- MEM/WB pipeline register ---"
add wave -radix hex /processor_tb/DUT/memwb_alu_result_out
add wave -radix hex /processor_tb/DUT/memwb_mem_data_out
add wave -radix unsigned /processor_tb/DUT/memwb_rdst_out
add wave /processor_tb/DUT/memwb_reg_write_out
add wave /processor_tb/DUT/memwb_mem_to_reg_out

add wave -divider "--- WRITEBACK ---"
add wave /processor_tb/DUT/wb_write_en_1
add wave -radix unsigned /processor_tb/DUT/wb_write_addr_1
add wave -radix hex /processor_tb/DUT/wb_write_data_1
add wave /processor_tb/DUT/wb_write_en_2
add wave -radix unsigned /processor_tb/DUT/wb_write_addr_2
add wave -radix hex /processor_tb/DUT/wb_write_data_2

# ── 5. Run and zoom ───────────────────────────────────────────────────────────
run 1200 ns
wave zoom full

puts "=== Simulation done. Check transcript for per-cycle reports ==="
