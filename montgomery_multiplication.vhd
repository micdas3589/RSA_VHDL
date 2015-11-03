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
		mode		: in std_logic_vector(3 downto 0);
		clk			: in std_logic;
		flag		: out std_logic;
		output		: out std_logic_vector(mod_len-1 downto 0)
	);
end entity montgomery_multiplication;

architecture arch_montgomery_multiplication of montgomery_multiplication is
	signal iterator		: unsigned(10 downto 0);
	signal iterator1	: unsigned(10 downto 0);
	signal iterator2	: unsigned(10 downto 0);
	signal iterator3	: unsigned(10 downto 0);
	signal temp_result	: std_logic_vector(2*mod_len-1 downto 0);
	signal steps		: unsigned(word_len-1 downto 0);
	signal u_mod_len	: unsigned(10 downto 0);
	signal vec_v		: std_logic_vector(mod_len-1 downto 0);
	signal vec_u		: std_logic_vector(mod_len-1 downto 0);
begin
	process(clk)
		variable index			: unsigned(21 downto 0);
		variable temp			: std_logic_vector(word_len-1 downto 0);
		variable temp2			: std_logic_vector(mod_len downto 0);
	begin
		if clk = '1' and clk'event then
			if mode(0) = '1' then -- reset
				flag		<= '0';
				temp_result	<= std_logic_vector(to_unsigned(0, 2*mod_len));
				vec_u		<= vec_x;
				vec_v		<= vec_y;
				steps		<= to_unsigned(mod_len/word_len, word_len);
				iterator	<= to_unsigned(0, 11);
				iterator1	<= to_unsigned(0, 11);
				iterator3	<= to_unsigned(mod_len/word_len+3, 11);
				u_mod_len	<= to_unsigned(mod_len, 11);
				
				if mode(2 downto 1) /= "01" then
					iterator2	<= to_unsigned(0, 11);
				else
					iterator2	<= to_unsigned(mod_len/word_len+3, 11);
				end if;
			end if;
			
			if mode(3) = '1' and mode(0) = '0' then -- work
				if mode(2 downto 1) = "01" then -- transform
					if iterator < u_mod_len then
						temp2		:= std_logic_vector(unsigned(vec_u) & '0');
						
						if unsigned(temp2) >= unsigned(module) then
							vec_u	<= std_logic_vector(unsigned(temp2) - unsigned(module))(mod_len-1 downto 0);
						else
							vec_u	<= temp2(mod_len-1 downto 0);
						end if;
						
						iterator	<= iterator + 1;
					elsif iterator = u_mod_len then
						iterator2	<= to_unsigned(0, 11);
						
						iterator	<= iterator + 1;
					end if;
					
					if iterator1 < u_mod_len then
						temp2		:= std_logic_vector(unsigned(vec_v) & '0');
						
						if unsigned(temp2) >= unsigned(module) then
							vec_v	<= std_logic_vector(unsigned(temp2) - unsigned(module))(mod_len-1 downto 0);
						else
							vec_v	<= temp2(mod_len-1 downto 0);
						end if;
						
						iterator1	<= iterator1 + 1;
					end if;
				end if;
				
				if iterator2 < steps then -- multiply
					temp		:= std_logic_vector(((unsigned(temp_result(word_len-1 downto 0)) + (unsigned(vec_u(word_len-1 downto 0)))*unsigned(vec_v(word_len-1 downto 0))))*unsigned(module_inv))(word_len-1 downto 0);
					temp_result	<= std_logic_vector(to_unsigned(0, word_len)) & std_logic_vector(unsigned(temp_result) + unsigned(vec_u(word_len-1 downto 0))*unsigned(vec_v) + unsigned(temp)*unsigned(module))(2*mod_len-1 downto word_len);
					vec_u		<= vec_u(word_len-1 downto 0) & vec_u(mod_len-1 downto word_len);
					
					iterator2	<= iterator2 + 1;
				elsif iterator2 = steps then
					if unsigned(temp_result) >= unsigned(module) then
						temp_result	<= std_logic_vector(unsigned(temp_result) - unsigned(module));
					end if;
					
					iterator2	<= iterator2 + 1;
				elsif mode(2 downto 1) /= "11" and iterator2 = steps+1 then
					output		<= temp_result(mod_len-1 downto 0);
					flag		<= '1';
					
					iterator2	<= iterator2 + 1;
				elsif mode(2 downto 1) = "11" and iterator2 = steps+1 then
					iterator3	<= to_unsigned(0, 11);
					
					iterator2	<= iterator2 + 1;
				end if;
				
				if mode(2 downto 1) = "11" then -- reduce
					if iterator3 < steps then
						index		:= iterator3*to_unsigned(word_len, 11);
						temp		:= std_logic_vector(unsigned(temp_result(to_integer(index)+word_len-1 downto to_integer(index)))*unsigned(module_inv))(word_len-1 downto 0);
						temp_result	<= std_logic_vector(unsigned(temp_result) + shift_left(to_unsigned(0, 2*mod_len) + unsigned(temp)*unsigned(module), to_integer(index)));
						
						iterator3	<= iterator3 + 1;
					elsif iterator3 = steps then
						temp_result <= std_logic_vector(shift_right(unsigned(temp_result), mod_len));
						
						iterator3	<= iterator3 + 1;
					elsif iterator3 = steps+1 then
						if unsigned(temp_result) > unsigned(module) then
							temp_result <= std_logic_vector(unsigned(temp_result) - unsigned(module));
						end if;
						
						iterator3	<= iterator3 + 1;
					elsif iterator3 = steps+2 then
						output		<= temp_result(mod_len-1 downto 0);
						flag		<= '1';
						
						iterator3	<= iterator3 + 1;
					end if;
				end if;
			end if;
			
			--if mode = "0000" then
				--flag	<= '0';
			--end if;
		end if;
	end process;
end architecture arch_montgomery_multiplication;