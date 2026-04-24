library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use ieee.std_logic_textio.all;

entity reg_file_memory is
    generic( N: integer := 32; M: integer := 1024 );
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

    -- 1024 * 4 bytes = 4KB    
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
    signal memory : mem_array := init_memory_from_file("./comparch_project/test.mem");
    signal readdata, instruction : std_logic_vector(N-1 downto 0);
    signal internal_memory_busy : std_logic;
begin
    process(clk, rst)
        variable access_conflict : boolean;
    begin
        if rst = '1' then
            internal_memory_busy <= '0';
         elsif rising_edge(clk) then
            -- Check for memory access conflict
            access_conflict := false;
            
            -- Data memory access requested
            if mem_write = '1' or mem_read = '1' then
                -- Instruction fetch always happens (PC is always reading)
                -- In Von Neumann, both can't access memory simultaneously
                access_conflict := true;
            end if;
            
            if access_conflict then
                internal_memory_busy <= '1';
                -- Priority: data memory access over instruction fetch
                if mem_write = '1' then
                    memory(to_integer(unsigned(address(11 downto 0)))) <= writedata;
                end if;
                -- If mem_read = '1', readdata will be available next cycle
            else
                internal_memory_busy <= '0';
            end if;
        end if;
    end process;
   readdata <= memory(to_integer(unsigned(address(11 downto 0)))) when mem_read = '1' 
                else (others => '0');
    
    instruction <= memory(to_integer(unsigned(instruction_address(11 downto 0))));
    
    -- Output selection
    mem_output <= readdata when mem_read = '1' 
                  else instruction;
    
    memory_busy <= internal_memory_busy;
    mem1 <= memory(0);
    mem2 <= memory(1);
    mem3<= memory(2);
    mem4<= memory(3);
end structure;