library std;
use std.textio.all;

library ieee;
use ieee.std_logic_1164.all;

library work;
use ieee.std_logic_unsigned.ALL;

entity Testbench is
end entity;
architecture struc of Testbench is

component Pipe_V2 is
port (r0, r1, r2, r3, r4, r5, r6, r7 : out std_logic_vector(15 downto 0);
	c_flag, z_flag: out std_logic; 
	clock : in std_logic);
end component Pipe_V2;

signal clk50: std_logic :='1';
--signal Wrsignal: std_logic :='1';
signal r0, r1, r2, r3, r4, r5, r6, r7 : std_logic_vector(15 downto 0);
signal c_flag, z_flag : std_logic; 

constant clkper:time:= 20 ns;
begin
p: Pipe_V2 port map(clock => clk50, r0 => r0, r1 => r1, r2 =>r2 , r3 => r3, r4 => r4, r5 =>r5, r6 =>r6, r7 =>r7,
								c_flag => c_flag, z_flag => z_flag);
   clk50 <= not clk50 after clkper/2;
	--Wrsignal <= '0' after clkper;
end struc;