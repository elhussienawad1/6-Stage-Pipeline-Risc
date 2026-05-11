library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity execute_2_tb is
end execute_2_tb;

architecture tb of execute_2_tb is

    constant CLK_PERIOD : time := 10 ns;

    function to_hstring(slv : std_logic_vector) return string is
        constant HEX    : string(1 to 16) := "0123456789ABCDEF";
        variable result : string(1 to slv'length / 4);
        variable nibble : std_logic_vector(3 downto 0);
    begin
        for i in 0 to slv'length / 4 - 1 loop
            nibble := slv(slv'length - 1 - i*4 downto slv'length - 4 - i*4);
            result(i + 1) := HEX(to_integer(unsigned(nibble)) + 1);
        end loop;
        return result;
    end function;

    -- =========================================================
    -- Signals
    -- =========================================================

    signal clk, rst : std_logic := '0';
    signal clk_enable : std_logic := '1';

    -- execute_2 inputs
    signal ex2_clk_en      : std_logic := '1';
    signal ex2_rsrc        : std_logic_vector(31 downto 0) := (others => '0');
    signal ex2_imm_val     : std_logic_vector(31 downto 0) := (others => '0');
    signal ex2_branch_type : std_logic_vector(1 downto 0)  := "00";
    signal ex2_branch      : std_logic := '0';
    signal ex2_Z           : std_logic := '0';
    signal ex2_C           : std_logic := '0';
    signal ex2_Neg         : std_logic := '0';
    -- execute_2 outputs
    signal ex2_pc_src      : std_logic;
    signal ex2_address     : std_logic_vector(31 downto 0);

    -- ex2_mem_forwarding inputs (driven directly in tests, independent of execute_2)
    signal fwd1_clk_en            : std_logic := '1';
    signal fwd1_flush             : std_logic := '0';
    signal fwd1_incremented_pc_in : std_logic_vector(31 downto 0) := (others => '0');
    signal fwd1_pc_in             : std_logic_vector(31 downto 0) := (others => '0');
    signal fwd1_in_port_in        : std_logic_vector(31 downto 0) := (others => '0');
    signal fwd1_r_rsrc1_in        : std_logic_vector(31 downto 0) := (others => '0');
    signal fwd1_r_rsrc2_in        : std_logic_vector(31 downto 0) := (others => '0');
    signal fwd1_alu_result_in     : std_logic_vector(31 downto 0) := (others => '0');
    signal fwd1_address_in        : std_logic_vector(31 downto 0) := (others => '0');
    signal fwd1_rdst_in           : std_logic_vector(2 downto 0)  := (others => '0');
    signal fwd1_rsrc1_in          : std_logic_vector(2 downto 0)  := (others => '0');
    signal fwd1_inc_sp_in         : std_logic := '0';
    signal fwd1_dec_sp_in         : std_logic := '0';
    signal fwd1_mem_add_src_in    : std_logic := '0';
    signal fwd1_mem_data_src_in   : std_logic := '0';
    signal fwd1_mem_read_in       : std_logic := '0';
    signal fwd1_mem_write_in      : std_logic := '0';
    signal fwd1_output_enable_in  : std_logic := '0';
    signal fwd1_mem_to_reg_in     : std_logic := '0';
    signal fwd1_reg_to_reg_in     : std_logic := '0';
    signal fwd1_input_enable_in   : std_logic := '0';
    signal fwd1_reg_write_in      : std_logic := '0';
    signal fwd1_reg2_write_in     : std_logic := '0';
    -- ex2_mem_forwarding outputs (wires into mem_stage)
    signal fwd1_incremented_pc_out : std_logic_vector(31 downto 0);
    signal fwd1_pc_out             : std_logic_vector(31 downto 0);
    signal fwd1_in_port_out        : std_logic_vector(31 downto 0);
    signal fwd1_r_rsrc1_out        : std_logic_vector(31 downto 0);
    signal fwd1_r_rsrc2_out        : std_logic_vector(31 downto 0);
    signal fwd1_alu_result_out     : std_logic_vector(31 downto 0);
    signal fwd1_address_out        : std_logic_vector(31 downto 0);
    signal fwd1_rdst_out           : std_logic_vector(2 downto 0);
    signal fwd1_rsrc1_out          : std_logic_vector(2 downto 0);
    signal fwd1_inc_sp_out         : std_logic;
    signal fwd1_dec_sp_out         : std_logic;
    signal fwd1_mem_add_src_out    : std_logic;
    signal fwd1_mem_data_src_out   : std_logic;
    signal fwd1_mem_read_out       : std_logic;
    signal fwd1_mem_write_out      : std_logic;
    signal fwd1_output_enable_out  : std_logic;
    signal fwd1_mem_to_reg_out     : std_logic;
    signal fwd1_reg_to_reg_out     : std_logic;
    signal fwd1_input_enable_out   : std_logic;
    signal fwd1_reg_write_out      : std_logic;
    signal fwd1_reg2_write_out     : std_logic;

    -- mem_stage top-level memory interface
    signal mem_address    : std_logic_vector(31 downto 0);
    signal writedata      : std_logic_vector(31 downto 0);
    signal mem_read_sig   : std_logic;
    signal mem_write_sig  : std_logic;
    signal tb_mem_data    : std_logic_vector(31 downto 0) := (others => '0');
    -- mem_stage outputs
    signal mem_data_out   : std_logic_vector(31 downto 0);
    signal sp_out         : std_logic_vector(31 downto 0);

    -- mem_wb_forwarding inputs (wired from ex2_mem_forwarding + mem_stage)
    signal fwd2_clk_en : std_logic := '1';

    -- mem_wb_forwarding outputs (wired into writeback)
    signal fwd2_incremented_pc_out : std_logic_vector(31 downto 0);
    signal fwd2_in_port_out        : std_logic_vector(31 downto 0);
    signal fwd2_r_rsrc1_out        : std_logic_vector(31 downto 0);
    signal fwd2_r_rsrc2_out        : std_logic_vector(31 downto 0);
    signal fwd2_alu_result_out     : std_logic_vector(31 downto 0);
    signal fwd2_mem_data_out       : std_logic_vector(31 downto 0);
    signal fwd2_rdst_out           : std_logic_vector(2 downto 0);
    signal fwd2_rsrc1_out          : std_logic_vector(2 downto 0);
    signal fwd2_output_enable_out  : std_logic;
    signal fwd2_mem_to_reg_out     : std_logic;
    signal fwd2_reg_to_reg_out     : std_logic;
    signal fwd2_input_enable_out   : std_logic;
    signal fwd2_reg_write_out      : std_logic;
    signal fwd2_reg2_write_out     : std_logic;

    -- writeback outputs
    signal wb_out_port    : std_logic_vector(31 downto 0);
    signal wb_write_data1 : std_logic_vector(31 downto 0);
    signal wb_write_addr1 : std_logic_vector(2 downto 0);
    signal wb_write_en1   : std_logic;
    signal wb_write_data2 : std_logic_vector(31 downto 0);
    signal wb_write_addr2 : std_logic_vector(2 downto 0);
    signal wb_write_en2   : std_logic;
    signal wb_result      : std_logic_vector(31 downto 0);

begin

    -- =========================================================
    -- Instantiations
    -- =========================================================

    uut_ex2: entity work.execute_2 port map(
        rst         => rst,
        clk         => clk,
        clk_en      => ex2_clk_en,
        rsrc        => ex2_rsrc,
        imm_val     => ex2_imm_val,
        branch_type => ex2_branch_type,
        branch      => ex2_branch,
        Z           => ex2_Z,
        C           => ex2_C,
        Neg         => ex2_Neg,
        pc_src      => ex2_pc_src,
        address     => ex2_address
    );

    uut_fwd1: entity work.ex2_mem_forwarding port map(
        clk               => clk,
        rst               => rst,
        clk_en            => fwd1_clk_en,
        flush             => fwd1_flush,
        incremented_pc_in => fwd1_incremented_pc_in,
        pc_in             => fwd1_pc_in,
        in_port_in        => fwd1_in_port_in,
        r_rsrc1_in        => fwd1_r_rsrc1_in,
        r_rsrc2_in        => fwd1_r_rsrc2_in,
        alu_result_in     => fwd1_alu_result_in,
        address_in        => fwd1_address_in,
        rdst_in           => fwd1_rdst_in,
        rsrc1_in          => fwd1_rsrc1_in,
        inc_sp_in         => fwd1_inc_sp_in,
        dec_sp_in         => fwd1_dec_sp_in,
        mem_add_src_in    => fwd1_mem_add_src_in,
        mem_data_src_in   => fwd1_mem_data_src_in,
        mem_read_in       => fwd1_mem_read_in,
        mem_write_in      => fwd1_mem_write_in,
        output_enable_in  => fwd1_output_enable_in,
        mem_to_reg_in     => fwd1_mem_to_reg_in,
        reg_to_reg_in     => fwd1_reg_to_reg_in,
        input_enable_in   => fwd1_input_enable_in,
        reg_write_in      => fwd1_reg_write_in,
        reg2_write_in     => fwd1_reg2_write_in,
        incremented_pc_out => fwd1_incremented_pc_out,
        pc_out             => fwd1_pc_out,
        in_port_out        => fwd1_in_port_out,
        r_rsrc1_out        => fwd1_r_rsrc1_out,
        r_rsrc2_out        => fwd1_r_rsrc2_out,
        alu_result_out     => fwd1_alu_result_out,
        address_out        => fwd1_address_out,
        rdst_out           => fwd1_rdst_out,
        rsrc1_out          => fwd1_rsrc1_out,
        inc_sp_out         => fwd1_inc_sp_out,
        dec_sp_out         => fwd1_dec_sp_out,
        mem_add_src_out    => fwd1_mem_add_src_out,
        mem_data_src_out   => fwd1_mem_data_src_out,
        mem_read_out       => fwd1_mem_read_out,
        mem_write_out      => fwd1_mem_write_out,
        output_enable_out  => fwd1_output_enable_out,
        mem_to_reg_out     => fwd1_mem_to_reg_out,
        reg_to_reg_out     => fwd1_reg_to_reg_out,
        input_enable_out   => fwd1_input_enable_out,
        reg_write_out      => fwd1_reg_write_out,
        reg2_write_out     => fwd1_reg2_write_out
    );

    uut_mem: entity work.mem_stage port map(
        clk               => clk,
        rst               => rst,
        clk_enable        => clk_enable,
        address_in        => fwd1_address_out,
        r_rsrc1_in        => fwd1_r_rsrc1_out,
        r_rsrc2_in        => fwd1_r_rsrc2_out,
        incremented_pc_in => fwd1_incremented_pc_out,
        inc_sp            => fwd1_inc_sp_out,
        dec_sp            => fwd1_dec_sp_out,
        mem_add_src       => fwd1_mem_add_src_out,
        mem_data_src      => fwd1_mem_data_src_out,
        mem_read          => fwd1_mem_read_out,
        mem_write         => fwd1_mem_write_out,
        mem_address_out   => mem_address,
        writedata_out     => writedata,
        mem_read_out      => mem_read_sig,
        mem_write_out     => mem_write_sig,
        mem_data_in       => tb_mem_data,
        mem_data_out      => mem_data_out,
        sp_out            => sp_out
    );

    uut_fwd2: entity work.mem_wb_forwarding port map(
        clk               => clk,
        rst               => rst,
        clk_en            => fwd2_clk_en,
        incremented_pc_in => fwd1_incremented_pc_out,
        in_port_in        => fwd1_in_port_out,
        r_rsrc1_in        => fwd1_r_rsrc1_out,
        r_rsrc2_in        => fwd1_r_rsrc2_out,
        alu_result_in     => fwd1_alu_result_out,
        mem_data_in       => mem_data_out,
        rdst_in           => fwd1_rdst_out,
        rsrc1_in          => fwd1_rsrc1_out,
        output_enable_in  => fwd1_output_enable_out,
        mem_to_reg_in     => fwd1_mem_to_reg_out,
        reg_to_reg_in     => fwd1_reg_to_reg_out,
        input_enable_in   => fwd1_input_enable_out,
        reg_write_in      => fwd1_reg_write_out,
        reg2_write_in     => fwd1_reg2_write_out,
        incremented_pc_out => fwd2_incremented_pc_out,
        in_port_out        => fwd2_in_port_out,
        r_rsrc1_out        => fwd2_r_rsrc1_out,
        r_rsrc2_out        => fwd2_r_rsrc2_out,
        alu_result_out     => fwd2_alu_result_out,
        mem_data_out       => fwd2_mem_data_out,
        rdst_out           => fwd2_rdst_out,
        rsrc1_out          => fwd2_rsrc1_out,
        output_enable_out  => fwd2_output_enable_out,
        mem_to_reg_out     => fwd2_mem_to_reg_out,
        reg_to_reg_out     => fwd2_reg_to_reg_out,
        input_enable_out   => fwd2_input_enable_out,
        reg_write_out      => fwd2_reg_write_out,
        reg2_write_out     => fwd2_reg2_write_out
    );

    uut_wb: entity work.writeback port map(
        alu_result    => fwd2_alu_result_out,
        mem_data      => fwd2_mem_data_out,
        in_port       => fwd2_in_port_out,
        r_rsrc1       => fwd2_r_rsrc1_out,
        r_rsrc2       => fwd2_r_rsrc2_out,
        rdst          => fwd2_rdst_out,
        rsrc1         => fwd2_rsrc1_out,
        output_enable => fwd2_output_enable_out,
        input_enable  => fwd2_input_enable_out,
        mem_to_reg    => fwd2_mem_to_reg_out,
        reg_to_reg    => fwd2_reg_to_reg_out,
        reg_write     => fwd2_reg_write_out,
        reg2_write    => fwd2_reg2_write_out,
        out_port      => wb_out_port,
        write_data_1  => wb_write_data1,
        write_addr_1  => wb_write_addr1,
        write_en_1    => wb_write_en1,
        write_data_2  => wb_write_data2,
        write_addr_2  => wb_write_addr2,
        write_en_2    => wb_write_en2,
        wb_result     => wb_result
    );

    clk <= not clk after CLK_PERIOD / 2;

    -- =========================================================
    -- Stimulus
    -- =========================================================
    process
        -- helper: clear all fwd1 control inputs to safe defaults
        procedure clear_fwd1_ctrl is
        begin
            fwd1_inc_sp_in        <= '0';
            fwd1_dec_sp_in        <= '0';
            fwd1_mem_add_src_in   <= '0';
            fwd1_mem_data_src_in  <= '0';
            fwd1_mem_read_in      <= '0';
            fwd1_mem_write_in     <= '0';
            fwd1_output_enable_in <= '0';
            fwd1_mem_to_reg_in    <= '0';
            fwd1_reg_to_reg_in    <= '0';
            fwd1_input_enable_in  <= '0';
            fwd1_reg_write_in     <= '0';
            fwd1_reg2_write_in    <= '0';
            fwd1_flush            <= '0';
        end procedure;
    begin
        -- =========================================================
        -- RESET
        -- =========================================================
        rst <= '1';
        wait for CLK_PERIOD;
        rst <= '0';
        wait for CLK_PERIOD;
        report "======================================" severity note;
        report "Starting execute_2_tb (EX2+MEM+WB integrated)" severity note;
        report "======================================" severity note;

        -- =========================================================
        -- TEST 1: JMP (branch_type="11") — pc_src must go high
        -- =========================================================
        ex2_branch      <= '1';
        ex2_branch_type <= "11";
        ex2_Z           <= '0';
        ex2_C           <= '0';
        ex2_Neg         <= '0';
        ex2_clk_en      <= '1';
        wait for CLK_PERIOD;
        report "TEST 1: JMP branch=1 branch_type=11 | expected pc_src=1 got=" &
            std_logic'image(ex2_pc_src) severity note;
        assert ex2_pc_src = '1'
            report "FAIL TEST 1: JMP pc_src should be 1 got " &
            std_logic'image(ex2_pc_src) severity error;
        ex2_branch <= '0';
        wait for CLK_PERIOD;

        -- =========================================================
        -- TEST 2: JZ not taken (Z='0') — pc_src must stay low
        -- =========================================================
        ex2_branch      <= '1';
        ex2_branch_type <= "00";
        ex2_Z           <= '0';
        ex2_clk_en      <= '1';
        wait for CLK_PERIOD;
        report "TEST 2: JZ not taken Z=0 | expected pc_src=0 got=" &
            std_logic'image(ex2_pc_src) severity note;
        assert ex2_pc_src = '0'
            report "FAIL TEST 2: JZ not taken pc_src should be 0 got " &
            std_logic'image(ex2_pc_src) severity error;
        ex2_branch <= '0';
        wait for CLK_PERIOD;

        -- =========================================================
        -- TEST 3: JZ taken (Z='1')
        -- =========================================================
        ex2_branch      <= '1';
        ex2_branch_type <= "00";
        ex2_Z           <= '1';
        ex2_clk_en      <= '1';
        wait for CLK_PERIOD;
        report "TEST 3: JZ taken Z=1 | expected pc_src=1 got=" &
            std_logic'image(ex2_pc_src) severity note;
        assert ex2_pc_src = '1'
            report "FAIL TEST 3: JZ taken pc_src should be 1 got " &
            std_logic'image(ex2_pc_src) severity error;
        ex2_branch <= '0';
        ex2_Z      <= '0';
        wait for CLK_PERIOD;

        -- =========================================================
        -- TEST 4: EX2 address adder (combinational) rsrc=100 + imm=50 = 150
        -- =========================================================
        ex2_rsrc    <= std_logic_vector(to_unsigned(100, 32));
        ex2_imm_val <= std_logic_vector(to_unsigned(50, 32));
        wait for 1 ns; -- combinational settle
        report "TEST 4: address adder rsrc=100 imm=50 | expected=150 got=" &
            integer'image(to_integer(unsigned(ex2_address))) severity note;
        assert ex2_address = std_logic_vector(to_unsigned(150, 32))
            report "FAIL TEST 4: address adder expected 150 got " &
            integer'image(to_integer(unsigned(ex2_address))) severity error;
        ex2_rsrc    <= (others => '0');
        ex2_imm_val <= (others => '0');
        wait for CLK_PERIOD;

        -- =========================================================
        -- TEST 5: JN taken (branch_type="10", Neg='1')
        -- =========================================================
        ex2_branch      <= '1';
        ex2_branch_type <= "10";
        ex2_Neg         <= '1';
        ex2_clk_en      <= '1';
        wait for CLK_PERIOD;
        report "TEST 5: JN taken Neg=1 | expected pc_src=1 got=" &
            std_logic'image(ex2_pc_src) severity note;
        assert ex2_pc_src = '1'
            report "FAIL TEST 5: JN taken pc_src should be 1 got " &
            std_logic'image(ex2_pc_src) severity error;
        ex2_branch <= '0';
        ex2_Neg    <= '0';
        wait for CLK_PERIOD;

        -- =========================================================
        -- TEST 6: WB ALU result path (ADD / arithmetic)
        -- fwd1 -> fwd2 -> writeback: 2 clocks pipeline latency
        -- =========================================================
        clear_fwd1_ctrl;
        fwd1_alu_result_in <= std_logic_vector(to_unsigned(42, 32));
        fwd1_reg_write_in  <= '1';
        fwd1_rdst_in       <= "010";
        fwd1_clk_en        <= '1';
        tb_mem_data        <= (others => '0');
        wait for CLK_PERIOD; -- fwd1 latches
        fwd1_alu_result_in <= (others => '0');
        fwd1_reg_write_in  <= '0';
        fwd1_rdst_in       <= (others => '0');
        wait for CLK_PERIOD; -- fwd2 latches
        report "TEST 6: WB ALU result | alu=42 rdst=010 | expected write_data1=42 got=" &
            integer'image(to_integer(unsigned(wb_write_data1))) &
            " write_addr1=" & integer'image(to_integer(unsigned(wb_write_addr1))) &
            " write_en1=" & std_logic'image(wb_write_en1) severity note;
        assert wb_write_data1 = std_logic_vector(to_unsigned(42, 32))
            report "FAIL TEST 6: WB ALU result expected 42 got " &
            integer'image(to_integer(unsigned(wb_write_data1))) severity error;
        assert wb_write_addr1 = "010"
            report "FAIL TEST 6: write_addr1 expected 010 got " &
            integer'image(to_integer(unsigned(wb_write_addr1))) severity error;
        assert wb_write_en1 = '1'
            report "FAIL TEST 6: write_en1 should be 1" severity error;
        assert wb_write_en2 = '0'
            report "FAIL TEST 6: write_en2 should be 0" severity error;
        wait for CLK_PERIOD;

        -- =========================================================
        -- TEST 7: WB mem_to_reg path (LDD/POP)
        -- =========================================================
        clear_fwd1_ctrl;
        fwd1_alu_result_in <= std_logic_vector(to_unsigned(99, 32));
        fwd1_mem_to_reg_in <= '1';
        fwd1_reg_write_in  <= '1';
        fwd1_rdst_in       <= "101";
        fwd1_clk_en        <= '1';
        tb_mem_data        <= x"0000ABCD";
        wait for CLK_PERIOD; -- fwd1 latches
        fwd1_alu_result_in <= (others => '0');
        fwd1_mem_to_reg_in <= '0';
        fwd1_reg_write_in  <= '0';
        fwd1_rdst_in       <= (others => '0');
        wait for CLK_PERIOD; -- fwd2 latches (mem_data_out = tb_mem_data passes through)
        report "TEST 7: WB mem_to_reg (LDD) | mem_data=0x0000ABCD | expected write_data1=0x0000ABCD got=0x" &
            to_hstring(wb_write_data1) severity note;
        assert wb_write_data1 = x"0000ABCD"
            report "FAIL TEST 7: LDD expected 0x0000ABCD got 0x" &
            to_hstring(wb_write_data1) severity error;
        assert wb_write_addr1 = "101"
            report "FAIL TEST 7: write_addr1 expected 101" severity error;
        assert wb_write_en1 = '1'
            report "FAIL TEST 7: write_en1 should be 1" severity error;
        tb_mem_data <= (others => '0');
        wait for CLK_PERIOD;

        -- =========================================================
        -- TEST 8: WB IN instruction (input_enable path)
        -- =========================================================
        clear_fwd1_ctrl;
        fwd1_in_port_in       <= x"DEADBEEF";
        fwd1_input_enable_in  <= '1';
        fwd1_rdst_in          <= "011";
        fwd1_clk_en           <= '1';
        wait for CLK_PERIOD;
        fwd1_in_port_in      <= (others => '0');
        fwd1_input_enable_in <= '0';
        fwd1_rdst_in         <= (others => '0');
        wait for CLK_PERIOD;
        report "TEST 8: WB IN (input_enable) | in_port=0xDEADBEEF | expected write_data1=0xDEADBEEF got=0x" &
            to_hstring(wb_write_data1) &
            " write_en1=" & std_logic'image(wb_write_en1) severity note;
        assert wb_write_data1 = x"DEADBEEF"
            report "FAIL TEST 8: IN expected 0xDEADBEEF got 0x" &
            to_hstring(wb_write_data1) severity error;
        assert wb_write_en1 = '1'
            report "FAIL TEST 8: write_en1 should be 1 for IN (input_enable OR reg_write)" severity error;
        wait for CLK_PERIOD;

        -- =========================================================
        -- TEST 9: WB MOV (reg_to_reg, single dest, no reg2_write)
        -- =========================================================
        clear_fwd1_ctrl;
        fwd1_r_rsrc1_in    <= x"12345678";
        fwd1_reg_to_reg_in <= '1';
        fwd1_reg_write_in  <= '1';
        fwd1_rdst_in       <= "001";
        fwd1_clk_en        <= '1';
        wait for CLK_PERIOD;
        fwd1_r_rsrc1_in    <= (others => '0');
        fwd1_reg_to_reg_in <= '0';
        fwd1_reg_write_in  <= '0';
        fwd1_rdst_in       <= (others => '0');
        wait for CLK_PERIOD;
        report "TEST 9: WB MOV | r_rsrc1=0x12345678 rdst=001 | expected write_data1=0x12345678 got=0x" &
            to_hstring(wb_write_data1) &
            " write_en2=" & std_logic'image(wb_write_en2) severity note;
        assert wb_write_data1 = x"12345678"
            report "FAIL TEST 9: MOV expected 0x12345678 got 0x" &
            to_hstring(wb_write_data1) severity error;
        assert wb_write_addr1 = "001"
            report "FAIL TEST 9: write_addr1 expected 001" severity error;
        assert wb_write_en2 = '0'
            report "FAIL TEST 9: MOV write_en2 should be 0" severity error;
        wait for CLK_PERIOD;

        -- =========================================================
        -- TEST 10: WB SWAP (both write ports)
        -- Port 1: R[Rdst] <- R[Rsrc] = r_rsrc1 = 0xAAAAAAAA -> rdst="100"
        -- Port 2: R[Rsrc] <- old R[Rdst] = r_rsrc2 = 0xBBBBBBBB -> rsrc1="110"
        -- =========================================================
        clear_fwd1_ctrl;
        fwd1_r_rsrc1_in    <= x"AAAAAAAA";
        fwd1_r_rsrc2_in    <= x"BBBBBBBB";
        fwd1_reg_to_reg_in <= '1';
        fwd1_reg_write_in  <= '1';
        fwd1_reg2_write_in <= '1';
        fwd1_rdst_in       <= "100";
        fwd1_rsrc1_in      <= "110";
        fwd1_clk_en        <= '1';
        wait for CLK_PERIOD;
        fwd1_r_rsrc1_in    <= (others => '0');
        fwd1_r_rsrc2_in    <= (others => '0');
        fwd1_reg_to_reg_in <= '0';
        fwd1_reg_write_in  <= '0';
        fwd1_reg2_write_in <= '0';
        fwd1_rdst_in       <= (others => '0');
        fwd1_rsrc1_in      <= (others => '0');
        wait for CLK_PERIOD;
        report "TEST 10: WB SWAP | r_rsrc1=0xAAAAAAAA r_rsrc2=0xBBBBBBBB rdst=100 rsrc1=110" severity note;
        report "         write_data1=0x" & to_hstring(wb_write_data1) &
            " write_addr1=" & integer'image(to_integer(unsigned(wb_write_addr1))) &
            " write_en1=" & std_logic'image(wb_write_en1) severity note;
        report "         write_data2=0x" & to_hstring(wb_write_data2) &
            " write_addr2=" & integer'image(to_integer(unsigned(wb_write_addr2))) &
            " write_en2=" & std_logic'image(wb_write_en2) severity note;
        assert wb_write_data1 = x"AAAAAAAA"
            report "FAIL TEST 10: SWAP port1 data expected 0xAAAAAAAA got 0x" &
            to_hstring(wb_write_data1) severity error;
        assert wb_write_addr1 = "100"
            report "FAIL TEST 10: SWAP port1 addr expected 100" severity error;
        assert wb_write_en1 = '1'
            report "FAIL TEST 10: SWAP write_en1 should be 1" severity error;
        assert wb_write_data2 = x"BBBBBBBB"
            report "FAIL TEST 10: SWAP port2 data expected 0xBBBBBBBB got 0x" &
            to_hstring(wb_write_data2) severity error;
        assert wb_write_addr2 = "110"
            report "FAIL TEST 10: SWAP port2 addr expected 110" severity error;
        assert wb_write_en2 = '1'
            report "FAIL TEST 10: SWAP write_en2 should be 1" severity error;
        wait for CLK_PERIOD;

        -- =========================================================
        -- TEST 11: WB OUT instruction (out_port = r_rsrc1)
        -- =========================================================
        clear_fwd1_ctrl;
        fwd1_r_rsrc1_in       <= x"CAFEBABE";
        fwd1_output_enable_in <= '1';
        fwd1_clk_en           <= '1';
        wait for CLK_PERIOD;
        fwd1_r_rsrc1_in       <= (others => '0');
        fwd1_output_enable_in <= '0';
        wait for CLK_PERIOD;
        report "TEST 11: WB OUT | r_rsrc1=0xCAFEBABE | expected out_port=0xCAFEBABE got=0x" &
            to_hstring(wb_out_port) severity note;
        assert wb_out_port = x"CAFEBABE"
            report "FAIL TEST 11: OUT out_port expected 0xCAFEBABE got 0x" &
            to_hstring(wb_out_port) severity error;
        wait for CLK_PERIOD;

        -- =========================================================
        -- TEST 12: MEM stage LDD — mem_add_src=0, address passes through
        -- =========================================================
        clear_fwd1_ctrl;
        fwd1_address_in     <= std_logic_vector(to_unsigned(100, 32));
        fwd1_mem_add_src_in <= '0';
        fwd1_mem_read_in    <= '1';
        fwd1_clk_en         <= '1';
        wait for CLK_PERIOD; -- fwd1 latches
        report "TEST 12: MEM LDD address=100 mem_add_src=0 | expected mem_address=100 got=" &
            integer'image(to_integer(unsigned(mem_address))) &
            " mem_read=" & std_logic'image(mem_read_sig) severity note;
        assert mem_address = std_logic_vector(to_unsigned(100, 32))
            report "FAIL TEST 12: LDD mem_address expected 100 got " &
            integer'image(to_integer(unsigned(mem_address))) severity error;
        assert mem_read_sig = '1'
            report "FAIL TEST 12: mem_read should be 1" severity error;
        fwd1_address_in  <= (others => '0');
        fwd1_mem_read_in <= '0';
        wait for CLK_PERIOD;

        -- =========================================================
        -- TEST 13: MEM stage STD write data (mem_data_src=0 -> r_rsrc1)
        -- =========================================================
        clear_fwd1_ctrl;
        fwd1_r_rsrc1_in      <= x"FEEDFACE";
        fwd1_mem_data_src_in <= '0';
        fwd1_mem_write_in    <= '1';
        fwd1_clk_en          <= '1';
        wait for CLK_PERIOD;
        report "TEST 13: MEM STD write data=0xFEEDFACE mem_data_src=0 | expected writedata=0xFEEDFACE got=0x" &
            to_hstring(writedata) &
            " mem_write=" & std_logic'image(mem_write_sig) severity note;
        assert writedata = x"FEEDFACE"
            report "FAIL TEST 13: STD writedata expected 0xFEEDFACE got 0x" &
            to_hstring(writedata) severity error;
        assert mem_write_sig = '1'
            report "FAIL TEST 13: mem_write should be 1" severity error;
        fwd1_r_rsrc1_in   <= (others => '0');
        fwd1_mem_write_in <= '0';
        wait for CLK_PERIOD;

        -- =========================================================
        -- TEST 14: MEM stage PUSH — SP decrements, write address = SP before dec
        -- After reset SP=4095. dec_sp=1 => write to SP(4095), then SP becomes 4094.
        -- =========================================================
        rst <= '1';
        wait for CLK_PERIOD;
        rst <= '0';
        wait for CLK_PERIOD;
        clear_fwd1_ctrl;
        fwd1_dec_sp_in      <= '1';
        fwd1_mem_add_src_in <= '1';
        fwd1_mem_write_in   <= '1';
        fwd1_clk_en         <= '1';
        wait for CLK_PERIOD; -- fwd1 latches; mem_stage sees dec_sp=1 mem_add_src=1
        report "TEST 14: MEM PUSH dec_sp=1 mem_add_src=1 | SP initial=4095" severity note;
        report "         mem_address=" & integer'image(to_integer(unsigned(mem_address))) &
            " (expected 4095, writes to current SP)" severity note;
        assert mem_address = std_logic_vector(to_unsigned(4095, 32))
            report "FAIL TEST 14: PUSH mem_address expected 4095 got " &
            integer'image(to_integer(unsigned(mem_address))) severity error;
        wait for CLK_PERIOD; -- SP register updates on this edge -> SP becomes 4094
        report "         sp_out after decrement=" & integer'image(to_integer(unsigned(sp_out))) &
            " (expected 4094)" severity note;
        assert sp_out = std_logic_vector(to_unsigned(4094, 32))
            report "FAIL TEST 14: SP after PUSH expected 4094 got " &
            integer'image(to_integer(unsigned(sp_out))) severity error;
        fwd1_dec_sp_in    <= '0';
        fwd1_mem_write_in <= '0';
        wait for CLK_PERIOD;

        -- =========================================================
        -- TEST 15: flush kills control, passes data
        -- =========================================================
        clear_fwd1_ctrl;
        fwd1_alu_result_in <= x"DEAD1234";
        fwd1_reg_write_in  <= '1';
        fwd1_rdst_in       <= "111";
        fwd1_flush         <= '1';
        fwd1_clk_en        <= '1';
        wait for CLK_PERIOD;
        report "TEST 15: flush | alu=0xDEAD1234 reg_write=1 rdst=111 | control should be zeroed, data passes" severity note;
        report "         reg_write_out=" & std_logic'image(fwd1_reg_write_out) &
            " alu_result_out=0x" & to_hstring(fwd1_alu_result_out) &
            " rdst_out=" & integer'image(to_integer(unsigned(fwd1_rdst_out))) severity note;
        assert fwd1_reg_write_out = '0'
            report "FAIL TEST 15: flush reg_write_out should be 0" severity error;
        assert fwd1_alu_result_out = x"DEAD1234"
            report "FAIL TEST 15: flush alu_result_out should still be 0xDEAD1234 got 0x" &
            to_hstring(fwd1_alu_result_out) severity error;
        fwd1_alu_result_in <= (others => '0');
        fwd1_reg_write_in  <= '0';
        fwd1_rdst_in       <= (others => '0');
        fwd1_flush         <= '0';
        wait for CLK_PERIOD;

        -- =========================================================
        -- TEST 16: JC taken (branch_type="01", C='1')
        -- =========================================================
        ex2_branch      <= '1';
        ex2_branch_type <= "01";
        ex2_C           <= '1';
        ex2_clk_en      <= '1';
        wait for CLK_PERIOD;
        report "TEST 16: JC taken C=1 | expected pc_src=1 got=" &
            std_logic'image(ex2_pc_src) severity note;
        assert ex2_pc_src = '1'
            report "FAIL TEST 16: JC taken pc_src should be 1 got " &
            std_logic'image(ex2_pc_src) severity error;
        ex2_branch <= '0';
        ex2_C      <= '0';
        wait for CLK_PERIOD;

        -- =========================================================
        -- TEST 17: execute_2 clk_en=0 stall — pc_src must hold
        -- Drive JMP with clk_en=1 to set pc_src=1, then stall with clk_en=0
        -- and assert a non-taken condition. pc_src should NOT update.
        -- =========================================================
        ex2_branch      <= '1';
        ex2_branch_type <= "11";   -- JMP -> pc_src=1
        ex2_clk_en      <= '1';
        wait for CLK_PERIOD;
        assert ex2_pc_src = '1'
            report "FAIL TEST 17 setup: JMP should have set pc_src=1" severity error;
        -- Now stall and present a not-taken case
        ex2_branch      <= '1';
        ex2_branch_type <= "00";
        ex2_Z           <= '0';    -- would normally make pc_src=0
        ex2_clk_en      <= '0';    -- STALL
        wait for CLK_PERIOD;
        report "TEST 17: clk_en=0 stall | pc_src should hold at 1 got=" &
            std_logic'image(ex2_pc_src) severity note;
        assert ex2_pc_src = '1'
            report "FAIL TEST 17: clk_en=0 stall pc_src should hold 1 got " &
            std_logic'image(ex2_pc_src) severity error;
        -- Resume
        ex2_clk_en      <= '1';
        wait for CLK_PERIOD;
        assert ex2_pc_src = '0'
            report "FAIL TEST 17: after resume pc_src should drop to 0 got " &
            std_logic'image(ex2_pc_src) severity error;
        ex2_branch <= '0';
        wait for CLK_PERIOD;

        -- =========================================================
        -- TEST 18: ex2_mem_forwarding clk_en=0 stall — data + control hold
        -- =========================================================
        clear_fwd1_ctrl;
        fwd1_alu_result_in <= x"DEADBEEF";
        fwd1_reg_write_in  <= '1';
        fwd1_rdst_in       <= "011";
        fwd1_clk_en        <= '1';
        wait for CLK_PERIOD;   -- fwd1 latches: alu_result_out=DEADBEEF, reg_write_out=1
        assert fwd1_alu_result_out = x"DEADBEEF"
            report "FAIL TEST 18 setup: alu_result_out should be 0xDEADBEEF" severity error;
        assert fwd1_reg_write_out = '1'
            report "FAIL TEST 18 setup: reg_write_out should be 1" severity error;
        -- Now stall and change inputs
        fwd1_alu_result_in <= x"FEEDFACE";
        fwd1_reg_write_in  <= '0';
        fwd1_rdst_in       <= "111";
        fwd1_clk_en        <= '0';   -- STALL
        wait for CLK_PERIOD;
        report "TEST 18: fwd1 stall | alu_result_out should hold 0xDEADBEEF got=0x" &
            to_hstring(fwd1_alu_result_out) severity note;
        assert fwd1_alu_result_out = x"DEADBEEF"
            report "FAIL TEST 18: stall should hold alu_result_out got 0x" &
            to_hstring(fwd1_alu_result_out) severity error;
        assert fwd1_reg_write_out = '1'
            report "FAIL TEST 18: stall should hold reg_write_out" severity error;
        assert fwd1_rdst_out = "011"
            report "FAIL TEST 18: stall should hold rdst_out" severity error;
        -- Resume
        fwd1_clk_en <= '1';
        wait for CLK_PERIOD;
        assert fwd1_alu_result_out = x"FEEDFACE"
            report "FAIL TEST 18: after resume should latch new value got 0x" &
            to_hstring(fwd1_alu_result_out) severity error;
        clear_fwd1_ctrl;
        fwd1_alu_result_in <= (others => '0');
        fwd1_rdst_in       <= (others => '0');
        wait for CLK_PERIOD;

        -- =========================================================
        -- TEST 19: MEM POP — inc_sp=1 -> mem_address = SP+1, SP increments
        -- Reset SP=4095. inc_sp=1 -> read addr = 4096, then SP becomes 4096.
        -- =========================================================
        rst <= '1';
        wait for CLK_PERIOD;
        rst <= '0';
        wait for CLK_PERIOD;
        clear_fwd1_ctrl;
        fwd1_inc_sp_in      <= '1';
        fwd1_mem_add_src_in <= '1';
        fwd1_mem_read_in    <= '1';
        fwd1_clk_en         <= '1';
        wait for CLK_PERIOD;   -- fwd1 latches; mem_stage sees inc_sp=1 mem_add_src=1
        report "TEST 19: MEM POP inc_sp=1 mem_add_src=1 | SP initial=4095" severity note;
        report "         mem_address=" & integer'image(to_integer(unsigned(mem_address))) &
            " (expected 4096, reads SP+1)" severity note;
        assert mem_address = std_logic_vector(to_unsigned(4096, 32))
            report "FAIL TEST 19: POP mem_address expected 4096 got " &
            integer'image(to_integer(unsigned(mem_address))) severity error;
        assert mem_read_sig = '1'
            report "FAIL TEST 19: mem_read should be 1" severity error;
        wait for CLK_PERIOD;   -- SP register updates -> SP becomes 4096
        report "         sp_out after increment=" & integer'image(to_integer(unsigned(sp_out))) &
            " (expected 4096)" severity note;
        assert sp_out = std_logic_vector(to_unsigned(4096, 32))
            report "FAIL TEST 19: SP after POP expected 4096 got " &
            integer'image(to_integer(unsigned(sp_out))) severity error;
        clear_fwd1_ctrl;
        wait for CLK_PERIOD;

        -- =========================================================
        -- TEST 20: SP hold — no inc/dec, SP unchanged across cycles
        -- =========================================================
        rst <= '1';
        wait for CLK_PERIOD;
        rst <= '0';
        wait for CLK_PERIOD;
        clear_fwd1_ctrl;
        fwd1_clk_en <= '1';
        wait for CLK_PERIOD * 3;   -- several cycles with no inc/dec
        report "TEST 20: SP hold (no inc/dec) | expected sp_out=4095 got=" &
            integer'image(to_integer(unsigned(sp_out))) severity note;
        assert sp_out = std_logic_vector(to_unsigned(4095, 32))
            report "FAIL TEST 20: SP should hold at 4095 got " &
            integer'image(to_integer(unsigned(sp_out))) severity error;

        -- =========================================================
        -- TEST 21: MEM CALL/INT — mem_data_src=1 writes incremented_pc as return addr
        -- =========================================================
        clear_fwd1_ctrl;
        fwd1_incremented_pc_in <= x"C0DEBABE";
        fwd1_r_rsrc1_in        <= x"11111111";   -- should be ignored
        fwd1_mem_data_src_in   <= '1';
        fwd1_mem_write_in      <= '1';
        fwd1_clk_en            <= '1';
        wait for CLK_PERIOD;
        report "TEST 21: MEM CALL/INT mem_data_src=1 | expected writedata=0xC0DEBABE got=0x" &
            to_hstring(writedata) severity note;
        assert writedata = x"C0DEBABE"
            report "FAIL TEST 21: writedata expected 0xC0DEBABE got 0x" &
            to_hstring(writedata) severity error;
        assert mem_write_sig = '1'
            report "FAIL TEST 21: mem_write should be 1" severity error;
        fwd1_incremented_pc_in <= (others => '0');
        fwd1_r_rsrc1_in        <= (others => '0');
        clear_fwd1_ctrl;
        wait for CLK_PERIOD;

        -- =========================================================
        -- TEST 22: MEM mem_data_in -> mem_data_out pass-through (combinational)
        -- =========================================================
        tb_mem_data <= x"5A5A5A5A";
        wait for 1 ns;
        report "TEST 22: mem_data_in passthrough | tb_mem_data=0x5A5A5A5A | expected mem_data_out=0x5A5A5A5A got=0x" &
            to_hstring(mem_data_out) severity note;
        assert mem_data_out = x"5A5A5A5A"
            report "FAIL TEST 22: mem_data_out should equal mem_data_in got 0x" &
            to_hstring(mem_data_out) severity error;
        tb_mem_data <= (others => '0');
        wait for CLK_PERIOD;

        -- =========================================================
        -- TEST 23: WB wb_result equals port1 write data (forwarded to EX1)
        -- =========================================================
        clear_fwd1_ctrl;
        fwd1_alu_result_in <= x"7777BEEF";
        fwd1_reg_write_in  <= '1';
        fwd1_rdst_in       <= "010";
        fwd1_clk_en        <= '1';
        wait for CLK_PERIOD;   -- fwd1 latches
        clear_fwd1_ctrl;
        fwd1_alu_result_in <= (others => '0');
        fwd1_rdst_in       <= (others => '0');
        wait for CLK_PERIOD;   -- fwd2 latches
        report "TEST 23: wb_result | expected wb_result=write_data_1=0x7777BEEF | got wb_result=0x" &
            to_hstring(wb_result) & " write_data_1=0x" & to_hstring(wb_write_data1) severity note;
        assert wb_result = wb_write_data1
            report "FAIL TEST 23: wb_result should equal write_data_1" severity error;
        assert wb_result = x"7777BEEF"
            report "FAIL TEST 23: wb_result expected 0x7777BEEF got 0x" &
            to_hstring(wb_result) severity error;
        wait for CLK_PERIOD;

        -- =========================================================
        -- TEST 24: WB priority MUX — input_enable wins over mem_to_reg
        -- Both asserted simultaneously: should pick in_port (input_enable highest priority)
        -- =========================================================
        clear_fwd1_ctrl;
        fwd1_in_port_in       <= x"AAAA0000";
        fwd1_input_enable_in  <= '1';
        fwd1_mem_to_reg_in    <= '1';   -- competing
        fwd1_reg_write_in     <= '1';
        fwd1_rdst_in          <= "100";
        fwd1_clk_en           <= '1';
        tb_mem_data           <= x"BBBB0000";
        wait for CLK_PERIOD;   -- fwd1 latches
        clear_fwd1_ctrl;
        fwd1_in_port_in       <= (others => '0');
        fwd1_rdst_in          <= (others => '0');
        wait for CLK_PERIOD;   -- fwd2 latches
        report "TEST 24: WB priority | in_port=0xAAAA0000 mem_data=0xBBBB0000 both enables=1 | expected in_port wins got=0x" &
            to_hstring(wb_write_data1) severity note;
        assert wb_write_data1 = x"AAAA0000"
            report "FAIL TEST 24: input_enable should beat mem_to_reg, expected 0xAAAA0000 got 0x" &
            to_hstring(wb_write_data1) severity error;
        tb_mem_data <= (others => '0');
        wait for CLK_PERIOD;

        -- =========================================================
        -- TEST 25: WB no-write — all enables off => write_en_1 = 0
        -- =========================================================
        clear_fwd1_ctrl;
        fwd1_alu_result_in <= x"99999999";   -- something on the data lines
        fwd1_reg_write_in  <= '0';
        fwd1_input_enable_in <= '0';
        fwd1_clk_en        <= '1';
        wait for CLK_PERIOD;
        clear_fwd1_ctrl;
        fwd1_alu_result_in <= (others => '0');
        wait for CLK_PERIOD;
        report "TEST 25: WB no-write | reg_write=0 input_enable=0 | expected write_en_1=0 got=" &
            std_logic'image(wb_write_en1) severity note;
        assert wb_write_en1 = '0'
            report "FAIL TEST 25: write_en_1 should be 0 when both reg_write and input_enable are 0" severity error;
        assert wb_write_en2 = '0'
            report "FAIL TEST 25: write_en_2 should also be 0" severity error;
        wait for CLK_PERIOD;

        -- =========================================================
        report "======================================" severity note;
        report "ALL TESTS DONE" severity note;
        report "======================================" severity note;
        wait;
    end process;

end tb;
