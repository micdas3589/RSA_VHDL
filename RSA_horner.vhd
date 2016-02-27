library IEEE;
	use IEEE.std_logic_1164.all;
	use IEEE.numeric_std.all;
library altera;
	use altera.altera_primitives_components.all;

entity RSA is
	generic(
		module		: std_logic_vector(1023 downto 0)	:= "1101011001110010000011100001100011100011110101111111110011010101100011110010001101000001011011010000000010101010110101001111010110001101010111000001100101010011001000000100100101001100100100110111001111011101011010111001100101011011101111111010101010111001000111111010011010111001100110001100100101000010101001101111101000000110100010101010001010010000101011010101000111111010110011101100010011111111110111100111000110100001010000011001111100110001001010000000000101100000100010110011000111101001100111101011111101100101111011010001101001001100001011011110001101000011100001001010011000011001101100011111010000111111100011010101001101010111100000111111110110101111010100110110001010011111100101101001100011110110111010001010001001100000011000001001101001011000001010011010010001100111001001010011101101000010010101100001000011100010111001011111001101101101100110010100000010101101101000110110010110110011000111101111101100111000100010110101010110101101101111011001001000100000001101000010000011100111111111011100000101110101";
		key			: std_logic_vector(1023 downto 0) := "0100101001001010100011111110111011111111101000011000010011010101101100110100011110111100001000111100000001010011110101010100100101001101111111111100110000001010110011111010011011011011010011010100000001000110100101011110001101000000010110101101010110111101011110110010100100001100010101110101110110111001100110001111010001100101111110110011000110001010111110100011110011100001111111011001101010101111001011010110001000001000010111011011010011011111100100101101010001111111011101011110000010001011001111001001101100001110011010001001100110100111010011111011001111100011101110011000001111001010000011001110111100111000111101010000100110111011011110111010111111101110101101110010111101010101001000101001001001010001110001001111100010100111111011110001110000111101001110010111010010010110011000110000110010100111100010111001111101011100111110001100001001101000110001111011111111001011011101010100111010010000101011000101111000011011000111000111010001000101001111110010001011111000111101100001101111011001101001101011011111011001";
		mod_len		: integer						:= 1024;
		in_out_len	: integer						:= 128
	);                                         
	port(
		msg_word	: in std_logic_vector(in_out_len-1 downto 0);
		mode		: in std_logic; --on/off
		reset		: in std_logic;
		clk			: in std_logic;
		flag		: out std_logic;
		ciphertext	: out std_logic_vector(in_out_len-1 downto 0)
	);
end entity RSA;

architecture arch_RSA of RSA is
	component fast_mod_exponentiation is
		generic(
			mod_len		: integer
		);              
		port(
			base		: in std_logic_vector(mod_len-1 downto 0);
			exp			: in std_logic_vector(mod_len-1 downto 0);
			module		: in std_logic_vector(mod_len-1 downto 0);
			mode		: in std_logic;
			reset		: in std_logic;
			clk			: in std_logic;
			flag		: out std_logic;
			result		: out std_logic_vector(mod_len-1 downto 0)
		);
	end component fast_mod_exponentiation;
	
	signal flag_mapped		: std_logic;
	signal mode_mapped		: std_logic;
	signal reset_mapped		: std_logic;
	signal message			: std_logic_vector(mod_len-1 downto 0);
	signal result_mapped	: std_logic_vector(mod_len-1 downto 0);
	signal steps			: unsigned(10 downto 0);
	signal iterator			: unsigned(10 downto 0);
	signal iterator2		: unsigned(10 downto 0);
	signal result_returned	: std_logic_vector(mod_len-1 downto 0);
	
begin
	exponentiation : fast_mod_exponentiation
	generic map(
		mod_len
	)
	port map(
		message,
		key,
		module,
		mode_mapped,
		reset_mapped,
		clk,
		flag_mapped,
		result_mapped
	);

	process(clk)
		variable temp	: std_logic_vector(mod_len-1 downto 0);
	begin
		if clk'event and clk = '1' then
			if reset = '1' then
				flag			<= '0';
				mode_mapped		<= '0';
				reset_mapped	<= '0';
				steps			<= to_unsigned(mod_len/in_out_len, 11);
				iterator		<= to_unsigned(0, 11);
				iterator2		<= to_unsigned(0, 11);
			end if;
			
			if mode = '1' and reset = '0' then
				if iterator < steps then
					temp			:= msg_word & temp(mod_len-1 downto in_out_len);
					
					iterator		<= iterator + 1;
				elsif iterator = steps then
					message			<= temp;
					mode_mapped		<= '1';
					reset_mapped	<= '1';
					
					iterator		<= iterator + 1;
				elsif iterator = steps + 1 then
					reset_mapped	<= '0';
					
					iterator		<= iterator + 1;	
				end if;
				
				if flag_mapped = '1' then
					if iterator2 = 0 then
						flag			<= '1';
						mode_mapped		<= '0';
						result_returned <= result_mapped;
						
						iterator2 		<= iterator2 + 1;
					elsif iterator2 <= steps then
						ciphertext		<= result_returned(in_out_len-1 downto 0);
						result_returned	<= std_logic_vector(to_unsigned(0, in_out_len)) & result_returned(mod_len-1 downto in_out_len);
						
						iterator2 		<= iterator2 + 1;
					end if;
				end if;
			end if;
		end if;
	end process;
end architecture arch_RSA;