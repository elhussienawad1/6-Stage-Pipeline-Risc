library ieee;
use ieee.std_logic_1164.all;
entity pc is
    generic (n:integer:=32);
    port(
        rst,clk: in std_logic;
        enable: in std_logic;
        pc_src: in std_logic;
        d:in std_logic_vector(n-1 downto 0);
        mem1: in std_logic_vector(n-1 downto 0);
        q:out std_logic_vector(n-1 downto 0)
    );
end pc;
architecture a_pc of pc is
begin 
process(clk,rst)
begin
    if(rst='1')then
	    q<= mem1;
    elsif clk'event and clk = '1' and (enable= '1' or pc_src='1')then 
        q<=d; 
    end if;
end process;
end a_pc;