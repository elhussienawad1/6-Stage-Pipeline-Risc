LIBRARY IEEE;
USE IEEE.std_logic_1164.all;

ENTITY one_bit_adder IS
    PORT (a,b,cin : IN  std_logic;
          s, cout : OUT std_logic);
END one_bit_adder;

ARCHITECTURE a_one_bit_adder OF one_bit_adder IS
BEGIN
    s    <= a XOR b XOR cin;
    cout <= (a AND b) OR (cin AND (a XOR b));
END a_one_bit_adder;