library ieee;
use ieee.std_logic_1164.all;

entity id_ex_reg is
    port(
        clk, rst    : in std_logic;
        clk_enable  : in std_logic;

        -- ── INPUTS ───────────────────────────────────────────────

        -- pass-throughs
        pc_in          : in std_logic_vector(31 downto 0);
        input_port_in  : in std_logic_vector(31 downto 0);

        -- register file read data
        readdata1_in   : in std_logic_vector(31 downto 0);
        readdata2_in   : in std_logic_vector(31 downto 0);

        -- immediate
        immediate_in   : in std_logic_vector(31 downto 0);

        -- instruction fields (for forwarding unit)
        rs_in          : in std_logic_vector(2 downto 0);
        rt_in          : in std_logic_vector(2 downto 0);
        rd_in          : in std_logic_vector(2 downto 0);

        -- control signals (PC)
        mem_or_branch_pc_in : in std_logic;
        inc_pc_in           : in std_logic;

        -- control signals (register write)
        reg1_write_in  : in std_logic;
        reg2_write_in  : in std_logic;

        -- control signals (EX1)
        alu_src_in         : in std_logic;
        alu_op_in          : in std_logic_vector(2 downto 0);
        set_carry_in       : in std_logic;
        alu_passthrough_in : in std_logic;
        flag_enable_in     : in std_logic;
        restore_ccr_in     : in std_logic;
        store_ccr_in       : in std_logic;

        -- control signals (EX2 branch)
        branch_in      : in std_logic;
        branch_type_in : in std_logic_vector(1 downto 0);

        -- control signals (stack)
        inc_sp_in      : in std_logic;
        dec_sp_in      : in std_logic;

        -- control signals (memory)
        mem_addr_src_in : in std_logic;
        mem_data_src_in : in std_logic_vector(1 downto 0);
        mem_read_in     : in std_logic;
        mem_write_in    : in std_logic;

        -- control signals (WB)
        mem_to_reg_in  : in std_logic;
        reg_to_reg_in  : in std_logic;

        -- control signals (misc)
        output_enable_in    : in std_logic;
        input_enable_in     : in std_logic;
        clock_enable_in     : in std_logic;
        interrupt_enable_in : in std_logic;

        -- ── OUTPUTS ──────────────────────────────────────────────

        -- pass-throughs
        pc_out          : out std_logic_vector(31 downto 0);
        input_port_out  : out std_logic_vector(31 downto 0);

        -- register file read data
        readdata1_out   : out std_logic_vector(31 downto 0); --r[rsrc1]
        readdata2_out   : out std_logic_vector(31 downto 0); --r[rsrc2]

        -- immediate
        immediate_out   : out std_logic_vector(31 downto 0);

        -- instruction fields (for forwarding unit)
        rs_out          : out std_logic_vector(2 downto 0);
        rt_out          : out std_logic_vector(2 downto 0);
        rd_out          : out std_logic_vector(2 downto 0);

        -- control signals (PC)
        mem_or_branch_pc_out : out std_logic;
        inc_pc_out           : out std_logic;

        -- control signals (register write)
        reg1_write_out : out std_logic;
        reg2_write_out : out std_logic;

        -- control signals (EX1)
        alu_src_out         : out std_logic;
        alu_op_out          : out std_logic_vector(2 downto 0);
        set_carry_out       : out std_logic;
        alu_passthrough_out : out std_logic;
        flag_enable_out     : out std_logic;
        restore_ccr_out     : out std_logic;
        store_ccr_out       : out std_logic;

        -- control signals (EX2 branch)
        branch_out      : out std_logic;
        branch_type_out : out std_logic_vector(1 downto 0);

        -- control signals (stack)
        inc_sp_out      : out std_logic;
        dec_sp_out      : out std_logic;

        -- control signals (memory)
        mem_addr_src_out : out std_logic;
        mem_data_src_out : out std_logic_vector(1 downto 0);
        mem_read_out     : out std_logic;
        mem_write_out    : out std_logic;

        -- control signals (WB)
        mem_to_reg_out  : out std_logic;
        reg_to_reg_out  : out std_logic;

        -- control signals (misc)
        output_enable_out    : out std_logic;
        input_enable_out     : out std_logic;
        clock_enable_out     : out std_logic;
        interrupt_enable_out : out std_logic
    );
end id_ex_reg;

architecture behavioral of id_ex_reg is
begin

    process(clk, rst)
    begin
        if rst = '1' then
            -- pass-throughs
            pc_out              <= (others => '0');
            input_port_out      <= (others => '0');
            -- data
            readdata1_out       <= (others => '0');
            readdata2_out       <= (others => '0');
            immediate_out       <= (others => '0');
            -- fields
            rs_out              <= (others => '0');
            rt_out              <= (others => '0');
            rd_out              <= (others => '0');
            -- control (PC)
            mem_or_branch_pc_out <= '0';
            inc_pc_out           <= '0';
            -- control (reg write)
            reg1_write_out      <= '0';
            reg2_write_out      <= '0';
            -- control (EX1)
            alu_src_out         <= '0';
            alu_op_out          <= (others => '0');
            set_carry_out       <= '0';
            alu_passthrough_out <= '0';
            flag_enable_out     <= '0';
            restore_ccr_out     <= '0';
            store_ccr_out       <= '0';
            -- control (branch)
            branch_out          <= '0';
            branch_type_out     <= (others => '0');
            -- control (stack)
            inc_sp_out          <= '0';
            dec_sp_out          <= '0';
            -- control (memory)
            mem_addr_src_out    <= '0';
            mem_data_src_out    <= (others => '0');
            mem_read_out        <= '0';
            mem_write_out       <= '0';
            -- control (WB)
            mem_to_reg_out      <= '0';
            reg_to_reg_out      <= '0';
            -- control (misc)
            output_enable_out    <= '0';
            input_enable_out     <= '0';
            clock_enable_out     <= '1';
            interrupt_enable_out <= '0';

        elsif rising_edge(clk) then
          if clk_enable = '1' then
            -- pass-throughs
            pc_out              <= pc_in;
            input_port_out      <= input_port_in;
            -- data
            readdata1_out       <= readdata1_in;
            readdata2_out       <= readdata2_in;
            immediate_out       <= immediate_in;
            -- fields
            rs_out              <= rs_in;
            rt_out              <= rt_in;
            rd_out              <= rd_in;
            -- control (PC)
            mem_or_branch_pc_out <= mem_or_branch_pc_in;
            inc_pc_out           <= inc_pc_in;
            -- control (reg write)
            reg1_write_out      <= reg1_write_in;
            reg2_write_out      <= reg2_write_in;
            -- control (EX1)
            alu_src_out         <= alu_src_in;
            alu_op_out          <= alu_op_in;
            set_carry_out       <= set_carry_in;
            alu_passthrough_out <= alu_passthrough_in;
            flag_enable_out     <= flag_enable_in;
            restore_ccr_out     <= restore_ccr_in;
            store_ccr_out       <= store_ccr_in;
            -- control (branch)
            branch_out          <= branch_in;
            branch_type_out     <= branch_type_in;
            -- control (stack)
            inc_sp_out          <= inc_sp_in;
            dec_sp_out          <= dec_sp_in;
            -- control (memory)
            mem_addr_src_out    <= mem_addr_src_in;
            mem_data_src_out    <= mem_data_src_in;
            mem_read_out        <= mem_read_in;
            mem_write_out       <= mem_write_in;
            -- control (WB)
            mem_to_reg_out      <= mem_to_reg_in;
            reg_to_reg_out      <= reg_to_reg_in;
            -- control (misc)
            output_enable_out    <= output_enable_in;
            input_enable_out     <= input_enable_in;
            clock_enable_out     <= clock_enable_in;
            interrupt_enable_out <= interrupt_enable_in;
          end if;
        end if;
    end process;

end behavioral;