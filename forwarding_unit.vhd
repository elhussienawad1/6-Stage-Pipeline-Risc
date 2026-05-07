library ieee;
use ieee.std_logic_1164.all;

entity forwarding_unit is
    port(
        mem_wb_regwrite : in std_logic;
        ex1_ex2_regwrite : in std_logic;
        ex2_mem_regwrite: in std_logic;
        mem_wb_rdst : in std_logic_vector(4 downto 0);
        id_ex1_rs1 : in std_logic_vector(4 downto 0);
        id_ex1_rs2 : in std_logic_vector(4 downto 0);
        ex1_ex2_rdst : in std_logic_vector(4 downto 0);
        ex2_mem_rdst : in std_logic_vector(4 downto 0);
        forward_a : out std_logic_vector(1 downto 0);
        forward_b : out std_logic_vector(1 downto 0)
    );
end forwarding_unit;

architecture a_forwarding_unit of forwarding_unit is
    --used for zero checks
    signal zeros: std_logic_vector(4 downto 0) :=(others=>'0');

    begin   
        forward_a<= "01" when ex1_ex2_regwrite='1' and ex1_ex2_rdst/=zeros and ex1_ex2_rdst=id_ex1_rs1
        else "10" when ex2_mem_regwrite='1' and ex2_mem_rdst/=zeros and ex2_mem_rdst=id_ex1_rs1
        else "11" when mem_wb_regwrite='1' and mem_wb_rdst/=zeros and mem_wb_rdst=id_ex1_rs1
        else "00";

        forward_b<= "01" when ex1_ex2_regwrite='1' and ex1_ex2_rdst/=zeros and ex1_ex2_rdst=id_ex1_rs2
        else "10" when ex2_mem_regwrite='1' and ex2_mem_rdst/=zeros and ex2_mem_rdst=id_ex1_rs2
        else "11" when mem_wb_regwrite='1' and mem_wb_rdst/=zeros and mem_wb_rdst=id_ex1_rs2
        else "00";

end a_forwarding_unit;
