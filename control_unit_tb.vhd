-- ============================================================
-- control_unit_tb.vhd  (fixed)
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;

entity control_unit_tb is
end control_unit_tb;

architecture behavior of control_unit_tb is

    signal opcode           : std_logic_vector(4 downto 0);
    signal mem_or_branch_pc : std_logic;
    signal inc_pc           : std_logic;
    signal reg1_write       : std_logic;
    signal reg2_write       : std_logic;
    signal alu_src          : std_logic;
    signal alu_op           : std_logic_vector(2 downto 0);
    signal alu_passthrough  : std_logic;
    signal set_carry        : std_logic;
    signal restore_ccr      : std_logic;
    signal flag_enable      : std_logic;
    signal store_ccr        : std_logic;
    signal branch           : std_logic;
    signal branch_type      : std_logic_vector(1 downto 0);
    signal inc_sp           : std_logic;
    signal dec_sp           : std_logic;
    signal mem_addr_src     : std_logic;
    signal mem_data_src     : std_logic_vector(1 downto 0);
    signal mem_read         : std_logic;
    signal mem_write        : std_logic;
    signal output_enable    : std_logic;
    signal input_enable     : std_logic;
    signal mem_to_reg       : std_logic;
    signal reg_to_reg       : std_logic;
    signal clock_enable     : std_logic;
    signal interrupt_enable : std_logic;
    signal rst            : std_logic;

    -- FIX 3: replace to_string with a local function compatible with VHDL-93/2002
    function slv_to_str(v : std_logic_vector) return string is
        variable s : string(1 to v'length);
    begin
        for i in v'range loop
            if v(i) = '1' then
                s(v'length - (i - v'low)) := '1';
            else
                s(v'length - (i - v'low)) := '0';
            end if;
        end loop;
        return s;
    end function;

    procedure check(
        iname         : in string;
        exp_rw1       : std_logic;  exp_rw2      : std_logic;
        exp_alu_src   : std_logic;  exp_alu_op   : std_logic_vector(2 downto 0);
        exp_set_carry : std_logic;  exp_passthru : std_logic;
        exp_flag_en   : std_logic;  exp_restore  : std_logic;
        exp_store     : std_logic;
        exp_branch    : std_logic;  exp_btype    : std_logic_vector(1 downto 0);
        exp_inc_sp    : std_logic;  exp_dec_sp   : std_logic;
        exp_maddr     : std_logic;  exp_mdata    : std_logic_vector(1 downto 0);
        exp_mread     : std_logic;  exp_mwrite   : std_logic;
        exp_m2r       : std_logic;  exp_r2r      : std_logic;
        exp_inc_pc    : std_logic;  exp_mob_pc   : std_logic;
        exp_in_en     : std_logic;  exp_out_en   : std_logic;
        exp_clk_en    : std_logic;  exp_int_en   : std_logic;
        exp_rst       : std_logic;
        act_rw1       : std_logic;  act_rw2      : std_logic;
        act_alu_src   : std_logic;  act_alu_op   : std_logic_vector(2 downto 0);
        act_set_carry : std_logic;  act_passthru : std_logic;
        act_flag_en   : std_logic;  act_restore  : std_logic;
        act_store     : std_logic;
        act_branch    : std_logic;  act_btype    : std_logic_vector(1 downto 0);
        act_inc_sp    : std_logic;  act_dec_sp   : std_logic;
        act_maddr     : std_logic;  act_mdata    : std_logic_vector(1 downto 0);
        act_mread     : std_logic;  act_mwrite   : std_logic;
        act_m2r       : std_logic;  act_r2r      : std_logic;
        act_inc_pc    : std_logic;  act_mob_pc   : std_logic;
        act_in_en     : std_logic;  act_out_en   : std_logic;
        act_clk_en    : std_logic;  act_int_en   : std_logic;
        act_rst       : std_logic
    ) is
        variable pass : boolean := true;
    begin
        if act_rw1       /= exp_rw1       then report iname&": FAIL reg1_write   exp="&std_logic'image(exp_rw1)      &" got="&std_logic'image(act_rw1)       severity error; pass:=false; end if;
        if act_rw2       /= exp_rw2       then report iname&": FAIL reg2_write   exp="&std_logic'image(exp_rw2)      &" got="&std_logic'image(act_rw2)       severity error; pass:=false; end if;
        if act_alu_src   /= exp_alu_src   then report iname&": FAIL alu_src      exp="&std_logic'image(exp_alu_src)  &" got="&std_logic'image(act_alu_src)   severity error; pass:=false; end if;
        if act_alu_op    /= exp_alu_op    then report iname&": FAIL alu_op       exp="&slv_to_str(exp_alu_op)        &" got="&slv_to_str(act_alu_op)         severity error; pass:=false; end if;  -- FIX 3
        if act_set_carry /= exp_set_carry then report iname&": FAIL set_carry    exp="&std_logic'image(exp_set_carry)&" got="&std_logic'image(act_set_carry) severity error; pass:=false; end if;
        if act_passthru  /= exp_passthru  then report iname&": FAIL alu_passthru exp="&std_logic'image(exp_passthru) &" got="&std_logic'image(act_passthru)  severity error; pass:=false; end if;
        if act_flag_en   /= exp_flag_en   then report iname&": FAIL flag_enable  exp="&std_logic'image(exp_flag_en)  &" got="&std_logic'image(act_flag_en)   severity error; pass:=false; end if;
        if act_restore   /= exp_restore   then report iname&": FAIL restore_ccr  exp="&std_logic'image(exp_restore)  &" got="&std_logic'image(act_restore)   severity error; pass:=false; end if;
        if act_store     /= exp_store     then report iname&": FAIL store_ccr    exp="&std_logic'image(exp_store)    &" got="&std_logic'image(act_store)     severity error; pass:=false; end if;
        if act_branch    /= exp_branch    then report iname&": FAIL branch       exp="&std_logic'image(exp_branch)   &" got="&std_logic'image(act_branch)    severity error; pass:=false; end if;
        if act_btype     /= exp_btype     then report iname&": FAIL branch_type  exp="&slv_to_str(exp_btype)         &" got="&slv_to_str(act_btype)          severity error; pass:=false; end if;  -- FIX 3
        if act_inc_sp    /= exp_inc_sp    then report iname&": FAIL inc_sp       exp="&std_logic'image(exp_inc_sp)   &" got="&std_logic'image(act_inc_sp)    severity error; pass:=false; end if;
        if act_dec_sp    /= exp_dec_sp    then report iname&": FAIL dec_sp       exp="&std_logic'image(exp_dec_sp)   &" got="&std_logic'image(act_dec_sp)    severity error; pass:=false; end if;
        if act_maddr     /= exp_maddr     then report iname&": FAIL mem_addr_src exp="&std_logic'image(exp_maddr)    &" got="&std_logic'image(act_maddr)     severity error; pass:=false; end if;
        if act_mdata     /= exp_mdata     then report iname&": FAIL mem_data_src exp="&slv_to_str(exp_mdata)         &" got="&slv_to_str(act_mdata)          severity error; pass:=false; end if;  -- FIX 3
        if act_mread     /= exp_mread     then report iname&": FAIL mem_read     exp="&std_logic'image(exp_mread)    &" got="&std_logic'image(act_mread)     severity error; pass:=false; end if;
        if act_mwrite    /= exp_mwrite    then report iname&": FAIL mem_write    exp="&std_logic'image(exp_mwrite)   &" got="&std_logic'image(act_mwrite)    severity error; pass:=false; end if;
        if act_m2r       /= exp_m2r       then report iname&": FAIL mem_to_reg   exp="&std_logic'image(exp_m2r)      &" got="&std_logic'image(act_m2r)       severity error; pass:=false; end if;
        if act_r2r       /= exp_r2r       then report iname&": FAIL reg_to_reg   exp="&std_logic'image(exp_r2r)      &" got="&std_logic'image(act_r2r)       severity error; pass:=false; end if;
        if act_inc_pc    /= exp_inc_pc    then report iname&": FAIL inc_pc       exp="&std_logic'image(exp_inc_pc)   &" got="&std_logic'image(act_inc_pc)    severity error; pass:=false; end if;
        if act_mob_pc    /= exp_mob_pc    then report iname&": FAIL mem_or_br_pc exp="&std_logic'image(exp_mob_pc)   &" got="&std_logic'image(act_mob_pc)    severity error; pass:=false; end if;
        if act_in_en     /= exp_in_en     then report iname&": FAIL input_enable exp="&std_logic'image(exp_in_en)    &" got="&std_logic'image(act_in_en)     severity error; pass:=false; end if;
        if act_out_en    /= exp_out_en    then report iname&": FAIL output_enable exp="&std_logic'image(exp_out_en)  &" got="&std_logic'image(act_out_en)    severity error; pass:=false; end if;
        if act_clk_en    /= exp_clk_en    then report iname&": FAIL clock_enable exp="&std_logic'image(exp_clk_en)   &" got="&std_logic'image(act_clk_en)    severity error; pass:=false; end if;
        if act_int_en    /= exp_int_en    then report iname&": FAIL int_enable   exp="&std_logic'image(exp_int_en)   &" got="&std_logic'image(act_int_en)    severity error; pass:=false; end if;
        if act_rst       /= exp_rst       then report iname&": FAIL reset        exp="&std_logic'image(exp_rst)      &" got="&std_logic'image(act_rst)       severity error; pass:=false; end if;
        if pass then report iname & ": PASS" severity note; end if;
    end procedure;

begin

    DUT: entity work.control_unit
    port map(
        opcode           => opcode,
        mem_or_branch_pc => mem_or_branch_pc,
        inc_pc           => inc_pc,
        reg1_write       => reg1_write,
        reg2_write       => reg2_write,
        alu_src          => alu_src,
        alu_op           => alu_op,
        alu_passthrough  => alu_passthrough,
        set_carry        => set_carry,
        restore_ccr      => restore_ccr,
        flag_enable      => flag_enable,
        store_ccr        => store_ccr,
        branch           => branch,
        branch_type      => branch_type,
        inc_sp           => inc_sp,
        dec_sp           => dec_sp,
        mem_addr_src     => mem_addr_src,
        mem_data_src     => mem_data_src,
        mem_read         => mem_read,
        mem_write        => mem_write,
        output_enable    => output_enable,
        input_enable     => input_enable,
        mem_to_reg       => mem_to_reg,
        reg_to_reg       => reg_to_reg,
        clock_enable     => clock_enable,
        interrupt_enable => interrupt_enable,
        rst            => rst
    );

    stimulus: process
    begin
        -- NOP
        opcode <= "00000"; wait for 20 ns;
        check("NOP",
            '0','0', '0',"000",'0','0','0','0','0',
            '0',"00", '0','0', '0',"00",'0','0', '0','0',
            '1','0', '0','0','1','0','0',
            reg1_write,reg2_write,alu_src,alu_op,set_carry,alu_passthrough,
            flag_enable,restore_ccr,store_ccr,branch,branch_type,
            inc_sp,dec_sp,mem_addr_src,mem_data_src,mem_read,mem_write,
            mem_to_reg,reg_to_reg,inc_pc,mem_or_branch_pc,
            input_enable,output_enable,clock_enable,interrupt_enable,rst);

        -- HLT
        opcode <= "00001"; wait for 20 ns;
        check("HLT",
            '0','0', '0',"000",'0','0','0','0','0',
            '0',"00", '0','0', '0',"00",'0','0', '0','0',
            '0','0', '0','0','0','0','0',
            reg1_write,reg2_write,alu_src,alu_op,set_carry,alu_passthrough,
            flag_enable,restore_ccr,store_ccr,branch,branch_type,
            inc_sp,dec_sp,mem_addr_src,mem_data_src,mem_read,mem_write,
            mem_to_reg,reg_to_reg,inc_pc,mem_or_branch_pc,
            input_enable,output_enable,clock_enable,interrupt_enable,rst);

        -- SETC
        opcode <= "00010"; wait for 20 ns;
        check("SETC",
            '0','0', '0',"000",'1','0','1','0','0',
            '0',"00", '0','0', '0',"00",'0','0', '0','0',
            '1','0', '0','0','1','0','0',
            reg1_write,reg2_write,alu_src,alu_op,set_carry,alu_passthrough,
            flag_enable,restore_ccr,store_ccr,branch,branch_type,
            inc_sp,dec_sp,mem_addr_src,mem_data_src,mem_read,mem_write,
            mem_to_reg,reg_to_reg,inc_pc,mem_or_branch_pc,
            input_enable,output_enable,clock_enable,interrupt_enable,rst);

        -- NOT
        opcode <= "00111"; wait for 20 ns;
        check("NOT",
            '1','0', '1',"010",'0','0','1','0','0',
            '0',"00", '0','0', '0',"00",'0','0', '0','0',
            '1','0', '0','0','1','0','0',
            reg1_write,reg2_write,alu_src,alu_op,set_carry,alu_passthrough,
            flag_enable,restore_ccr,store_ccr,branch,branch_type,
            inc_sp,dec_sp,mem_addr_src,mem_data_src,mem_read,mem_write,
            mem_to_reg,reg_to_reg,inc_pc,mem_or_branch_pc,
            input_enable,output_enable,clock_enable,interrupt_enable,rst);

        -- INC
        opcode <= "00100"; wait for 20 ns;
        check("INC",
            '1','0', '1',"001",'0','0','1','0','0',
            '0',"00", '0','0', '0',"00",'0','0', '0','0',
            '1','0', '0','0','1','0','0',
            reg1_write,reg2_write,alu_src,alu_op,set_carry,alu_passthrough,
            flag_enable,restore_ccr,store_ccr,branch,branch_type,
            inc_sp,dec_sp,mem_addr_src,mem_data_src,mem_read,mem_write,
            mem_to_reg,reg_to_reg,inc_pc,mem_or_branch_pc,
            input_enable,output_enable,clock_enable,interrupt_enable,rst);

        -- OUT
        opcode <= "00101"; wait for 20 ns;
        check("OUT",
            '0','0', '0',"000",'0','0','0','0','0',
            '0',"00", '0','0', '0',"00",'0','0', '0','0',
            '1','0', '0','1','1','0','0',
            reg1_write,reg2_write,alu_src,alu_op,set_carry,alu_passthrough,
            flag_enable,restore_ccr,store_ccr,branch,branch_type,
            inc_sp,dec_sp,mem_addr_src,mem_data_src,mem_read,mem_write,
            mem_to_reg,reg_to_reg,inc_pc,mem_or_branch_pc,
            input_enable,output_enable,clock_enable,interrupt_enable,rst);

        -- IN
        opcode <= "00110"; wait for 20 ns;
        check("IN",
            '1','0', '0',"000",'0','0','0','0','0',
            '0',"00", '0','0', '0',"00",'0','0', '0','0',
            '1','0', '1','0','1','0','0',
            reg1_write,reg2_write,alu_src,alu_op,set_carry,alu_passthrough,
            flag_enable,restore_ccr,store_ccr,branch,branch_type,
            inc_sp,dec_sp,mem_addr_src,mem_data_src,mem_read,mem_write,
            mem_to_reg,reg_to_reg,inc_pc,mem_or_branch_pc,
            input_enable,output_enable,clock_enable,interrupt_enable,rst);

        -- MOV
        opcode <= "01011"; wait for 20 ns;
        check("MOV",
            '1','0', '1',"000",'0','0','0','0','0',
            '0',"00", '0','0', '0',"00",'0','0', '0','1',
            '1','0', '0','0','1','0','0',
            reg1_write,reg2_write,alu_src,alu_op,set_carry,alu_passthrough,
            flag_enable,restore_ccr,store_ccr,branch,branch_type,
            inc_sp,dec_sp,mem_addr_src,mem_data_src,mem_read,mem_write,
            mem_to_reg,reg_to_reg,inc_pc,mem_or_branch_pc,
            input_enable,output_enable,clock_enable,interrupt_enable,rst);

        -- SWAP
        opcode <= "01000"; wait for 20 ns;
        check("SWAP",
            '1','1', '0',"000",'0','0','0','0','0',
            '0',"00", '0','0', '0',"00",'0','0', '0','1',
            '1','0', '0','0','1','0','0',
            reg1_write,reg2_write,alu_src,alu_op,set_carry,alu_passthrough,
            flag_enable,restore_ccr,store_ccr,branch,branch_type,
            inc_sp,dec_sp,mem_addr_src,mem_data_src,mem_read,mem_write,
            mem_to_reg,reg_to_reg,inc_pc,mem_or_branch_pc,
            input_enable,output_enable,clock_enable,interrupt_enable,rst);

        -- ADD
        opcode <= "01001"; wait for 20 ns;
        check("ADD",
            '1','0', '0',"001",'0','0','1','0','0',
            '0',"00", '0','0', '0',"00",'0','0', '0','0',
            '1','0', '0','0','1','0','0',
            reg1_write,reg2_write,alu_src,alu_op,set_carry,alu_passthrough,
            flag_enable,restore_ccr,store_ccr,branch,branch_type,
            inc_sp,dec_sp,mem_addr_src,mem_data_src,mem_read,mem_write,
            mem_to_reg,reg_to_reg,inc_pc,mem_or_branch_pc,
            input_enable,output_enable,clock_enable,interrupt_enable,rst);

        -- SUB
        opcode <= "01110"; wait for 20 ns;
        check("SUB",
            '1','0', '0',"011",'0','0','1','0','0',
            '0',"00", '0','0', '0',"00",'0','0', '0','0',
            '1','0', '0','0','1','0','0',
            reg1_write,reg2_write,alu_src,alu_op,set_carry,alu_passthrough,
            flag_enable,restore_ccr,store_ccr,branch,branch_type,
            inc_sp,dec_sp,mem_addr_src,mem_data_src,mem_read,mem_write,
            mem_to_reg,reg_to_reg,inc_pc,mem_or_branch_pc,
            input_enable,output_enable,clock_enable,interrupt_enable,rst);

        -- AND
        opcode <= "01111"; wait for 20 ns;
        check("AND",
            '1','0', '0',"100",'0','0','1','0','0',
            '0',"00", '0','0', '0',"00",'0','0', '0','0',
            '1','0', '0','0','1','0','0',
            reg1_write,reg2_write,alu_src,alu_op,set_carry,alu_passthrough,
            flag_enable,restore_ccr,store_ccr,branch,branch_type,
            inc_sp,dec_sp,mem_addr_src,mem_data_src,mem_read,mem_write,
            mem_to_reg,reg_to_reg,inc_pc,mem_or_branch_pc,
            input_enable,output_enable,clock_enable,interrupt_enable,rst);

        -- IADD
        opcode <= "01100"; wait for 20 ns;
        check("IADD",
            '1','0', '1',"001",'0','0','1','0','0',
            '0',"00", '0','0', '0',"00",'0','0', '0','0',
            '1','0', '0','0','1','0','0',
            reg1_write,reg2_write,alu_src,alu_op,set_carry,alu_passthrough,
            flag_enable,restore_ccr,store_ccr,branch,branch_type,
            inc_sp,dec_sp,mem_addr_src,mem_data_src,mem_read,mem_write,
            mem_to_reg,reg_to_reg,inc_pc,mem_or_branch_pc,
            input_enable,output_enable,clock_enable,interrupt_enable,rst);

        -- LDM
        opcode <= "10111"; wait for 20 ns;
        check("LDM",
            '1','0', '1',"000",'0','1','0','0','0',
            '0',"00", '0','0', '0',"00",'0','0', '1','0',
            '1','0', '0','0','1','0','0',
            reg1_write,reg2_write,alu_src,alu_op,set_carry,alu_passthrough,
            flag_enable,restore_ccr,store_ccr,branch,branch_type,
            inc_sp,dec_sp,mem_addr_src,mem_data_src,mem_read,mem_write,
            mem_to_reg,reg_to_reg,inc_pc,mem_or_branch_pc,
            input_enable,output_enable,clock_enable,interrupt_enable,rst);

        -- LDD
        opcode <= "10100"; wait for 20 ns;
        check("LDD",
            '1','0', '1',"001",'0','0','0','0','0',
            '0',"00", '0','0', '0',"00",'1','0', '1','0',
            '1','0', '0','0','1','0','0',
            reg1_write,reg2_write,alu_src,alu_op,set_carry,alu_passthrough,
            flag_enable,restore_ccr,store_ccr,branch,branch_type,
            inc_sp,dec_sp,mem_addr_src,mem_data_src,mem_read,mem_write,
            mem_to_reg,reg_to_reg,inc_pc,mem_or_branch_pc,
            input_enable,output_enable,clock_enable,interrupt_enable,rst);

        -- STD
        opcode <= "10101"; wait for 20 ns;
        check("STD",
            '0','0', '1',"001",'0','0','0','0','0',
            '0',"00", '0','0', '0',"00",'0','1', '0','0',
            '1','0', '0','0','1','0','0',
            reg1_write,reg2_write,alu_src,alu_op,set_carry,alu_passthrough,
            flag_enable,restore_ccr,store_ccr,branch,branch_type,
            inc_sp,dec_sp,mem_addr_src,mem_data_src,mem_read,mem_write,
            mem_to_reg,reg_to_reg,inc_pc,mem_or_branch_pc,
            input_enable,output_enable,clock_enable,interrupt_enable,rst);

        -- JZ
        opcode <= "11010"; wait for 20 ns;
        check("JZ",
            '0','0', '0',"000",'0','1','0','0','0',
            '1',"00", '0','0', '0',"00",'0','0', '0','0',
            '0','1', '0','0','1','0','0',
            reg1_write,reg2_write,alu_src,alu_op,set_carry,alu_passthrough,
            flag_enable,restore_ccr,store_ccr,branch,branch_type,
            inc_sp,dec_sp,mem_addr_src,mem_data_src,mem_read,mem_write,
            mem_to_reg,reg_to_reg,inc_pc,mem_or_branch_pc,
            input_enable,output_enable,clock_enable,interrupt_enable,rst);

        -- JN
        opcode <= "11011"; wait for 20 ns;
        check("JN",
            '0','0', '0',"000",'0','1','0','0','0',
            '1',"10", '0','0', '0',"00",'0','0', '0','0',
            '0','1', '0','0','1','0','0',
            reg1_write,reg2_write,alu_src,alu_op,set_carry,alu_passthrough,
            flag_enable,restore_ccr,store_ccr,branch,branch_type,
            inc_sp,dec_sp,mem_addr_src,mem_data_src,mem_read,mem_write,
            mem_to_reg,reg_to_reg,inc_pc,mem_or_branch_pc,
            input_enable,output_enable,clock_enable,interrupt_enable,rst);

        -- JC
        opcode <= "11000"; wait for 20 ns;
        check("JC",
            '0','0', '0',"000",'0','1','0','0','0',
            '1',"01", '0','0', '0',"00",'0','0', '0','0',
            '0','1', '0','0','1','0','0',
            reg1_write,reg2_write,alu_src,alu_op,set_carry,alu_passthrough,
            flag_enable,restore_ccr,store_ccr,branch,branch_type,
            inc_sp,dec_sp,mem_addr_src,mem_data_src,mem_read,mem_write,
            mem_to_reg,reg_to_reg,inc_pc,mem_or_branch_pc,
            input_enable,output_enable,clock_enable,interrupt_enable,rst);

        -- JMP
        opcode <= "11001"; wait for 20 ns;
        check("JMP",
            '0','0', '0',"000",'0','1','0','0','0',
            '1',"11", '0','0', '0',"00",'0','0', '0','0',
            '0','1', '0','0','1','0','0',
            reg1_write,reg2_write,alu_src,alu_op,set_carry,alu_passthrough,
            flag_enable,restore_ccr,store_ccr,branch,branch_type,
            inc_sp,dec_sp,mem_addr_src,mem_data_src,mem_read,mem_write,
            mem_to_reg,reg_to_reg,inc_pc,mem_or_branch_pc,
            input_enable,output_enable,clock_enable,interrupt_enable,rst);

        -- CALL
        opcode <= "11110"; wait for 20 ns;
        check("CALL",
            '0','0', '0',"000",'0','1','0','0','0',
            '1',"11", '0','1', '1',"01",'0','1', '0','0',
            '0','1', '0','0','1','0','0',
            reg1_write,reg2_write,alu_src,alu_op,set_carry,alu_passthrough,
            flag_enable,restore_ccr,store_ccr,branch,branch_type,
            inc_sp,dec_sp,mem_addr_src,mem_data_src,mem_read,mem_write,
            mem_to_reg,reg_to_reg,inc_pc,mem_or_branch_pc,
            input_enable,output_enable,clock_enable,interrupt_enable,rst
            );

        -- RET
        opcode <= "11111"; wait for 20 ns;
        check("RET",
            '0','0', '0',"000",'0','0','0','0','0',
            '0',"00", '1','0', '1',"00",'1','0', '0','0',
            '0','1', '0','0','1','0','0',
            reg1_write,reg2_write,alu_src,alu_op,set_carry,alu_passthrough,
            flag_enable,restore_ccr,store_ccr,branch,branch_type,
            inc_sp,dec_sp,mem_addr_src,mem_data_src,mem_read,mem_write,
            mem_to_reg,reg_to_reg,inc_pc,mem_or_branch_pc,
            input_enable,output_enable,clock_enable,interrupt_enable,rst);

        -- PUSH
        opcode <= "10001"; wait for 20 ns;
        check("PUSH",
            '0','0', '0',"000",'0','0','0','0','0',
            '0',"00", '0','1', '1',"00",'0','1', '0','0',
            '1','0', '0','0','1','0','0',
            reg1_write,reg2_write,alu_src,alu_op,set_carry,alu_passthrough,
            flag_enable,restore_ccr,store_ccr,branch,branch_type,
            inc_sp,dec_sp,mem_addr_src,mem_data_src,mem_read,mem_write,
            mem_to_reg,reg_to_reg,inc_pc,mem_or_branch_pc,
            input_enable,output_enable,clock_enable,interrupt_enable,rst);

        -- POP
        opcode <= "10010"; wait for 20 ns;
        check("POP",
            '1','0', '0',"000",'0','0','0','0','0',
            '0',"00", '1','0', '1',"00",'1','0', '1','0',
            '1','0', '0','0','1','0','0',
            reg1_write,reg2_write,alu_src,alu_op,set_carry,alu_passthrough,
            flag_enable,restore_ccr,store_ccr,branch,branch_type,
            inc_sp,dec_sp,mem_addr_src,mem_data_src,mem_read,mem_write,
            mem_to_reg,reg_to_reg,inc_pc,mem_or_branch_pc,
            input_enable,output_enable,clock_enable,interrupt_enable,rst);

        -- INT
        opcode <= "11100"; wait for 20 ns;
        check("INT",
            '0','0', '0',"000",'0','0','0','0','1',
            '0',"00", '0','1', '1',"10",'0','1', '0','0',
            '1','0', '0','0','1','1','0',
            reg1_write,reg2_write,alu_src,alu_op,set_carry,alu_passthrough,
            flag_enable,restore_ccr,store_ccr,branch,branch_type,
            inc_sp,dec_sp,mem_addr_src,mem_data_src,mem_read,mem_write,
            mem_to_reg,reg_to_reg,inc_pc,mem_or_branch_pc,
            input_enable,output_enable,clock_enable,interrupt_enable,rst);

        -- RTI
        opcode <= "11101"; wait for 20 ns;
        check("RTI",
            '0','0', '0',"000",'0','0','0','1','0',
            '0',"00", '1','0', '1',"00",'1','0', '0','0',
            '0','1', '0','0','1','0','0',
            reg1_write,reg2_write,alu_src,alu_op,set_carry,alu_passthrough,
            flag_enable,restore_ccr,store_ccr,branch,branch_type,
            inc_sp,dec_sp,mem_addr_src,mem_data_src,mem_read,mem_write,
            mem_to_reg,reg_to_reg,inc_pc,mem_or_branch_pc,
            input_enable,output_enable,clock_enable,interrupt_enable,rst);

        -- RESET
        opcode <= "10000"; wait for 20 ns;
        check("RESET",
            '0','0', '0',"000",'0','0','0','0','0',
            '0',"00", '0','0', '0',"00",'0','0', '0','0',
            '0','0', '0','0','0','0','1',
            reg1_write,reg2_write,alu_src,alu_op,set_carry,alu_passthrough,
            flag_enable,restore_ccr,store_ccr,branch,branch_type,
            inc_sp,dec_sp,mem_addr_src,mem_data_src,mem_read,mem_write,
            mem_to_reg,reg_to_reg,inc_pc,mem_or_branch_pc,
            input_enable,output_enable,clock_enable,interrupt_enable,rst);

        -- INTERRUPT (internal pseudo-op)
        opcode <= "10011"; wait for 20 ns;
        check("INTERRUPT",
            '0','0', '0',"000",'0','0','0','0','1',
            '0',"00", '0','1', '1',"10",'0','1', '0','0',
            '0','0', '0','0','1','1','0',
            reg1_write,reg2_write,alu_src,alu_op,set_carry,alu_passthrough,
            flag_enable,restore_ccr,store_ccr,branch,branch_type,
            inc_sp,dec_sp,mem_addr_src,mem_data_src,mem_read,mem_write,
            mem_to_reg,reg_to_reg,inc_pc,mem_or_branch_pc,
            input_enable,output_enable,clock_enable,interrupt_enable,rst);

        report "=== Simulation complete ===" severity note;
        wait;

    end process;

end behavior;