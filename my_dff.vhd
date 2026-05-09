library ieee;
use ieee.std_logic_1164.all;

entity my_dff is
	port(d,clk,rst:in STD_LOGIC; q: out STD_LOGIC);
end my_dff;

architecture dff of my_dff is
begin
	process(clk,rst)
	begin
		if (rst='1') then
			q <= '0';
		elsif clk'event and clk = '1' then
			q <= d;
		end if;
	end process;
end dff;