library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fetch is
port (
    -- fetch section
    -- input to processor
    input_port          : in  std_logic_vector(31 downto 0);
    clk			: in  std_logic;
    reset, interrupt	: in  std_logic;  --overide 
    -- input from execute 2 section
    pc_plus_immediate   : in  std_logic_vector(31 downto 0);
    do_branch           : in  std_logic;
    -- input from hazard detection
    pc_enable           : in  std_logic;   --low to stall
    -- output to if/id reg
    instruction_d       : out std_logic_vector(31 downto 0);
    pc_d                : out std_logic_vector(31 downto 0);  --PC+1
    inputport_d_if_id   : out std_logic_vector(31 downto 0);

    -- memory section
    -- input from ex/mem reg for write data or addresses for memory access or control signals
    sp_q                : in  std_logic_vector(31 downto 0);
    pc1_q               : in  std_logic_vector(31 downto 0);
    alu_q               : in  std_logic_vector(31 downto 0);
    inputport_q         : in  std_logic_vector(31 downto 0);
    readdata1_q         : in  std_logic_vector(31 downto 0);
    readdata2_q         : in  std_logic_vector(31 downto 0);
    writeaddress1_q     : in  std_logic_vector(2 downto 0);
    writeaddress2_q     : in  std_logic_vector(2 downto 0);
    memtoreg_q          : in  std_logic;
    outputenable_q      : in  std_logic;
    regwrite1_q         : in  std_logic;
    regwrite2_q         : in  std_logic;
    inputenable_q       : in  std_logic;
    memwrite_q          : in  std_logic;
    memread_q           : in  std_logic;
    mem_add_src_q       : in  std_logic;  --SELECT <> SP AND ALU
    mem_data_src_q      : in  std_logic_vector(1 downto 0);
    sp_dec_q            : in  std_logic;
    pc_src_q            : in  std_logic;
    -- input from assembler
    offset              : in  std_logic_vector(31 downto 0);
    -- output to mem/wb reg
    memory_d            : out std_logic_vector(31 downto 0);
    alu_d               : out std_logic_vector(31 downto 0);
    inputport_d         : out std_logic_vector(31 downto 0);
    readdata1_d         : out std_logic_vector(31 downto 0);
    readdata2_d         : out std_logic_vector(31 downto 0);
    writeaddress1_d     : out std_logic_vector(2 downto 0);
    writeaddress2_d     : out std_logic_vector(2 downto 0);
    memtoreg_d          : out std_logic;
    outputenable_d      : out std_logic;
    regwrite1_d         : out std_logic;
    regwrite2_d         : out std_logic;
    inputenable_d       : out std_logic;
    -- input from decode
    call_signal         : in  std_logic;
    immediate_input     : in  std_logic_vector(31 downto 0);
    -- output sp and dec_sp for execute section
    ex_mem_sp           : out std_logic_vector(31 downto 0);
    ex_mem_sp_dec       : out std_logic;
    int_signal          : in  std_logic;
    index               : in  std_logic  -- 0->INT0(mem3) & 1->INT1(mem4)
);
end entity;

architecture imp of fetch is

    component reg_file_memory is
        port(
            clk, rst             : in  std_logic;
            address              : in  std_logic_vector(31 downto 0);
            instruction_address  : in  std_logic_vector(31 downto 0);
            mem_write, mem_read  : in  std_logic;
            writedata            : in  std_logic_vector(31 downto 0);
            mem_output           : out std_logic_vector(31 downto 0);
            mem1                 : out std_logic_vector(31 downto 0);
            mem2                 : out std_logic_vector(31 downto 0);
            mem3                 : out std_logic_vector(31 downto 0);
            mem4                 : out std_logic_vector(31 downto 0)
        );
    end component;

    component pc is
        port(
            Rst, Clk  : in  std_logic;
            enable    : in  std_logic;  --hazard unit
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
    signal mem_address       : std_logic_vector(31 downto 0);
    signal writedata         : std_logic_vector(31 downto 0);
    signal readdata          : std_logic_vector(31 downto 0);
    signal sp_or_alu         : std_logic_vector(31 downto 0);
    signal mem1, mem2, mem3, mem4 : std_logic_vector(31 downto 0);

    constant RESET_INSTR     : std_logic_vector(31 downto 0) := "10000" & X"000000" & "000";
    constant INTERRUPT_INSTR : std_logic_vector(31 downto 0) := "10011" & X"000000" & "100";

begin

    memory: reg_file_memory port map (
        clk, reset,
        mem_address, pc_component_q,
        memwrite_q, memread_q,
        writedata, readdata,
        mem1, mem2, mem3, mem4
    );

    regular_pc <= pc_plus_immediate when do_branch = '1'
             else pc_plus_one;

    pc_component_d <= readdata        when pc_src_q    = '1'              -- RET / RTI: PC from memory
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

    pc_plus_one <= std_logic_vector(to_unsigned(1 + to_integer(unsigned(pc_component_q)), 32));
    pc_d              <= pc_plus_one;
    inputport_d_if_id <= input_port;
    instruction_d <= RESET_INSTR     when reset     = '1'
                else INTERRUPT_INSTR when interrupt  = '1'
                else readdata;

    writedata <= pc1_q                                 when mem_data_src_q = "01"  -- CALL: PC+1
            else std_logic_vector(unsigned(pc1_q) - 1) when mem_data_src_q = "10"  -- INT:  PC
            else readdata2_q;                                                        -- PUSH: Rsrc1 ("00")
    --to exe
    ex_mem_sp     <= sp_q;
    ex_mem_sp_dec <= sp_dec_q;

    sp_or_alu   <= sp_q when mem_add_src_q = '1' else alu_q;
    mem_address <= std_logic_vector(
        (unsigned(offset) + unsigned(sp_or_alu)) mod (2**20)
    );

    --to MEM/WB register
    memory_d        <= readdata;
    alu_d           <= alu_q;
    inputport_d     <= inputport_q;
    readdata1_d     <= readdata1_q;
    readdata2_d     <= readdata2_q;
    writeaddress1_d <= writeaddress1_q;
    writeaddress2_d <= writeaddress2_q;
    memtoreg_d      <= memtoreg_q;
    outputenable_d  <= outputenable_q;
    regwrite1_d     <= regwrite1_q;
    regwrite2_d     <= regwrite2_q;
    inputenable_d   <= inputenable_q;

end architecture imp;