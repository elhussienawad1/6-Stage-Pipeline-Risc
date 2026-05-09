Library ieee;
use ieee.std_logic_1164.all;

entity single_bit_adder is
    port (
        A : in std_logic;
        B : in std_logic;
        Cin : in std_logic;
        S : out std_logic;
        Cout : out std_logic
    );
end entity single_bit_adder;

Architecture single_bit_adder_imp of single_bit_adder is
begin
    S <= A xor B xor Cin;
    Cout <= (A and B) or (Cin and (A xor B));
end Architecture single_bit_adder_imp;