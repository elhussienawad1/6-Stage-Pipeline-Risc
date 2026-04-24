LIBRARY IEEE;
USE IEEE.std_logic_1164.all;

ENTITY ripple_adder IS
    GENERIC (n : integer := 32);
    PORT(
        a, b  : in  std_logic_vector(n-1 downto 0);
        c_in  : in  std_logic;
        s     : out std_logic_vector(n-1 downto 0);
        c_out : out std_logic
    );
END ripple_adder;

ARCHITECTURE a_ripple_adder OF ripple_adder IS
    COMPONENT one_bit_adder IS
        PORT (a, b, cin : IN  std_logic;
              s, cout   : OUT std_logic);
    END COMPONENT;

    SIGNAL c : std_logic_vector(n downto 0);
BEGIN
    c(0) <= c_in;
    gen: FOR i IN 0 TO n-1 GENERATE
        fa: one_bit_adder PORT MAP(a(i), b(i), c(i), s(i), c(i+1));
    END GENERATE;
    c_out <= c(n);
END a_ripple_adder;