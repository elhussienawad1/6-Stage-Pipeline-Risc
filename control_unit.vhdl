library ieee;
use ieee.std_logic_1164.all;

entity control_unit is 
port(
    --INSTR(31-27)
    opcode: in std_logic_vector(4 downto 0); 
    
    mem_or_branch_pc,inc_pc:out std_logic;

    reg1_write,reg2_write: out std_logic;
    
    alu_src,alu_op,alu_passthrough,set_carry: out std_logic;
    restore_ccr,flag_enable,store_ccr: out std_logic;

    branch:out std_logic;
    branch_type:out std_logic_vector(1 downto 0);
    inc_sp,dec_sp: out std_logic;

    mem_addr_src,mem_data_src,mem_read,mem_write:out std_logic;

    output_enable,input_enable:out std_logic;
    mem_to_reg,reg_to_reg:out std_logic;

    clock_enable,interrupt_enable,reset:out std_logic

);

end control_unit;

architecture behavioral of control_unit is

    constant NOP : std_logic_vector(4 downto 0) := "00000";
    constant HLT : std_logic_vector(4 downto 0) := "00001";
    constant SETC : std_logic_vector(4 downto 0) := "00010";
    constant NOT_op : std_logic_vector(4 downto 0) := "00111";
    constant INC : std_logic_vector(4 downto 0) := "00100";
    constant OUT_op : std_logic_vector(4 downto 0) := "00101";
    constant IN_op : std_logic_vector(4 downto 0) := "00110";
    constant MOV : std_logic_vector(4 downto 0) := "01011";
    constant SWAP : std_logic_vector(4 downto 0) := "01000";
    constant ADD : std_logic_vector(4 downto 0) := "01001";
    constant SUB : std_logic_vector(4 downto 0) := "01110";
    constant AND_op : std_logic_vector(4 downto 0) := "01111";
    constant IADD : std_logic_vector(4 downto 0) := "01100";
    constant PUSH : std_logic_vector(4 downto 0) := "10001";
    constant POP : std_logic_vector(4 downto 0) := "10010";
    constant LDM : std_logic_vector(4 downto 0) := "10111";
    constant LDD : std_logic_vector(4 downto 0) := "10100";
    constant STD : std_logic_vector(4 downto 0) := "10101";
    constant JZ : std_logic_vector(4 downto 0) := "11010";
    constant JN : std_logic_vector(4 downto 0) := "11011";
    constant JC : std_logic_vector(4 downto 0) := "11000";
    constant JMP : std_logic_vector(4 downto 0) := "11001";
    constant CALL : std_logic_vector(4 downto 0) := "11110";
    constant RET : std_logic_vector(4 downto 0) := "11111";
    constant INT : std_logic_vector(4 downto 0) := "11100";
    constant RTI : std_logic_vector(4 downto 0) := "11101";
    constant RESET : std_logic_vector(4 downto 0) := "10000";
    constant INTERRUPT : std_logic_vector(4 downto 0) := "10011";

begin 

    decode_process: process(opcode)
    begin   
    mem_or_branch_pc <= '0';
    inc_pc <= '0';
    reg1_write <= '0';
    reg2_write <= '0';
    alu_src <= '0';
    alu_op <= '0';
    alu_passthrough <= '0';
    set_carry <= '0';
    restore_ccr <= '0';
    flag_enable <= '0';
    store_ccr <= '0';
    branch <= '0';
    branch_type <= "00";
    inc_sp <= '0';
    dec_sp <= '0';
    mem_addr_src <= '0';
    mem_data_src <= '0';
    mem_read <= '0';
    mem_write <= '0';
    output_enable <= '0';
    input_enable <= '0';
    mem_to_reg <= '0';
    reg_to_reg <= '0';
    clock_enable <= '1';
    interrupt_enable <= '0';
    reset <= '0';

case opcode is

        when NOP =>
            inc_pc      <= '1';

        when HLT =>
            null; -- clock_enable already '0' from defaults... wait, default is '1'
            clock_enable <= '0';

        when SETC =>
            set_carry    <= '1';
            flag_enable  <= '1';
            inc_pc       <= '1';

        when NOT_op =>
            reg1_write   <= '1';
            alu_src      <= '1';
            alu_op       <= '1';
            flag_enable  <= '1';
            inc_pc       <= '1';

        when INC =>
            reg1_write   <= '1';
            alu_src      <= '1';
            alu_op       <= '1';
            flag_enable  <= '1';
            inc_pc       <= '1';

        when OUT_op =>
            output_enable <= '1';
            inc_pc        <= '1';

        when IN_op =>
            input_enable  <= '1';
            inc_pc        <= '1';

        when MOV =>
            reg1_write   <= '1';
            alu_src      <= '1';
            alu_op       <= '1';
            alu_passthrough <= '1';
            inc_pc       <= '1';
            reg_to_reg   <= '1';

        when SWAP =>
            reg1_write   <= '1';
            reg2_write   <= '1';
            alu_op       <= '1';
            inc_pc       <= '1';
            reg_to_reg   <= '1';

        when ADD =>
            reg1_write   <= '1';
            alu_op       <= '1';
            flag_enable  <= '1';
            inc_pc       <= '1';

        when SUB =>
            reg1_write   <= '1';
            alu_op       <= '1';
            flag_enable  <= '1';
            inc_pc       <= '1';

        when AND_op =>
            reg1_write   <= '1';
            alu_op       <= '1';
            flag_enable  <= '1';
            inc_pc       <= '1';

        when IADD =>
            reg1_write   <= '1';
            alu_src      <= '1';
            alu_op       <= '1';
            flag_enable  <= '1';
            inc_pc       <= '1';

        when LDM =>
            reg1_write      <= '1';
            alu_passthrough <= '1';
            inc_pc          <= '1';
            mem_to_reg      <= '1';

        when LDD =>
            reg1_write      <= '1';
            alu_passthrough <= '1';
            mem_read        <= '1';
            inc_pc          <= '1';
            mem_to_reg      <= '1';

        when STD =>
            mem_write    <= '1';
            inc_pc       <= '1';

        when JZ =>
            alu_passthrough  <= '1';
            branch_type      <= "00";
            branch           <= '1';
            mem_or_branch_pc <= '1';

        when JN =>
            alu_passthrough  <= '1';
            branch_type      <= "10";
            branch           <= '1';
            mem_or_branch_pc <= '1';

        when JC =>
            alu_passthrough  <= '1';
            branch_type      <= "01";
            branch           <= '1';
            mem_or_branch_pc <= '1';

        when JMP =>
            alu_passthrough  <= '1';
            branch_type      <= "11";
            branch           <= '1';
            mem_or_branch_pc <= '1';

        when CALL =>
            alu_passthrough  <= '1';
            branch_type      <= "11";
            branch           <= '1';
            dec_sp           <= '1';
            mem_addr_src     <= '1';
            mem_write        <= '1';
            mem_or_branch_pc <= '1';

        when RET =>
            inc_sp       <= '1';
            mem_addr_src <= '1';
            mem_read     <= '1';

        when PUSH =>
            dec_sp           <= '1';
            mem_addr_src     <= '1';
            mem_write        <= '1';
            inc_pc           <= '1';
            mem_or_branch_pc <= '1';

        when POP =>
            inc_sp           <= '1';
            mem_addr_src     <= '1';
            mem_read         <= '1';
            inc_pc           <= '1';
            mem_or_branch_pc <= '1';
            mem_to_reg       <= '1';

        when INT =>
            store_ccr        <= '1';
            dec_sp           <= '1';
            mem_addr_src     <= '1';
            mem_data_src     <= '1';
            mem_write        <= '1';
            interrupt_enable <= '1';

        when RTI =>
            restore_ccr      <= '1';
            inc_sp           <= '1';
            mem_addr_src     <= '1';
            mem_read         <= '1';

        when RESET =>
            clock_enable <= '0';
            reset        <= '1';

        when INTERRUPT =>
            store_ccr        <= '1';
            dec_sp           <= '1';
            mem_addr_src     <= '1';
            mem_data_src     <= '1';
            mem_write        <= '1';
            interrupt_enable <= '1';

        when others =>
            null;

    end case;
    end process decode_process;

end architecture behavioral;