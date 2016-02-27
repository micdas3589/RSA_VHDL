library IEEE;
	use IEEE.std_logic_1164.all;
	use IEEE.numeric_std.all;
library altera;
	use altera.altera_primitives_components.all;

entity horner_multiplication is
	generic(
		mod_len		: integer
	);
	port(
		vec_x		: in std_logic_vector(mod_len-1 downto 0);
		vec_y		: in std_logic_vector(mod_len-1 downto 0);
		module		: in std_logic_vector(mod_len-1 downto 0);
		mode		: in std_logic;
		reset		: in std_logic;
		clk			: in std_logic;
		flag		: out std_logic;
		result		: out std_logic_vector(mod_len-1 downto 0)
	);
end entity horner_multiplication;

architecture arch_horner_multiplication of horner_multiplication is
	signal iterator		: unsigned(10 downto 0);
	signal vec_v		: std_logic_vector(mod_len-1 downto 0);
	signal vec_u		: std_logic_vector(mod_len-1 downto 0);
	signal temp_result	: std_logic_vector(mod_len-1 downto 0);
begin
	process(clk)		
		variable temp	: std_logic_vector(mod_len+1 downto 0);
	begin
		if clk = '1' and clk'event then
			if reset = '1' then
				flag		<= '0';
				iterator	<= to_unsigned(0, 11);
				temp_result	<= std_logic_vector(to_unsigned(0, mod_len));
				vec_v		<= vec_x;
				vec_u		<= vec_y;
			end if;
			
			if mode = '1' and reset = '0' then
				if iterator < mod_len then
					temp	:= std_logic_vector(unsigned('0' & temp_result & '0') + unsigned(vec_u(mod_len-1 downto mod_len-1))*unsigned(vec_v));
					
					if unsigned(temp) >= unsigned(module & '0') then
						temp_result	<= std_logic_vector(unsigned(temp) - unsigned(module & '0'))(mod_len-1 downto 0);
					elsif unsigned(temp) >= unsigned(module) then
						temp_result	<= std_logic_vector(unsigned(temp) - unsigned(module))(mod_len-1 downto 0);
					else
						temp_result	<= temp(mod_len-1 downto 0);
					end if;
					
					vec_u		<= vec_u(mod_len-2 downto 0) & '0';
					iterator 	<= iterator + 1;
				elsif iterator = mod_len then
					result		<= temp_result(mod_len-1 downto 0);
					flag		<= '1';
					
					iterator <= iterator + 1;
				end if;
			end if;
		end if;
	end process;
end architecture arch_horner_multiplication;