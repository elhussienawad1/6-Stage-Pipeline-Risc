library ieee;
use ieee.std_logic_1164.all;

entity mem_wb_forwarding is
    generic (n : integer := 32);
    port(
        clk, rst : in std_logic;
        clk_en   : in std_logic;

        -- data inputs
        incremented_pc_in : in std_logic_vector(n-1 downto 0);
        in_port_in        : in std_logic_vector(n-1 downto 0);
        r_rsrc1_in        : in std_logic_vector(n-1 downto 0);
        r_rsrc2_in        : in std_logic_vector(n-1 downto 0);
        alu_result_in     : in std_logic_vector(n-1 downto 0);
        mem_data_in       : in std_logic_vector(n-1 downto 0);
        rdst_in           : in std_logic_vector(2 downto 0);
        rsrc1_in          : in std_logic_vector(2 downto 0);

        -- control inputs
        output_enable_in : in std_logic;
        mem_to_reg_in    : in std_logic;
        reg_to_reg_in    : in std_logic;
        input_enable_in  : in std_logic;
        reg_write_in     : in std_logic;
        reg2_write_in    : in std_logic;

        -- data outputs
        incremented_pc_out : out std_logic_vector(n-1 downto 0);
        in_port_out        : out std_logic_vector(n-1 downto 0);
        r_rsrc1_out        : out std_logic_vector(n-1 downto 0);
        r_rsrc2_out        : out std_logic_vector(n-1 downto 0);
        alu_result_out     : out std_logic_vector(n-1 downto 0);
        mem_data_out       : out std_logic_vector(n-1 downto 0);
        rdst_out           : out std_logic_vector(2 downto 0);
        rsrc1_out          : out std_logic_vector(2 downto 0);

        -- control outputs
        output_enable_out : out std_logic;
        mem_to_reg_out    : out std_logic;
        reg_to_reg_out    : out std_logic;
        input_enable_out  : out std_logic;
        reg_write_out     : out std_logic;
        reg2_write_out    : out std_logic
    );
end mem_wb_forwarding;

architecture a_mem_wb_forwarding of mem_wb_forwarding is
begin
    process(clk, rst)
    begin
        if rst = '1' then
            incremented_pc_out <= (others => '0');
            in_port_out        <= (others => '0');
            r_rsrc1_out        <= (others => '0');
            r_rsrc2_out        <= (others => '0');
            alu_result_out     <= (others => '0');
            mem_data_out       <= (others => '0');
            rdst_out           <= (others => '0');
            rsrc1_out          <= (others => '0');
            output_enable_out  <= '0';
            mem_to_reg_out     <= '0';
            reg_to_reg_out     <= '0';
            input_enable_out   <= '0';
            reg_write_out      <= '0';
            reg2_write_out     <= '0';
        elsif rising_edge(clk) then
            if clk_en = '1' then
                incremented_pc_out <= incremented_pc_in;
                in_port_out        <= in_port_in;
                r_rsrc1_out        <= r_rsrc1_in;
                r_rsrc2_out        <= r_rsrc2_in;
                alu_result_out     <= alu_result_in;
                mem_data_out       <= mem_data_in;
                rdst_out           <= rdst_in;
                rsrc1_out          <= rsrc1_in;
                output_enable_out  <= output_enable_in;
                mem_to_reg_out     <= mem_to_reg_in;
                reg_to_reg_out     <= reg_to_reg_in;
                input_enable_out   <= input_enable_in;
                reg_write_out      <= reg_write_in;
                reg2_write_out     <= reg2_write_in;
            end if;
        end if;
    end process;
end a_mem_wb_forwarding;
