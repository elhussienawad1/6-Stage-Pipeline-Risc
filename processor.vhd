library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity processor is
    port(
        clk        : in  std_logic;
        rst        : in  std_logic;
        interrupt  : in  std_logic;
        input_port : in  std_logic_vector(31 downto 0);
        output_port: out std_logic_vector(31 downto 0)
    );
end processor;

architecture structural of processor is

    -- ── Component declarations ────────────────────────────────────────────

    component fetch is
        port(
            input_port          : in  std_logic_vector(31 downto 0);
            clk                 : in  std_logic;
            reset, interrupt    : in  std_logic;
            pc_plus_immediate   : in  std_logic_vector(31 downto 0);
            do_branch           : in  std_logic;
            pc_enable           : in  std_logic;
            instruction_d       : out std_logic_vector(31 downto 0);
            pc_d                : out std_logic_vector(31 downto 0);
            inputport_d_if_id   : out std_logic_vector(31 downto 0);
            instruction_in      : in  std_logic_vector(31 downto 0);
            memory_busy         : in  std_logic;
            pc_out              : out std_logic_vector(31 downto 0);
            mem1                : in  std_logic_vector(31 downto 0);
            mem2                : in  std_logic_vector(31 downto 0);
            mem3                : in  std_logic_vector(31 downto 0);
            mem4                : in  std_logic_vector(31 downto 0);
            pc_src_q            : in  std_logic;
            call_signal         : in  std_logic;
            immediate_input     : in  std_logic_vector(31 downto 0);
            int_signal          : in  std_logic;
            index               : in  std_logic
        );
    end component;

    component f_d_reg is
        port(
            clk           : in  std_logic;
            rst           : in  std_logic;
            flush         : in  std_logic;
            enable        : in  std_logic;
            instruction_d : in  std_logic_vector(31 downto 0);
            instruction_q : out std_logic_vector(31 downto 0);
            pc_d          : in  std_logic_vector(31 downto 0);
            pc_q          : out std_logic_vector(31 downto 0);
            inputport_d   : in  std_logic_vector(31 downto 0);
            inputport_q   : out std_logic_vector(31 downto 0)
        );
    end component;

    component decode is
        port(
            clk, rst         : in  std_logic;
            instruction_in   : in  std_logic_vector(31 downto 0);
            pc_in            : in  std_logic_vector(31 downto 0);
            pc_out           : out std_logic_vector(31 downto 0);
            input_port_in    : in  std_logic_vector(31 downto 0);
            input_port_out   : out std_logic_vector(31 downto 0);
            mem_wb_regwrite1 : in  std_logic;
            mem_wb_regwrite2 : in  std_logic;
            mem_wb_waddr1    : in  std_logic_vector(2 downto 0);
            mem_wb_waddr2    : in  std_logic_vector(2 downto 0);
            mem_wb_wdata1    : in  std_logic_vector(31 downto 0);
            mem_wb_wdata2    : in  std_logic_vector(31 downto 0);
            rs_out           : out std_logic_vector(2 downto 0);
            rt_out           : out std_logic_vector(2 downto 0);
            rd_out           : out std_logic_vector(2 downto 0);
            readdata1        : out std_logic_vector(31 downto 0);
            readdata2        : out std_logic_vector(31 downto 0);
            immediate_out    : out std_logic_vector(31 downto 0);
            opcode_out       : out std_logic_vector(4 downto 0)
        );
    end component;

    component control_unit is
        port(
            opcode           : in  std_logic_vector(4 downto 0);
            mem_or_branch_pc : out std_logic;
            inc_pc           : out std_logic;
            reg1_write       : out std_logic;
            reg2_write       : out std_logic;
            alu_src          : out std_logic;
            alu_op           : out std_logic_vector(2 downto 0);
            set_carry        : out std_logic;
            alu_passthrough  : out std_logic;
            flag_enable      : out std_logic;
            restore_ccr      : out std_logic;
            store_ccr        : out std_logic;
            branch           : out std_logic;
            branch_type      : out std_logic_vector(1 downto 0);
            inc_sp           : out std_logic;
            dec_sp           : out std_logic;
            mem_addr_src     : out std_logic;
            mem_data_src     : out std_logic_vector(1 downto 0);
            mem_read         : out std_logic;
            mem_write        : out std_logic;
            mem_to_reg       : out std_logic;
            reg_to_reg       : out std_logic;
            output_enable    : out std_logic;
            input_enable     : out std_logic;
            clock_enable     : out std_logic;
            interrupt_enable : out std_logic;
            rst              : out std_logic
        );
    end component;

    component id_ex_reg is
        port(
            clk, rst    : in std_logic;
            clk_enable  : in std_logic;
            pc_in          : in  std_logic_vector(31 downto 0);
            input_port_in  : in  std_logic_vector(31 downto 0);
            readdata1_in   : in  std_logic_vector(31 downto 0);
            readdata2_in   : in  std_logic_vector(31 downto 0);
            immediate_in   : in  std_logic_vector(31 downto 0);
            rs_in          : in  std_logic_vector(2 downto 0);
            rt_in          : in  std_logic_vector(2 downto 0);
            rd_in          : in  std_logic_vector(2 downto 0);
            mem_or_branch_pc_in : in std_logic;
            inc_pc_in           : in std_logic;
            reg1_write_in  : in  std_logic;
            reg2_write_in  : in  std_logic;
            alu_src_in         : in std_logic;
            alu_op_in          : in std_logic_vector(2 downto 0);
            set_carry_in       : in std_logic;
            alu_passthrough_in : in std_logic;
            flag_enable_in     : in std_logic;
            restore_ccr_in     : in std_logic;
            store_ccr_in       : in std_logic;
            branch_in      : in  std_logic;
            branch_type_in : in  std_logic_vector(1 downto 0);
            inc_sp_in      : in  std_logic;
            dec_sp_in      : in  std_logic;
            mem_addr_src_in : in std_logic;
            mem_data_src_in : in std_logic_vector(1 downto 0);
            mem_read_in     : in std_logic;
            mem_write_in    : in std_logic;
            mem_to_reg_in  : in  std_logic;
            reg_to_reg_in  : in  std_logic;
            output_enable_in    : in std_logic;
            input_enable_in     : in std_logic;
            clock_enable_in     : in std_logic;
            interrupt_enable_in : in std_logic;
            pc_out          : out std_logic_vector(31 downto 0);
            input_port_out  : out std_logic_vector(31 downto 0);
            readdata1_out   : out std_logic_vector(31 downto 0);
            readdata2_out   : out std_logic_vector(31 downto 0);
            immediate_out   : out std_logic_vector(31 downto 0);
            rs_out          : out std_logic_vector(2 downto 0);
            rt_out          : out std_logic_vector(2 downto 0);
            rd_out          : out std_logic_vector(2 downto 0);
            mem_or_branch_pc_out : out std_logic;
            inc_pc_out           : out std_logic;
            reg1_write_out : out std_logic;
            reg2_write_out : out std_logic;
            alu_src_out         : out std_logic;
            alu_op_out          : out std_logic_vector(2 downto 0);
            set_carry_out       : out std_logic;
            alu_passthrough_out : out std_logic;
            flag_enable_out     : out std_logic;
            restore_ccr_out     : out std_logic;
            store_ccr_out       : out std_logic;
            branch_out      : out std_logic;
            branch_type_out : out std_logic_vector(1 downto 0);
            inc_sp_out      : out std_logic;
            dec_sp_out      : out std_logic;
            mem_addr_src_out : out std_logic;
            mem_data_src_out : out std_logic_vector(1 downto 0);
            mem_read_out     : out std_logic;
            mem_write_out    : out std_logic;
            mem_to_reg_out  : out std_logic;
            reg_to_reg_out  : out std_logic;
            output_enable_out    : out std_logic;
            input_enable_out     : out std_logic;
            clock_enable_out     : out std_logic;
            interrupt_enable_out : out std_logic
        );
    end component;

    component execute_1 is
        generic (n : integer := 32);
        port(
            clk, rst        : in  std_logic;
            clk_enable      : in  std_logic;
            r_rs1           : in  std_logic_vector(n-1 downto 0);
            r_rs2           : in  std_logic_vector(n-1 downto 0);
            imm             : in  std_logic_vector(n-1 downto 0);
            alu_result      : out std_logic_vector(n-1 downto 0);
            ex1_ex2_result  : in  std_logic_vector(n-1 downto 0);
            ex2_mem_result  : in  std_logic_vector(n-1 downto 0);
            mem_wb_result   : in  std_logic_vector(n-1 downto 0);
            forward_a       : in  std_logic_vector(1 downto 0);
            forward_b       : in  std_logic_vector(1 downto 0);
            zero            : out std_logic;
            negative        : out std_logic;
            carry           : out std_logic;
            alu_src         : in  std_logic;
            alu_operation   : in  std_logic_vector(2 downto 0);
            set_carry       : in  std_logic;
            alu_passthrough : in  std_logic;
            store_ccr       : in  std_logic;
            flag_enable     : in  std_logic;
            restore_ccr     : in  std_logic
        );
    end component;

    component ex1_ex2_forwarding is
        generic (n : integer := 32);
        port(
            clk, rst          : in  std_logic;
            clk_en            : in  std_logic;
            flush             : in  std_logic;
            zero_in           : in  std_logic;
            negative_in       : in  std_logic;
            carry             : in  std_logic;
            zero_out          : out std_logic;
            negative_out      : out std_logic;
            carry_out         : out std_logic;
            incremented_pc_in : in  std_logic_vector(n-1 downto 0);
            pc_in             : in  std_logic_vector(n-1 downto 0);
            in_port_in        : in  std_logic_vector(n-1 downto 0);
            rdst_in           : in  std_logic_vector(2 downto 0);
            rsrc1_in          : in  std_logic_vector(2 downto 0);
            r_rsrc1_in        : in  std_logic_vector(n-1 downto 0);
            r_rsrc2_in        : in  std_logic_vector(n-1 downto 0);
            alu_result_in     : in  std_logic_vector(n-1 downto 0);
            imm_in            : in  std_logic_vector(n-1 downto 0);
            branch_type_in    : in  std_logic_vector(1 downto 0);
            branch_in         : in  std_logic;
            inc_sp_in         : in  std_logic;
            dec_sp_in         : in  std_logic;
            mem_add_src_in    : in  std_logic;
            mem_data_src_in   : in  std_logic;
            mem_read_in       : in  std_logic;
            mem_write_in      : in  std_logic;
            output_enable_in  : in  std_logic;
            mem_to_reg_in     : in  std_logic;
            reg_to_reg_in     : in  std_logic;
            input_enable_in   : in  std_logic;
            incremented_pc_out: out std_logic_vector(n-1 downto 0);
            pc_out            : out std_logic_vector(n-1 downto 0);
            in_port_out       : out std_logic_vector(n-1 downto 0);
            rdst_out          : out std_logic_vector(2 downto 0);
            rsrc1_out         : out std_logic_vector(2 downto 0);
            r_rsrc1_out       : out std_logic_vector(n-1 downto 0);
            r_rsrc2_out       : out std_logic_vector(n-1 downto 0);
            alu_result_out    : out std_logic_vector(n-1 downto 0);
            imm_out           : out std_logic_vector(n-1 downto 0);
            branch_type_out   : out std_logic_vector(1 downto 0);
            branch_out        : out std_logic;
            inc_sp_out        : out std_logic;
            dec_sp_out        : out std_logic;
            mem_add_src_out   : out std_logic;
            mem_data_src_out  : out std_logic;
            mem_read_out      : out std_logic;
            mem_write_out     : out std_logic;
            output_enable_out : out std_logic;
            mem_to_reg_out    : out std_logic;
            reg_to_reg_out    : out std_logic;
            input_enable_out  : out std_logic
        );
    end component;

    component execute_2 is
        generic (n : integer := 32);
        port(
            rst, clk    : in  std_logic;
            clk_en      : in  std_logic;
            rsrc        : in  std_logic_vector(n-1 downto 0);
            imm_val     : in  std_logic_vector(n-1 downto 0);
            branch_type : in  std_logic_vector(1 downto 0);
            branch      : in  std_logic;
            Z, C, Neg   : in  std_logic;
            pc_src      : out std_logic;
            address     : out std_logic_vector(n-1 downto 0)
        );
    end component;

    component ex2_mem_forwarding is
        generic (n : integer := 32);
        port(
            clk, rst          : in  std_logic;
            clk_en            : in  std_logic;
            flush             : in  std_logic;
            incremented_pc_in : in  std_logic_vector(n-1 downto 0);
            pc_in             : in  std_logic_vector(n-1 downto 0);
            in_port_in        : in  std_logic_vector(n-1 downto 0);
            r_rsrc1_in        : in  std_logic_vector(n-1 downto 0);
            r_rsrc2_in        : in  std_logic_vector(n-1 downto 0);
            alu_result_in     : in  std_logic_vector(n-1 downto 0);
            address_in        : in  std_logic_vector(n-1 downto 0);
            rdst_in           : in  std_logic_vector(2 downto 0);
            rsrc1_in          : in  std_logic_vector(2 downto 0);
            inc_sp_in         : in  std_logic;
            dec_sp_in         : in  std_logic;
            mem_add_src_in    : in  std_logic;
            mem_data_src_in   : in  std_logic;
            mem_read_in       : in  std_logic;
            mem_write_in      : in  std_logic;
            output_enable_in  : in  std_logic;
            mem_to_reg_in     : in  std_logic;
            reg_to_reg_in     : in  std_logic;
            input_enable_in   : in  std_logic;
            reg_write_in      : in  std_logic;
            reg2_write_in     : in  std_logic;
            incremented_pc_out: out std_logic_vector(n-1 downto 0);
            pc_out            : out std_logic_vector(n-1 downto 0);
            in_port_out       : out std_logic_vector(n-1 downto 0);
            r_rsrc1_out       : out std_logic_vector(n-1 downto 0);
            r_rsrc2_out       : out std_logic_vector(n-1 downto 0);
            alu_result_out    : out std_logic_vector(n-1 downto 0);
            address_out       : out std_logic_vector(n-1 downto 0);
            rdst_out          : out std_logic_vector(2 downto 0);
            rsrc1_out         : out std_logic_vector(2 downto 0);
            inc_sp_out        : out std_logic;
            dec_sp_out        : out std_logic;
            mem_add_src_out   : out std_logic;
            mem_data_src_out  : out std_logic;
            mem_read_out      : out std_logic;
            mem_write_out     : out std_logic;
            output_enable_out : out std_logic;
            mem_to_reg_out    : out std_logic;
            reg_to_reg_out    : out std_logic;
            input_enable_out  : out std_logic;
            reg_write_out     : out std_logic;
            reg2_write_out    : out std_logic
        );
    end component;

    component mem_stage is
        generic (n : integer := 32);
        port(
            clk, rst    : in  std_logic;
            clk_enable  : in  std_logic;
            address_in        : in  std_logic_vector(n-1 downto 0);
            r_rsrc1_in        : in  std_logic_vector(n-1 downto 0);
            r_rsrc2_in        : in  std_logic_vector(n-1 downto 0);
            incremented_pc_in : in  std_logic_vector(n-1 downto 0);
            inc_sp            : in  std_logic;
            dec_sp            : in  std_logic;
            mem_add_src       : in  std_logic;
            mem_data_src      : in  std_logic;
            mem_read          : in  std_logic;
            mem_write         : in  std_logic;
            mem_address_out   : out std_logic_vector(n-1 downto 0);
            writedata_out     : out std_logic_vector(n-1 downto 0);
            mem_read_out      : out std_logic;
            mem_write_out     : out std_logic;
            mem_data_in       : in  std_logic_vector(n-1 downto 0);
            mem_data_out      : out std_logic_vector(n-1 downto 0);
            sp_out            : out std_logic_vector(n-1 downto 0)
        );
    end component;

    component mem_wb_forwarding is
        generic (n : integer := 32);
        port(
            clk, rst          : in  std_logic;
            clk_en            : in  std_logic;
            incremented_pc_in : in  std_logic_vector(n-1 downto 0);
            in_port_in        : in  std_logic_vector(n-1 downto 0);
            r_rsrc1_in        : in  std_logic_vector(n-1 downto 0);
            r_rsrc2_in        : in  std_logic_vector(n-1 downto 0);
            alu_result_in     : in  std_logic_vector(n-1 downto 0);
            mem_data_in       : in  std_logic_vector(n-1 downto 0);
            rdst_in           : in  std_logic_vector(2 downto 0);
            rsrc1_in          : in  std_logic_vector(2 downto 0);
            output_enable_in  : in  std_logic;
            mem_to_reg_in     : in  std_logic;
            reg_to_reg_in     : in  std_logic;
            input_enable_in   : in  std_logic;
            reg_write_in      : in  std_logic;
            reg2_write_in     : in  std_logic;
            incremented_pc_out: out std_logic_vector(n-1 downto 0);
            in_port_out       : out std_logic_vector(n-1 downto 0);
            r_rsrc1_out       : out std_logic_vector(n-1 downto 0);
            r_rsrc2_out       : out std_logic_vector(n-1 downto 0);
            alu_result_out    : out std_logic_vector(n-1 downto 0);
            mem_data_out      : out std_logic_vector(n-1 downto 0);
            rdst_out          : out std_logic_vector(2 downto 0);
            rsrc1_out         : out std_logic_vector(2 downto 0);
            output_enable_out : out std_logic;
            mem_to_reg_out    : out std_logic;
            reg_to_reg_out    : out std_logic;
            input_enable_out  : out std_logic;
            reg_write_out     : out std_logic;
            reg2_write_out    : out std_logic
        );
    end component;

    component writeback is
        generic (n : integer := 32);
        port(
            alu_result    : in  std_logic_vector(n-1 downto 0);
            mem_data      : in  std_logic_vector(n-1 downto 0);
            in_port       : in  std_logic_vector(n-1 downto 0);
            r_rsrc1       : in  std_logic_vector(n-1 downto 0);
            r_rsrc2       : in  std_logic_vector(n-1 downto 0);
            rdst          : in  std_logic_vector(2 downto 0);
            rsrc1         : in  std_logic_vector(2 downto 0);
            output_enable : in  std_logic;
            input_enable  : in  std_logic;
            mem_to_reg    : in  std_logic;
            reg_to_reg    : in  std_logic;
            reg_write     : in  std_logic;
            reg2_write    : in  std_logic;
            out_port      : out std_logic_vector(n-1 downto 0);
            write_data_1  : out std_logic_vector(n-1 downto 0);
            write_addr_1  : out std_logic_vector(2 downto 0);
            write_en_1    : out std_logic;
            write_data_2  : out std_logic_vector(n-1 downto 0);
            write_addr_2  : out std_logic_vector(2 downto 0);
            write_en_2    : out std_logic;
            wb_result     : out std_logic_vector(n-1 downto 0)
        );
    end component;

    component hazard_unit is
        port(
            reset               : in  std_logic;
            id_ex1_mem_read     : in  std_logic;
            id_ex1_mem_write    : in  std_logic;
            memread_q           : in  std_logic;
            memwrite_q          : in  std_logic;
            do_branch           : in  std_logic;
            call_signal         : in  std_logic;
            int_signal          : in  std_logic;
            rst_if_id           : out std_logic;
            rst_id_ex1          : out std_logic;
            rst_ex1_ex2         : out std_logic;
            rst_ex2_mem         : out std_logic;
            rst_mem_wb          : out std_logic;
            enable_if_id        : out std_logic;
            enable_id_ex1       : out std_logic;
            enable_ex1_ex2      : out std_logic;
            enable_ex2_mem      : out std_logic;
            enable_mem_wb       : out std_logic;
            pc_enable           : out std_logic
        );
    end component;

    component forwarding_unit is
        port(
            mem_wb_regwrite  : in  std_logic;
            ex1_ex2_regwrite : in  std_logic;
            ex2_mem_regwrite : in  std_logic;
            mem_wb_rdst      : in  std_logic_vector(2 downto 0);
            id_ex1_rs1       : in  std_logic_vector(2 downto 0);
            id_ex1_rs2       : in  std_logic_vector(2 downto 0);
            ex1_ex2_rdst     : in  std_logic_vector(2 downto 0);
            ex2_mem_rdst     : in  std_logic_vector(2 downto 0);
            forward_a        : out std_logic_vector(1 downto 0);
            forward_b        : out std_logic_vector(1 downto 0)
        );
    end component;

    component reg_file_memory is
        generic(N : integer := 32; M : integer := 1024);
        port(
            clk, rst            : in  std_logic;
            address             : in  std_logic_vector(31 downto 0);
            instruction_address : in  std_logic_vector(31 downto 0);
            mem_write, mem_read : in  std_logic;
            writedata           : in  std_logic_vector(N-1 downto 0);
            mem_output          : out std_logic_vector(N-1 downto 0);
            memory_busy         : out std_logic;
            mem1                : out std_logic_vector(N-1 downto 0);
            mem2                : out std_logic_vector(N-1 downto 0);
            mem3                : out std_logic_vector(N-1 downto 0);
            mem4                : out std_logic_vector(N-1 downto 0)
        );
    end component;

    -- ── Memory signals ────────────────────────────────────────────────────
    signal mem_output_sig  : std_logic_vector(31 downto 0);
    signal memory_busy_sig : std_logic;
    signal mem1_sig        : std_logic_vector(31 downto 0);
    signal mem2_sig        : std_logic_vector(31 downto 0);
    signal mem3_sig        : std_logic_vector(31 downto 0);
    signal mem4_sig        : std_logic_vector(31 downto 0);
    signal mem_address_wire   : std_logic_vector(31 downto 0);
    signal mem_writedata_wire : std_logic_vector(31 downto 0);
    signal mem_re_wire        : std_logic;
    signal mem_we_wire        : std_logic;

    -- ── Fetch outputs ─────────────────────────────────────────────────────
    signal fetch_instruction_d  : std_logic_vector(31 downto 0);
    signal fetch_pc_d           : std_logic_vector(31 downto 0);
    signal fetch_inputport_d    : std_logic_vector(31 downto 0);
    signal fetch_pc_out         : std_logic_vector(31 downto 0);

    -- ── F/D register outputs ──────────────────────────────────────────────
    signal fd_instruction_q : std_logic_vector(31 downto 0);
    signal fd_pc_q          : std_logic_vector(31 downto 0);
    signal fd_inputport_q   : std_logic_vector(31 downto 0);

    -- ── Decode outputs ────────────────────────────────────────────────────
    signal dec_pc_out        : std_logic_vector(31 downto 0);
    signal dec_input_port_out: std_logic_vector(31 downto 0);
    signal dec_rs_out        : std_logic_vector(2 downto 0);
    signal dec_rt_out        : std_logic_vector(2 downto 0);
    signal dec_rd_out        : std_logic_vector(2 downto 0);
    signal dec_readdata1     : std_logic_vector(31 downto 0);
    signal dec_readdata2     : std_logic_vector(31 downto 0);
    signal dec_immediate_out : std_logic_vector(31 downto 0);
    signal dec_opcode_out    : std_logic_vector(4 downto 0);

    -- ── Control unit outputs ──────────────────────────────────────────────
    signal cu_mem_or_branch_pc  : std_logic;
    signal cu_inc_pc            : std_logic;
    signal cu_reg1_write        : std_logic;
    signal cu_reg2_write        : std_logic;
    signal cu_alu_src           : std_logic;
    signal cu_alu_op            : std_logic_vector(2 downto 0);
    signal cu_set_carry         : std_logic;
    signal cu_alu_passthrough   : std_logic;
    signal cu_flag_enable       : std_logic;
    signal cu_restore_ccr       : std_logic;
    signal cu_store_ccr         : std_logic;
    signal cu_branch            : std_logic;
    signal cu_branch_type       : std_logic_vector(1 downto 0);
    signal cu_inc_sp            : std_logic;
    signal cu_dec_sp            : std_logic;
    signal cu_mem_addr_src      : std_logic;
    signal cu_mem_data_src      : std_logic_vector(1 downto 0);
    signal cu_mem_read          : std_logic;
    signal cu_mem_write         : std_logic;
    signal cu_mem_to_reg        : std_logic;
    signal cu_reg_to_reg        : std_logic;
    signal cu_output_enable     : std_logic;
    signal cu_input_enable      : std_logic;
    signal cu_clock_enable      : std_logic;
    signal cu_interrupt_enable  : std_logic;
    signal cu_rst               : std_logic;

    -- ── ID/EX1 register outputs ───────────────────────────────────────────
    signal idex_pc_out               : std_logic_vector(31 downto 0);
    signal idex_input_port_out       : std_logic_vector(31 downto 0);
    signal idex_readdata1_out        : std_logic_vector(31 downto 0);
    signal idex_readdata2_out        : std_logic_vector(31 downto 0);
    signal idex_immediate_out        : std_logic_vector(31 downto 0);
    signal idex_rs_out               : std_logic_vector(2 downto 0);
    signal idex_rt_out               : std_logic_vector(2 downto 0);
    signal idex_rd_out               : std_logic_vector(2 downto 0);
    signal idex_mem_or_branch_pc_out : std_logic;
    signal idex_inc_pc_out           : std_logic;
    signal idex_reg1_write_out       : std_logic;
    signal idex_reg2_write_out       : std_logic;
    signal idex_alu_src_out          : std_logic;
    signal idex_alu_op_out           : std_logic_vector(2 downto 0);
    signal idex_set_carry_out        : std_logic;
    signal idex_alu_passthrough_out  : std_logic;
    signal idex_flag_enable_out      : std_logic;
    signal idex_restore_ccr_out      : std_logic;
    signal idex_store_ccr_out        : std_logic;
    signal idex_branch_out           : std_logic;
    signal idex_branch_type_out      : std_logic_vector(1 downto 0);
    signal idex_inc_sp_out           : std_logic;
    signal idex_dec_sp_out           : std_logic;
    signal idex_mem_addr_src_out     : std_logic;
    signal idex_mem_data_src_out     : std_logic_vector(1 downto 0);
    signal idex_mem_read_out         : std_logic;
    signal idex_mem_write_out        : std_logic;
    signal idex_mem_to_reg_out       : std_logic;
    signal idex_reg_to_reg_out       : std_logic;
    signal idex_output_enable_out    : std_logic;
    signal idex_input_enable_out     : std_logic;
    signal idex_clock_enable_out     : std_logic;
    signal idex_interrupt_enable_out : std_logic;

    -- ── Execute_1 outputs ─────────────────────────────────────────────────
    signal ex1_alu_result : std_logic_vector(31 downto 0);
    signal ex1_zero       : std_logic;
    signal ex1_negative   : std_logic;
    signal ex1_carry      : std_logic;

    -- ── EX1/EX2 forwarding register outputs ──────────────────────────────
    signal ex1ex2_incremented_pc_out : std_logic_vector(31 downto 0);
    signal ex1ex2_pc_out             : std_logic_vector(31 downto 0);
    signal ex1ex2_in_port_out        : std_logic_vector(31 downto 0);
    signal ex1ex2_rdst_out           : std_logic_vector(2 downto 0);
    signal ex1ex2_rsrc1_out          : std_logic_vector(2 downto 0);
    signal ex1ex2_r_rsrc1_out        : std_logic_vector(31 downto 0);
    signal ex1ex2_r_rsrc2_out        : std_logic_vector(31 downto 0);
    signal ex1ex2_alu_result_out     : std_logic_vector(31 downto 0);
    signal ex1ex2_imm_out            : std_logic_vector(31 downto 0);
    signal ex1ex2_zero_out           : std_logic;
    signal ex1ex2_negative_out       : std_logic;
    signal ex1ex2_carry_out          : std_logic;
    signal ex1ex2_branch_type_out    : std_logic_vector(1 downto 0);
    signal ex1ex2_branch_out         : std_logic;
    signal ex1ex2_inc_sp_out         : std_logic;
    signal ex1ex2_dec_sp_out         : std_logic;
    signal ex1ex2_mem_add_src_out    : std_logic;
    signal ex1ex2_mem_data_src_out   : std_logic;
    signal ex1ex2_mem_read_out       : std_logic;
    signal ex1ex2_mem_write_out      : std_logic;
    signal ex1ex2_output_enable_out  : std_logic;
    signal ex1ex2_mem_to_reg_out     : std_logic;
    signal ex1ex2_reg_to_reg_out     : std_logic;
    signal ex1ex2_input_enable_out   : std_logic;

    -- ── Execute_2 outputs ─────────────────────────────────────────────────
    signal ex2_pc_src  : std_logic;
    signal ex2_address : std_logic_vector(31 downto 0);

    -- ── EX2/MEM forwarding register outputs ──────────────────────────────
    signal ex2mem_incremented_pc_out : std_logic_vector(31 downto 0);
    signal ex2mem_pc_out             : std_logic_vector(31 downto 0);
    signal ex2mem_in_port_out        : std_logic_vector(31 downto 0);
    signal ex2mem_r_rsrc1_out        : std_logic_vector(31 downto 0);
    signal ex2mem_r_rsrc2_out        : std_logic_vector(31 downto 0);
    signal ex2mem_alu_result_out     : std_logic_vector(31 downto 0);
    signal ex2mem_address_out        : std_logic_vector(31 downto 0);
    signal ex2mem_rdst_out           : std_logic_vector(2 downto 0);
    signal ex2mem_rsrc1_out          : std_logic_vector(2 downto 0);
    signal ex2mem_inc_sp_out         : std_logic;
    signal ex2mem_dec_sp_out         : std_logic;
    signal ex2mem_mem_add_src_out    : std_logic;
    signal ex2mem_mem_data_src_out   : std_logic;
    signal ex2mem_mem_read_out       : std_logic;
    signal ex2mem_mem_write_out      : std_logic;
    signal ex2mem_output_enable_out  : std_logic;
    signal ex2mem_mem_to_reg_out     : std_logic;
    signal ex2mem_reg_to_reg_out     : std_logic;
    signal ex2mem_input_enable_out   : std_logic;
    signal ex2mem_reg_write_out      : std_logic;
    signal ex2mem_reg2_write_out     : std_logic;

    -- ── Mem stage outputs ─────────────────────────────────────────────────
    signal mem_data_out_wire : std_logic_vector(31 downto 0);

    -- ── MEM/WB forwarding register outputs ───────────────────────────────
    signal memwb_incremented_pc_out : std_logic_vector(31 downto 0);
    signal memwb_in_port_out        : std_logic_vector(31 downto 0);
    signal memwb_r_rsrc1_out        : std_logic_vector(31 downto 0);
    signal memwb_r_rsrc2_out        : std_logic_vector(31 downto 0);
    signal memwb_alu_result_out     : std_logic_vector(31 downto 0);
    signal memwb_mem_data_out       : std_logic_vector(31 downto 0);
    signal memwb_rdst_out           : std_logic_vector(2 downto 0);
    signal memwb_rsrc1_out          : std_logic_vector(2 downto 0);
    signal memwb_output_enable_out  : std_logic;
    signal memwb_mem_to_reg_out     : std_logic;
    signal memwb_reg_to_reg_out     : std_logic;
    signal memwb_input_enable_out   : std_logic;
    signal memwb_reg_write_out      : std_logic;
    signal memwb_reg2_write_out     : std_logic;

    -- ── Writeback outputs ─────────────────────────────────────────────────
    signal wb_write_data_1 : std_logic_vector(31 downto 0);
    signal wb_write_addr_1 : std_logic_vector(2 downto 0);
    signal wb_write_en_1   : std_logic;
    signal wb_write_data_2 : std_logic_vector(31 downto 0);
    signal wb_write_addr_2 : std_logic_vector(2 downto 0);
    signal wb_write_en_2   : std_logic;
    signal wb_result       : std_logic_vector(31 downto 0);

    -- ── Hazard unit outputs ───────────────────────────────────────────────
    signal hz_rst_if_id      : std_logic;
    signal hz_rst_id_ex1     : std_logic;
    signal hz_rst_ex1_ex2    : std_logic;
    signal hz_rst_ex2_mem    : std_logic;
    signal hz_rst_mem_wb     : std_logic;
    signal hz_enable_if_id   : std_logic;
    signal hz_enable_id_ex1  : std_logic;
    signal hz_enable_ex1_ex2 : std_logic;
    signal hz_enable_ex2_mem : std_logic;
    signal hz_enable_mem_wb  : std_logic;
    signal hz_pc_enable      : std_logic;

    -- ── Forwarding unit outputs ───────────────────────────────────────────
    signal fwd_forward_a : std_logic_vector(1 downto 0);
    signal fwd_forward_b : std_logic_vector(1 downto 0);

    -- ── Derived helper signals ────────────────────────────────────────────
    signal global_rst       : std_logic;
    signal id_ex1_rst_sig   : std_logic;
    signal call_sig         : std_logic;
    signal int_sig          : std_logic;
    signal index_sig        : std_logic;
    -- RET/RTI: inc_sp=1, mem_read=1, mem_to_reg=0 (no reg writeback for RET/RTI)
    signal fetch_pc_src_q   : std_logic;

begin

    -- ── Derived signals ───────────────────────────────────────────────────

    -- software RESET instruction triggers same global reset as hardware reset
    global_rst <= rst or cu_rst;

    -- flush signals for pipeline registers that only have rst (no flush port)
    id_ex1_rst_sig <= global_rst or hz_rst_id_ex1;

    -- CALL: branch instruction that also decrements SP (distinguishes from JMP)
    call_sig  <= idex_mem_or_branch_pc_out and idex_dec_sp_out;

    -- INT instruction enable
    int_sig   <= idex_interrupt_enable_out;

    -- interrupt index bit from instruction Rdst field
    index_sig <= idex_rd_out(0);

    -- RET/RTI: memory read with SP increment but no register write (vs POP)
    fetch_pc_src_q <= ex2mem_inc_sp_out and ex2mem_mem_read_out and (not ex2mem_mem_to_reg_out);

    --── Component instantiations ──────────────────────────────────────────

    U_MEMORY: reg_file_memory
        generic map(N => 32, M => 1024)
        port map(
            clk                 => clk,
            rst                 => global_rst,
            address             => mem_address_wire,
            instruction_address => fetch_pc_out,
            mem_write           => mem_we_wire,
            mem_read            => mem_re_wire,
            writedata           => mem_writedata_wire,
            mem_output          => mem_output_sig,
            memory_busy         => memory_busy_sig,
            mem1                => mem1_sig,
            mem2                => mem2_sig,
            mem3                => mem3_sig,
            mem4                => mem4_sig
        );

    U_FETCH: fetch
        port map(
            input_port        => input_port,
            clk               => clk,
            reset             => global_rst,
            interrupt         => interrupt,
            pc_plus_immediate => ex2_address,
            do_branch         => ex2_pc_src,
            pc_enable         => hz_pc_enable,
            instruction_d     => fetch_instruction_d,
            pc_d              => fetch_pc_d,
            inputport_d_if_id => fetch_inputport_d,
            instruction_in    => mem_output_sig,
            memory_busy       => memory_busy_sig,
            pc_out            => fetch_pc_out,
            mem1              => mem1_sig,
            mem2              => mem2_sig,
            mem3              => mem3_sig,
            mem4              => mem4_sig,
            pc_src_q          => fetch_pc_src_q,
            call_signal       => call_sig,
            immediate_input   => idex_immediate_out,
            int_signal        => int_sig,
            index             => index_sig
        );

    U_FD_REG: f_d_reg
        port map(
            clk           => clk,
            rst           => global_rst,
            flush         => hz_rst_if_id,
            enable        => hz_enable_if_id,
            instruction_d => fetch_instruction_d,
            instruction_q => fd_instruction_q,
            pc_d          => fetch_pc_d,
            pc_q          => fd_pc_q,
            inputport_d   => fetch_inputport_d,
            inputport_q   => fd_inputport_q
        );

    U_DECODE: decode
        port map(
            clk              => clk,
            rst              => global_rst,
            instruction_in   => fd_instruction_q,
            pc_in            => fd_pc_q,
            pc_out           => dec_pc_out,
            input_port_in    => fd_inputport_q,
            input_port_out   => dec_input_port_out,
            mem_wb_regwrite1 => wb_write_en_1,
            mem_wb_regwrite2 => wb_write_en_2,
            mem_wb_waddr1    => wb_write_addr_1,
            mem_wb_waddr2    => wb_write_addr_2,
            mem_wb_wdata1    => wb_write_data_1,
            mem_wb_wdata2    => wb_write_data_2,
            rs_out           => dec_rs_out,
            rt_out           => dec_rt_out,
            rd_out           => dec_rd_out,
            readdata1        => dec_readdata1,
            readdata2        => dec_readdata2,
            immediate_out    => dec_immediate_out,
            opcode_out       => dec_opcode_out
        );

    U_CTRL: control_unit
        port map(
            opcode           => dec_opcode_out,
            mem_or_branch_pc => cu_mem_or_branch_pc,
            inc_pc           => cu_inc_pc,
            reg1_write       => cu_reg1_write,
            reg2_write       => cu_reg2_write,
            alu_src          => cu_alu_src,
            alu_op           => cu_alu_op,
            set_carry        => cu_set_carry,
            alu_passthrough  => cu_alu_passthrough,
            flag_enable      => cu_flag_enable,
            restore_ccr      => cu_restore_ccr,
            store_ccr        => cu_store_ccr,
            branch           => cu_branch,
            branch_type      => cu_branch_type,
            inc_sp           => cu_inc_sp,
            dec_sp           => cu_dec_sp,
            mem_addr_src     => cu_mem_addr_src,
            mem_data_src     => cu_mem_data_src,
            mem_read         => cu_mem_read,
            mem_write        => cu_mem_write,
            mem_to_reg       => cu_mem_to_reg,
            reg_to_reg       => cu_reg_to_reg,
            output_enable    => cu_output_enable,
            input_enable     => cu_input_enable,
            clock_enable     => cu_clock_enable,
            interrupt_enable => cu_interrupt_enable,
            rst              => cu_rst
        );

    U_IDEX_REG: id_ex_reg
        port map(
            clk                 => clk,
            rst                 => id_ex1_rst_sig,
            clk_enable          => hz_enable_id_ex1,
            pc_in               => dec_pc_out,
            input_port_in       => dec_input_port_out,
            readdata1_in        => dec_readdata1,
            readdata2_in        => dec_readdata2,
            immediate_in        => dec_immediate_out,
            rs_in               => dec_rs_out,
            rt_in               => dec_rt_out,
            rd_in               => dec_rd_out,
            mem_or_branch_pc_in => cu_mem_or_branch_pc,
            inc_pc_in           => cu_inc_pc,
            reg1_write_in       => cu_reg1_write,
            reg2_write_in       => cu_reg2_write,
            alu_src_in          => cu_alu_src,
            alu_op_in           => cu_alu_op,
            set_carry_in        => cu_set_carry,
            alu_passthrough_in  => cu_alu_passthrough,
            flag_enable_in      => cu_flag_enable,
            restore_ccr_in      => cu_restore_ccr,
            store_ccr_in        => cu_store_ccr,
            branch_in           => cu_branch,
            branch_type_in      => cu_branch_type,
            inc_sp_in           => cu_inc_sp,
            dec_sp_in           => cu_dec_sp,
            mem_addr_src_in     => cu_mem_addr_src,
            mem_data_src_in     => cu_mem_data_src,
            mem_read_in         => cu_mem_read,
            mem_write_in        => cu_mem_write,
            mem_to_reg_in       => cu_mem_to_reg,
            reg_to_reg_in       => cu_reg_to_reg,
            output_enable_in    => cu_output_enable,
            input_enable_in     => cu_input_enable,
            clock_enable_in     => cu_clock_enable,
            interrupt_enable_in => cu_interrupt_enable,
            pc_out               => idex_pc_out,
            input_port_out       => idex_input_port_out,
            readdata1_out        => idex_readdata1_out,
            readdata2_out        => idex_readdata2_out,
            immediate_out        => idex_immediate_out,
            rs_out               => idex_rs_out,
            rt_out               => idex_rt_out,
            rd_out               => idex_rd_out,
            mem_or_branch_pc_out => idex_mem_or_branch_pc_out,
            inc_pc_out           => idex_inc_pc_out,
            reg1_write_out       => idex_reg1_write_out,
            reg2_write_out       => idex_reg2_write_out,
            alu_src_out          => idex_alu_src_out,
            alu_op_out           => idex_alu_op_out,
            set_carry_out        => idex_set_carry_out,
            alu_passthrough_out  => idex_alu_passthrough_out,
            flag_enable_out      => idex_flag_enable_out,
            restore_ccr_out      => idex_restore_ccr_out,
            store_ccr_out        => idex_store_ccr_out,
            branch_out           => idex_branch_out,
            branch_type_out      => idex_branch_type_out,
            inc_sp_out           => idex_inc_sp_out,
            dec_sp_out           => idex_dec_sp_out,
            mem_addr_src_out     => idex_mem_addr_src_out,
            mem_data_src_out     => idex_mem_data_src_out,
            mem_read_out         => idex_mem_read_out,
            mem_write_out        => idex_mem_write_out,
            mem_to_reg_out       => idex_mem_to_reg_out,
            reg_to_reg_out       => idex_reg_to_reg_out,
            output_enable_out    => idex_output_enable_out,
            input_enable_out     => idex_input_enable_out,
            clock_enable_out     => idex_clock_enable_out,
            interrupt_enable_out => idex_interrupt_enable_out
        );

    U_EX1: execute_1
        generic map(n => 32)
        port map(
            clk             => clk,
            rst             => global_rst,
            clk_enable      => idex_clock_enable_out,
            r_rs1           => idex_readdata1_out,
            r_rs2           => idex_readdata2_out,
            imm             => idex_immediate_out,
            alu_result      => ex1_alu_result,
            ex1_ex2_result  => ex1ex2_alu_result_out,
            ex2_mem_result  => ex2mem_alu_result_out,
            mem_wb_result   => wb_result,
            forward_a       => fwd_forward_a,
            forward_b       => fwd_forward_b,
            zero            => ex1_zero,
            negative        => ex1_negative,
            carry           => ex1_carry,
            alu_src         => idex_alu_src_out,
            alu_operation   => idex_alu_op_out,
            set_carry       => idex_set_carry_out,
            alu_passthrough => idex_alu_passthrough_out,
            store_ccr       => idex_store_ccr_out,
            flag_enable     => idex_flag_enable_out,
            restore_ccr     => idex_restore_ccr_out
        );

    U_EX1EX2_REG: ex1_ex2_forwarding
        generic map(n => 32)
        port map(
            clk               => clk,
            rst               => global_rst,
            clk_en            => hz_enable_ex1_ex2,
            flush             => hz_rst_ex1_ex2,
            zero_in           => ex1_zero,
            negative_in       => ex1_negative,
            carry             => ex1_carry,
            zero_out          => ex1ex2_zero_out,
            negative_out      => ex1ex2_negative_out,
            carry_out         => ex1ex2_carry_out,
            incremented_pc_in => idex_pc_out,
            pc_in             => idex_pc_out,
            in_port_in        => idex_input_port_out,
            rdst_in           => idex_rd_out,
            rsrc1_in          => idex_rs_out,
            r_rsrc1_in        => idex_readdata1_out,
            r_rsrc2_in        => idex_readdata2_out,
            alu_result_in     => ex1_alu_result,
            imm_in            => idex_immediate_out,
            branch_type_in    => idex_branch_type_out,
            branch_in         => idex_branch_out,
            inc_sp_in         => idex_inc_sp_out,
            dec_sp_in         => idex_dec_sp_out,
            mem_add_src_in    => idex_mem_addr_src_out,
            mem_data_src_in   => idex_mem_data_src_out(0),
            mem_read_in       => idex_mem_read_out,
            mem_write_in      => idex_mem_write_out,
            output_enable_in  => idex_output_enable_out,
            mem_to_reg_in     => idex_mem_to_reg_out,
            reg_to_reg_in     => idex_reg_to_reg_out,
            input_enable_in   => idex_input_enable_out,
            incremented_pc_out=> ex1ex2_incremented_pc_out,
            pc_out            => ex1ex2_pc_out,
            in_port_out       => ex1ex2_in_port_out,
            rdst_out          => ex1ex2_rdst_out,
            rsrc1_out         => ex1ex2_rsrc1_out,
            r_rsrc1_out       => ex1ex2_r_rsrc1_out,
            r_rsrc2_out       => ex1ex2_r_rsrc2_out,
            alu_result_out    => ex1ex2_alu_result_out,
            imm_out           => ex1ex2_imm_out,
            branch_type_out   => ex1ex2_branch_type_out,
            branch_out        => ex1ex2_branch_out,
            inc_sp_out        => ex1ex2_inc_sp_out,
            dec_sp_out        => ex1ex2_dec_sp_out,
            mem_add_src_out   => ex1ex2_mem_add_src_out,
            mem_data_src_out  => ex1ex2_mem_data_src_out,
            mem_read_out      => ex1ex2_mem_read_out,
            mem_write_out     => ex1ex2_mem_write_out,
            output_enable_out => ex1ex2_output_enable_out,
            mem_to_reg_out    => ex1ex2_mem_to_reg_out,
            reg_to_reg_out    => ex1ex2_reg_to_reg_out,
            input_enable_out  => ex1ex2_input_enable_out
        );

    U_EX2: execute_2
        generic map(n => 32)
        port map(
            rst         => global_rst,
            clk         => clk,
            clk_en      => hz_enable_ex1_ex2,
            rsrc        => ex1ex2_alu_result_out,
            imm_val     => ex1ex2_imm_out,
            branch_type => ex1ex2_branch_type_out,
            branch      => ex1ex2_branch_out,
            Z           => ex1ex2_zero_out,
            C           => ex1ex2_carry_out,
            Neg         => ex1ex2_negative_out,
            pc_src      => ex2_pc_src,
            address     => ex2_address
        );

    U_EX2MEM_REG: ex2_mem_forwarding
        generic map(n => 32)
        port map(
            clk               => clk,
            rst               => global_rst,
            clk_en            => hz_enable_ex2_mem,
            flush             => hz_rst_ex2_mem,
            incremented_pc_in => ex1ex2_incremented_pc_out,
            pc_in             => ex1ex2_pc_out,
            in_port_in        => ex1ex2_in_port_out,
            r_rsrc1_in        => ex1ex2_r_rsrc1_out,
            r_rsrc2_in        => ex1ex2_r_rsrc2_out,
            alu_result_in     => ex1ex2_alu_result_out,
            address_in        => ex2_address,
            rdst_in           => ex1ex2_rdst_out,
            rsrc1_in          => ex1ex2_rsrc1_out,
            inc_sp_in         => ex1ex2_inc_sp_out,
            dec_sp_in         => ex1ex2_dec_sp_out,
            mem_add_src_in    => ex1ex2_mem_add_src_out,
            mem_data_src_in   => ex1ex2_mem_data_src_out,
            mem_read_in       => ex1ex2_mem_read_out,
            mem_write_in      => ex1ex2_mem_write_out,
            output_enable_in  => ex1ex2_output_enable_out,
            mem_to_reg_in     => ex1ex2_mem_to_reg_out,
            reg_to_reg_in     => ex1ex2_reg_to_reg_out,
            input_enable_in   => ex1ex2_input_enable_out,
            -- reg_write not carried by ex1_ex2_forwarding; use idex value (1-cycle approx)
            reg_write_in      => idex_reg1_write_out,
            reg2_write_in     => idex_reg2_write_out,
            incremented_pc_out=> ex2mem_incremented_pc_out,
            pc_out            => ex2mem_pc_out,
            in_port_out       => ex2mem_in_port_out,
            r_rsrc1_out       => ex2mem_r_rsrc1_out,
            r_rsrc2_out       => ex2mem_r_rsrc2_out,
            alu_result_out    => ex2mem_alu_result_out,
            address_out       => ex2mem_address_out,
            rdst_out          => ex2mem_rdst_out,
            rsrc1_out         => ex2mem_rsrc1_out,
            inc_sp_out        => ex2mem_inc_sp_out,
            dec_sp_out        => ex2mem_dec_sp_out,
            mem_add_src_out   => ex2mem_mem_add_src_out,
            mem_data_src_out  => ex2mem_mem_data_src_out,
            mem_read_out      => ex2mem_mem_read_out,
            mem_write_out     => ex2mem_mem_write_out,
            output_enable_out => ex2mem_output_enable_out,
            mem_to_reg_out    => ex2mem_mem_to_reg_out,
            reg_to_reg_out    => ex2mem_reg_to_reg_out,
            input_enable_out  => ex2mem_input_enable_out,
            reg_write_out     => ex2mem_reg_write_out,
            reg2_write_out    => ex2mem_reg2_write_out
        );

    U_MEM_STAGE: mem_stage
        generic map(n => 32)
        port map(
            clk               => clk,
            rst               => global_rst,
            clk_enable        => hz_enable_ex2_mem,
            address_in        => ex2mem_address_out,
            r_rsrc1_in        => ex2mem_r_rsrc1_out,
            r_rsrc2_in        => ex2mem_r_rsrc2_out,
            incremented_pc_in => ex2mem_incremented_pc_out,
            inc_sp            => ex2mem_inc_sp_out,
            dec_sp            => ex2mem_dec_sp_out,
            mem_add_src       => ex2mem_mem_add_src_out,
            mem_data_src      => ex2mem_mem_data_src_out,
            mem_read          => ex2mem_mem_read_out,
            mem_write         => ex2mem_mem_write_out,
            mem_address_out   => mem_address_wire,
            writedata_out     => mem_writedata_wire,
            mem_read_out      => mem_re_wire,
            mem_write_out     => mem_we_wire,
            mem_data_in       => mem_output_sig,
            mem_data_out      => mem_data_out_wire,
            sp_out            => open
        );

    U_MEMWB_REG: mem_wb_forwarding
        generic map(n => 32)
        port map(
            clk               => clk,
            rst               => global_rst,
            clk_en            => hz_enable_mem_wb,
            incremented_pc_in => ex2mem_incremented_pc_out,
            in_port_in        => ex2mem_in_port_out,
            r_rsrc1_in        => ex2mem_r_rsrc1_out,
            r_rsrc2_in        => ex2mem_r_rsrc2_out,
            alu_result_in     => ex2mem_alu_result_out,
            mem_data_in       => mem_data_out_wire,
            rdst_in           => ex2mem_rdst_out,
            rsrc1_in          => ex2mem_rsrc1_out,
            output_enable_in  => ex2mem_output_enable_out,
            mem_to_reg_in     => ex2mem_mem_to_reg_out,
            reg_to_reg_in     => ex2mem_reg_to_reg_out,
            input_enable_in   => ex2mem_input_enable_out,
            reg_write_in      => ex2mem_reg_write_out,
            reg2_write_in     => ex2mem_reg2_write_out,
            incremented_pc_out=> memwb_incremented_pc_out,
            in_port_out       => memwb_in_port_out,
            r_rsrc1_out       => memwb_r_rsrc1_out,
            r_rsrc2_out       => memwb_r_rsrc2_out,
            alu_result_out    => memwb_alu_result_out,
            mem_data_out      => memwb_mem_data_out,
            rdst_out          => memwb_rdst_out,
            rsrc1_out         => memwb_rsrc1_out,
            output_enable_out => memwb_output_enable_out,
            mem_to_reg_out    => memwb_mem_to_reg_out,
            reg_to_reg_out    => memwb_reg_to_reg_out,
            input_enable_out  => memwb_input_enable_out,
            reg_write_out     => memwb_reg_write_out,
            reg2_write_out    => memwb_reg2_write_out
        );

    U_WB: writeback
        generic map(n => 32)
        port map(
            alu_result    => memwb_alu_result_out,
            mem_data      => memwb_mem_data_out,
            in_port       => memwb_in_port_out,
            r_rsrc1       => memwb_r_rsrc1_out,
            r_rsrc2       => memwb_r_rsrc2_out,
            rdst          => memwb_rdst_out,
            rsrc1         => memwb_rsrc1_out,
            output_enable => memwb_output_enable_out,
            input_enable  => memwb_input_enable_out,
            mem_to_reg    => memwb_mem_to_reg_out,
            reg_to_reg    => memwb_reg_to_reg_out,
            reg_write     => memwb_reg_write_out,
            reg2_write    => memwb_reg2_write_out,
            out_port      => output_port,
            write_data_1  => wb_write_data_1,
            write_addr_1  => wb_write_addr_1,
            write_en_1    => wb_write_en_1,
            write_data_2  => wb_write_data_2,
            write_addr_2  => wb_write_addr_2,
            write_en_2    => wb_write_en_2,
            wb_result     => wb_result
        );

    U_HAZARD: hazard_unit
        port map(
            reset            => global_rst,
            id_ex1_mem_read  => idex_mem_read_out,
            id_ex1_mem_write => idex_mem_write_out,
            memread_q        => ex2mem_mem_read_out,
            memwrite_q       => ex2mem_mem_write_out,
            do_branch        => ex2_pc_src,
            call_signal      => call_sig,
            int_signal       => int_sig,
            rst_if_id        => hz_rst_if_id,
            rst_id_ex1       => hz_rst_id_ex1,
            rst_ex1_ex2      => hz_rst_ex1_ex2,
            rst_ex2_mem      => hz_rst_ex2_mem,
            rst_mem_wb       => hz_rst_mem_wb,
            enable_if_id     => hz_enable_if_id,
            enable_id_ex1    => hz_enable_id_ex1,
            enable_ex1_ex2   => hz_enable_ex1_ex2,
            enable_ex2_mem   => hz_enable_ex2_mem,
            enable_mem_wb    => hz_enable_mem_wb,
            pc_enable        => hz_pc_enable
        );

    U_FWD: forwarding_unit
        port map(
            mem_wb_regwrite  => memwb_reg_write_out,
            -- ex1_ex2_forwarding does not carry reg_write; use idex value (1-cycle approx)
            ex1_ex2_regwrite => idex_reg1_write_out,
            ex2_mem_regwrite => ex2mem_reg_write_out,
            mem_wb_rdst      => memwb_rdst_out,
            id_ex1_rs1       => idex_rs_out,
            id_ex1_rs2       => idex_rt_out,
            ex1_ex2_rdst     => ex1ex2_rdst_out,
            ex2_mem_rdst     => ex2mem_rdst_out,
            forward_a        => fwd_forward_a,
            forward_b        => fwd_forward_b
        );

end structural;
