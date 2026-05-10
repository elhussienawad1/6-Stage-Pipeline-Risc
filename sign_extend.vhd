LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;

entity sign_extend is
    port(
        input  : in  std_logic_vector(15 downto 0);
        output : out std_logic_vector(31 downto 0)
    );
end sign_extend;

architecture behavioral of sign_extend is
begin

    output <= (31 downto 16 => input(15)) & input;

end behavioral;

