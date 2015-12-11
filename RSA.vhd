library IEEE;
	use IEEE.std_logic_1164.all;
	use IEEE.numeric_std.all;
library altera;
	use altera.altera_primitives_components.all;

entity RSA is
	generic(
		module		: std_logic_vector(94 downto 0)	:= "11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111110001";
		key			: std_logic_vector(94 downto 0) := "11110000100111111011100100110111000110011010110000010000111011110110111111000001010111111100111";
		resid_sqr	: std_logic_vector(94 downto 0)	:= "00000000000000000000000000000000000000000000000000000000000000000000000000000000000000011100001";
		module_inv 	: std_logic_vector( 4 downto 0)	:= "01111";
		mod_len		: integer						:= 95;
		word_len	: integer						:= 5;
		in_out_len	: integer						:= 19
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
			mod_len		: integer;
			word_len	: integer
		);              
		port(
			base		: in std_logic_vector(mod_len-1 downto 0);
			exp			: in std_logic_vector(mod_len-1 downto 0);
			module		: in std_logic_vector(mod_len-1 downto 0);
			resid_sqr	: in std_logic_vector(mod_len-1 downto 0);
			module_inv	: in std_logic_vector(word_len-1 downto 0);
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
	signal steps			: unsigned(word_len-1 downto 0);
	signal iterator			: unsigned(10 downto 0);
	signal iterator2		: unsigned(10 downto 0);
	signal result_returned	: std_logic_vector(mod_len-1 downto 0);
	
begin
	exponentiation : fast_mod_exponentiation
	generic map(
		mod_len,
		word_len
	)
	port map(
		message,
		key,
		module,
		resid_sqr,
		module_inv,
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
				steps			<= to_unsigned(mod_len/in_out_len, word_len);
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
					elsif iterator2 < steps then
						ciphertext		<= result_returned(in_out_len-1 downto 0);
						result_returned	<= std_logic_vector(to_unsigned(0, in_out_len)) & result_returned(mod_len-1 downto in_out_len);
						
						iterator2 		<= iterator2 + 1;
					end if;
				end if;
			end if;
		end if;
	end process;
end architecture arch_RSA;