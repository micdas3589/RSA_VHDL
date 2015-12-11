library IEEE;
	use IEEE.std_logic_1164.all;
	use IEEE.numeric_std.all;
library altera;
	use altera.altera_primitives_components.all;

entity montgomery_multiplication is
	generic(
		mod_len		: integer;
		word_len	: integer
	);
	port(
		vec_x,
		vec_y		: in std_logic_vector(mod_len-1 downto 0);
		module		: in std_logic_vector(mod_len-1 downto 0);
		module_inv 	: in std_logic_vector(word_len-1 downto 0);
		mode		: in std_logic;
		reset		: in std_logic;
		clk			: in std_logic;
		flag		: out std_logic;
		result		: out std_logic_vector(mod_len-1 downto 0)
	);
end entity montgomery_multiplication;

architecture arch_montgomery_multiplication of montgomery_multiplication is
	signal iterator		: unsigned(10 downto 0);
	signal u_mod_len	: unsigned(10 downto 0);
	signal temp_result	: std_logic_vector(mod_len+word_len downto 0);
	signal steps		: unsigned(word_len-1 downto 0);
	signal vec_v		: std_logic_vector(mod_len-1 downto 0);
	signal vec_u		: std_logic_vector(mod_len-1 downto 0);
begin
	process(clk)
		variable temp	: std_logic_vector(word_len-1 downto 0);
		variable temp1	: std_logic_vector(3*word_len downto 0);
		variable temp2	: std_logic_vector(mod_len+word_len downto 0);
	begin
		if clk = '1' and clk'event then
			if reset = '1' then
				flag		<= '0';
				temp_result	<= std_logic_vector(to_unsigned(0, mod_len+word_len+1));
				vec_u		<= vec_x;
				vec_v		<= vec_y;
				steps		<= to_unsigned(mod_len/word_len, word_len);
				iterator	<= to_unsigned(0, 11);
			end if;
			
			if mode = '1' and reset = '0' then -- work				
				if iterator < steps then -- multiply
					temp1		:= std_logic_vector(to_unsigned(0,3*word_len+1) + unsigned(temp_result(word_len-1 downto 0)));
					temp1		:= std_logic_vector(unsigned(temp1) + unsigned(vec_u(word_len-1 downto 0))*unsigned(vec_v(word_len-1 downto 0)));
					temp		:= std_logic_vector(unsigned(temp1(2*word_len downto 0))*unsigned(module_inv))(word_len-1 downto 0);
					temp2		:= '0' & std_logic_vector(unsigned(temp)*unsigned(module));
					temp2		:= std_logic_vector(unsigned(temp2) + unsigned(vec_u(word_len-1 downto 0))*unsigned(vec_v));
					temp_result	<= std_logic_vector(to_unsigned(0, word_len)) & std_logic_vector(unsigned(temp_result) + unsigned(temp2))(mod_len+word_len downto word_len);
					vec_u		<= vec_u(word_len-1 downto 0) & vec_u(mod_len-1 downto word_len);
					
					iterator	<= iterator + 1;
				elsif iterator = steps then
					if unsigned(temp_result) >= unsigned(module) then
						temp_result	<= std_logic_vector(unsigned(temp_result) - unsigned(module));
					end if;
					
					iterator	<= iterator + 1;
				elsif iterator = steps+1 then
					result		<= temp_result(mod_len-1 downto 0);
					flag		<= '1';
					
					iterator	<= iterator + 1;
				end if;
			end if;
		end if;
	end process;
end architecture arch_montgomery_multiplication;