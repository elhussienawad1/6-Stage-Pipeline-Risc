library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity hazard_unit is
    port (
        -- ── Global ────────────────────────────────────────────────────
        reset               : in  std_logic;
        id_ex1_mem_read     : in  std_logic;   -- LDD / POP  in EX1
        id_ex1_mem_write    : in  std_logic;   -- STD / PUSH / CALL / INT in EX1

        memread_q           : in  std_logic;   -- LDD / POP  in MEM
        memwrite_q          : in  std_logic;   -- STD / PUSH / CALL / INT in MEM
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
end entity hazard_unit;

-- =============================================================
architecture hazard_unit_imp of hazard_unit is
begin

    hazard_process : process (
        reset,
        do_branch,
        call_signal,     int_signal,
        id_ex1_mem_read, id_ex1_mem_write,
        memread_q,       memwrite_q
    )
    begin
        rst_if_id    <= '0';
        rst_id_ex1   <= '0';
        rst_ex1_ex2  <= '0';
        rst_ex2_mem  <= '0';
        rst_mem_wb   <= '0';

        enable_if_id   <= '1';
        enable_id_ex1  <= '1';
        enable_ex1_ex2 <= '1';
        enable_ex2_mem <= '1';
        enable_mem_wb  <= '1';

        pc_enable <= '1';

        if reset = '1' then
            rst_if_id   <= '1';
            rst_id_ex1  <= '1';
            rst_ex1_ex2 <= '1';
            rst_ex2_mem <= '1';
            rst_mem_wb  <= '1';
            pc_enable   <= '0';

        elsif do_branch = '1' then
            rst_if_id   <= '1';
            rst_id_ex1  <= '1';
            rst_ex1_ex2 <= '1';
            pc_enable   <= '0';
        end if;

        -- unaffected.
        if call_signal = '1' or int_signal = '1' then
            rst_if_id <= '1';
            pc_enable <= '0';
        end if;


        if memread_q = '1' or memwrite_q = '1' then
            rst_if_id <= '1';
            pc_enable <= '0';
        end if;
-- needs fix
        if memread_q = '1' then
            enable_if_id  <= '0';
            enable_id_ex1 <= '0';
            rst_ex1_ex2   <= '1';
        end if;

        if id_ex1_mem_read = '1' or id_ex1_mem_write = '1' then
            pc_enable <= '0';
        end if;

    end process;

end architecture hazard_unit_imp;
