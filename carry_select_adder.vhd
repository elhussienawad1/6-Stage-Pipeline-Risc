LIBRARY IEEE;
USE IEEE.std_logic_1164.all;

ENTITY carry_select_adder IS
    GENERIC (n : integer := 32);
    PORT(
        a, b  : in  std_logic_vector(n-1 downto 0);
        c_in  : in  std_logic;
        s     : out std_logic_vector(n-1 downto 0);
        c_out : out std_logic
    );
END carry_select_adder;

ARCHITECTURE a_carry_select_adder OF carry_select_adder IS
    COMPONENT ripple_adder IS
        GENERIC (n : integer := 32);
        PORT(
            a, b  : in  std_logic_vector(n-1 downto 0);
            c_in  : in  std_logic;
            s     : out std_logic_vector(n-1 downto 0);
            c_out : out std_logic
        );
    END COMPONENT;

    SIGNAL s0, s1         : std_logic_vector(n-1 downto 0);
    SIGNAL c_out0, c_out1 : std_logic;
BEGIN
    ra0: ripple_adder GENERIC MAP(n=>n) PORT MAP(a, b, '0', s0, c_out0);
    ra1: ripple_adder GENERIC MAP(n=>n) PORT MAP(a, b, '1', s1, c_out1);

    s     <= s0 when c_in = '0' else s1;
    c_out <= c_out0 when c_in = '0' else c_out1;
END a_carry_select_adder;