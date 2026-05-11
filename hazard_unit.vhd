library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity hazard_unit is
    port (
        -- ── Global ────────────────────────────────────────────────────
        reset               : in  std_logic;

        -- ── Memory control from each pipeline register output ────────
        -- (each signal reflects the instruction CURRENTLY in that stage)
        id_ex1_mem_read     : in  std_logic;   -- load in EX1 (for load-use)
        ex1_ex2_mem_read    : in  std_logic;   -- mem op in EX2 (preemptive)
        ex1_ex2_mem_write   : in  std_logic;
        memread_q           : in  std_logic;   -- mem op in MEM (active)
        memwrite_q          : in  std_logic;

        -- ── Load-use data-hazard detection ──────────────────────────
        -- Compare the load's destination register (currently in EX1)
        -- against the ID-stage instruction's source registers.
        id_ex1_rd           : in  std_logic_vector(2 downto 0);
        if_id_rs1           : in  std_logic_vector(2 downto 0);
        if_id_rs2           : in  std_logic_vector(2 downto 0);

        -- ── Control flow ─────────────────────────────────────────────
        do_branch           : in  std_logic;   -- branch taken (EX2)
        call_signal         : in  std_logic;
        int_signal          : in  std_logic;

        -- ── Pipeline register flushes ────────────────────────────────
        rst_if_id           : out std_logic;
        rst_id_ex1          : out std_logic;
        rst_ex1_ex2         : out std_logic;
        rst_ex2_mem         : out std_logic;
        rst_mem_wb          : out std_logic;

        -- ── Pipeline register enables (stall when '0') ───────────────
        enable_if_id        : out std_logic;
        enable_id_ex1       : out std_logic;
        enable_ex1_ex2      : out std_logic;
        enable_ex2_mem      : out std_logic;
        enable_mem_wb       : out std_logic;

        -- ── PC enable ────────────────────────────────────────────────
        pc_enable           : out std_logic
    );
end entity hazard_unit;

-- =============================================================
architecture hazard_unit_imp of hazard_unit is
    signal load_use_hazard : std_logic;
begin

    -- ── Combinational load-use detector ─────────────────────────────
    -- True iff there is a load in EX1 whose destination matches a source
    -- of the instruction currently in ID.  R0 ("000") is excluded since
    -- it's never a real dependency.
    load_use_hazard <= '1' when id_ex1_mem_read = '1'
                            and id_ex1_rd /= "000"
                            and (id_ex1_rd = if_id_rs1 or
                                 id_ex1_rd = if_id_rs2)
                       else '0';

    hazard_process : process (
        reset, do_branch, call_signal, int_signal,
        ex1_ex2_mem_read, ex1_ex2_mem_write,
        memread_q, memwrite_q,
        load_use_hazard
    )
    begin
        -- ── Defaults: no stall, no flush ────────────────────────────
        rst_if_id      <= '0';
        rst_id_ex1     <= '0';
        rst_ex1_ex2    <= '0';
        rst_ex2_mem    <= '0';
        rst_mem_wb     <= '0';

        enable_if_id   <= '1';
        enable_id_ex1  <= '1';
        enable_ex1_ex2 <= '1';
        enable_ex2_mem <= '1';
        enable_mem_wb  <= '1';

        pc_enable      <= '1';

        -- (1) Reset: flush every pipeline register, hold PC.
        --     Reset is master-dominant: nothing else can drive outputs.
        if reset = '1' then
            rst_if_id   <= '1';
            rst_id_ex1  <= '1';
            rst_ex1_ex2 <= '1';
            rst_ex2_mem <= '1';
            rst_mem_wb  <= '1';
            pc_enable   <= '0';

        else
            -- (2) Taken branch resolved in EX2:
            --     flush the three wrongly-fetched stages behind it
            if do_branch = '1' then
                rst_if_id   <= '1';
                rst_id_ex1  <= '1';
                rst_ex1_ex2 <= '1';
                pc_enable   <= '0';
            end if;

            -- (3) CALL / INT: new PC is supplied by decode/exception logic,
            --     so the IF slot from this cycle is garbage
            if call_signal = '1' or int_signal = '1' then
                rst_if_id <= '1';
                pc_enable <= '0';
            end if;

            -- (4) Memory structural hazard - preemptive (1 cycle out):
            --     mem op in EX2 will own the memory port next cycle, so
            --     freeze PC now to avoid a wasted fetch
            if ex1_ex2_mem_read = '1' or ex1_ex2_mem_write = '1' then
                pc_enable <= '0';
            end if;

            -- (5) Memory structural hazard - active:
            --     MEM is using the memory port THIS cycle.
            --     IF couldn't have fetched a real instruction, so kill
            --     IF/ID and hold PC so we can re-fetch next cycle.
            if memread_q = '1' or memwrite_q = '1' then
                rst_if_id <= '1';
                pc_enable <= '0';
            end if;

            -- (6) Load-use data hazard:
            --     load in EX1, dependent in ID.
            --     Hold PC and IF/ID (dep stays in ID), and bubble into EX1
            --     by resetting ID/EX1.  Forwarding handles the rest next cycle.
            if load_use_hazard = '1' then
                pc_enable     <= '0';
                enable_if_id  <= '0';
                rst_id_ex1    <= '1';
            end if;
        end if;

    end process;

end architecture hazard_unit_imp;