library ieee;
use ieee.std_logic_1164.all;

entity control_unit is
port(
    -- INSTR(31-27)
    opcode : in std_logic_vector(4 downto 0);

    -- PC control (WB stage)
    mem_or_branch_pc : out std_logic;   -- 1 = PC from mem/branch, 0 = incremented
    inc_pc           : out std_logic;   -- 1 = use incremented PC

    -- Register file (Decode stage)
    reg1_write : out std_logic;         -- Write enable for Rdst
    reg2_write : out std_logic;         -- Write enable for Rdst2 (SWAP only)

    -- EX1 stage
    alu_src         : out std_logic;                    -- 0 = Rsrc2, 1 = sign-ext imm
    alu_op          : out std_logic_vector(2 downto 0); -- ALU operation select
    set_carry       : out std_logic;                    -- 1 = force carry=1 (SETC), 0 = use ALU carry
    alu_passthrough : out std_logic;                    -- 1 = ALU result = imm (LDM, jumps)
    flag_enable     : out std_logic;                    -- 1 = update flags from ALU
    restore_ccr     : out std_logic;                    -- 1 = restore CCR from stack (RTI)
    store_ccr       : out std_logic;                    -- 1 = save CCR to stack (INT/INTERRUPT)

    -- EX2 – Branch resolution
    branch      : out std_logic;                    -- 1 = branch instruction
    branch_type : out std_logic_vector(1 downto 0); -- 00=Z, 01=C, 10=N, 11=unconditional

    -- Stack pointer
    inc_sp : out std_logic; -- 1 = SP++
    dec_sp : out std_logic; -- 1 = SP--

    -- Memory stage
    -- MemAddrSrc: 0 = TargetMemAddress (LDD/STD), 1 = SP (PUSH/POP/CALL/RET/INT/RTI)
    mem_addr_src : out std_logic;
    -- MemDataSrc: bit1=interrupt selector, bit0: 0=Rsrc1, 1=PC/PC+1 -- wire interrupt signal to mem_data_src[1]
    mem_data_src : out std_logic_vector(1 downto 0);
    mem_read     : out std_logic;
    mem_write    : out std_logic;

    -- WB stage
    mem_to_reg : out std_logic; -- 1 = write-back from memory, 0 = from ALU
    -- RegToReg mux: selects source for reg write when mem_to_reg=0
    -- 0 = ALU result, 1 = Rsrc (MOV/SWAP forwarding)
    reg_to_reg : out std_logic;

    -- Misc
    output_enable    : out std_logic;
    input_enable     : out std_logic;
    clock_enable     : out std_logic;
    interrupt_enable : out std_logic;
    rst            : out std_logic
);
end control_unit;

architecture behavioral of control_unit is

    -- Opcode constants  (INSTR[31:27])
    constant NOP       : std_logic_vector(4 downto 0) := "00000";
    constant HLT       : std_logic_vector(4 downto 0) := "00001";
    constant SETC      : std_logic_vector(4 downto 0) := "00010";
    constant NOT_op    : std_logic_vector(4 downto 0) := "00111";
    constant INC       : std_logic_vector(4 downto 0) := "00100";
    constant OUT_op    : std_logic_vector(4 downto 0) := "00101";
    constant IN_op     : std_logic_vector(4 downto 0) := "00110";
    constant MOV       : std_logic_vector(4 downto 0) := "01011";
    constant SWAP      : std_logic_vector(4 downto 0) := "01000";
    constant ADD       : std_logic_vector(4 downto 0) := "01001";
    constant SUB       : std_logic_vector(4 downto 0) := "01110";
    constant AND_op    : std_logic_vector(4 downto 0) := "01111";
    constant IADD      : std_logic_vector(4 downto 0) := "01100";
    constant PUSH      : std_logic_vector(4 downto 0) := "10001";
    constant POP       : std_logic_vector(4 downto 0) := "10010";
    constant LDM       : std_logic_vector(4 downto 0) := "10111";
    constant LDD       : std_logic_vector(4 downto 0) := "10100";
    constant STD       : std_logic_vector(4 downto 0) := "10101";
    constant JZ        : std_logic_vector(4 downto 0) := "11010";
    constant JN        : std_logic_vector(4 downto 0) := "11011";
    constant JC        : std_logic_vector(4 downto 0) := "11000";
    constant JMP       : std_logic_vector(4 downto 0) := "11001";
    constant CALL      : std_logic_vector(4 downto 0) := "11110";
    constant RET       : std_logic_vector(4 downto 0) := "11111";
    constant INT       : std_logic_vector(4 downto 0) := "11100";
    constant RTI       : std_logic_vector(4 downto 0) := "11101";
    constant RESET     : std_logic_vector(4 downto 0) := "10000";
    constant INTERRUPT : std_logic_vector(4 downto 0) := "10011";

begin

    decode_process: process(opcode)
    begin
        -- ── Safe defaults (all signals de-asserted) ──────────────────────
        mem_or_branch_pc <= '0';
        inc_pc           <= '0';
        reg1_write       <= '0';
        reg2_write       <= '0';
        alu_src          <= '0';
        alu_op           <= "000";
        set_carry        <= '0';
        alu_passthrough  <= '0';
        flag_enable      <= '0';
        restore_ccr      <= '0';
        store_ccr        <= '0';
        branch           <= '0';
        branch_type      <= "00";
        inc_sp           <= '0';
        dec_sp           <= '0';
        mem_addr_src     <= '0';
        mem_data_src     <= "00";
        mem_read         <= '0';
        mem_write        <= '0';
        mem_to_reg       <= '0';
        reg_to_reg       <= '0';
        output_enable    <= '0';
        input_enable     <= '0';
        clock_enable     <= '1';
        interrupt_enable <= '0';
        rst              <= '0';

        -- ── ALU operation encoding ────────────────────────────────────────
        --   000 = pass-through / MOV
        --   001 = ADD / INC / IADD
        --   010 = NOT
        --   011 = SUB
        --   100 = AND

        case opcode is

            -- ── No-op ────────────────────────────────────────────────────
            when NOP =>
                inc_pc <= '1';

            -- ── Halt ─────────────────────────────────────────────────────
            when HLT =>
                clock_enable <= '0';

            -- ── Set carry ────────────────────────────────────────────────
            when SETC =>
                set_carry   <= '1';
                flag_enable <= '1';
                inc_pc      <= '1';

            -- ── NOT Rdst  (Rsrc = Rdst, imm path used for unary) ─────────
            when NOT_op =>
                reg1_write  <= '1';
                alu_src     <= '1';   -- unary: imm path, Rsrc2 unused
                alu_op      <= "010";
                flag_enable <= '1';
                inc_pc      <= '1';

            -- ── INC Rdst  (imm = 1 baked into datapath) ──────────────────
            when INC =>
                reg1_write  <= '1';
                alu_src     <= '1';   -- immediate = 1
                alu_op      <= "001";
                flag_enable <= '1';
                inc_pc      <= '1';

            -- ── OUT Rsrc ─────────────────────────────────────────────────
            -- alu_op=ADD (001) + alu_src=imm(0) passes Rsrc through ALU so
            -- that forwarding in EX1 works and alu_result = forwarded Rsrc.
            when OUT_op =>
                output_enable <= '1';
                alu_op        <= "001";
                alu_src       <= '1';  -- imm=0, so result = Rsrc + 0 = Rsrc
                inc_pc        <= '1';

            -- ── IN Rdst ──────────────────────────────────────────────────
            when IN_op =>
                input_enable <= '1';
                reg1_write   <= '1';
                inc_pc       <= '1';

            -- ── MOV Rdst, Rsrc ───────────────────────────────────────────
            -- reg_to_reg=1 mux selects Rsrc forward into Rdst write port
            when MOV =>
                reg1_write  <= '1';
                alu_src     <= '1';   -- imm path (value comes from Rsrc via reg_to_reg mux)
                alu_op      <= "000";
                reg_to_reg  <= '1';
                inc_pc      <= '1';

            -- ── SWAP Rsrc, Rdst ──────────────────────────────────────────
            when SWAP =>
                reg1_write <= '1';
                reg2_write <= '1';
                alu_op     <= "000";
                reg_to_reg <= '1';
                inc_pc     <= '1';

            -- ── ADD Rdst, Rsrc1, Rsrc2 ───────────────────────────────────
            when ADD =>
                reg1_write  <= '1';
                alu_op      <= "001";
                flag_enable <= '1';
                inc_pc      <= '1';

            -- ── SUB Rdst, Rsrc1, Rsrc2 ───────────────────────────────────
            when SUB =>
                reg1_write  <= '1';
                alu_op      <= "011";
                flag_enable <= '1';
                inc_pc      <= '1';

            -- ── AND Rdst, Rsrc1, Rsrc2 ───────────────────────────────────
            when AND_op =>
                reg1_write  <= '1';
                alu_op      <= "100";
                flag_enable <= '1';
                inc_pc      <= '1';

            -- ── IADD Rdst, Rsrc, Imm ─────────────────────────────────────
            when IADD =>
                reg1_write  <= '1';
                alu_src     <= '1';   -- select sign-extended immediate
                alu_op      <= "001";
                flag_enable <= '1';
                inc_pc      <= '1';

            -- ── LDM Rdst, Imm  (load immediate into register) ────────────
            -- ALU passes imm straight through; mem_to_reg=1 but no mem_read
            -- (datapath treats passthrough result as the "memory data" mux input)
            when LDM =>
                reg1_write      <= '1';
                alu_src         <= '1';
                alu_passthrough <= '1';   -- ALU result = imm
                mem_to_reg      <= '1';   -- write-back from "mem/imm" path
                inc_pc          <= '1';

            -- ── LDD Rdst, offset(Rsrc) ───────────────────────────────────
            when LDD =>
                reg1_write      <= '1';
                alu_src         <= '1';   -- compute eff. addr = Rsrc + imm
                alu_passthrough <= '0';
                mem_addr_src    <= '0';   -- eff. address from ALU (TargetMemAddress)
                mem_read        <= '1';
                mem_to_reg      <= '1';
                inc_pc          <= '1';

            -- ── STD Rsrc1, offset(Rsrc2) ─────────────────────────────────
            when STD =>
                alu_src      <= '1';   -- compute eff. addr = Rsrc2 + imm
                mem_addr_src <= '0';   -- eff. address from ALU
                mem_data_src <= "00";  -- data = Rsrc1
                mem_write    <= '1';
                inc_pc       <= '1';

            -- ── JZ Imm ───────────────────────────────────────────────────
            when JZ =>
                alu_passthrough  <= '1';
                branch_type      <= "00";
                branch           <= '1';
                mem_or_branch_pc <= '1';

            -- ── JN Imm ───────────────────────────────────────────────────
            when JN =>
                alu_passthrough  <= '1';
                branch_type      <= "10";
                branch           <= '1';
                mem_or_branch_pc <= '1';

            -- ── JC Imm ───────────────────────────────────────────────────
            when JC =>
                alu_passthrough  <= '1';
                branch_type      <= "01";
                branch           <= '1';
                mem_or_branch_pc <= '1';

            -- ── JMP Imm ──────────────────────────────────────────────────
            when JMP =>
                alu_passthrough  <= '1';
                branch_type      <= "11";
                branch           <= '1';
                mem_or_branch_pc <= '1';

            -- ── CALL Imm ─────────────────────────────────────────────────
            -- Push PC+1 onto stack, jump to imm
            when CALL =>
                alu_passthrough  <= '1';
                branch_type      <= "11";
                branch           <= '1';
                dec_sp           <= '1';
                mem_addr_src     <= '1';   -- SP
                mem_data_src     <= "01";  -- data = PC+1
                mem_write        <= '1';
                mem_or_branch_pc <= '1';

            -- ── RET ──────────────────────────────────────────────────────
            -- Pop PC from stack
            when RET =>
                inc_sp           <= '1';
                mem_addr_src     <= '1';   -- SP
                mem_read         <= '1';
                mem_or_branch_pc <= '1';   -- new PC from memory

            -- ── PUSH Rsrc ────────────────────────────────────────────────
            when PUSH =>
                dec_sp       <= '1';
                mem_addr_src <= '1';   -- SP
                mem_data_src <= "00";  -- data = Rsrc1
                mem_write    <= '1';
                inc_pc       <= '1';

            -- ── POP Rdst ─────────────────────────────────────────────────
            when POP =>
                reg1_write   <= '1';
                inc_sp       <= '1';
                mem_addr_src <= '1';   -- SP
                mem_read     <= '1';
                mem_to_reg   <= '1';
                inc_pc       <= '1';

            -- ── INT index ────────────────────────────────────────────────
            -- Save CCR, push PC, jump via interrupt vector
            when INT =>
                store_ccr        <= '1';
                dec_sp           <= '1';
                mem_addr_src     <= '1';   -- SP
                mem_data_src     <= "10";  -- bit1=interrupt, PC (via vector)
                mem_write        <= '1';
                interrupt_enable <= '1';
                inc_pc           <= '1';

            -- ── RTI ──────────────────────────────────────────────────────
            -- Restore CCR, pop PC
            when RTI =>
                restore_ccr      <= '1';
                inc_sp           <= '1';
                mem_addr_src     <= '1';   -- SP
                mem_read         <= '1';
                mem_or_branch_pc <= '1';

            -- ── RESET (hardware reset signal on bus) ──────────────────────
            when RESET =>
                clock_enable <= '0';
                rst            <= '1';

            -- ── INTERRUPT (internal pseudo-op for interrupt handling) ──────
            when INTERRUPT =>
                store_ccr        <= '1';
                dec_sp           <= '1';
                mem_addr_src     <= '1';   -- SP
                mem_data_src     <= "10";  -- bit1=interrupt
                mem_write        <= '1';
                interrupt_enable <= '1';

            when others =>
                null;

        end case;
    end process decode_process;

end architecture behavioral;