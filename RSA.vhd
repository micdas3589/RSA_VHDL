library IEEE;
	use IEEE.std_logic_1164.all;
	use IEEE.numeric_std.all;
library altera;
	use altera.altera_primitives_components.all;

entity RSA is
	generic(
		module		: std_logic_vector(1023 downto 0)	:= "1100101000001010101011001101010001001110010110001101100010100000110100101110100111110010110010111011101000110101110011000101100010010011011111000011110111110101101000101100100011101000111110001010111101001101111001101011101010101001000000111000110110111110001011011100001111100011100011110000011001011000010011110010000111001100011000111011111011000000001101001001100011001001001100001001011001010110111110000001000000111101000100100001001001100001011011110011100100110000011000101110011011001101100001100100001010111010011010100001011100001010101111010110001111011101111010100011100111000100101011110101011110111101000010110111001100011111100001111100100000100010101010111101011011100110010100100110001011110001000011100110111001111111010000110100011101100011101001011001111001100100011000001100101101100110100000100000001000000000010000000101011111110010111101101111101001010110011001000111010000111010100010011101001110011011110001011101111000110110011001111000101000111000000100011010100010111110100100001101000111010001";
		key			: std_logic_vector(1023 downto 0) 	:= "0101111101110001110010011111111001110100111100000001100000010010100110011010011000101111010100110111101000010011111111010110001111100100111110100100010001100001010001101010100001110001110001110011011001001101110111010111101111101000011101011110011111111001010101101110000010010110001111100100101011000010011001011110110000000000000101001111001111101000000000100001100110100101110100111011111001111101100000100110001111010011001111001000011110110001010111001000110111010001000000111000101001001011100011110101110111101101100100101001100001001000011101101101100011111111000001010000000110100100001001111011110010100100101000110100000101000010011101001001001001100001010010011111111100010101111101001001011111110011010011101011111100100110010101100001010011101010101010100100000010011010011101010001100000011000111110111000101111000001111111001011100100000110000110100011001111100110011111001101010110010111111100010000000100101100111001000000001100110011010110101000100110111010000111001110101000011010101011001100001100010111";
		module_inv 	: std_logic_vector(  15 downto 0)	:= "1101100011001111";
		mod_len		: integer							:= 1024;
		word_len	: integer							:= 16;
		in_out_len	: integer							:= 128
	);                                         
	port(
		msg_word	: in std_logic_vector(in_out_len-1 downto 0);
		clk			: in std_logic;
		reset		: in std_logic;
		flag		: out std_logic;
		ciphertext	: out std_logic_vector(in_out_len-1 downto 0)
	);
end entity RSA;

architecture RSA_arch of RSA is
	component montgomery_multiplication is
		generic(
			mod_len		: integer;
			word_len	: integer
		);                                          
		port(
			vec_x		: in std_logic_vector(mod_len-1 downto 0);
			vec_y		: in std_logic_vector(mod_len-1 downto 0);
			module		: in std_logic_vector(mod_len-1 downto 0);
			module_inv 	: in std_logic_vector(word_len-1 downto 0);
			mode		: in std_logic_vector(3 downto 0); -- first bit: 1 - start, 0 - stop, second and third bits: 00 - no action, 01 - transform and multiply, 10 - multiply, 11 - multiply and reduce, fourth: bit 1 - reset, 0 - no action
			clk			: in std_logic;
			flag		: out std_logic;
			result		: out std_logic_vector(mod_len-1 downto 0)
		);  
	end component montgomery_multiplication;
	
	signal mode_mapped	: std_logic_vector(3 downto 0);
	signal vec_u		: std_logic_vector(mod_len-1 downto 0);
	signal vec_v		: std_logic_vector(mod_len-1 downto 0);
	signal result		: std_logic_vector(mod_len-1 downto 0);
	signal temp_result	: std_logic_vector(mod_len-1 downto 0);
	signal key_exp		: std_logic_vector(mod_len-1 downto 0);
	signal base			: std_logic_vector(mod_len-1 downto 0);
	signal flag_mapped	: std_logic;
	signal flag_reset	: std_logic;
	signal mode_flag	: std_logic_vector(1 downto 0); -- 00 - do nothing, 01 - control, 10 - multiply, 11 - sqare
	signal iterator		: unsigned(10 downto 0);
	signal iterator2	: unsigned(10 downto 0);
	signal steps		: unsigned(word_len-1 downto 0);
	
begin
	multiplication : montgomery_multiplication
	generic map(
		mod_len,
		word_len
	)
	port map(
		vec_u,
		vec_v,
		module,
		module_inv,
		mode_mapped,
		clk,
		flag_mapped,
		result
	);
	
	process(clk)
	begin
		if clk'event and clk = '1' then
			if reset = '1' then
				temp_result	<= std_logic_vector(to_unsigned(1, mod_len));
				key_exp		<= key;
				iterator	<= to_unsigned(0, 11);
				iterator2	<= to_unsigned(0, 11);
				steps		<= to_unsigned(mod_len/in_out_len, word_len);
				mode_flag	<= "00";
				flag		<= '0';
				mode_mapped	<= "0000";
			elsif iterator < steps then
				base		<= msg_word & base(mod_len-1 downto in_out_len);
				
				iterator	<= iterator + 1;
			elsif iterator = steps then
				mode_flag	<= "01";
				
				iterator	<= iterator + 1;
			end if;

			if mode_flag = "01" then
				if unsigned(key_exp) > 0 then
					if key_exp(0) = '1' then
						mode_flag	<= "10";
					else
						mode_flag	<= "11";
					end if;
				else
					flag	<= '1';
					
					if iterator2 = 0 then
						base		<= temp_result;
						
						iterator2	<= iterator2 + 1;
					elsif iterator2 <= steps then
						ciphertext	<= base(in_out_len-1 downto 0);
						base		<= std_logic_vector(to_unsigned(0, in_out_len)) & base(mod_len-1 downto in_out_len);
						
						iterator2	<= iterator2 + 1;
					elsif iterator2 = steps+1 then
						mode_flag	<= "00";
						
						iterator2	<= iterator2 + 1;
					end if;
				end if;
			elsif mode_flag = "10" then
				vec_u		<= temp_result;
				vec_v		<= base;
				
				if key = key_exp then
					if iterator2 = 0 then
						mode_mapped	<= "1011";
						
						iterator2	<= iterator2 + 1;
					elsif iterator2 = 1 then
						mode_mapped	<= "1010";

						iterator2	<= iterator2 + 1;
					end if;
				elsif unsigned(key_exp) = 1 then
					if iterator2 = 0 then
						mode_mapped	<= "1111";
						
						iterator2	<= iterator2 + 1;
					elsif iterator2 = 1 then
						mode_mapped	<= "1110";

						iterator2	<= iterator2 + 1;
					end if;
				else
					if iterator2 = 0 then
						mode_mapped	<= "1101";
						
						iterator2	<= iterator2 + 1;
					elsif iterator2 = 1 then
						mode_mapped	<= "1100";

						iterator2	<= iterator2 + 1;
					end if;
				end if;
			elsif mode_flag = "11" then
				vec_u	<= base;
				vec_v	<= base;
				
				if key = key_exp then
					if iterator2 = 0 then
						mode_mapped	<= "1011";
						if key_exp(0) = '0' then
							temp_result	<= std_logic_vector(('1' & to_unsigned(0, mod_len)) - unsigned(module))(mod_len-1 downto 0);
						end if;
						
						iterator2	<= iterator2 + 1;
					elsif iterator2 = 1 then
						mode_mapped	<= "1010";

						iterator2	<= iterator2 + 1;
					end if;
				else
					if iterator2 = 0 then
						mode_mapped	<= "1101";
						
						iterator2	<= iterator2 + 1;
					elsif iterator2 = 1 then
						mode_mapped	<= "1100";

						iterator2	<= iterator2 + 1;
					end if;
				end if;
			end if;
			
			if flag_mapped = '1' then
				if flag_reset = '0' then
					if mode_flag = "10" then
						temp_result	<= result;
						mode_flag	<= "11";
					else
						base		<= result;
						mode_flag	<= "01";
						key_exp		<= '0' & key_exp(mod_len-1 downto 1);
					end if;
					
					mode_mapped <= "0000";
					iterator2	<= to_unsigned(0, 11);
					
					flag_reset	<= '1';
				end if;
			else
				flag_reset	<= '0';
			end if;
		end if;
	end process;
end architecture RSA_arch;