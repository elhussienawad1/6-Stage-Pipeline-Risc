library ieee;
use ieee.std_logic_1164.all;

-- Purely combinational. Drives both register file write ports.
-- Port 1: always Rdst (reg_write controls enable)
-- Port 2: Rsrc1 register, used only for SWAP (reg2_write controls enable)
entity writeback is
    port(
        -- from MEM/WB register
        alu_result    : in std_logic_vector(31 downto 0);
        mem_data      : in std_logic_vector(31 downto 0);
        in_port       : in std_logic_vector(31 downto 0);
        r_rsrc1       : in std_logic_vector(31 downto 0);
        r_rsrc2       : in std_logic_vector(31 downto 0);
        rdst          : in std_logic_vector(2 downto 0);
        rsrc1         : in std_logic_vector(2 downto 0);
        output_enable : in std_logic;
        input_enable  : in std_logic;
        mem_to_reg    : in std_logic;
        reg_to_reg    : in std_logic;
        reg_write     : in std_logic;
        reg2_write    : in std_logic;

        -- OUT.PORT value (top level latches this when output_enable='1')
        out_port      : out std_logic_vector(31 downto 0);

        -- register file write port 1 (Rdst)
        write_data_1  : out std_logic_vector(31 downto 0);
        write_addr_1  : out std_logic_vector(2 downto 0);
        write_en_1    : out std_logic;

        -- register file write port 2 (Rsrc1, SWAP only)
        write_data_2  : out std_logic_vector(31 downto 0);
        write_addr_2  : out std_logic_vector(2 downto 0);
        write_en_2    : out std_logic;

        -- forwarded to execute_1 as mem_wb_result
        wb_result     : out std_logic_vector(31 downto 0)
    );
end writeback;

architecture a_writeback of writeback is
    signal wd1 : std_logic_vector(31 downto 0);
begin
    -- Write data MUX for port 1 (Rdst):
    --   IN:        in_port
    --   LDD/POP:   mem_data
    --   MOV/SWAP:  r_rsrc1 (R[Rsrc] -> Rdst, identical for both ops)
    --   default:   alu_result (ADD/SUB/AND/INC/NOT/IADD/LDM/SETC/CALL/etc.)
    wd1 <= in_port    when input_enable = '1'
      else mem_data   when mem_to_reg = '1'
      else r_rsrc1    when reg_to_reg = '1'
      else alu_result;

    write_data_1 <= wd1;
    write_addr_1 <= rdst;
    -- input_enable guard: control_unit omits reg1_write for IN instruction
    write_en_1   <= reg_write or input_enable;

    -- Port 2: SWAP writes old Rdst value (read via readport2 = r_rsrc2)
    -- back into the Rsrc1 register.
    write_data_2 <= r_rsrc2;
    write_addr_2 <= rsrc1;
    write_en_2   <= reg2_write;

    -- OUT instruction outputs r_rsrc1 (the source register value)
    out_port <= r_rsrc1;

    -- result seen by forwarding unit
    wb_result <= wd1;

end a_writeback;
