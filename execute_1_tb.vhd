library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity execute_1_tb is
end execute_1_tb;

architecture tb of execute_1_tb is

    constant n : integer := 32;
    constant CLK_PERIOD : time := 10 ns;

    function to_hstring(slv : std_logic_vector) return string is
        constant HEX : string(1 to 16) := "0123456789ABCDEF";
        variable result : string(1 to slv'length / 4);
        variable nibble : std_logic_vector(3 downto 0);
    begin
        for i in 0 to slv'length / 4 - 1 loop
            nibble := slv(slv'length - 1 - i*4 downto slv'length - 4 - i*4);
            result(i + 1) := HEX(to_integer(unsigned(nibble)) + 1);
        end loop;
        return result;
    end function;

    component execute_1 is
        generic (n : integer := 32);
        port(
            clk, rst       : in std_logic;
            r_rs1          : in std_logic_vector(n-1 downto 0);
            r_rs2          : in std_logic_vector(n-1 downto 0);
            imm            : in std_logic_vector(n-1 downto 0);
            alu_result     : out std_logic_vector(n-1 downto 0);
            ex1_ex2_result : in std_logic_vector(n-1 downto 0);
            ex2_mem_result : in std_logic_vector(n-1 downto 0);
            mem_wb_result  : in std_logic_vector(n-1 downto 0);
            forward_a      : in std_logic_vector(1 downto 0);
            forward_b      : in std_logic_vector(1 downto 0);
            zero           : out std_logic;
            negative       : out std_logic;
            carry          : out std_logic;
            alu_src        : in std_logic;
            alu_operation  : in std_logic_vector(2 downto 0);
            set_carry      : in std_logic;
            alu_passthrough: in std_logic;
            store_ccr      : in std_logic;
            flag_enable    : in std_logic;
            restore_ccr    : in std_logic
        );
    end component;

    signal clk, rst        : std_logic := '0';
    signal r_rs1, r_rs2    : std_logic_vector(n-1 downto 0) := (others => '0');
    signal imm             : std_logic_vector(n-1 downto 0) := (others => '0');
    signal ex1_ex2_result  : std_logic_vector(n-1 downto 0) := (others => '0');
    signal ex2_mem_result  : std_logic_vector(n-1 downto 0) := (others => '0');
    signal mem_wb_result   : std_logic_vector(n-1 downto 0) := (others => '0');
    signal forward_a       : std_logic_vector(1 downto 0) := "00";
    signal forward_b       : std_logic_vector(1 downto 0) := "00";
    signal alu_src         : std_logic := '0';
    signal alu_operation   : std_logic_vector(2 downto 0) := "000";
    signal set_carry       : std_logic := '0';
    signal alu_passthrough : std_logic := '0';
    signal store_ccr       : std_logic := '0';
    signal flag_enable     : std_logic := '0';
    signal restore_ccr     : std_logic := '0';
    signal alu_result      : std_logic_vector(n-1 downto 0);
    signal zero            : std_logic;
    signal negative        : std_logic;
    signal carry           : std_logic;

begin

    uut: execute_1 generic map(n) port map(
        clk            => clk,
        rst            => rst,
        r_rs1          => r_rs1,
        r_rs2          => r_rs2,
        imm            => imm,
        alu_result     => alu_result,
        ex1_ex2_result => ex1_ex2_result,
        ex2_mem_result => ex2_mem_result,
        mem_wb_result  => mem_wb_result,
        forward_a      => forward_a,
        forward_b      => forward_b,
        zero           => zero,
        negative       => negative,
        carry          => carry,
        alu_src        => alu_src,
        alu_operation  => alu_operation,
        set_carry      => set_carry,
        alu_passthrough=> alu_passthrough,
        store_ccr      => store_ccr,
        flag_enable    => flag_enable,
        restore_ccr    => restore_ccr
    );

    clk <= not clk after CLK_PERIOD / 2;

    process
    begin
        -- =========================================================
        -- RESET
        -- =========================================================
        rst <= '1';
        wait for CLK_PERIOD;
        rst <= '0';
        wait for CLK_PERIOD;
        report "======================================" severity note;
        report "Starting execute_1 testbench" severity note;
        report "======================================" severity note;

        -- =========================================================
        -- TEST 1: ADD 5 + 3 = 8
        -- =========================================================
        r_rs1         <= std_logic_vector(to_unsigned(5, n));
        r_rs2         <= std_logic_vector(to_unsigned(3, n));
        alu_operation <= "001";
        alu_src       <= '0';
        flag_enable   <= '1';
        wait for CLK_PERIOD;
        report "TEST 1: ADD | r_rs1=5 r_rs2=3 | expected=8 got=" &
            integer'image(to_integer(unsigned(alu_result))) &
            " | zero=" & std_logic'image(zero) &
            " neg="    & std_logic'image(negative) &
            " carry="  & std_logic'image(carry) severity note;
        assert alu_result = std_logic_vector(to_unsigned(8, n))
            report "FAIL TEST 1: ADD expected 8 got " &
            integer'image(to_integer(unsigned(alu_result))) severity error;
        flag_enable <= '0';
        wait for CLK_PERIOD;

        -- =========================================================
        -- TEST 2: SUB 10 - 3 = 7
        -- =========================================================
        r_rs1         <= std_logic_vector(to_unsigned(10, n));
        r_rs2         <= std_logic_vector(to_unsigned(3, n));
        alu_operation <= "011";
        alu_src       <= '0';
        flag_enable   <= '1';
        wait for CLK_PERIOD;
        report "TEST 2: SUB | r_rs1=10 r_rs2=3 | expected=7 got=" &
            integer'image(to_integer(unsigned(alu_result))) &
            " | zero=" & std_logic'image(zero) &
            " neg="    & std_logic'image(negative) &
            " carry="  & std_logic'image(carry) severity note;
        assert alu_result = std_logic_vector(to_unsigned(7, n))
            report "FAIL TEST 2: SUB expected 7 got " &
            integer'image(to_integer(unsigned(alu_result))) severity error;
        flag_enable <= '0';
        wait for CLK_PERIOD;

        -- =========================================================
        -- TEST 3: AND 0xF0F0F0F0 AND 0x0F0F0F0F = 0x00000000
        -- =========================================================
        r_rs1         <= x"F0F0F0F0";
        r_rs2         <= x"0F0F0F0F";
        alu_operation <= "100";
        alu_src       <= '0';
        flag_enable   <= '1';
        wait for CLK_PERIOD;
        report "TEST 3: AND | r_rs1=0xF0F0F0F0 r_rs2=0x0F0F0F0F | expected=0x00000000 got=0x" &
            to_hstring(alu_result) &
            " | zero=" & std_logic'image(zero) &
            " neg="    & std_logic'image(negative) severity note;
        assert alu_result = x"00000000"
            report "FAIL TEST 3: AND expected 0x00000000 got 0x" &
            to_hstring(alu_result) severity error;
        assert zero = '1'
            report "FAIL TEST 3: zero flag should be 1" severity error;
        flag_enable <= '0';
        wait for CLK_PERIOD;

        -- =========================================================
        -- TEST 4: NOT 0x00000000 = 0xFFFFFFFF
        -- =========================================================
        r_rs1         <= x"00000000";
        alu_operation <= "010";
        flag_enable   <= '1';
        wait for CLK_PERIOD;
        report "TEST 4: NOT | r_rs1=0x00000000 | expected=0xFFFFFFFF got=0x" &
            to_hstring(alu_result) &
            " | zero=" & std_logic'image(zero) &
            " neg="    & std_logic'image(negative) severity note;
        assert alu_result = x"FFFFFFFF"
            report "FAIL TEST 4: NOT expected 0xFFFFFFFF got 0x" &
            to_hstring(alu_result) severity error;
        assert negative = '1'
            report "FAIL TEST 4: negative flag should be 1" severity error;
        flag_enable <= '0';
        wait for CLK_PERIOD;

        -- =========================================================
        -- TEST 5: IADD r_rs1=5 + imm=10 = 15
        -- =========================================================
        r_rs1         <= std_logic_vector(to_unsigned(5, n));
        imm           <= std_logic_vector(to_unsigned(10, n));
        alu_operation <= "001";
        alu_src       <= '1';
        flag_enable   <= '1';
        wait for CLK_PERIOD;
        report "TEST 5: IADD | r_rs1=5 imm=10 | expected=15 got=" &
            integer'image(to_integer(unsigned(alu_result))) &
            " | zero=" & std_logic'image(zero) &
            " neg="    & std_logic'image(negative) &
            " carry="  & std_logic'image(carry) severity note;
        assert alu_result = std_logic_vector(to_unsigned(15, n))
            report "FAIL TEST 5: IADD expected 15 got " &
            integer'image(to_integer(unsigned(alu_result))) severity error;
        alu_src     <= '0';
        flag_enable <= '0';
        wait for CLK_PERIOD;

        -- =========================================================
        -- TEST 6: SETC - carry forced to 1
        -- =========================================================
        r_rs1         <= std_logic_vector(to_unsigned(1, n));
        r_rs2         <= std_logic_vector(to_unsigned(1, n));
        alu_operation <= "001";
        set_carry     <= '1';
        flag_enable   <= '1';
        wait for CLK_PERIOD;
        report "TEST 6: SETC | expected carry=1 got carry=" &
            std_logic'image(carry) severity note;
        assert carry = '1'
            report "FAIL TEST 6: SETC carry should be 1 got " &
            std_logic'image(carry) severity error;
        set_carry   <= '0';
        flag_enable <= '0';
        wait for CLK_PERIOD;

        -- =========================================================
        -- TEST 7: ALU passthrough - result = imm not alu output
        -- =========================================================
        r_rs1           <= std_logic_vector(to_unsigned(5, n));
        r_rs2           <= std_logic_vector(to_unsigned(3, n));
        imm             <= std_logic_vector(to_unsigned(99, n));
        alu_operation   <= "001";
        alu_passthrough <= '1';
        wait for CLK_PERIOD;
        report "TEST 7: ALU passthrough | imm=99 | expected=99 got=" &
            integer'image(to_integer(unsigned(alu_result))) severity note;
        assert alu_result = std_logic_vector(to_unsigned(99, n))
            report "FAIL TEST 7: passthrough expected 99 got " &
            integer'image(to_integer(unsigned(alu_result))) severity error;
        alu_passthrough <= '0';
        wait for CLK_PERIOD;

        -- =========================================================
        -- TEST 8: ForwardA from EX1/EX2 (forward_a="01")
        -- forwarded(20) + r_rs2(5) = 25
        -- =========================================================
        ex1_ex2_result <= std_logic_vector(to_unsigned(20, n));
        r_rs2          <= std_logic_vector(to_unsigned(5, n));
        forward_a      <= "01";
        forward_b      <= "00";
        alu_operation  <= "001";
        alu_src        <= '0';
        flag_enable    <= '1';
        wait for CLK_PERIOD;
        report "TEST 8: ForwardA EX1/EX2 | fwd=20 r_rs2=5 | expected=25 got=" &
            integer'image(to_integer(unsigned(alu_result))) severity note;
        assert alu_result = std_logic_vector(to_unsigned(25, n))
            report "FAIL TEST 8: ForwardA expected 25 got " &
            integer'image(to_integer(unsigned(alu_result))) severity error;
        forward_a   <= "00";
        flag_enable <= '0';
        wait for CLK_PERIOD;

        -- =========================================================
        -- TEST 9: ForwardB from MEM/WB (forward_b="11")
        -- r_rs1(10) + forwarded(7) = 17
        -- =========================================================
        r_rs1         <= std_logic_vector(to_unsigned(10, n));
        r_rs2         <= std_logic_vector(to_unsigned(99, n)); -- overridden by forwarding
        mem_wb_result <= std_logic_vector(to_unsigned(7, n));
        forward_a     <= "00";
        forward_b     <= "11";
        alu_operation <= "001";
        alu_src       <= '0';
        flag_enable   <= '1';
        wait for CLK_PERIOD;
        report "TEST 9: ForwardB MEM/WB (11) | r_rs1=10 fwd=7 | expected=17 got=" &
            integer'image(to_integer(unsigned(alu_result))) severity note;
        assert alu_result = std_logic_vector(to_unsigned(17, n))
            report "FAIL TEST 9: ForwardB expected 17 got " &
            integer'image(to_integer(unsigned(alu_result))) severity error;
        forward_b   <= "00";
        flag_enable <= '0';
        wait for CLK_PERIOD;

        -- =========================================================
        -- TEST 10: CCR store and restore
        -- step 1: ADD 1+0 -> zero=0 negative=0
        -- step 2: store CCR
        -- step 3: NOT 0x00000000 -> negative=1 (overwrites flags)
        -- step 4: restore CCR -> negative should go back to 0
        -- =========================================================

        -- step 1: set flags with ADD 1+0
        r_rs1         <= std_logic_vector(to_unsigned(1, n));
        r_rs2         <= std_logic_vector(to_unsigned(0, n));
        alu_operation <= "001";
        alu_src       <= '0';
        flag_enable   <= '1';
        wait for CLK_PERIOD;
        report "TEST 10 step 1: ADD 1+0 | zero=" & std_logic'image(zero) &
            " neg=" & std_logic'image(negative) severity note;
        flag_enable <= '0';
        wait for CLK_PERIOD;

        -- step 2: store CCR
        store_ccr <= '1';
        wait for CLK_PERIOD;
        report "TEST 10 step 2: CCR stored | zero=" & std_logic'image(zero) &
            " neg=" & std_logic'image(negative) severity note;
        store_ccr <= '0';
        wait for CLK_PERIOD;

        -- step 3: NOT 0x00000000 -> sets negative=1
        r_rs1         <= x"00000000";
        alu_operation <= "010";
        flag_enable   <= '1';
        wait for CLK_PERIOD;
        report "TEST 10 step 3: NOT 0x0 | zero=" & std_logic'image(zero) &
            " neg=" & std_logic'image(negative) &
            " (negative should now be 1)" severity note;
        flag_enable <= '0';
        wait for CLK_PERIOD;

        -- step 4: restore CCR -> negative should go back to 0
        restore_ccr <= '1';
        flag_enable <= '1';
        wait for CLK_PERIOD;
        report "TEST 10 step 4: CCR restored | zero=" & std_logic'image(zero) &
            " neg=" & std_logic'image(negative) &
            " (negative should be 0 again)" severity note;
        assert negative = '0'
            report "FAIL TEST 10: after restore negative should be 0 got " &
            std_logic'image(negative) severity error;
        restore_ccr <= '0';
        flag_enable <= '0';
        wait for CLK_PERIOD;

        -- =========================================================
        report "======================================" severity note;
        report "ALL TESTS DONE" severity note;
        report "======================================" severity note;
        wait;
    end process;

end tb;