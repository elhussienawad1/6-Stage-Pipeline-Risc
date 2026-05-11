library ieee;
use ieee.std_logic_1164.all;

entity f_d_reg is
    port(
        clk     : in  std_logic;
        rst     : in  std_logic;  
        flush   : in  std_logic;  -- branch/interrupt flush
        enable  : in  std_logic;  
        instruction_d : in  std_logic_vector(31 downto 0);
        instruction_q : out std_logic_vector(31 downto 0);
        pc_d          : in  std_logic_vector(31 downto 0);
        pc_q          : out std_logic_vector(31 downto 0);
        inputport_d   : in  std_logic_vector(31 downto 0);
        inputport_q   : out std_logic_vector(31 downto 0)
    );
end f_d_reg;

architecture dff of f_d_reg is
begin
    process(clk, rst)
    begin
        if rst = '1' then
            instruction_q <= (others => '0');
            pc_q          <= (others => '0');
            inputport_q   <= (others => '0');
        elsif rising_edge(clk) then
            if flush = '1' then
                instruction_q <= (others => '0');
                pc_q          <= (others => '0');
                inputport_q   <= (others => '0');
            elsif enable = '1' then
                instruction_q <= instruction_d;
                pc_q          <= pc_d;
                inputport_q   <= inputport_d;
            end if;
        end if;
    end process;
end dff;