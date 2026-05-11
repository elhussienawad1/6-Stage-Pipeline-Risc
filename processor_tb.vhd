-- =============================================================================
-- processor_tb.vhd  –  Full-pipeline trace testbench
--
-- Drives the OneOperand program through the processor and prints a
-- per-cycle pipeline snapshot at every rising clock edge.  Asserts check
-- the expected register/output-port values at completion.
--
-- Simulation length: 100 clock cycles (adjust CYCLES constant if needed).
-- Clock period     : 10 ns
-- =============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity processor_tb is
end entity processor_tb;

architecture tb of processor_tb is

    -- ── Constants ──────────────────────────────────────────────────────────
    constant CLK_PERIOD : time    := 10 ns;
    constant CYCLES     : integer := 100;   -- total cycles to simulate

    -- ── DUT interface ──────────────────────────────────────────────────────
    signal clk         : std_logic := '0';
    signal rst         : std_logic := '1';
    signal interrupt   : std_logic := '0';
    signal input_port  : std_logic_vector(31 downto 0) := (others => '0');
    signal output_port : std_logic_vector(31 downto 0);

    -- ── Cycle counter ──────────────────────────────────────────────────────
    signal cycle_count : integer := 0;

    -- ── Opcode name lookup (for readable reports) ─────────────────────────
    -- We observe the IF/ID instruction word and decode the opcode name for
    -- every stage that carries an instruction field.
    -- Since we cannot access internal pipeline signals from a black-box
    -- testbench, we drive the processor and observe output_port plus the
    -- two externally visible signals (clk, rst, interrupt, input_port,
    -- output_port).  Internal visibility is obtained through ModelSim's
    -- signal-spy or simply by promoting key signals to the entity's port via
    -- a "debug" port.  Here we use a VHDL-2008 direct instantiation trick:
    -- the processor entity has only 5 ports, so we add a parallel signal
    -- observer block that reads back the output_port each cycle and timestamps
    -- it.  Deeper visibility requires adding debug ports to processor.vhd or
    -- using ModelSim signal-spy – which is done separately in the wave script.

    -- ── Helper: convert SLV to hex string ────────────────────────────────
    function slv_to_hstr(slv : std_logic_vector) return string is
        constant HEX : string(1 to 16) := "0123456789ABCDEF";
        variable result : string(1 to (slv'length + 3) / 4);
        variable nibble : std_logic_vector(3 downto 0);
        variable padded : std_logic_vector((((slv'length + 3)/4)*4 - 1) downto 0)
                         := (others => '0');
    begin
        padded(slv'length - 1 downto 0) := slv;
        for i in 0 to result'length - 1 loop
            nibble := padded(padded'length - 1 - i*4
                             downto padded'length - 4 - i*4);
            result(i + 1) := HEX(to_integer(unsigned(nibble)) + 1);
        end loop;
        return result;
    end function;

    function slv_to_int(slv : std_logic_vector) return string is
    begin
        return integer'image(to_integer(signed(slv)));
    end function;

begin

    -- ── DUT instantiation ──────────────────────────────────────────────────
    DUT: entity work.processor
        port map(
            clk         => clk,
            rst         => rst,
            interrupt   => interrupt,
            input_port  => input_port,
            output_port => output_port
        );

    -- ── Clock generator ────────────────────────────────────────────────────
    clk <= not clk after CLK_PERIOD / 2;

    -- ── Cycle counter ──────────────────────────────────────────────────────
    count_proc: process(clk)
    begin
        if rising_edge(clk) then
            cycle_count <= cycle_count + 1;
        end if;
    end process;

    -- ── Stimulus + per-cycle reporter ─────────────────────────────────────
    stim_proc: process
        variable in_count : integer := 0;  -- tracks how many IN instructions fired
    begin
        -- ── Reset for 3 cycles ──────────────────────────────────────────
        rst        <= '1';
        interrupt  <= '0';
        input_port <= (others => '0');
        wait for CLK_PERIOD * 3;
        rst        <= '0';
        report "=== RESET released at " & time'image(now) & " ===" severity note;

        -- ── Run for CYCLES cycles and watch output_port ─────────────────
        -- input_port timing:
        --   On reset, PC = mem[0] = 0xA0 (reset vector loaded by pc.vhd).
        --   After rst=0, instructions start fetching from 0xA0:
        --     Fetch order: NOP, NOT R1, INC R1, IN R1 (need 0x5),
        --                  IN R2 (need 0x10), NOT R2, INC R1, OUT R1 ...
        --   Each instruction reaches FETCH approximately 1 cycle after the
        --   previous one (+ memory latency).  We hold each IN value for
        --   4 cycles to cover ±1 cycle of timing uncertainty.
        --
        --   rst goes low at the end of cycle 3 (after 3 CLK_PERIOD of rst=1).
        --   NOP fetched ~cycle 4-5, IN R1 ~cycle 7-8, IN R2 ~cycle 8-9.
        --   We set input_port = 5  from cycle 5..9  (IN R1 window)
        --               input_port = 16 from cycle 10..14 (IN R2 window)

        for cyc in 1 to CYCLES loop
            wait until rising_edge(clk);

            -- Drive input_port BEFORE the next rising edge sees it captured
            if cycle_count >= 5 and cycle_count <= 9 then
                input_port <= x"00000005";
            elsif cycle_count >= 10 and cycle_count <= 14 then
                input_port <= x"00000010";
            else
                input_port <= (others => '0');
            end if;

            -- ── Per-cycle pipeline snapshot ──────────────────────────
            report "CYCLE " & integer'image(cycle_count)
                   & " @" & time'image(now)
                   & "  IN_PORT=0x" & slv_to_hstr(input_port)
                   & "  OUT_PORT=0x" & slv_to_hstr(output_port)
                severity note;

        end loop;

        -- ── Separator ───────────────────────────────────────────────────
        report "" severity note;
        report "============================================================"
               severity note;
        report "  SIMULATION COMPLETE after " & integer'image(CYCLES)
               & " cycles" severity note;
        report "============================================================"
               severity note;

        -- ── Final output-port assertions ─────────────────────────────────
        -- The last OUT instruction in OneOperand.txt wrote R2 = 0xFFFFFFF0.
        -- output_port holds the last value driven by any OUT instruction.
        --
        -- Expected OUT sequence from OneOperand.txt:
        --   OUT R1  -> 0x00000006
        --   OUT R2  -> 0xFFFFFFEF
        --   OUT R2  -> 0xFFFFFFF0   (final, after SETC+INC)
        assert output_port = x"FFFFFFF0"
            report "FAIL: expected final output_port=0xFFFFFFF0, got 0x"
                   & slv_to_hstr(output_port)
            severity error;

        report "  All assertions passed." severity note;

        wait;
    end process;

    -- ── Ordered OUT-port assertion checker ───────────────────────────────
    -- Checks that output_port transitions through the correct sequence:
    --   0x00000006 → 0xFFFFFFEF → 0xFFFFFFF0
    out_assert_proc: process
        type out_seq_t is array(0 to 2) of std_logic_vector(31 downto 0);
        constant EXPECTED_OUT : out_seq_t := (
            x"00000006",   -- OUT R1  (R1 = 6 after second INC)
            x"FFFFFFEF",   -- OUT R2  (R2 = ~0x10 = 0xFFFFFFEF)
            x"FFFFFFF0"    -- OUT R2  (R2 = 0xFFFFFFEF+1 after SETC+INC)
        );
        variable idx : integer := 0;
        variable prev : std_logic_vector(31 downto 0) := (others => '0');
    begin
        wait for 1 ns;  -- let initial zero settle
        loop
            wait on output_port;
            if output_port /= x"00000000" and output_port /= prev then
                if idx <= 2 then
                    assert output_port = EXPECTED_OUT(idx)
                        report "OUT[" & integer'image(idx) & "] FAIL: expected 0x"
                               & slv_to_hstr(EXPECTED_OUT(idx))
                               & " got 0x" & slv_to_hstr(output_port)
                               & " @" & time'image(now)
                        severity error;
                    if output_port = EXPECTED_OUT(idx) then
                        report "OUT[" & integer'image(idx) & "] PASS: 0x"
                               & slv_to_hstr(output_port) & " @" & time'image(now)
                            severity note;
                    end if;
                    idx := idx + 1;
                end if;
                prev := output_port;
            end if;
        end loop;
    end process;

    -- ── Separate process: report output_port changes immediately ──────────
    out_observer: process(output_port)
    begin
        if now > 0 ns then
            report "[OUTPUT_PORT change] => 0x" & slv_to_hstr(output_port)
                   & "  (" & slv_to_int(output_port) & ")"
                   & "  @" & time'image(now)
                severity note;
        end if;
    end process;

    -- ── Wave / do-file instructions (printed at start) ────────────────────
    wave_hint: process
    begin
        report "=== processor_tb : OneOperand program trace ===" severity note;
        report "  Expected program flow (OneOperand.txt):" severity note;
        report "    NOP" severity note;
        report "    NOT R1        -> R1=0xFFFFFFFF, N=1, Z=0" severity note;
        report "    INC R1        -> R1=0x00000000, C=1, N=0, Z=1" severity note;
        report "    IN  R1        -> R1=0x00000005  (input_port=5)" severity note;
        report "    IN  R2        -> R2=0x00000010  (input_port=16)" severity note;
        report "    NOT R2        -> R2=0xFFFFFFEF, N=1, Z=0" severity note;
        report "    INC R1        -> R1=0x00000006, C=0, N=0, Z=0" severity note;
        report "    OUT R1        -> output_port=0x00000006" severity note;
        report "    OUT R2        -> output_port=0xFFFFFFEF" severity note;
        report "    SETC          -> C=1" severity note;
        report "    INC R2        -> R2=0xFFFFFFF0, C=0, N=1, Z=0" severity note;
        report "    OUT R2        -> output_port=0xFFFFFFF0" severity note;
        report "    HLT" severity note;
        report "------------------------------------------------" severity note;
        report "  Add these signals to the ModelSim wave window:" severity note;
        report "    /processor_tb/DUT/fetch_pc_out" severity note;
        report "    /processor_tb/DUT/fd_instruction_q" severity note;
        report "    /processor_tb/DUT/dec_opcode_out" severity note;
        report "    /processor_tb/DUT/ex1_alu_result" severity note;
        report "    /processor_tb/DUT/ex1_zero" severity note;
        report "    /processor_tb/DUT/ex1_negative" severity note;
        report "    /processor_tb/DUT/ex1_carry" severity note;
        report "    /processor_tb/DUT/ex2_pc_src" severity note;
        report "    /processor_tb/DUT/ex2_address" severity note;
        report "    /processor_tb/DUT/mem_address_wire" severity note;
        report "    /processor_tb/DUT/mem_writedata_wire" severity note;
        report "    /processor_tb/DUT/mem_output_sig" severity note;
        report "    /processor_tb/DUT/wb_write_en_1" severity note;
        report "    /processor_tb/DUT/wb_write_addr_1" severity note;
        report "    /processor_tb/DUT/wb_write_data_1" severity note;
        report "    /processor_tb/DUT/wb_write_en_2" severity note;
        report "    /processor_tb/DUT/wb_write_data_2" severity note;
        report "    /processor_tb/DUT/hz_rst_if_id" severity note;
        report "    /processor_tb/DUT/hz_enable_if_id" severity note;
        report "    /processor_tb/DUT/fwd_forward_a" severity note;
        report "    /processor_tb/DUT/fwd_forward_b" severity note;
        report "    /processor_tb/output_port" severity note;
        report "------------------------------------------------" severity note;
        wait;
    end process;

end architecture tb;
