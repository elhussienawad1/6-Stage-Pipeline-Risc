library ieee;
use ieee.std_logic_1164.all;

entity CCR is
    Port (
        clk: in std_logic;            -- Clock
        rst: in std_logic;            -- Synchronous reset
        flag_enable: in std_logic;    -- 1 = update CCR with new ALU flags

        -- Inputs from ALU
        alu_Z: in std_logic;    -- Zero flag from ALU
        alu_N: in std_logic;    -- Negative flag from ALU
        alu_C: in std_logic;    -- Carry flag from ALU

        -- Outputs (to branch instructions / control)
        Z: out std_logic;
        N: out std_logic;
        C: out std_logic;
        branch_type: in std_logic_vector(1 downto 0);
        do_branch: in std_logic
    );
end CCR;

architecture Behavioral of CCR is
    -- Internal registers to store CCR flags
    signal Z_reg, N_reg, C_reg: std_logic;
begin
    process(clk, rst)
    begin
        if rst = '1' then
            -- Reset all flags to 0
            Z_reg <= '0';
            N_reg <= '0';
            C_reg <= '0';
            
        elsif rising_edge(clk) then
            if flag_enable = '1' then
                -- Update flags from ALU only when control signal updateFlags = 1
                Z_reg <= alu_Z;
                N_reg <= alu_N;
                C_reg <= alu_C;
            end if;
            if do_branch = '1' then
                if branch_type = "01" then
                    Z_reg <= '0';
                elsif  branch_type = "11" then
                    C_reg <= '0';
                elsif  branch_type = "10" then
                    N_reg <= '0';
                end if;
                    
                    
            end if;
        end if;
    end process;

    -- immediate output when flag_enable is high
    Z <= alu_Z when flag_enable = '1' else Z_reg;
    N <= alu_N when flag_enable = '1' else N_reg;
    C <= alu_C when flag_enable = '1' else C_reg;

end Behavioral;