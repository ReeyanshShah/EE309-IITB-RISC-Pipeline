library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--look at the C Z stuff

entity ALU_V2 is
    port(ALU_A, ALU_B, ALU_load_A, ALU_load_B, r_dest: in std_logic_vector(15 downto 0);
        C, Z: in std_logic;
        it3, it5: in std_logic_vector(15 downto 0); -- 14-12
        Output: out std_logic_vector(15 downto 0);
        C_out,Z_out: out std_logic
    );
end entity ALU_V2;

architecture arch of ALU_V2 is
    signal carry_buf : std_logic_vector(0 downto 0):= "0";
	signal sum_buf : std_logic_vector(16 downto 0):= (others=>'0'); -- First term has carry
    signal nand_buf, Nand_out, Add_out : std_logic_vector(15 downto 0):= (others=>'0');
    signal NorPair : std_logic_vector(7 downto 0):= (others => '0');
    signal ALU_out: std_logic_vector(15 downto 0);
    signal ALU_in_A: std_logic_vector(16 downto 0):= (others => '0');
    signal ALU_in_B: std_logic_vector(16 downto 0):= (others => '0');
    signal ALU_temp_B: std_logic_vector(15 downto 0):= (others => '0');
    signal NandIns, Loadins, LW,LW_it3, LLI, AddIns, ADI: std_logic:= '0';
    signal NandAdd_C: std_logic:= '0';
	signal AWC_ACW: std_logic:= '0';
    signal C_wr, Z_wr, z_buf: std_logic:= '0';
begin

    NandIns <= (it3(15) nor it3(14)) and (it3(13) and not it3(12));
    LW <= not it5(15) and it5(14) and (it5(13) nor it5(12));
    LW_it3 <= not it3(15) and it3(14) and (it3(13) nor it3(12));
    LLI <= (it5(15) nor it5(14)) and (it5(13) and it5(12));
    LoadIns <= LW or LLI;
    Z_wr <= it3(0) and Z and not AWC_ACW;
    C_wr <= it3(1) and C and not AWC_ACW;
    AddIns <= (it3(15) nor it3(14)) and not it3(13) and it3(12);
    ADI <= (it3(15) nor it3(14)) and (it3(13) nor it3(12));

        -- when adc/adz/acc/acz/ndc/ndz/ncc/ncz 

    
    Nand_out <= nand_buf when (NandIns and not it3(0) and not it3(1)) = '1' else --NDU/NCU
        nand_buf when (NandIns and Z_wr) = '1' else --NDZ/NCZ with z = 1 
        nand_buf when (NandIns and C_wr) = '1' else --NDC/NCC with c = 1
        r_dest;
    
    Add_out <= sum_buf(15 downto 0) when (AddIns and not it3(0) and not it3(1)) = '1' else --ADA/ACA
        sum_buf(15 downto 0) when (AddIns and AWC_ACW) = '1' else --AWC/ACW
        sum_buf(15 downto 0) when ADI = '1' else --ADI
        sum_buf(15 downto 0) when (AddIns and Z_wr) = '1' else --ADZ/ACZ with z = 1 
        sum_buf(15 downto 0) when (AddIns and C_wr) = '1' else --ADC/ACC with c = 1
        r_dest;
    
    ALU_out <= Nand_out when NandIns = '1' else
        Add_out when (AddIns or ADI) = '1' else
        sum_buf(15 downto 0);

    Output <= ALU_out;
    
    C_out <= sum_buf(16) when (AddIns and not it3(0) and not it3(1)) = '1' else --ADA/ACA
        sum_buf(16) when (AddIns and AWC_ACW) = '1' else --AWC/ACW
        sum_buf(16) when ADI = '1' else --ADI
        sum_buf(16) when (AddIns and Z_wr) = '1' else --ADZ/ACZ with z = 1 
        sum_buf(16) when (AddIns and C_wr) = '1' else --ADC/ACC with c = 1
        C;     
    
    Z_out <= z_buf when ADI = '1' else
        z_buf when (AddIns and not it3(0) and not it3(1)) = '1' else
        z_buf when (AddIns and AWC_ACW) = '1' else
        z_buf when (AddIns and Z_wr) = '1' else
        z_buf when (AddIns and C_wr) = '1' else
        z_buf when (NandIns and not it3(0) and not it3(1)) = '1' else
        z_buf when (NandIns and Z_wr) = '1' else
        z_buf when (NandIns and C_wr) = '1' else
        z_buf when LW_it3 = '1' else
        Z;

    ALU_in_A(15 downto 0) <= ALU_A when LoadIns = '0' else
                             ALU_load_A;
    NandAdd_C <= (it3(15) nor it3(14)) and (it3(13) xor it3(12)) and it3(2);

    ALU_temp_B <= not ALU_B when NandAdd_C = '1' else
        ALU_B;

    ALU_in_B(15 downto 0) <= ALU_temp_B when LoadIns = '0' else
                            ALU_load_B;
    
    sum_buf <= std_logic_vector(unsigned(ALU_in_A) + unsigned(ALU_in_B) + unsigned(carry_buf));
    carry_buf(0) <= C when AWC_ACW = '1' else 
                 '0';
    nand_buf <= ALU_in_A(15 downto 0) nand ALU_in_B(15 downto 0);
    
    AWC_ACW <= it3(1) and it3(0) and (it3(15) nor it3(14));
    Nors: for i in 0 to 7 generate
        NorPair(i) <= ALU_out(2*i) nor ALU_out(2*i + 1);
    end generate Nors;

    z_buf <= NorPair(7) and NorPair(6) and NorPair(5) and NorPair(4) and NorPair(3) and NorPair(2) and NorPair(1) and NorPair(0);
end arch;