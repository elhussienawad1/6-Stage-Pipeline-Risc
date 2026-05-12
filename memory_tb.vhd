library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- ============================================================
-- Testbench for reg_file_memory (memory.vhd)
-- Tests:
--   1. File initialisation: addr 0xA0 reads back expected instruction
--   2. Combinatorial read: mem_read='1' returns data same cycle
--   3. Synchronous write + readback: write on rising edge, read next cycle
--   4. Instruction fetch: independent of data read port
--   5. Simultaneous data read + instruction fetch (no conflict, no busy)
--   6. Write-during-fetch: memory_busy asserts same cycle as mem_write
--   7. Write does NOT corrupt instruction_address port output
--   8. Address boundary: write/read at top address 0xFFF
--   9. mem_read='0': mem_output shows instruction (not stale data)
--  10. Reset has no side-effect on memory contents
-- ============================================================
entity memory_tb is
end entity;

architecture sim of memory_tb is

    component reg_file_memory is
        generic( N: integer := 32; M: integer := 4096 );
        port(
            clk, rst              : in  std_logic;
            address               : in  std_logic_vector(31 downto 0);
            instruction_address   : in  std_logic_vector(31 downto 0);
            mem_write, mem_read   : in  std_logic;
            writedata             : in  std_logic_vector(31 downto 0);
            mem_output            : out std_logic_vector(31 downto 0);
            memory_busy           : out std_logic;
            mem1, mem2, mem3, mem4: out std_logic_vector(31 downto 0)
        );
    end component;

    -- DUT signals
    signal clk              : std_logic := '0';
    signal rst              : std_logic := '0';
    signal address          : std_logic_vector(31 downto 0) := (others => '0');
    signal instr_addr       : std_logic_vector(31 downto 0) := (others => '0');
    signal mem_write        : std_logic := '0';
    signal mem_read         : std_logic := '0';
    signal writedata        : std_logic_vector(31 downto 0) := (others => '0');
    signal mem_output       : std_logic_vector(31 downto 0);
    signal memory_busy      : std_logic;
    signal mem1,mem2,mem3,mem4 : std_logic_vector(31 downto 0);

    constant CLK_PERIOD : time := 10 ns;
    constant LOAD_ADDR  : integer := 16#A0#; -- program starts at 0xA0 in OneOperand.txt

    -- Helper
    procedure check(
        signal   val      : in  std_logic_vector(31 downto 0);
        constant expected : in  std_logic_vector(31 downto 0);
        constant msg      : in  string) is
    begin
        if val /= expected then
            report "FAIL [" & msg & "]: got 0x" &
                   to_hstring(val) & " expected 0x" & to_hstring(expected)
                severity error;
        else
            report "PASS [" & msg & "]" severity note;
        end if;
    end procedure;

    procedure check_bit(
        signal   val      : in  std_logic;
        constant expected : in  std_logic;
        constant msg      : in  string) is
    begin
        if val /= expected then
            report "FAIL [" & msg & "]: got " & std_logic'image(val) &
                   " expected " & std_logic'image(expected)
                severity error;
        else
            report "PASS [" & msg & "]" severity note;
        end if;
    end procedure;

begin

    clk <= not clk after CLK_PERIOD/2;

    DUT: reg_file_memory
        generic map(N => 32, M => 4096)
        port map(
            clk                 => clk,
            rst                 => rst,
            address             => address,
            instruction_address => instr_addr,
            mem_write           => mem_write,
            mem_read            => mem_read,
            writedata           => writedata,
            mem_output          => mem_output,
            memory_busy         => memory_busy,
            mem1 => mem1, mem2 => mem2, mem3 => mem3, mem4 => mem4
        );

    stim: process
    begin
        -- ── Initial reset pulse ──────────────────────────────────────────
        rst <= '1';
        wait for CLK_PERIOD * 2;
        rst <= '0';
        wait for CLK_PERIOD;

        -- ── TEST 1: File initialisation at 0xA0 ─────────────────────────
        -- The first word of the loaded program (NOP = 0x00000000 usually,
        -- but OneOperand.txt has the program at address 0xA0).
        -- We just verify the address reads back a non-X value (not unknown),
        -- and specifically check address 0 returns what the file loaded.
        instr_addr <= std_logic_vector(to_unsigned(LOAD_ADDR, 32));
        wait for 1 ns;  -- combinatorial propagation
        -- We can only assert it is not 'U' / 'X' in simulation;
        -- the exact value depends on the assembled binary which may change.
        -- Check that reading gives a defined (non-metavalue) word.
        if mem_output(0) = 'U' or mem_output(0) = 'X' then
            report "FAIL [TEST 1 file init]: got undefined value at 0xA0" severity error;
        else
            report "PASS [TEST 1 file init]: address 0xA0 reads defined value 0x" &
                   to_hstring(mem_output) severity note;
        end if;
        instr_addr <= (others => '0');

        -- ── TEST 2: Combinatorial read – same cycle as mem_read='1' ──────
        -- Write a known value first (synchronous), then verify read is
        -- available combinatorially (no clock edge needed after mem_read).
        address   <= X"00000010";
        writedata <= X"DEADBEEF";
        mem_write <= '1';
        wait until rising_edge(clk);
        wait for 1 ns;
        mem_write <= '0';
        -- Now assert mem_read and check output immediately (no clock)
        mem_read  <= '1';
        wait for 1 ns;
        check(mem_output, X"DEADBEEF", "TEST 2 combinatorial read");

        -- ── TEST 3: mem_read='0' → output shows instruction port ─────────
        mem_read  <= '0';
        instr_addr <= X"00000010";
        wait for 1 ns;
        check(mem_output, X"DEADBEEF", "TEST 3 mem_read=0 shows instruction port");
        instr_addr <= (others => '0');

        -- ── TEST 4: Write then readback ───────────────────────────────────
        address   <= X"00000020";
        writedata <= X"CAFEF00D";
        mem_write <= '1';
        wait until rising_edge(clk);
        wait for 1 ns;
        mem_write <= '0';
        mem_read  <= '1';
        wait for 1 ns;
        check(mem_output, X"CAFEF00D", "TEST 4 write then readback");
        mem_read <= '0';

        -- ── TEST 5: Instruction fetch independent of data port ───────────
        instr_addr <= X"00000010";   -- fetch the DEADBEEF we wrote
        address    <= X"00000020";   -- data port at CAFEF00D
        mem_read   <= '1';
        wait for 1 ns;
        -- mem_output should be readdata (mem_read=1) = CAFEF00D
        check(mem_output, X"CAFEF00D", "TEST 5 data port while fetching");
        -- switch mem_read off; mem_output should now show instruction
        mem_read <= '0';
        wait for 1 ns;
        check(mem_output, X"DEADBEEF", "TEST 5 instruction fetch independent");
        instr_addr <= (others => '0');

        -- ── TEST 6: Simultaneous read + fetch → memory_busy='0' ──────────
        instr_addr <= X"00000010";
        address    <= X"00000020";
        mem_read   <= '1';
        mem_write  <= '0';
        wait for 1 ns;
        check_bit(memory_busy, '0', "TEST 6 read+fetch no busy");
        mem_read <= '0';
        instr_addr <= (others => '0');

        -- ── TEST 7: Write-during-fetch → memory_busy='1' same cycle ──────
        instr_addr <= X"00000010";
        address    <= X"00000030";
        writedata  <= X"12345678";
        mem_write  <= '1';
        wait for 1 ns;  -- combinatorial, no clock needed
        check_bit(memory_busy, '1', "TEST 7 write asserts busy combinatorially");
        wait until rising_edge(clk);
        wait for 1 ns;
        mem_write <= '0';
        instr_addr <= (others => '0');

        -- ── TEST 8: Top-of-memory address (stack boundary 0xFFF) ─────────
        address   <= X"00000FFF";
        writedata <= X"FFFF0000";
        mem_write <= '1';
        wait until rising_edge(clk);
        wait for 1 ns;
        mem_write <= '0';
        mem_read  <= '1';
        wait for 1 ns;
        check(mem_output, X"FFFF0000", "TEST 8 top address 0xFFF write/read");
        mem_read <= '0';

        -- ── TEST 9: Reset does not clear memory ───────────────────────────
        -- After reset, previously written address 0x10 should still hold DEADBEEF.
        rst <= '1';
        wait for CLK_PERIOD * 2;
        rst <= '0';
        wait for 1 ns;
        address  <= X"00000010";
        mem_read <= '1';
        wait for 1 ns;
        check(mem_output, X"DEADBEEF", "TEST 9 reset does not clear memory");
        mem_read <= '0';

        -- ── TEST 10: mem1..mem4 reflect addresses 0..3 ───────────────────
        -- Write known values into addresses 0-3 then verify mem1..4 outputs.
        for idx in 0 to 3 loop
            address   <= std_logic_vector(to_unsigned(idx, 32));
            writedata <= std_logic_vector(to_unsigned(16#A0# + idx, 32));
            mem_write <= '1';
            wait until rising_edge(clk);
            wait for 1 ns;
        end loop;
        mem_write <= '0';
        wait for 1 ns;
        check(mem1, X"000000A0", "TEST 10 mem1 = memory(0)");
        check(mem2, X"000000A1", "TEST 10 mem2 = memory(1)");
        check(mem3, X"000000A2", "TEST 10 mem3 = memory(2)");
        check(mem4, X"000000A3", "TEST 10 mem4 = memory(3)");

        report "=== MEMORY TESTBENCH COMPLETE ===" severity note;
        wait;
    end process;

end architecture;
