library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use ieee.std_logic_textio.all;

entity reg_file_memory is
    generic( N: integer := 32; M: integer := 4096 );
    port(
        clk, rst : in std_logic;
        address, instruction_address  : in std_logic_vector(31 downto 0);
        mem_write, mem_read : in std_logic;
        writedata : in std_logic_vector(N-1 downto 0);
        mem_output : out std_logic_vector(N-1 downto 0);
        memory_busy : out std_logic;
        mem1 : out std_logic_vector(N-1 downto 0);
        mem2:out std_logic_vector(N-1 downto 0);
        mem3:out std_logic_vector(N-1 downto 0);
        mem4:out std_logic_vector(N-1 downto 0)
    );
end reg_file_memory;

architecture structure of reg_file_memory is

    -- 4096 * 4 bytes = 16KB (addresses 0x000..0xFFF; SP resets to 0xFFF)
    type mem_array is array (0 to M-1) of std_logic_vector(N-1 downto 0);
    -- Function to initialize memory from file (simulation only)
    impure function init_memory_from_file(filename : string) return mem_array is
        file mem_file : text open read_mode is filename;
        variable line_buf : line;
        variable bin_val : std_logic_vector(N-1 downto 0);
        variable memory : mem_array;
        variable i : integer := 0;
    begin
        -- Initialize all memory to zeros first
        memory := (others => (others => '0'));
        
        -- Read from file until EOF or memory is full
        while not endfile(mem_file) and i < M loop
            readline(mem_file, line_buf);
            read(line_buf, bin_val);
            memory(i) := bin_val;
            i := i + 1;
        end loop;
        
        return memory;
    end function;
    -- Initialize memory using the function
    signal memory : mem_array := init_memory_from_file("./test.mem");
    signal readdata, instruction : std_logic_vector(N-1 downto 0);
begin
    -- Synchronous write only; reads are combinatorial (SRAM-like)
    process(clk, rst)
    begin
        if rst = '1' then
            null;  -- no registers to reset
        elsif rising_edge(clk) then
            -- Unconditional write on clock edge when write-enable is asserted
            if mem_write = '1' then
                memory(to_integer(unsigned(address(11 downto 0)))) <= writedata;
            end if;
        end if;
    end process;

    -- Combinatorial reads: available in the same cycle (no latency)
    readdata    <= memory(to_integer(unsigned(address(11 downto 0)))) when mem_read = '1'
                   else (others => '0');
    instruction <= memory(to_integer(unsigned(instruction_address(11 downto 0))));

    -- Assert memory_busy combinatorially so the fetch stage is stalled
    -- in the SAME cycle as the data write (Von Neumann structural hazard).
    -- Pure data reads alongside instruction fetch are safe (two reads, no conflict).
    memory_busy <= '1' when mem_write = '1' else '0';

    -- Output selection
    mem_output <= readdata when mem_read = '1'
                  else instruction;
    mem1 <= memory(0);
    mem2 <= memory(1);
    mem3<= memory(2);
    mem4<= memory(3);
end structure;