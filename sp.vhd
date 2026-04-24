library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sp is
    generic (n: integer := 32);
    port(
        Rst, Clk: in std_logic;
        d: in std_logic_vector(n-1 downto 0);
        q: out std_logic_vector(n-1 downto 0)
    );
end sp;

architecture a_sp of sp is
    constant SP_INITIAL_VALUE: std_logic_vector(n-1 downto 0) := 
        std_logic_vector(to_unsigned(2**12 - 1, n));
begin 
process(Clk, Rst)
begin
    if Rst = '1' then
        q <= SP_INITIAL_VALUE;
    elsif rising_edge(Clk) then 
        q <= d; 
    end if;
end process;
end a_sp;