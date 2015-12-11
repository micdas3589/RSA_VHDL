library IEEE;
	use IEEE.std_logic_1164.all;
	use IEEE.numeric_std.all;
library altera;
	use altera.altera_primitives_components.all;

entity RSA is
	generic(
		module		: std_logic_vector(1023 downto 0)	:= "1000010101110110111110000101101110000101100001111111000000001000101000001011111000001111110000000000100000000011100011011110101101000101000101111110111010001110110011000101101000011110101101100100011010000111001011100001011011011101010111101111001000011100111011100111010001110100100101000011100101110000001001110000010011101011000011100110110110001111101110000100111010001100000101101100001001000100110011100110111011011100111110001101111010010100011011101110010011011001000101100100001001001011011111111010111010010100111011011000001000110101100010001010100010100011110111001011011101100111110000100010111001100110110100111011010110100000000001010000011100100000101001000100111101001111000111111011010111001111100011101010100011000110001101101101000101000011000011000011110100111000010010000000000111100111100011100100110000101011101101001111001011110001110110110010010001111100101011101101100101100101001101111001010001001011001011000110111110011011011101100100010011101011011110000111011111001010100111101000011111010011";
		key			: std_logic_vector(1023 downto 0) 	:= "0110000010111000101101011111110111101111001100001000000101111110001011001101010110110011101011011010111101111000010111010000101000110001100101001110110110101000001111001101111000111010101110000111011010110111110111011001010011000011011110110000111100001011010110110010110100101100010000100111101110100111011100100100010101111101110001101101001100011101100100011000011100011100010011100000011001001011100011101101010110101011110111100101100110010111101010001111010001010011111000001000001000010101011010001100001110011100011100010000010111001101100001100111110110000101111100011000111100100011110000110111110000000000100001101110111100010011011000001100010111001111101101001000010100100101111110000101001000010010011101111111000011001111010010110100110011101100000101011100111110010000011010010111000100100101100000101001111011010111001001101101110010010100110011100110101101100001101010010101010000111000001110100100011010010101100101101111111100101010111011111001100100111000110100011001100010011110110101100100100011100111";
		module_inv 	: std_logic_vector(  31 downto 0)	:= "01110111111000011101111000100111";
		mod_len		: integer							:= 1024;
		word_len	: integer							:= 32;
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