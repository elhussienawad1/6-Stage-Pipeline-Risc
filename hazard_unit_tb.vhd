
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity hazard_unit_tb is
end entity hazard_unit_tb;

architecture sim of hazard_unit_tb is

    -- ── DUT signals ─────────────────────────────────────────────────
    signal reset             : std_logic := '0';

    signal id_ex1_mem_read   : std_logic := '0';
    signal ex1_ex2_mem_read  : std_logic := '0';
    signal ex1_ex2_mem_write : std_logic := '0';
    signal memread_q         : std_logic := '0';
    signal memwrite_q        : std_logic := '0';

    signal id_ex1_rd         : std_logic_vector(2 downto 0) := "000";
    signal if_id_rs1         : std_logic_vector(2 downto 0) := "000";
    signal if_id_rs2         : std_logic_vector(2 downto 0) := "000";

    signal do_branch         : std_logic := '0';
    signal call_signal       : std_logic := '0';
    signal int_signal        : std_logic := '0';

    signal rst_if_id         : std_logic;
    signal rst_id_ex1        : std_logic;
    signal rst_ex1_ex2       : std_logic;
    signal rst_ex2_mem       : std_logic;
    signal rst_mem_wb        : std_logic;

    signal enable_if_id      : std_logic;
    signal enable_id_ex1     : std_logic;
    signal enable_ex1_ex2    : std_logic;
    signal enable_ex2_mem    : std_logic;
    signal enable_mem_wb     : std_logic;

    signal pc_enable         : std_logic;

    -- ── Helper: clear every input back to its inactive state ────────
    procedure clear_inputs(
        signal r             : out std_logic;
        signal br            : out std_logic;
        signal cs            : out std_logic;
        signal ints          : out std_logic;
        signal idmr          : out std_logic;
        signal ex2mr         : out std_logic;
        signal ex2mw         : out std_logic;
        signal mr            : out std_logic;
        signal mw            : out std_logic;
        signal rd            : out std_logic_vector(2 downto 0);
        signal rs1           : out std_logic_vector(2 downto 0);
        signal rs2           : out std_logic_vector(2 downto 0)
    ) is
    begin
        r    <= '0';
        br   <= '0';
        cs   <= '0';
        ints <= '0';
        idmr <= '0';
        ex2mr<= '0';
        ex2mw<= '0';
        mr   <= '0';
        mw   <= '0';
        rd   <= "000";
        rs1  <= "000";
        rs2  <= "000";
    end procedure;

    -- ── Helper: compare outputs against expected pattern ────────────
    -- Order: rst_if_id, rst_id_ex1, rst_ex1_ex2, rst_ex2_mem, rst_mem_wb,
    --        en_if_id, en_id_ex1, en_ex1_ex2, en_ex2_mem, en_mem_wb, pc_en
    procedure check(
        test_name      : in string;
        exp_rst_ifid   : in std_logic;
        exp_rst_idex1  : in std_logic;
        exp_rst_ex1ex2 : in std_logic;
        exp_rst_ex2mem : in std_logic;
        exp_rst_memwb  : in std_logic;
        exp_en_ifid    : in std_logic;
        exp_en_idex1   : in std_logic;
        exp_en_ex1ex2  : in std_logic;
        exp_en_ex2mem  : in std_logic;
        exp_en_memwb   : in std_logic;
        exp_pc_en      : in std_logic;
        signal a_rst_ifid    : in std_logic;
        signal a_rst_idex1   : in std_logic;
        signal a_rst_ex1ex2  : in std_logic;
        signal a_rst_ex2mem  : in std_logic;
        signal a_rst_memwb   : in std_logic;
        signal a_en_ifid     : in std_logic;
        signal a_en_idex1    : in std_logic;
        signal a_en_ex1ex2   : in std_logic;
        signal a_en_ex2mem   : in std_logic;
        signal a_en_memwb    : in std_logic;
        signal a_pc_en       : in std_logic
    ) is
    begin
        assert a_rst_ifid = exp_rst_ifid
            report test_name & ": rst_if_id mismatch" severity error;
        assert a_rst_idex1 = exp_rst_idex1
            report test_name & ": rst_id_ex1 mismatch" severity error;
        assert a_rst_ex1ex2 = exp_rst_ex1ex2
            report test_name & ": rst_ex1_ex2 mismatch" severity error;
        assert a_rst_ex2mem = exp_rst_ex2mem
            report test_name & ": rst_ex2_mem mismatch" severity error;
        assert a_rst_memwb = exp_rst_memwb
            report test_name & ": rst_mem_wb mismatch" severity error;
        assert a_en_ifid = exp_en_ifid
            report test_name & ": enable_if_id mismatch" severity error;
        assert a_en_idex1 = exp_en_idex1
            report test_name & ": enable_id_ex1 mismatch" severity error;
        assert a_en_ex1ex2 = exp_en_ex1ex2
            report test_name & ": enable_ex1_ex2 mismatch" severity error;
        assert a_en_ex2mem = exp_en_ex2mem
            report test_name & ": enable_ex2_mem mismatch" severity error;
        assert a_en_memwb = exp_en_memwb
            report test_name & ": enable_mem_wb mismatch" severity error;
        assert a_pc_en = exp_pc_en
            report test_name & ": pc_enable mismatch" severity error;
    end procedure;

begin

    -- ── DUT ─────────────────────────────────────────────────────────
    dut: entity work.hazard_unit
        port map (
            reset             => reset,
            id_ex1_mem_read   => id_ex1_mem_read,
            ex1_ex2_mem_read  => ex1_ex2_mem_read,
            ex1_ex2_mem_write => ex1_ex2_mem_write,
            memread_q         => memread_q,
            memwrite_q        => memwrite_q,
            id_ex1_rd         => id_ex1_rd,
            if_id_rs1         => if_id_rs1,
            if_id_rs2         => if_id_rs2,
            do_branch         => do_branch,
            call_signal       => call_signal,
            int_signal        => int_signal,
            rst_if_id         => rst_if_id,
            rst_id_ex1        => rst_id_ex1,
            rst_ex1_ex2       => rst_ex1_ex2,
            rst_ex2_mem       => rst_ex2_mem,
            rst_mem_wb        => rst_mem_wb,
            enable_if_id      => enable_if_id,
            enable_id_ex1     => enable_id_ex1,
            enable_ex1_ex2    => enable_ex1_ex2,
            enable_ex2_mem    => enable_ex2_mem,
            enable_mem_wb     => enable_mem_wb,
            pc_enable         => pc_enable
        );

    -- ── Stimulus ────────────────────────────────────────────────────
    stim: process
    begin
        ------------------------------------------------------------------
        -- TEST 1: idle - no hazard, no flush
        ------------------------------------------------------------------
        clear_inputs(reset, do_branch, call_signal, int_signal,
                     id_ex1_mem_read, ex1_ex2_mem_read, ex1_ex2_mem_write,
                     memread_q, memwrite_q,
                     id_ex1_rd, if_id_rs1, if_id_rs2);
        wait for 10 ns;
        check("T1 idle",
              '0','0','0','0','0',   -- rsts
              '1','1','1','1','1',   -- enables
              '1',                   -- pc_en
              rst_if_id, rst_id_ex1, rst_ex1_ex2, rst_ex2_mem, rst_mem_wb,
              enable_if_id, enable_id_ex1, enable_ex1_ex2,
              enable_ex2_mem, enable_mem_wb, pc_enable);

        ------------------------------------------------------------------
        -- TEST 2: reset asserted - everything flushed, PC held
        ------------------------------------------------------------------
        reset <= '1';
        wait for 10 ns;
        check("T2 reset",
              '1','1','1','1','1',
              '1','1','1','1','1',
              '0',
              rst_if_id, rst_id_ex1, rst_ex1_ex2, rst_ex2_mem, rst_mem_wb,
              enable_if_id, enable_id_ex1, enable_ex1_ex2,
              enable_ex2_mem, enable_mem_wb, pc_enable);
        reset <= '0';
        wait for 10 ns;

        ------------------------------------------------------------------
        -- TEST 3: taken branch - flush IF/ID, ID/EX1, EX1/EX2, hold PC
        ------------------------------------------------------------------
        do_branch <= '1';
        wait for 10 ns;
        check("T3 branch",
              '1','1','1','0','0',
              '1','1','1','1','1',
              '0',
              rst_if_id, rst_id_ex1, rst_ex1_ex2, rst_ex2_mem, rst_mem_wb,
              enable_if_id, enable_id_ex1, enable_ex1_ex2,
              enable_ex2_mem, enable_mem_wb, pc_enable);
        do_branch <= '0';
        wait for 10 ns;

        ------------------------------------------------------------------
        -- TEST 4: CALL - flush IF/ID only, hold PC
        ------------------------------------------------------------------
        call_signal <= '1';
        wait for 10 ns;
        check("T4 CALL",
              '1','0','0','0','0',
              '1','1','1','1','1',
              '0',
              rst_if_id, rst_id_ex1, rst_ex1_ex2, rst_ex2_mem, rst_mem_wb,
              enable_if_id, enable_id_ex1, enable_ex1_ex2,
              enable_ex2_mem, enable_mem_wb, pc_enable);
        call_signal <= '0';
        wait for 10 ns;

        ------------------------------------------------------------------
        -- TEST 5: INT - same shape as CALL
        ------------------------------------------------------------------
        int_signal <= '1';
        wait for 10 ns;
        check("T5 INT",
              '1','0','0','0','0',
              '1','1','1','1','1',
              '0',
              rst_if_id, rst_id_ex1, rst_ex1_ex2, rst_ex2_mem, rst_mem_wb,
              enable_if_id, enable_id_ex1, enable_ex1_ex2,
              enable_ex2_mem, enable_mem_wb, pc_enable);
        int_signal <= '0';
        wait for 10 ns;

        ------------------------------------------------------------------
        -- TEST 6: structural hazard preemptive - mem op in EX2.
        --   Only PC should stall; no flush this cycle.
        ------------------------------------------------------------------
        ex1_ex2_mem_read <= '1';
        wait for 10 ns;
        check("T6 ex2 mem_read",
              '0','0','0','0','0',
              '1','1','1','1','1',
              '0',
              rst_if_id, rst_id_ex1, rst_ex1_ex2, rst_ex2_mem, rst_mem_wb,
              enable_if_id, enable_id_ex1, enable_ex1_ex2,
              enable_ex2_mem, enable_mem_wb, pc_enable);
        ex1_ex2_mem_read <= '0';

        ex1_ex2_mem_write <= '1';
        wait for 10 ns;
        check("T6b ex2 mem_write",
              '0','0','0','0','0',
              '1','1','1','1','1',
              '0',
              rst_if_id, rst_id_ex1, rst_ex1_ex2, rst_ex2_mem, rst_mem_wb,
              enable_if_id, enable_id_ex1, enable_ex1_ex2,
              enable_ex2_mem, enable_mem_wb, pc_enable);
        ex1_ex2_mem_write <= '0';
        wait for 10 ns;

        ------------------------------------------------------------------
        -- TEST 7: structural hazard active - mem op in MEM.
        --   PC stalled AND IF/ID flushed (fetch was doomed).
        ------------------------------------------------------------------
        memread_q <= '1';
        wait for 10 ns;
        check("T7 MEM read",
              '1','0','0','0','0',
              '1','1','1','1','1',
              '0',
              rst_if_id, rst_id_ex1, rst_ex1_ex2, rst_ex2_mem, rst_mem_wb,
              enable_if_id, enable_id_ex1, enable_ex1_ex2,
              enable_ex2_mem, enable_mem_wb, pc_enable);
        memread_q <= '0';

        memwrite_q <= '1';
        wait for 10 ns;
        check("T7b MEM write",
              '1','0','0','0','0',
              '1','1','1','1','1',
              '0',
              rst_if_id, rst_id_ex1, rst_ex1_ex2, rst_ex2_mem, rst_mem_wb,
              enable_if_id, enable_id_ex1, enable_ex1_ex2,
              enable_ex2_mem, enable_mem_wb, pc_enable);
        memwrite_q <= '0';
        wait for 10 ns;

        ------------------------------------------------------------------
        -- TEST 8: load-use - load (R3) in EX1, dep in ID reads R3 as rs1.
        --   Hold PC, freeze IF/ID, bubble into EX1.
        ------------------------------------------------------------------
        id_ex1_mem_read <= '1';
        id_ex1_rd       <= "011";
        if_id_rs1       <= "011";
        if_id_rs2       <= "101";
        wait for 10 ns;
        check("T8 load-use rs1",
              '0','1','0','0','0',
              '0','1','1','1','1',
              '0',
              rst_if_id, rst_id_ex1, rst_ex1_ex2, rst_ex2_mem, rst_mem_wb,
              enable_if_id, enable_id_ex1, enable_ex1_ex2,
              enable_ex2_mem, enable_mem_wb, pc_enable);

        ------------------------------------------------------------------
        -- TEST 9: load-use on rs2 path
        ------------------------------------------------------------------
        if_id_rs1 <= "111";
        if_id_rs2 <= "011";
        wait for 10 ns;
        check("T9 load-use rs2",
              '0','1','0','0','0',
              '0','1','1','1','1',
              '0',
              rst_if_id, rst_id_ex1, rst_ex1_ex2, rst_ex2_mem, rst_mem_wb,
              enable_if_id, enable_id_ex1, enable_ex1_ex2,
              enable_ex2_mem, enable_mem_wb, pc_enable);

        ------------------------------------------------------------------
        -- TEST 10: load-use, no register match - no stall
        ------------------------------------------------------------------
        if_id_rs1 <= "100";
        if_id_rs2 <= "101";
        wait for 10 ns;
        check("T10 load, no dep",
              '0','0','0','0','0',
              '1','1','1','1','1',
              '1',
              rst_if_id, rst_id_ex1, rst_ex1_ex2, rst_ex2_mem, rst_mem_wb,
              enable_if_id, enable_id_ex1, enable_ex1_ex2,
              enable_ex2_mem, enable_mem_wb, pc_enable);

        ------------------------------------------------------------------
        -- TEST 11: load into R0 (zero reg) - dep reads R0 - NO stall.
        --   Only meaningful if your ISA hardwires R0=0.  If not, remove
        --   the /= "000" guard in the DUT and this test will fail.
        ------------------------------------------------------------------
        id_ex1_rd <= "000";
        if_id_rs1 <= "000";
        if_id_rs2 <= "010";
        wait for 10 ns;
        check("T11 load R0 (no stall)",
              '0','0','0','0','0',
              '1','1','1','1','1',
              '1',
              rst_if_id, rst_id_ex1, rst_ex1_ex2, rst_ex2_mem, rst_mem_wb,
              enable_if_id, enable_id_ex1, enable_ex1_ex2,
              enable_ex2_mem, enable_mem_wb, pc_enable);
        id_ex1_mem_read <= '0';
        id_ex1_rd <= "000";
        if_id_rs1 <= "000";
        if_id_rs2 <= "000";
        wait for 10 ns;

        ------------------------------------------------------------------
        -- TEST 12: combined - branch wins over load-use
        --   (branch flushes EX1, so the load-use detection is moot)
        ------------------------------------------------------------------
        id_ex1_mem_read <= '1';
        id_ex1_rd       <= "010";
        if_id_rs1       <= "010";
        do_branch       <= '1';
        wait for 10 ns;
        -- Branch path flushes IF/ID + ID/EX1 + EX1/EX2; load-use also
        -- wants rst_id_ex1 and enable_if_id=0 / pc_enable=0.  The OR of
        -- both gives: rst_if_id=1, rst_id_ex1=1, rst_ex1_ex2=1,
        -- enable_if_id=0, pc_enable=0.
        check("T12 branch + load-use",
              '1','1','1','0','0',
              '0','1','1','1','1',
              '0',
              rst_if_id, rst_id_ex1, rst_ex1_ex2, rst_ex2_mem, rst_mem_wb,
              enable_if_id, enable_id_ex1, enable_ex1_ex2,
              enable_ex2_mem, enable_mem_wb, pc_enable);
        do_branch <= '0';
        id_ex1_mem_read <= '0';
        wait for 10 ns;

        ------------------------------------------------------------------
        -- TEST 13: mem op in EX2 AND in MEM simultaneously
        --   (back-to-back memory ops).  MEM-stage rule wins for flush;
        --   PC stalls either way.
        ------------------------------------------------------------------
        ex1_ex2_mem_read <= '1';
        memread_q        <= '1';
        wait for 10 ns;
        check("T13 EX2+MEM mem",
              '1','0','0','0','0',
              '1','1','1','1','1',
              '0',
              rst_if_id, rst_id_ex1, rst_ex1_ex2, rst_ex2_mem, rst_mem_wb,
              enable_if_id, enable_id_ex1, enable_ex1_ex2,
              enable_ex2_mem, enable_mem_wb, pc_enable);
        ex1_ex2_mem_read <= '0';
        memread_q        <= '0';
        wait for 10 ns;

        ------------------------------------------------------------------
        -- TEST 14: reset overrides everything
        ------------------------------------------------------------------
        do_branch <= '1';
        memread_q <= '1';
        id_ex1_mem_read <= '1';
        id_ex1_rd <= "010";
        if_id_rs1 <= "010";
        reset <= '1';
        wait for 10 ns;
        check("T14 reset overrides",
              '1','1','1','1','1',
              '1','1','1','1','1',
              '0',
              rst_if_id, rst_id_ex1, rst_ex1_ex2, rst_ex2_mem, rst_mem_wb,
              enable_if_id, enable_id_ex1, enable_ex1_ex2,
              enable_ex2_mem, enable_mem_wb, pc_enable);
        clear_inputs(reset, do_branch, call_signal, int_signal,
                     id_ex1_mem_read, ex1_ex2_mem_read, ex1_ex2_mem_write,
                     memread_q, memwrite_q,
                     id_ex1_rd, if_id_rs1, if_id_rs2);
        wait for 10 ns;

        report "==== hazard_unit_tb finished ====" severity note;
        wait;
    end process;

end architecture sim;