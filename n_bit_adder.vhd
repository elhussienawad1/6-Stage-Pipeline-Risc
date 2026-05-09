Library ieee;
use ieee.std_logic_1164.all;

entity n_bit_adder is
    GENERIC (
        N : integer := 32;
        M : integer := 4
    );
    port (
        A : in std_logic_vector(N-1 downto 0);
        B : in std_logic_vector(N-1 downto 0);
        Cin : in std_logic;
        S : out std_logic_vector(N-1 downto 0);
        Cout : out std_logic
    );
end entity n_bit_adder;

Architecture n_bit_adder_imp of n_bit_adder is
    Component  ripple_adder is
        port (
            A : in std_logic_vector(M-1 downto 0);
            B : in std_logic_vector(M-1 downto 0);
            Cin : in std_logic;
            S : out std_logic_vector(M-1 downto 0);
            Cout : out std_logic
        );
    end Component;
    Component carry_select_adder is
        port (
            A : in std_logic_vector(M-1 downto 0);
            B : in std_logic_vector(M-1 downto 0);
            Cin : in std_logic;
            S : out std_logic_vector(M-1 downto 0);
            Cout : out std_logic
        );
    end Component;
    signal c : std_logic_vector(N/M downto 0);
begin
    r0: ripple_adder GENERIC MAP (M) port map (A(M-1 downto 0), B(M-1 downto 0), Cin, S(M-1 downto 0), c(0));
    GEN_LOOP: for i in 1 to (N/M - 1) generate
        cs: carry_select_adder port map (A(i*M+M-1 downto i*M), B(i*M+M-1 downto i*M), c(i-1), S(i*M+M-1 downto i*M), c(i));
    end generate GEN_LOOP;
    Cout <= c(N/M - 1);
end Architecture n_bit_adder_imp; 