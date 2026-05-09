library ieee;
use ieee.std_logic_1164.all;

entity execute_1 is 
    generic (n:integer :=32);
    port(
        clk,rst: in std_logic; --for ccr
        clk_enable: in std_logic;
        r_rs1 : in std_logic_vector(n-1 downto 0);
        r_rs2 : in std_logic_vector(n-1 downto 0);
        imm : in std_logic_vector(n-1 downto 0);
        alu_result : out std_logic_vector(n-1 downto 0);

        --forwarding inputs
        ex1_ex2_result : in std_logic_vector(n-1 downto 0);
        ex2_mem_result : in std_logic_vector(n-1 downto 0);
        mem_wb_result : in std_logic_vector(n-1 downto 0);
        forward_a : in  std_logic_vector(1 downto 0);
        forward_b : in  std_logic_vector(1 downto 0);

        --alu flags
        zero : out std_logic;
        negative : out std_logic;
        carry : out std_logic;

        --control signals
        alu_src : in std_logic; 
        alu_operation : in std_logic_vector(2 downto 0); --alu select add=001 sub=011 and=100 not=010
        set_carry : in std_logic;
        alu_passthrough : in std_logic;
        store_ccr : in std_logic;
        flag_enable : in std_logic;
        restore_ccr : in std_logic
    );
end execute_1;

architecture a_execute_1 of execute_1 is
    COMPONENT alu IS
        GENERIC (n : integer := 32);
        PORT(
            a,b : in std_logic_vector(n-1 downto 0);
            c_in : in std_logic;
            sel : in std_logic_vector(2 downto 0);
            result : out std_logic_vector(n-1 downto 0);
            c_out,zero,negative : out std_logic
        );
    END COMPONENT;

    component ccr is
        Port (
        clk: in std_logic;
        rst: in std_logic;
        flag_enable: in std_logic;
        clk_enable: in std_logic;
        alu_Z: in std_logic;
        alu_N: in std_logic;
        alu_C: in std_logic;
        zero: out std_logic;
        negative: out std_logic;
        carry: out std_logic
    );
    end component;


    --operands and result
    signal operand_1 : std_logic_vector(n-1 downto 0);
    signal operand_2_interm : std_logic_vector(n-1 downto 0);
    signal operand_2 : std_logic_vector(n-1 downto 0);
    signal alu_result_temp : std_logic_vector(n-1 downto 0);
    --flags
    signal alu_zero : std_logic;
    signal alu_negative : std_logic;
    signal alu_carry : std_logic;
    signal alu_carry_temp : std_logic;

    signal ccr_main_in_zero : std_logic;
    signal ccr_main_in_negative : std_logic;
    signal ccr_main_in_carry : std_logic;
    signal ccr_main_out_zero : std_logic;
    signal ccr_main_out_negative : std_logic;
    signal ccr_main_out_carry : std_logic;

    signal ccr_store_zero : std_logic;
    signal ccr_store_negative : std_logic;
    signal ccr_store_carry : std_logic;

    begin 
        exec_1_alu : alu generic map(n) port map (operand_1,operand_2,'0',alu_operation,alu_result_temp,alu_carry_temp,alu_zero,alu_negative);
        ccr_main : ccr port map(clk,rst,clk_enable,flag_enable,ccr_main_in_zero,ccr_main_in_negative,ccr_main_in_carry,ccr_main_out_zero,ccr_main_out_negative,ccr_main_out_carry);
        ccr_restore : ccr port map(clk,rst,clk_enable,store_ccr,ccr_main_out_zero,ccr_main_out_negative,ccr_main_out_carry,ccr_store_zero,ccr_store_negative,ccr_store_carry);

        operand_2_interm<=r_rs2 when alu_src='0'
        else imm;

        operand_2<= operand_2_interm when forward_b="00"
        else ex1_ex2_result when forward_b="01"
        else ex2_mem_result when forward_b="10"
        else mem_wb_result;

        operand_1<= r_rs1 when forward_a="00"
        else ex1_ex2_result when forward_a="01"
        else ex2_mem_result when forward_a="10"
        else mem_wb_result;

        alu_carry<='1' when set_carry='1'
        else alu_carry_temp;

        ccr_main_in_zero<=alu_zero when restore_ccr='0'
        else ccr_store_zero;


        ccr_main_in_negative<=alu_negative when restore_ccr='0'
        else ccr_store_negative;

        ccr_main_in_carry<=alu_carry when restore_ccr='0'
        else ccr_store_carry;

        --outputs
        alu_result<=alu_result_temp when alu_passthrough='0'
        else imm;

        zero<=ccr_main_out_zero;
        negative<=ccr_main_out_negative;
        carry<=ccr_main_out_carry;

    end a_execute_1;

