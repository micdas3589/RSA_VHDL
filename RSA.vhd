library IEEE;
	use IEEE.std_logic_1164.all;
	use IEEE.numeric_std.all;
library altera;
	use altera.altera_primitives_components.all;

entity RSA is
	generic(
		module		: std_logic_vector(94 downto 0)	:= "11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111110001";
		key			: std_logic_vector(94 downto 0) := "11110000100111111011100100110111000110011010110000010000111011110110111111000001010111111100111";
		module_inv 	: std_logic_vector( 4 downto 0)	:= "01111";
		mod_len		: integer						:= 95;
		word_len	: integer						:= 5;
		in_out_len	: integer						:= 19
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
			output		: out std_logic_vector(mod_len-1 downto 0)
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
						
						iterator2	<= iterator2 + 1;
					elsif iterator2 = 1 then
						mode_mapped	<= "1010";
						key_exp		<= '0' & key_exp(mod_len-1 downto 1);

						iterator2	<= iterator2 + 1;
					end if;
				elsif unsigned(key_exp) = 1 then
					if iterator2 = 0 then
						mode_mapped	<= "1111";
						
						iterator2	<= iterator2 + 1;
					elsif iterator2 = 1 then
						mode_mapped	<= "1110";
						key_exp		<= '0' & key_exp(mod_len-1 downto 1);

						iterator2	<= iterator2 + 1;
					end if;
				else
					--mode_mapped	<= "1101";
					if iterator2 = 0 then
						mode_mapped	<= "1101";
						
						iterator2	<= iterator2 + 1;
					elsif iterator2 = 1 then
						mode_mapped	<= "1100";
						key_exp		<= '0' & key_exp(mod_len-1 downto 1);

						iterator2	<= iterator2 + 1;
					end if;
				end if;
			end if;
			
			if flag_mapped = '1' then
				if mode_flag = "10" then
					temp_result	<= result;
					mode_flag	<= "11"; 
				else
					base		<= result;
					mode_flag	<= "01";
				end if;
				
				mode_mapped <= "0000";
				iterator2	<= to_unsigned(0, 11);
			end if;
		end if;
	end process;
end architecture RSA_arch;