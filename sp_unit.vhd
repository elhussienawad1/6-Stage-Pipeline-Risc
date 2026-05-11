library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sp_unit is
    port(
        clk, rst    : in std_logic;
        inc_sp      : in std_logic;
        dec_sp      : in std_logic;
        sp_q        : out std_logic_vector(31 downto 0);
        sp_plus_one : out std_logic_vector(31 downto 0)
    );
end sp_unit;

architecture a_sp_unit of sp_unit is

    signal q_int        : std_logic_vector(31 downto 0);
    signal d_int        : std_logic_vector(31 downto 0);
    signal plus_one_int : std_logic_vector(31 downto 0);
    signal minus_one    : std_logic_vector(31 downto 0);

begin

    sp_reg: entity work.sp port map(rst, clk, d_int, q_int);

    plus_one_int <= std_logic_vector(unsigned(q_int) + 1);
    minus_one    <= std_logic_vector(unsigned(q_int) - 1);

    -- SP update: hold unless inc or dec
    d_int <= plus_one_int when inc_sp = '1'
        else minus_one    when dec_sp = '1'
        else q_int;

    sp_q        <= q_int;
    sp_plus_one <= plus_one_int;

end a_sp_unit;
