library ieee;
use ieee.std_logic_1164.all;

entity decode is
    port(
        clk, rst : in std_logic;

        -- instruction input
        instruction_in : in std_logic_vector(31 downto 0);

        -- pass-through
        pc_in          : in  std_logic_vector(31 downto 0);
        pc_out         : out std_logic_vector(31 downto 0);
        input_port_in  : in  std_logic_vector(31 downto 0);
        input_port_out : out std_logic_vector(31 downto 0);

        -- writeback interface (feeds back into reg_file)
        mem_wb_regwrite1 : in std_logic;
        mem_wb_regwrite2 : in std_logic;
        mem_wb_waddr1    : in std_logic_vector(2 downto 0);
        mem_wb_waddr2    : in std_logic_vector(2 downto 0);
        mem_wb_wdata1    : in std_logic_vector(31 downto 0);
        mem_wb_wdata2    : in std_logic_vector(31 downto 0);

        -- instruction fields out (for forwarding unit)
        rs_out     : out std_logic_vector(2 downto 0);
        rt_out     : out std_logic_vector(2 downto 0);
        rd_out     : out std_logic_vector(2 downto 0);

        -- reg_file read data
        readdata1 : out std_logic_vector(31 downto 0);
        readdata2 : out std_logic_vector(31 downto 0);

        -- sign extended immediate
        immediate_out : out std_logic_vector(31 downto 0);

        -- to control_unit
        opcode_out : out std_logic_vector(4 downto 0)
    );
end decode;

architecture behavioral of decode is

    -- internal wires
    signal rs_sig, rt_sig, rd_sig : std_logic_vector(2 downto 0);

begin

    -- ── Instruction field slicing ────────────────────────────────
    -- assuming format: [31:27]=opcode [26:24]=rs [23:21]=rt [20:18]=rd [15:0]=imm
    opcode_out <= instruction_in(31 downto 27);
    rd_sig     <= instruction_in(26 downto 24); --rdst
    rs_sig     <= instruction_in(23 downto 21); --rsrc1
    rt_sig     <= instruction_in(20 downto 18); --rsrc2

    rd_out <= rd_sig;   -- rdst  [26:24]
    rs_out <= rs_sig;   -- rsrc1 [23:21]
    rt_out <= rt_sig;   -- rsrc2 [20:18]

    -- ── Pass-throughs ────────────────────────────────────────────
    pc_out         <= pc_in;
    input_port_out <= input_port_in;

    -- ── Register file instantiation ──────────────────────────────
    U_REGFILE : entity work.reg_file
        generic map(N => 32, M => 8)
        port map(
            clk           => clk,
            rst           => rst,
            -- read ports: rs reads readdata1, rt reads readdata2
            readaddress1 => rs_sig,   -- rsrc1 → readdata1
            readaddress2 => rt_sig,   -- rsrc2 → readdata2
            -- write ports: fed from writeback stage
            writeaddress1 => mem_wb_waddr1,
            writeaddress2 => mem_wb_waddr2,
            wenable1      => mem_wb_regwrite1,
            wenable2      => mem_wb_regwrite2,
            writeport1    => mem_wb_wdata1,
            writeport2    => mem_wb_wdata2,
            -- read outputs
            readport1     => readdata1,
            readport2     => readdata2
        );

    -- ── Sign extend instantiation ────────────────────────────────
    U_SIGNEXT : entity work.sign_extend
        port map(
            input  => instruction_in(17 downto 2),
            output => immediate_out
        );

end behavioral;