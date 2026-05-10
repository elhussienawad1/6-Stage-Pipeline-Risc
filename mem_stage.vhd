library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mem_stage is
    generic (n : integer := 32);
    port(
        clk, rst : in std_logic;

        -- from EX2/MEM register
        address_in        : in std_logic_vector(n-1 downto 0);  -- EX2 computed (LDD/STD)
        r_rsrc1_in        : in std_logic_vector(n-1 downto 0);  -- write data for STD/PUSH (readport1=[20:18])
        r_rsrc2_in        : in std_logic_vector(n-1 downto 0);  -- base address register value
        incremented_pc_in : in std_logic_vector(n-1 downto 0);  -- return addr for CALL/INT
        inc_sp            : in std_logic;
        dec_sp            : in std_logic;
        mem_add_src       : in std_logic;  -- 0=EX2 address, 1=SP-based
        mem_data_src      : in std_logic;  -- 0=r_rsrc1 (data to store), 1=incremented_pc (return addr)
        mem_read          : in std_logic;
        mem_write         : in std_logic;

        -- to shared memory at top level
        mem_address_out   : out std_logic_vector(n-1 downto 0);
        writedata_out     : out std_logic_vector(n-1 downto 0);
        mem_read_out      : out std_logic;
        mem_write_out     : out std_logic;

        -- from shared memory at top level
        mem_data_in       : in std_logic_vector(n-1 downto 0);

        -- to MEM/WB register
        mem_data_out      : out std_logic_vector(n-1 downto 0);

        -- SP value (observable at top level for RET/RTI PC loading)
        sp_out            : out std_logic_vector(n-1 downto 0)
    );
end mem_stage;

architecture a_mem_stage of mem_stage is

    component sp is
        generic (n : integer := 32);
        port(
            Rst, Clk : in std_logic;
            d        : in std_logic_vector(n-1 downto 0);
            q        : out std_logic_vector(n-1 downto 0)
        );
    end component;

    signal sp_q         : std_logic_vector(n-1 downto 0);
    signal sp_d         : std_logic_vector(n-1 downto 0);
    signal sp_plus_one  : std_logic_vector(n-1 downto 0);
    signal sp_minus_one : std_logic_vector(n-1 downto 0);

begin

    sp_reg: sp generic map(n) port map(rst, clk, sp_d, sp_q);

    sp_plus_one  <= std_logic_vector(unsigned(sp_q) + 1);
    sp_minus_one <= std_logic_vector(unsigned(sp_q) - 1);

    -- SP update: hold unless inc or dec
    sp_d <= sp_plus_one  when inc_sp = '1'
       else sp_minus_one when dec_sp = '1'
       else sp_q;

    -- MemAddrSrc MUX
    -- inc_sp (POP/RET/RTI): read from SP+1 (new top after increment)
    -- dec_sp (PUSH/CALL/INT): write to current SP before decrement
    -- mem_add_src=0: use EX2-computed address (LDD/STD)
    mem_address_out <= address_in   when mem_add_src = '0'
                  else sp_plus_one  when inc_sp = '1'
                  else sp_q;

    -- MemDataSrc MUX: 0=r_rsrc1 data (STD/PUSH), 1=return address (INT, not CALL - see control_unit bug)
    writedata_out <= r_rsrc1_in        when mem_data_src = '0'
                else incremented_pc_in;

    mem_read_out  <= mem_read;
    mem_write_out <= mem_write;

    -- memory read data passes through to MEM/WB register
    mem_data_out  <= mem_data_in;

    sp_out <= sp_q;

end a_mem_stage;
