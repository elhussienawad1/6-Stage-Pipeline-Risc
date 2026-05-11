library ieee;
use ieee.std_logic_1164.all;

entity execute_2 is
    port(
        rst,clk: in std_logic;
        clk_en: in std_logic;
        rsrc,imm_val: in std_logic_vector(31 downto 0);
        branch_type: in std_logic_vector(1 downto 0);
        branch,Z,C,Neg: in std_logic;
        pc_src: out std_logic;
        address: out std_logic_vector(31 downto 0)
    );
end execute_2;

architecture a_execute_2 of execute_2 is
    signal cout: std_logic;
    signal address_a: std_logic_vector(31 downto 0);
    begin
        process(clk, rst)
        begin
            if rst = '1' then
                pc_src <= '0';
            elsif clk'event and clk = '1' then
                if clk_en = '1' then
                    if branch = '1' then
                        if (branch_type = "11") or (branch_type = "00" and Z = '1')
                            or (branch_type = "01" and C = '1') or (branch_type = "10" and Neg = '1') then
                            pc_src <= '1';
                        else
                            pc_src <= '0';
                        end if;
                    else
                        pc_src <= '0';
                    end if;
                end if;
            end if;
        end process;

    address_adder: entity work.carry_select_adder PORT MAP(rsrc, imm_val, '0', address_a, cout);
    address <= address_a;
    end a_execute_2;
