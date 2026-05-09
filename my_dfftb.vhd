library ieee;
use ieee.std_logic_1164.all;

entity my_dff_tb is
end my_dff_tb;

architecture tb of my_dff_tb is

    -- Component declaration
    component my_dff
        port(d, clk, rst : in std_logic; q : out std_logic);
    end component;

    -- Signals to drive the DFF
    signal d   : std_logic := '0';
    signal clk : std_logic := '0';
    signal rst : std_logic := '0';
    signal q   : std_logic;

    -- Clock period constant
    constant CLK_PERIOD : time := 10 ns;

begin

    UUT: my_dff port map(d => d, clk => clk, rst => rst, q => q);

    clk_process: process
    begin
        clk <= '0';
        wait for CLK_PERIOD / 2;
        clk <= '1';
        wait for CLK_PERIOD / 2;
    end process;

    -- Stimulus process: applies test cases one by one
    stimulus: process
    begin

        -- -------------------------------------------------------
        -- TEST 1: Asynchronous Reset
        -- rst is high → q must go to '0' immediately, no clock needed
        -- -------------------------------------------------------
        d   <= '1';
        rst <= '1';               -- assert reset while d='1'
        wait for 7 ns;            -- wait mid-cycle (not at a clock edge)
        -- q should already be '0' even though no rising edge happened
        assert q = '0'
            report "FAIL TEST 1: Reset did not clear q immediately" severity error;

        -- -------------------------------------------------------
        -- TEST 2: Reset Released — capture d='1' on rising edge
        -- -------------------------------------------------------
        rst <= '0';               -- release reset
        d   <= '1';
        wait until rising_edge(clk);
        wait for 1 ns;            -- small delta to let signal settle
        assert q = '1'
            report "FAIL TEST 2: q should be '1' after capturing d='1'" severity error;

        -- -------------------------------------------------------
        -- TEST 3: Capture d='0' on rising edge
        -- -------------------------------------------------------
        d <= '0';
        wait until rising_edge(clk);
        wait for 1 ns;
        assert q = '0'
            report "FAIL TEST 3: q should be '0' after capturing d='0'" severity error;

        -- -------------------------------------------------------
        -- TEST 4: Hold — q must NOT change between clock edges
        -- -------------------------------------------------------
        d <= '1';                 -- change d to '1' but don't clock yet
        wait for CLK_PERIOD / 2; -- wait half a cycle (no rising edge yet)
        assert q = '0'
            report "FAIL TEST 4: q changed without a rising edge (no hold)" severity error;

        -- -------------------------------------------------------
        -- TEST 5: Asynchronous Reset overrides clock
        -- Set d='1', reach rising edge, but assert rst at the same time
        -- -------------------------------------------------------
        d   <= '1';
        rst <= '1';               -- reset high at the same time as rising edge
        wait until rising_edge(clk);
        wait for 1 ns;
        assert q = '0'
            report "FAIL TEST 5: Reset should override clock capture" severity error;
        rst <= '0';

        -- -------------------------------------------------------
        -- TEST 6: Multiple consecutive captures
        -- -------------------------------------------------------
        d <= '1';
        wait until rising_edge(clk); wait for 1 ns;
        assert q = '1' report "FAIL TEST 6a" severity error;

        d <= '0';
        wait until rising_edge(clk); wait for 1 ns;
        assert q = '0' report "FAIL TEST 6b" severity error;

        d <= '1';
        wait until rising_edge(clk); wait for 1 ns;
        assert q = '1' report "FAIL TEST 6c" severity error;

        d <= '1';
        wait until rising_edge(clk); wait for 1 ns;
        assert q = '1' report "FAIL TEST 6d: same value twice" severity error;

        -- -------------------------------------------------------
        -- All tests done
        -- -------------------------------------------------------
        report "All tests passed!" severity note;
        wait; -- stop simulation
    end process;

end tb;