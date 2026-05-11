library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fetch is
port (
    -- fetch section
    input_port          : in  std_logic_vector(31 downto 0);
    clk                 : in  std_logic;
    reset, interrupt    : in  std_logic;
    -- input from execute 2 section
    pc_plus_immediate   : in  std_logic_vector(31 downto 0);
    do_branch           : in  std_logic;
    -- input from hazard detection
    pc_enable           : in  std_logic;   --low to stall
    -- output to if/id reg
    instruction_d       : out std_logic_vector(31 downto 0);
    pc_d                : out std_logic_vector(31 downto 0);  --PC+1
    inputport_d_if_id   : out std_logic_vector(31 downto 0);
    -- from memory (replaces internal reg_file_memory instantiation)
    instruction_in      : in  std_logic_vector(31 downto 0);
    memory_busy         : in  std_logic;
    -- expose PC so top level routes it to memory instruction_address port
    pc_out              : out std_logic_vector(31 downto 0);
    -- interrupt/reset vectors (from memory locations 0..3)
    mem1                : in  std_logic_vector(31 downto 0);
    mem2                : in  std_logic_vector(31 downto 0);
    mem3                : in  std_logic_vector(31 downto 0);
    mem4                : in  std_logic_vector(31 downto 0);
    -- RET/RTI: load PC from memory read result
    pc_src_q            : in  std_logic;
    -- from id_ex1 reg
    call_signal         : in  std_logic;
    immediate_input     : in  std_logic_vector(31 downto 0);
    int_signal          : in  std_logic;
    index               : in  std_logic  -- 0->INT0(mem3) & 1->INT1(mem4)
);
end entity;

architecture imp of fetch is

    component pc is
        port(
            Rst, Clk  : in  std_logic;
            enable    : in  std_logic;
            pc_src    : in  std_logic;
            d         : in  std_logic_vector(31 downto 0);
            mem1      : in  std_logic_vector(31 downto 0);
            q         : out std_logic_vector(31 downto 0)
        );
    end component;

    signal regular_pc        : std_logic_vector(31 downto 0);
    signal pc_plus_one       : std_logic_vector(31 downto 0);
    signal pc_component_d    : std_logic_vector(31 downto 0);
    signal pc_component_q    : std_logic_vector(31 downto 0);

    constant RESET_INSTR     : std_logic_vector(31 downto 0) := "10000" & X"000000" & "000";
    constant INTERRUPT_INSTR : std_logic_vector(31 downto 0) := "10011" & X"000000" & "100";

begin

    regular_pc <= pc_plus_immediate when do_branch = '1'
             else pc_plus_one;

    pc_component_d <= instruction_in  when pc_src_q    = '1'              -- RET / RTI: PC from memory
                 else immediate_input when call_signal  = '1'              -- CALL: PC = immediate
                 else mem2            when interrupt    = '1'              -- external interrupt vector
                 else mem3            when int_signal   = '1' and index = '0'  -- INT index 0 vector
                 else mem4            when int_signal   = '1' and index = '1'  -- INT index 1 vector
                 else regular_pc;

    pc_component: pc port map (
        reset, clk,
        pc_enable, pc_src_q,
        pc_component_d, mem1,
        pc_component_q
    );

    pc_plus_one       <= std_logic_vector(to_unsigned(1 + to_integer(unsigned(pc_component_q)), 32));
    pc_d              <= pc_plus_one;
    pc_out            <= pc_component_q;
    inputport_d_if_id <= input_port;

    instruction_d <= RESET_INSTR     when reset     = '1'
                else INTERRUPT_INSTR when interrupt  = '1'
                else instruction_in;

end architecture imp;
