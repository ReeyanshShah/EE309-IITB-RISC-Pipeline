library ieee; 
use ieee.std_logic_1164.all; 
use ieee.numeric_std.all; 



entity Pipe_V2 is
port (r0, r1, r2, r3, r4, r5, r6, r7 : out std_logic_vector(15 downto 0);
	c_flag, z_flag: out std_logic; 
	clock : in std_logic);
end Pipe_V2;


architecture bhv of Pipe_V2 is

--signal clock: std_logic := '1';
--constant clk_period : time := 20 ns;
--clock <= not clock after clk_period/2;


type mem is array(511 downto 0) of std_logic_vector(15 downto 0);	
signal mem_reg : mem := (
	0 =>   "0001001010011000",
  	2 =>   "0010011100101000",
	1 =>   "0100101011000001",
	3 =>   "1000110111000001",
	5 =>   "0011001011100001",
	others=>"1110000000000000");

	
type regfile is array(7 downto 0) of std_logic_vector(15 downto 0);	
signal RF : regfile := ( 	
		0 => "0000000000000000",
		1 => "0000000000000001",
		2 => "0000000000000001",
		3 => "0000000000000011",
		4 => "0000000000000100",
		5 => "0000000000000101",
		6 => "0000000000011110",
		7 => "0000000000000111"
		);


signal is_it_load, load_wait_over, r0_change, C_in, Z_in, Z_fwd, C_out, Z_out, C_alu_out,
		 C_fwd, Z_alu_out : std_logic := '0'; 
		 


signal C, Z: std_logic := '0'; 		 
signal r0_change_wait_counter, initial_counter : integer := 0; --initial_counter is to offset the number of r0 changes that should have happened from the start

signal alu_out, alu_out_reg, alu_out_fwd_reg, alu_a, alu_load_a, alu_b, alu_load_b, mem_read_out, r_dest : std_logic_vector(15 downto 0) := "0000000000000000";

signal it1, it2, it3, it4, it5, ir6 : std_logic_vector(15 downto 0) := "1110000000000000";

signal c1, c2, c3, c4 : std_logic_vector(4 downto 0) := "00000";  -- r0 write, C write, Z write, mem write, reg write

signal Ext6, Ext6_exec, Ext9, Ext9_exec, Imm_times_2_6, Imm_times_2_9, IExt6, IExt9 : std_logic_vector(15 downto 0) := "0000000000000000";

component ALU_V2 is
    port(ALU_A, ALU_B,ALU_load_A, ALU_load_B, r_dest: in std_logic_vector(15 downto 0);
        C, Z: in std_logic;
        it3, it5: in std_logic_vector(15 downto 0); -- 14-12
        Output: out std_logic_vector(15 downto 0);
        C_out,Z_out: out std_logic
    );
end component;

begin

--------------------------------------------------------------------------------------------------------------------------------------
	
	
	Ext6(15 downto 5) <= (others => it2(5));
	Ext6(4 downto 0) <= it2(4 downto 0);
	
	Ext6_exec(15 downto 5) <= (others => it3(5));
	Ext6_exec(4 downto 0) <= it3(4 downto 0);
	
	Ext9_exec(15 downto 9) <= (others => it5(8));
	Ext9_exec(8 downto 0) <= it5(8 downto 0);

	Ext9(15 downto 8) <= (others => it2(8));
	Ext9(8 downto 0) <= it2(8 downto 0);
	
	IExt6(15 downto 5) <= (others => it5(5));
	IExt6(4 downto 0) <= it5(4 downto 0);

	IExt9(15 downto 8) <= (others => it5(8));
	IExt9(8 downto 0) <= it5(8 downto 0);
	
	Imm_times_2_6 <= std_logic_vector(unsigned(Ext6) + unsigned(Ext6));
	Imm_times_2_9 <= std_logic_vector(unsigned(Ext9) + unsigned(Ext9));
	
	MainALU : ALU_V2 port map(ALU_A => alu_a, ALU_B => alu_b, ALU_load_A => alu_load_a, ALU_load_B => alu_load_b, it3 => it3, it5 => it5, 
		r_dest => r_dest, C => C_in, Z => Z_in, Output => alu_out, C_out => C_alu_out, Z_out => Z_alu_out);
		
	

--------------------------------------------------------------------------------------------------------------------------------------



Instr_Fetch : process(clock)
begin
	
	if(clock' event and clock='0') then
	
		--load check
		
		
		
		--r0 changing check
		if (r0_change_wait_counter = 0) then
			if (r0_change = '1') then
				r0_change_wait_counter <= 1;
			end if;
		elsif (r0_change_wait_counter = 4) then
			r0_change_wait_counter <= 0;
		else 
			r0_change_wait_counter <= r0_change_wait_counter + 1;
		end if;	
		
	end if;
end process;


--------------------------------------------------------------------------------------------------------------------------------------


Instr_Decode : process(it1, clock)
begin
		
	
	-- mem write and reg write
	if(clock' event and clock='0' and is_it_load = '0' and r0_change_wait_counter = 0) then
		if (it1(15 downto 14) = "00" or  it1(14 downto 12) = "100" or it1(15 downto 12) = "1101" or it1(15 downto 13) = "100" or it1(15 downto 12) = "1111") then
			c1(0) <= '1';
			c1(1) <= '0';
		elsif (it1(15 downto 12) = "0101") then
			c1(1) <= '1';
			c1(0) <= '0';
		else 
			c1(1 downto 0) <= "00";
		end if;	
	elsif (clock' event and clock = '0') then
		c1(1 downto 0) <= "00";
	end if;
	
	if(clock' event and clock='0') then
		report "it1 " & integer'image(to_integer(unsigned(it1)));
		report "it2 " & integer'image(to_integer(unsigned(it2)));
		report "it3 " & integer'image(to_integer(unsigned(it3)));
		report "it4 " & integer'image(to_integer(unsigned(it4)));
		report "it5 " & integer'image(to_integer(unsigned(it5)));
		it2 <= it1;
		if (it1(15 downto 12) = "0011" or it1(15 downto 12) = "0100") then
			is_it_load <= '1';
		else
			is_it_load <= '0';
		end if;
	
		-- if r0 changes	
		if (it1(15) = '1' and ((it1(14) nand it1(13)) = '1')) then
			r0_change <= '1';
		elsif it1(15 downto 12) = "1111" then 
			r0_change <= '1';
		else
			r0_change <= '0';
		end if;
	end if;
	
	
	-- C write and Z write
	if(clock' event and clock='0' and is_it_load = '0' and r0_change_wait_counter = 0) then
		if (it1(15 downto 13) = "000") then
			c1(3 downto 2) <= "11";
		elsif (it1(15 downto 13) = "000" or it1(15 downto 12) = "0010" or it1(15 downto 12) = "0100") then
			c1(3 downto 2) <= "01";
		else 
			c1(3 downto 2) <= "00";
		end if;
	end if;


	
end process;


--------------------------------------------------------------------------------------------------------------------------------------



Reg_Read : process(clock)
begin
	if(clock' event and clock='0') then
	
		--C input
		if (c2(3) = '1') then
			C_in <= C_alu_out;
		elsif (c3(3) = '1') then
			C_in <= C_out;
		elsif (c4(3) = '1') then
			C_in <= C_fwd;
		else
			C_in <= C;
		end if;
			
			
		--Z input
		if (c2(2) = '1') then
			Z_in <= Z_alu_out;
		elsif (c3(2) = '1') then
			Z_in <= Z_out;
		elsif (c4(2) = '1') then
			Z_in <= Z_fwd;
		else
			Z_in <= Z;
		end if;
		
		r_dest <= RF(to_integer(unsigned(it2(5 downto 3))));
	
		--ADD/NAND
		if (it2(15 downto 12) = "0001" or it2(15 downto 12) = "0010") then
			-- check whether it3 is add/nand and if data forwarding is required
			if ((it3(15 downto 12) = "0001" or it3(15 downto 12) = "0010") and (it3(5 downto 3) = it2(11 downto 9) or ((it3(5 downto 3) = it2(8 downto 6))))) then 
				report "Hellooooo";
				-- check if it4 is aadd/nand and is also involved in data forwarding
				if((it4(15 downto 12) = "0001" or it4(15 downto 12) = "0010")and ((it4(5 downto 3) = it2(11 downto 9) or ((it4(5 downto 3) = it2(8 downto 6)))) and not (it4(5 downto 3) = it3(5 downto 3)))) then
					if (it3(5 downto 3) = it2(11 downto 9) and it4(5 downto 3) = it2(8 downto 6)) then
						alu_b <= alu_out_reg;
						alu_a<= alu_out;
					else
						alu_a <= alu_out_reg;
						alu_b <= alu_out;
					end if;
				elsif(it4(15 downto 12)="0000" and (it4(8 downto 6) = it2(11 downto 9) or it4(8 downto 6) = it2(8 downto 6)) and not (it4(8 downto 6) =  it3(5 downto 3))) then
					if (it3(5 downto 3) = it2(11 downto 9) and it4(8 downto 6) = it2(8 downto 6)) then
						alu_b <= alu_out_reg;
						alu_a<= alu_out;
					else
						alu_a <= alu_out_reg;
						alu_b <= alu_out;
					end if;
				-- if it5 is involved in data forwarding
				elsif((it5(15 downto 12) = "0001" or it5(15 downto 12) = "0010")and ((it5(5 downto 3) = it2(11 downto 9) or ((it5(5 downto 3) = it2(8 downto 6)))) and not (it5(5 downto 3) = it3(5 downto 3)))) then
					if (it3(5 downto 3) = it2(11 downto 9) and it5(5 downto 3) = it2(8 downto 6)) then
						alu_b <= alu_out_reg;
						alu_a<= alu_out;
					else
						alu_a <= alu_out_reg;
						alu_b <= alu_out;
					end if;
				elsif(it5(15 downto 12)="0000" and (it5(8 downto 6) = it2(11 downto 9) or it5(8 downto 6) = it2(8 downto 6)) and not (it5(8 downto 6) =  it3(5 downto 3))) then
					if (it3(5 downto 3) = it2(11 downto 9) and it5(8 downto 6) = it2(8 downto 6)) then
						alu_b <= alu_out_reg;
						alu_a<= alu_out;
					else
						alu_a <= alu_out_reg;
						alu_b <= alu_out;
					end if;
				elsif(it5(15 downto 12) = "0100" and (it5(11 downto 9) = it2(11 downto 9) or it5(8 downto 6) = it2(8 downto 6)) and not (it5(11 downto 9) =  it3(5 downto 3))) then
					if(it3(5 downto 3) = it2(11 downto 9)) then
						alu_a <= alu_out;
						alu_b <= mem_read_out;
					else
						alu_b <= alu_out;
						alu_a <= mem_read_out;
					end if;
				
				elsif(it5(15 downto 12) = "0011" and (it5(11 downto 9) = it2(11 downto 9) or it5(8 downto 6) = it2(8 downto 6)) and not (it5(11 downto 9) =  it3(5 downto 3))) then
					if(it3(5 downto 3) = it2(11 downto 9)) then
						alu_a <= alu_out;
						alu_b <= Ext9_exec;
					else
						alu_b <= alu_out;
						alu_a <= Ext9_exec;
					end if;
					
				elsif ((it3(5 downto 3) = it2(8 downto 6)) and (it3(5 downto 3) = it2(11 downto 9))) then
					alu_b <= alu_out;
					alu_a <= alu_out;
				elsif (it3(5 downto 3) = it2(8 downto 6)) then
					report "Hellooooo1";
					 alu_b <= alu_out;
					 alu_a <= RF(to_integer(unsigned(it2(11 downto 9))));
				elsif (it3(5 downto 3) = it2(11 downto 9)) then
					report "Hellooooo2";
					 alu_a <= alu_out;
					 alu_b <= RF(to_integer(unsigned(it2(8 downto 6))));
				end if;
			elsif ((it3(15 downto 12) = "0000") and (it3(8 downto 6) = it2(11 downto 9) or ((it3(8 downto 6) = it2(8 downto 6))))) then 
				report "Hellooooo";
				-- check if it4 is aadd/nand and is also involved in data forwarding
				if((it4(15 downto 12) = "0001" or it4(15 downto 12) = "0010")and ((it4(5 downto 3) = it2(11 downto 9) or ((it4(5 downto 3) = it2(8 downto 6)))) and not (it4(5 downto 3) = it3(8 downto 6)))) then
					if (it3(8 downto 6) = it2(11 downto 9) and it4(5 downto 3) = it2(8 downto 6)) then
						alu_b <= alu_out_reg;
						alu_a<= alu_out;
					else
						alu_a <= alu_out_reg;
						alu_b <= alu_out;
					end if;
				elsif(it4(15 downto 12)="0000" and (it4(8 downto 6) = it2(11 downto 9) or it4(8 downto 6) = it2(8 downto 6)) and not (it4(8 downto 6) =  it3(8 downto 6))) then
					if (it3(8 downto 6) = it2(11 downto 9) and it4(8 downto 6) = it2(8 downto 6)) then
						alu_b <= alu_out_reg;
						alu_a<= alu_out;
					else
						alu_a <= alu_out_reg;
						alu_b <= alu_out;
					end if;
				-- if it5 is involved in data forwarding
				elsif((it5(15 downto 12) = "0001" or it5(15 downto 12) = "0010")and ((it5(5 downto 3) = it2(11 downto 9) or ((it5(5 downto 3) = it2(8 downto 6)))) and not (it5(5 downto 3) = it3(8 downto 6)))) then
					if (it3(8 downto 6) = it2(11 downto 9) and it5(5 downto 3) = it2(8 downto 6)) then
						alu_b <= alu_out_reg;
						alu_a<= alu_out;
					else
						alu_a <= alu_out_reg;
						alu_b <= alu_out;
					end if;
				elsif(it5(15 downto 12)="0000" and (it5(8 downto 6) = it2(11 downto 9) or it5(8 downto 6) = it2(8 downto 6)) and not (it5(8 downto 6) =  it3(8 downto 6))) then
					if (it3(8 downto 6) = it2(11 downto 9) and it5(8 downto 6) = it2(8 downto 6)) then
						alu_b <= alu_out_reg;
						alu_a<= alu_out;
					else
						alu_a <= alu_out_reg;
						alu_b <= alu_out;
					end if;
				elsif(it5(15 downto 12) = "0100" and (it5(11 downto 9) = it2(11 downto 9) or it5(8 downto 6) = it2(8 downto 6)) and not (it5(11 downto 9) =  it3(8 downto 6))) then
					if(it3(8 downto 6) = it2(11 downto 9)) then
						alu_a <= alu_out;
						alu_b <= mem_read_out;
					else
						alu_b <= alu_out;
						alu_a <= mem_read_out;
					end if;
				
				elsif(it5(15 downto 12) = "0011" and (it5(11 downto 9) = it2(11 downto 9) or it5(8 downto 6) = it2(8 downto 6)) and not (it5(11 downto 9) =  it3(8 downto 6))) then
					if(it3(8 downto 6) = it2(11 downto 9)) then
						alu_a <= alu_out;
						alu_b <= Ext9_exec;
					else
						alu_b <= alu_out;
						alu_a <= Ext9_exec;
					end if;
				elsif ((it3(8 downto 6) = it2(8 downto 6)) and (it3(8 downto 6) = it2(11 downto 9))) then
					alu_b <= alu_out;
					alu_a <= alu_out;
				elsif (it3(8 downto 6) = it2(8 downto 6)) then
					report "Hellooooo1";
					 alu_b <= alu_out;
					 alu_a <= RF(to_integer(unsigned(it2(11 downto 9))));
				elsif (it3(8 downto 6) = it2(11 downto 9)) then
					report "Hellooooo2";
					 alu_a <= alu_out;
					 alu_b <= RF(to_integer(unsigned(it2(8 downto 6))));
				end if;		
			-- data dependency without it3 but with it4
			elsif ((it4(15 downto 12) = "0001" or it4(15 downto 12) = "0010") and  ((it4(5 downto 3) = it2(8 downto 6)) or (it4(5 downto 3) = it2(11 downto 9)))) then 
				report "Hello0";
				--data dependency with it5
				if ((it5(15 downto 12) = "0001" or it5(15 downto 12) = "0010") and ((it5(5 downto 3) = it2(11 downto 9) or ((it5(5 downto 3) = it2(8 downto 6)))) and not (it4(5 downto 3) = it5(5 downto 3)))) then
					if (it4(5 downto 3) = it2(11 downto 9) and it5(5 downto 3) = it2(8 downto 6)) then
						alu_b <= alu_out_fwd_reg;
						alu_a<= alu_out_reg;
					else
						alu_a <= alu_out_fwd_reg;
						alu_b <= alu_out_reg;
					end if;
				elsif ((it5(15 downto 12) = "0000") and ((it5(8 downto 6) = it2(11 downto 9) or ((it5(8 downto 6) = it2(8 downto 6)))) and not (it4(5 downto 3) = it5(8 downto 6)))) then
					if (it4(5 downto 3) = it2(11 downto 9) and it5(8 downto 6) = it2(8 downto 6)) then
						alu_b <= alu_out_fwd_reg;
						alu_a<= alu_out_reg;
					else
						alu_a <= alu_out_fwd_reg;
						alu_b <= alu_out_reg;
					end if;
				elsif(it5(15 downto 12) = "0100" and (it5(11 downto 9) = it2(11 downto 9) or it5(8 downto 6) = it2(8 downto 6)) and not (it5(11 downto 9) =  it4(5 downto 3))) then
					if(it4(5 downto 3) = it2(11 downto 9)) then
						alu_a <= alu_out;
						alu_b <= mem_read_out;
					else
						alu_b <= alu_out;
						alu_a <= mem_read_out;
					end if;
				
				elsif(it5(15 downto 12) = "0011" and (it5(11 downto 9) = it2(11 downto 9) or it5(8 downto 6) = it2(8 downto 6)) and not (it5(11 downto 9) =  it4(5 downto 3))) then
					if(it4(5 downto 3) = it2(11 downto 9)) then
						alu_a <= alu_out;
						alu_b <= Ext9_exec;
					else
						alu_b <= alu_out;
						alu_a <= Ext9_exec;
					end if;
				elsif ((it4(5 downto 3) = it2(8 downto 6)) and (it4(5 downto 3) = it2(11 downto 9))) then
					alu_b <= alu_out_reg;
					alu_a <= alu_out_reg;
				elsif (it4(5 downto 3) = it2(8 downto 6)) then
					report "Hellooooo1";
					 alu_b <= alu_out_reg;
					 alu_a <= RF(to_integer(unsigned(it2(11 downto 9))));
				elsif (it4(5 downto 3) = it2(11 downto 9)) then
					report "Hellooooo2";
					 alu_a <= alu_out_reg;
					 alu_b <= RF(to_integer(unsigned(it2(8 downto 6))));
				end if;
			elsif ((it4(15 downto 12) = "0000") and  ((it4(8 downto 6) = it2(8 downto 6)) or (it4(8 downto 6) = it2(11 downto 9)))) then 
				report "Hello0";
				--data dependency with it5
				if ((it5(15 downto 12) = "0001" or it5(15 downto 12) = "0010") and ((it5(5 downto 3) = it2(11 downto 9) or ((it5(5 downto 3) = it2(8 downto 6)))) and not (it4(8 downto 6) = it5(5 downto 3)))) then
					if (it4(8 downto 6) = it2(11 downto 9) and it5(5 downto 3) = it2(8 downto 6)) then
						alu_b <= alu_out_fwd_reg;
						alu_a<= alu_out_reg;
					else
						alu_a <= alu_out_fwd_reg;
						alu_b <= alu_out_reg;
					end if;
				elsif ((it5(15 downto 12) = "0000") and ((it5(8 downto 6) = it2(11 downto 9) or ((it5(8 downto 6) = it2(8 downto 6)))) and not (it4(8 downto 6) = it5(8 downto 6)))) then
					if (it4(8 downto 6) = it2(11 downto 9) and it5(8 downto 6) = it2(8 downto 6)) then
						alu_b <= alu_out_fwd_reg;
						alu_a<= alu_out_reg;
					else
						alu_a <= alu_out_fwd_reg;
						alu_b <= alu_out_reg;
					end if;
				elsif(it5(15 downto 12) = "0100" and (it5(11 downto 9) = it2(11 downto 9) or it5(8 downto 6) = it2(8 downto 6)) and not (it5(11 downto 9) =  it4(8 downto 6))) then
					if(it4(8 downto 6) = it2(11 downto 9)) then
						alu_a <= alu_out;
						alu_b <= mem_read_out;
					else
						alu_b <= alu_out;
						alu_a <= mem_read_out;
					end if;
				
				elsif(it5(15 downto 12) = "0011" and (it5(11 downto 9) = it2(11 downto 9) or it5(8 downto 6) = it2(8 downto 6)) and not (it5(11 downto 9) =  it4(8 downto 6))) then
					if(it4(8 downto 6) = it2(11 downto 9)) then
						alu_a <= alu_out;
						alu_b <= Ext9_exec;
					else
						alu_b <= alu_out;
						alu_a <= Ext9_exec;
					end if;
				elsif ((it4(8 downto 6) = it2(8 downto 6)) and (it4(8 downto 6) = it2(11 downto 9))) then
					alu_b <= alu_out_reg;
					alu_a <= alu_out_reg;
				elsif (it4(8 downto 6) = it2(8 downto 6)) then
					report "Hellooooo1";
					 alu_b <= alu_out_reg;
					 alu_a <= RF(to_integer(unsigned(it2(11 downto 9))));
				elsif (it4(8 downto 6) = it2(11 downto 9)) then
					report "Hellooooo2";
					 alu_a <= alu_out_reg;
					 alu_b <= RF(to_integer(unsigned(it2(8 downto 6))));
				end if;
			-- elsif (it4(15 downto 12) = "0000" and (it4(8 downto 6) = it2(8 downto 6) and it4(8 downto 6) = it2(11 downto 9))) then
			-- 	alu_b <= alu_out_reg;
			-- 	alu_a <= alu_out_reg;
			-- elsif (it4(15 downto 12) = "0000" and it4(8 downto 6) = it2(8 downto 6)) then
			-- 	alu_b <= alu_out_reg;
			-- 	alu_a <= RF(to_integer(unsigned(it2(11 downto 9))));
			-- elsif (it4(15 downto 12) = "0000" and it4(8 downto 6) = it2(11 downto 9)) then
			-- 	alu_a <= alu_out_reg;
			-- 	alu_b <= RF(to_integer(unsigned(it2(8 downto 6))));
				
			
			elsif ((it5(15 downto 12) = "0001" or it5(15 downto 12) = "0010") and ((it5(5 downto 3) = it2(8 downto 6)) or (it5(5 downto 3) = it2(11 downto 9)))) then 
				report "hello6";
				if ((it5(5 downto 3) = it2(8 downto 6)) and (it5(5 downto 3) = it2(11 downto 9))) then
					alu_b <= alu_out_fwd_reg;
					alu_a <= alu_out_fwd_reg;
				elsif (it5(5 downto 3) = it2(8 downto 6)) then
					report "Hellooooo1";
					 alu_b <= alu_out_fwd_reg;
					 alu_a <= RF(to_integer(unsigned(it2(11 downto 9))));
				elsif (it5(5 downto 3) = it2(11 downto 9)) then
					report "Hellooooo2";
					 alu_a <= alu_out_fwd_reg;
					 alu_b <= RF(to_integer(unsigned(it2(8 downto 6))));
				end if;
			elsif (it5(15 downto 12) = "0000" and (it5(8 downto 6) = it2(8 downto 6) and it5(8 downto 6) = it2(11 downto 9))) then
				alu_b <= alu_out_fwd_reg;
				alu_a <= alu_out_fwd_reg;
			elsif (it5(15 downto 12) = "0000" and it5(8 downto 6) = it2(8 downto 6)) then
				alu_b <= alu_out_fwd_reg;
				alu_a <= RF(to_integer(unsigned(it2(11 downto 9))));
			elsif (it5(15 downto 12) = "0000" and it5(8 downto 6) = it2(11 downto 9)) then
				alu_a <= alu_out_fwd_reg;
				alu_b <= RF(to_integer(unsigned(it2(8 downto 6))));
			elsif (it5(15 downto 12) = "0011" and (it5(11 downto 9) = it2(8 downto 6) and it5(11 downto 9) = it2(11 downto 9))) then
				alu_b <= Ext9_exec;
				alu_a <= Ext9_exec;
			elsif (it5(15 downto 12) = "0011" and it5(11 downto 9) = it2(8 downto 6)) then
				alu_b <= Ext9_exec;
				alu_a <= RF(to_integer(unsigned(it2(11 downto 9))));
			elsif (it5(15 downto 12) = "0011" and it5(11 downto 9) = it2(11 downto 9)) then
				alu_a <= Ext9_exec;
				alu_b <= RF(to_integer(unsigned(it2(8 downto 6))));
			elsif (it5(15 downto 12) = "0100" and (it5(11 downto 9) = it2(8 downto 6) and it5(11 downto 9) = it2(11 downto 9))) then
				alu_b <= mem_read_out;
				alu_a <= mem_read_out;
			elsif (it5(15 downto 12) = "0100" and it5(11 downto 9) = it2(8 downto 6)) then
				alu_b <= mem_read_out;
				alu_a <= RF(to_integer(unsigned(it2(11 downto 9))));
			elsif (it5(15 downto 12) = "0100" and it5(11 downto 9) = it2(11 downto 9)) then
				alu_a <= mem_read_out;
				alu_b <= RF(to_integer(unsigned(it2(8 downto 6))));
			else
				report "hello12";
				alu_a <= RF(to_integer(unsigned(it2(11 downto 9))));
				alu_b <= RF(to_integer(unsigned(it2(8 downto 6))));
			end if;
		
		
		--ADI	
		elsif (it2(15 downto 12) = "0000") then
			alu_b <= Ext6;
			if ((it3(15 downto 12) = "0001" or it3(15 downto 12) = "0010") and (it3(5 downto 3) = it2(11 downto 9))) then 
				if (it3(5 downto 3) = it2(11 downto 9)) then
					 alu_a <= alu_out;
				-- else
				-- 	alu_a <= RF(to_integer(unsigned(it2(11 downto 9))));
				end if;			
			elsif (it3(15 downto 12) = "0000" and it3(8 downto 6) = it2(11 downto 9)) then
				alu_a <= alu_out;
			
			elsif ((it4(15 downto 12) = "0001" or it4(15 downto 12) = "0010") and (it4(5 downto 3) = it2(11 downto 9))) then 
				-- if (it4(5 downto 3) = it2(11 downto 9)) then
					 alu_a <= alu_out_reg;
				-- else
				-- 	alu_a <= RF(to_integer(unsigned(it2(11 downto 9))));
				-- end if;			
			elsif (it4(15 downto 12) = "0000" and it4(8 downto 6) = it2(11 downto 9)) then
				alu_a <= alu_out_reg;
			
			elsif ((it5(15 downto 12) = "0001" or it5(15 downto 12) = "0010") and (it5(5 downto 3) = it2(11 downto 9))) then 
				-- if (it5(5 downto 3) = it2(11 downto 9)) then
					 alu_a <= alu_out_fwd_reg;
				-- else
				-- 	alu_a <= RF(to_integer(unsigned(it2(11 downto 9))));
				-- end if;			
			elsif (it5(15 downto 12) = "0000" and it5(8 downto 6) = it2(11 downto 9)) then
				alu_a <= alu_out_fwd_reg;
			elsif(it5(15 downto 12) = "0011" and it5(11 downto 9) = it2(11 downto 9)) then
				alu_a <= Ext9_exec;
			elsif(it5(15 downto 12) = "0100" and it5(11 downto 9) = it2(11 downto 9)) then
				alu_a <= mem_read_out;	
			else
				alu_a <= RF(to_integer(unsigned(it2(11 downto 9))));
			end if;
		
		
		--LW/SW
		elsif (it2(15 downto 13) = "010") then
			alu_a <= Ext6;
			if ((it3(15 downto 12) = "0001" or it3(15 downto 12) = "0010") and (it3(5 downto 3) = it2(8 downto 6))) then 
				-- if (it3(5 downto 3) = it2(8 downto 6)) then
					 alu_b <= alu_out;
				-- else
				-- 	alu_b <= RF(to_integer(unsigned(it2(8 downto 6))));
				-- end if;			
			elsif (it3(15 downto 12) = "0000" and it3(8 downto 6) = it2(8 downto 6)) then
				alu_b <= alu_out;
				
			elsif ((it4(15 downto 12) = "0001" or it4(15 downto 12) = "0010") and (it4(5 downto 3) = it2(8 downto 6))) then 
				-- if (it4(5 downto 3) = it2(8 downto 6)) then
					 alu_b <= alu_out_reg;
				-- else
				-- 	alu_b <= RF(to_integer(unsigned(it2(8 downto 6))));
				-- end if;			
			elsif (it4(15 downto 12) = "0000" and it4(8 downto 6) = it2(8 downto 6)) then
				alu_b <= alu_out_reg;
				
			elsif ((it5(15 downto 12) = "0001" or it5(15 downto 12) = "0010") and (it5(5 downto 3) = it2(8 downto 6))) then 
				-- if (it5(5 downto 3) = it2(8 downto 6)) then
					 alu_b <= alu_out_fwd_reg;
				-- else
				-- 	alu_b <= RF(to_integer(unsigned(it2(8 downto 6))));
				-- end if;			
			elsif (it5(15 downto 12) = "0000" and it5(8 downto 6) = it2(8 downto 6)) then
				alu_b <= alu_out_fwd_reg;
			elsif(it5(15 downto 12) = "0011" and it5(11 downto 9) = it2(8 downto 6)) then
				alu_b <= Ext9_exec;
			elsif(it5(15 downto 12) = "0100" and it5(11 downto 9) = it2(8 downto 6)) then
				alu_b <= mem_read_out;
			else
				alu_b <= RF(to_integer(unsigned(it2(8 downto 6))));
			end if;
		
		
		--JRI
		elsif (it2(15 downto 12) = "1111") then
			alu_a <= Imm_times_2_6;
			if ((it3(15 downto 12) = "0001" or it3(15 downto 12) = "0010") and (it3(5 downto 3) = it2(8 downto 6))) then 
				-- if (it3(5 downto 3) = it2(8 downto 6)) then
					 alu_b <= alu_out;
				-- else
				-- 	alu_b <= RF(to_integer(unsigned(it2(8 downto 6))));
				-- end if;			
			elsif (it3(15 downto 12) = "0000" and it3(8 downto 6) = it2(8 downto 6)) then
				alu_b <= alu_out;
				
			elsif ((it4(15 downto 12) = "0001" or it4(15 downto 12) = "0010") and (it4(5 downto 3) = it2(8 downto 6))) then 
				-- if (it4(5 downto 3) = it2(8 downto 6)) then
					 alu_b <= alu_out_reg;
				-- else
				-- 	alu_b <= RF(to_integer(unsigned(it2(8 downto 6))));
				-- end if;			
			elsif (it4(15 downto 12) = "0000" and it4(8 downto 6) = it2(8 downto 6)) then
				alu_b <= alu_out_reg;
				
			elsif ((it5(15 downto 12) = "0001" or it5(15 downto 12) = "0010") and (it5(5 downto 3) = it2(8 downto 6))) then 
				-- if (it5(5 downto 3) = it2(8 downto 6)) then
					 alu_b <= alu_out_fwd_reg;
				-- else
				-- 	alu_b <= RF(to_integer(unsigned(it2(8 downto 6))));
				-- end if;			
			elsif (it5(15 downto 12) = "0000" and it5(8 downto 6) = it2(8 downto 6)) then
				alu_b <= alu_out_fwd_reg;
			elsif(it5(15 downto 12) = "0011" and it5(11 downto 9) = it2(8 downto 6)) then
				alu_b <= Ext9_exec;
			elsif(it5(15 downto 12) = "0100" and it5(11 downto 9) = it2(8 downto 6)) then
				alu_b <= mem_read_out;
			else
				alu_b <= RF(to_integer(unsigned(it2(8 downto 6))));
			end if;
			
			
		--BEQ/BLT/BLE/JAL
		elsif (it2(15 downto 13) = "100") then
			alu_a <= std_logic_vector(unsigned(RF(0)) - 2);
			alu_b <= Imm_times_2_6;	
		elsif (it2(15 downto 12) = "1100") then
			alu_a <= std_logic_vector(unsigned(RF(0)) - 2);
			alu_b <= Imm_times_2_9;
			
		end if;
	it3 <= it2;
	c2 <= c1;
	end if;
end process;


--------------------------------------------------------------------------------------------------------------------------------------

Execution : process(clock)
begin
	if(clock' event and clock='0') then
		alu_out_reg <= alu_out;
		C_out <= C_alu_out;
		Z_out <= Z_alu_out;
		it4 <= it3;
		c3 <= c2;
	end if;
	
	
	if(clock' event and clock='1') then
		if (it3(15 downto 12) = "0001" or it3(15 downto 12) = "0010") then
			if (it5(15 downto 12) = "0011") then 
				if (it5(11 downto 9) = it3(8 downto 6)) then
					 alu_load_b <= Ext9_exec;
					 alu_load_a <= RF(to_integer(unsigned(it3(11 downto 9))));
				elsif (it5(11 downto 9) = it3(11 downto 9)) then
					 alu_load_a <= Ext9_exec;
					 alu_load_b <= RF(to_integer(unsigned(it3(8 downto 6))));
				else
					alu_load_a <= RF(to_integer(unsigned(it3(11 downto 9))));
					alu_load_b <= RF(to_integer(unsigned(it3(8 downto 6))));
				end if;			
			elsif (it5(15 downto 12) = "0100") then 
				if (it5(11 downto 9) = it3(8 downto 6)) then
					 alu_load_b <= mem_read_out;
					 alu_load_a <= RF(to_integer(unsigned(it3(11 downto 9))));
				elsif (it5(11 downto 9) = it3(11 downto 9)) then
					 alu_load_a <= mem_read_out;
					 alu_load_b <= RF(to_integer(unsigned(it3(8 downto 6))));
				else
					alu_load_a <= RF(to_integer(unsigned(it3(11 downto 9))));
					alu_load_b <= RF(to_integer(unsigned(it3(8 downto 6))));
				end if;
			end if;

			
		elsif (it3(15 downto 12) = "0000") then
			alu_load_b <= Ext6_exec;
			if (it5(15 downto 12) = "0011") then
				if (it5(11 downto 9) = it3(11 downto 9)) then
					alu_load_a <= Ext9_exec;
				end if;
			elsif (it5(15 downto 12) = "0100") then 
				if (it5(11 downto 9) = it3(11 downto 9)) then
					 alu_load_a <= mem_read_out;
				else
					alu_load_a <= RF(to_integer(unsigned(it3(11 downto 9))));
				end if;
			end if;
		end if;
	end if;
	
	

end process;


--------------------------------------------------------------------------------------------------------------------------------------


Memory_Read : process(clock)
begin
	if(clock' event and clock='0') then
		mem_read_out <= mem_reg(to_integer(unsigned(alu_out_reg(8 downto 0))));
		alu_out_fwd_reg <= alu_out_reg;
		C_fwd <= C_out;
		Z_fwd <= Z_out;
		it5 <= it4;
		c4 <= c3;
	end if;

end process;


--------------------------------------------------------------------------------------------------------------------------------------


Writing : process(clock)
begin
	if(clock' event and clock='0') then
		
		if (it5(15 downto 12) = "1110") then
			if (r0_change_wait_counter = 0) then
				if (is_it_load = '1' and load_wait_over = '0') then
					report "Hello in load";
					RF(0) <= RF(0);
					it1 <= it1;
					load_wait_over <= '1';
				else 
					RF(0) <= std_logic_vector(unsigned(RF(0)) + 1);
					it1 <= mem_reg(to_integer(unsigned(RF(0)(8 downto 0))));
					load_wait_over <= '0';
					report "updating outside";
				end if;
			end if;
		end if;


		-- mem write
		if (c4(1) = '1') then
			mem_reg(to_integer(unsigned(alu_out_fwd_reg(8 downto 0)))) <= RF(to_integer(unsigned(it5(11 downto 9))));
			if (r0_change_wait_counter = 0) then
				--update RF0/r0
				if (is_it_load = '1' and load_wait_over = '0') then
					report "Hello in loadmem";
					it1 <= it1;
					RF(0) <= RF(0);
					load_wait_over <= '1';
				else
					it1 <= mem_reg(to_integer(unsigned(RF(0)(8 downto 0))));
					RF(0) <= std_logic_vector(unsigned(RF(0)) + 1);
					load_wait_over <= '0';
				end if;
			end if;	
		-- reg write
		elsif (c4(0) = '1') then
		
			if (r0_change_wait_counter = 0) then
				
				--update RF0/r0
				if (is_it_load = '1' and load_wait_over = '0') then
					report "Hello in loadreg";
					it1 <= it1;
					RF(0) <= RF(0);
					load_wait_over <= '1';
				else
					it1 <= mem_reg(to_integer(unsigned(RF(0)(8 downto 0))));
					RF(0) <= std_logic_vector(unsigned(RF(0)) + 1);
					load_wait_over <= '0';
				end if;
		
			
				--update reg files		
				if (it5(15 downto 14) = "00" and (it5(13) xor it5(12)) = '1') then
					RF(to_integer(unsigned(it5(5 downto 3)))) <= alu_out_fwd_reg;
					-- if (it5(1 downto 0) = "10" and C = '0') then 
					-- else
					-- 	RF(to_integer(unsigned(it5(5 downto 3)))) <= alu_out_fwd_reg;
					-- end if;
					-- if (it5(1 downto 0) = "01" and Z = '0') then
					-- else
					-- 	RF(to_integer(unsigned(it5(5 downto 3)))) <= alu_out_fwd_reg;
					-- end if;
				elsif (it5(15 downto 12) = "0000") then
					RF(to_integer(unsigned(it5(8 downto 6)))) <= alu_out_fwd_reg;
				elsif (it5(15 downto 12) = "0011") then
					RF(to_integer(unsigned(it5(11 downto 9))))(15 downto 9) <= "0000000";
					RF(to_integer(unsigned(it5(11 downto 9))))(8 downto 0) <= it5(8 downto 0);
				elsif (it5(15 downto 12) = "0100") then
					RF(to_integer(unsigned(it5(11 downto 9)))) <= mem_read_out;
				elsif (it5(15 downto 12) = "1000") then
					if (unsigned(RF(to_integer(unsigned(it5(11 downto 9))))) = unsigned(RF(to_integer(unsigned(it5(8 downto 6)))))) then
						RF(0) <= alu_out_fwd_reg;
					else 
						RF(0) <= std_logic_vector(unsigned(RF(0)) - 1);
					end if;
				elsif (it5(15 downto 12) = "1001") then
					if (unsigned(RF(to_integer(unsigned(it5(11 downto 9))))) < unsigned(RF(to_integer(unsigned(it5(8 downto 6)))))) then
						RF(0) <= alu_out_fwd_reg;
					else 
						RF(0) <= std_logic_vector(unsigned(RF(0)) - 1);
					end if;
				elsif (it5(15 downto 12) = "1100" or it5(15 downto 12) = "1111") then
					RF(0) <= alu_out_fwd_reg;
				elsif (it5(15 downto 12) = "1101") then
					RF(0) <= RF(to_integer(unsigned(it5(8 downto 6))));
				end if;
				
				
				if(it5(15 downto 12) = "1100" or it5(15 downto 12) = "1101") then
					RF(to_integer(unsigned(it5(11 downto 9)))) <= std_logic_vector(unsigned(RF(0)) + 1);
				end if;
				
			
			else
			--update only reg file, which updates RF0 itself
				if (it5(15 downto 14) = "00" and (it5(13) xor it5(12)) = '1') then
					RF(to_integer(unsigned(it5(5 downto 3)))) <= alu_out_fwd_reg;
					-- if (it5(1 downto 0) = "10" and C = '0') then 
					-- else
					-- 	RF(to_integer(unsigned(it5(5 downto 3)))) <= alu_out_fwd_reg;
					-- end if;
					-- if (it5(1 downto 0) = "01" and Z = '0') then
					-- else
					-- 	RF(to_integer(unsigned(it5(5 downto 3)))) <= alu_out_fwd_reg;
					-- end if;
				elsif (it5(15 downto 12) = "0000") then
					RF(to_integer(unsigned(it5(8 downto 6)))) <= alu_out_fwd_reg;
				elsif (it5(15 downto 12) = "0011") then
					RF(to_integer(unsigned(it5(11 downto 9))))(15 downto 9) <= "0000000";
					RF(to_integer(unsigned(it5(11 downto 9))))(8 downto 0) <= it5(8 downto 0);
				elsif (it5(15 downto 12) = "0100") then
					RF(to_integer(unsigned(it5(11 downto 9)))) <= mem_read_out;
				elsif (it5(15 downto 12) = "1000") then
					if (unsigned(RF(to_integer(unsigned(it5(11 downto 9))))) = unsigned(RF(to_integer(unsigned(it5(8 downto 6)))))) then
						RF(0) <= alu_out_fwd_reg;
					else 
						RF(0) <= std_logic_vector(unsigned(RF(0)) - 1);
					end if;
				elsif (it5(15 downto 12) = "1001") then
					if (unsigned(RF(to_integer(unsigned(it5(11 downto 9))))) < unsigned(RF(to_integer(unsigned(it5(8 downto 6)))))) then
						RF(0) <= alu_out_fwd_reg;
					else 
						RF(0) <= std_logic_vector(unsigned(RF(0)) - 1);
					end if;
				elsif (it5(15 downto 12) = "1100" or it5(15 downto 12) = "1111") then
					RF(0) <= alu_out_fwd_reg;
				elsif (it5(15 downto 12) = "1101") then
					RF(0) <= RF(to_integer(unsigned(it5(8 downto 6))));
				end if;
				
				
				if(it5(15 downto 12) = "1100" or it5(15 downto 12) = "1101") then
					RF(to_integer(unsigned(it5(11 downto 9)))) <= std_logic_vector(unsigned(RF(0)) - 1);
				end if;
				
				
			end if; 
		else
			if (r0_change_wait_counter = 0 and is_it_load = '0') then
				RF(0) <= std_logic_vector(unsigned(RF(0)) + 1);
				it1 <= mem_reg(to_integer(unsigned(RF(0)(8 downto 0))));
			end if;
		end if;
		
		
		--C write
		if (c4(3) = '1') then
			C <= C_fwd;
		end if;
		
		--Z write
		if (c4(2) = '1') then
			Z <= Z_fwd;
		end if;
	
		ir6 <= it5;
	end if;
end process;

r0 <= RF(0);
r1 <= RF(1);
r2 <= RF(2);
r3 <= RF(3);
r4 <= RF(4);
r5 <= RF(5);
r6 <= RF(6);
r7 <= RF(7);
c_flag <= C;
z_flag <= Z;

end bhv;