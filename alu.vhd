library ieee;
use ieee.std_logic_1164.all;

entity alu is
    GENERIC (n : integer := 32);
    port(
        a,b : in std_logic_vector(n-1 downto 0);
        c_in : in std_logic;
        sel : in std_logic_vector(2 downto 0);
        result : out std_logic_vector(n-1 downto 0);
        c_out,zero,negative : out std_logic
    );
end alu;

architecture arch of alu is
    COMPONENT carry_select_adder IS
        GENERIC (n : integer := 32);
        PORT(
            a, b  : in  std_logic_vector(n-1 downto 0);
            c_in  : in  std_logic;
            s     : out std_logic_vector(n-1 downto 0);
            c_out : out std_logic
        );
    END COMPONENT;

    signal cin_temp : std_logic;
    signal adder_output : std_logic_vector(n-1 downto 0);
    signal not_b: std_logic_vector(n-1 downto 0);
    signal b_temp: std_logic_vector(n-1 downto 0);
    signal cout_temp: std_logic;
    signal result_temp:std_logic_vector(n-1 downto 0);
    signal zeros: std_logic_vector(n-1 downto 0) :=(others=>'0');
    
    begin 
        not_b<=not b;
        adder: carry_select_adder generic map (n) port map(a,b_temp,cin_temp,adder_output,cout_temp);
        --add uses b, sub uses not b and cin=1
        -- add=001 sub=011
        b_temp<=b when sel="001"
        else not_b;

        cin_temp<= '1' when sel="011"
        else c_in;

        result_temp<= a and b when sel="100"
        else not a when sel="010"
        else adder_output;

        
        c_out<=cout_temp when sel="001" or sel="011" 
        else c_in;
        negative<=result_temp(n-1);
        zero<='1' when result_temp=zeros
        else '0';

        result<=result_temp;
     
end arch ;