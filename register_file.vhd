library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity reg_file is
    generic( N: integer := 32; M: integer := 8 );
    port(
        clk, rst : in std_logic;
        readaddress1, readaddress2 : in std_logic_vector(2 downto 0);
        writeaddress1, writeaddress2 : in std_logic_vector(2 downto 0);
        wenable1, wenable2 : in std_logic;
        writeport1, writeport2 : in std_logic_vector(N-1 downto 0);
        readport1, readport2 : out std_logic_vector(N-1 downto 0)
    );
end reg_file;

architecture structure of reg_file is

    type reg_array is array (0 to M-1) of std_logic_vector(N-1 downto 0);
    signal q_regs : reg_array;  -- the actual registers

begin

    gen_regs: for i in 0 to M-1 generate
    begin
        process(clk, rst)
        begin
            if rst = '1' then
                q_regs(i) <= (others => '0');
            elsif falling_edge(clk) then
                if wenable1 = '1' and to_integer(unsigned(writeaddress1)) = i then
                    q_regs(i) <= writeport1;
                end if;
                if wenable2 = '1' and to_integer(unsigned(writeaddress2)) = i then
                    q_regs(i) <= writeport2;
                end if;
            end if;
        end process;
    end generate;

    -- combinational read
    readport1 <= q_regs(to_integer(unsigned(readaddress1)));
    readport2 <= q_regs(to_integer(unsigned(readaddress2)));

end architecture;