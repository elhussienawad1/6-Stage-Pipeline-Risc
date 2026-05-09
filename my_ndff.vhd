library ieee;
use ieee.std_logic_1164.all;
entity my_ndff is
    generic (n:integer:=12);
    port(
        Rst,Clk: in std_logic;
        d:in std_logic_vector(n-1 downto 0);
        q:out std_logic_vector(n-1 downto 0)
    );
end my_ndff;

architecture b_my_ndff of my_ndff is
component my_dff is 
    port(d,clk,rst:in std_logic; q: out std_logic);
end component;
begin
loop1: for i in 0 to n-1 generate 
    fx: my_dff port map(d(i),Clk,Rst,q(i));
    end generate;
end b_my_ndff;