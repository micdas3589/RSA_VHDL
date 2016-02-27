library IEEE;
	use IEEE.std_logic_1164.all;
	use IEEE.numeric_std.all;
library altera;
	use altera.altera_primitives_components.all;

entity fast_mod_exponentiation is
	generic(
		mod_len		: integer;
		word_len	: integer
	);
	port(
		base		: in std_logic_vector(mod_len-1 downto 0);
		exp			: in std_logic_vector(mod_len-1 downto 0);
		module		: in std_logic_vector(mod_len-1 downto 0);
		resid_sqr	: in std_logic_vector(mod_len-1 downto 0);
		module_inv 	: in std_logic_vector(word_len-1 downto 0);
		mode		: in std_logic;
		reset		: in std_logic;
		clk			: in std_logic;
		flag		: out std_logic;
		result		: out std_logic_vector(mod_len-1 downto 0)
	);
end entity fast_mod_exponentiation;

architecture arch_fast_mod_exponentiation of fast_mod_exponentiation is
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
			mode		: in std_logic;
			reset		: in std_logic;
			clk			: in std_logic;
			flag		: out std_logic;
			result		: out std_logic_vector(mod_len-1 downto 0)
		);
	end component montgomery_multiplication;
	
	signal base_mapped	: std_logic_vector(mod_len-1 downto 0);
	signal base_squared	: std_logic_vector(mod_len-1 downto 0);
	signal mult_result	: std_logic_vector(mod_len-1 downto 0);
	signal flag1		: std_logic;
	signal flag2		: std_logic;
	signal reset1		: std_logic;
	signal reset2		: std_logic;
	signal mode1		: std_logic;
	signal mode2		: std_logic;
	signal exponent		: std_logic_vector(mod_len-1 downto 0);
	signal temp_result	: std_logic_vector(mod_len-1 downto 0);
	signal init			: std_logic := '0';
	signal transform	: std_logic := '0';
	signal red_result	: std_logic;
	signal mult_flag	: std_logic;
	signal iterator		: unsigned(10 downto 0);

begin
	multiplication : montgomery_multiplication
	generic map(
		mod_len,
		word_len
	)
	port map(
		base_mapped,
		temp_result,
		module,
		module_inv,
		mode1,
		reset1,
		clk,
		flag1,
		mult_result
	);

	squaring : montgomery_multiplication
	generic map(
		mod_len,
		word_len
	)
	port map(
		base_mapped,
		base_mapped,
		module,
		module_inv,
		mode2,
		reset2,
		clk,
		flag2,
		base_squared
	);

	process(clk)
	begin
		if clk'event and clk = '1' then
			if reset = '1' then
				init	<= '0';
			end if;
		
			if mode = '1' and reset = '0' then
				if init = '0' then
					base_mapped	<= base;
					exponent	<= exp;
					flag		<= '0';
					reset1		<= '1';
					reset2		<= '0';
					mode1		<= '1';
					mode2		<= '0';
					mult_flag	<= '0';
					red_result	<= '0';
					iterator	<= to_unsigned(0, 11);
					temp_result <= resid_sqr;
					
					init		<= '1';
					transform	<= '1';
				elsif transform = '1' and flag1 = '1' then
					base_mapped	<= mult_result;
					temp_result	<= std_logic_vector(('1' & to_unsigned(0, mod_len))-unsigned(module))(mod_len-1 downto 0);
					
					mode2		<= '1';
					reset1		<= '1';
					reset2		<= '1';
					transform	<= '0';
				elsif transform = '1' then
					reset1		<= '0';
				elsif unsigned(exp) > 0 and unsigned(exponent) > 0 then
					if flag1 = '1' then
						if exp = exponent then
							reset1	<= '0';
							reset2	<= '0';
						elsif mult_flag = '0' then
							temp_result	<= mult_result;
							
							mult_flag	<= '1';
						end if;
					else
						mult_flag		<= '0';
					end if;
					
					if flag2 = '1' then
						if iterator = 0 then
							exponent	<= '0' & exponent(mod_len-1 downto 1);
							base_mapped	<= base_squared;
							
							iterator 	<= iterator + 1;
						elsif iterator = 1 then
							reset2		<= '1';
							mode2		<= '1';
							
							if exponent(0) = '1' then
								mode1 	<= '1';
								reset1	<= '1';
							else
								mode1 	<= '0';
							end if;
							
							iterator	<= iterator + 1;
						elsif iterator = 2 then
							reset1		<= '0';
							reset2		<= '0';
							
							iterator	<= iterator + 1;
						end if;
					else
						iterator		<= to_unsigned(0, 11);
					end if;
				else
					if flag1 = '1' and red_result = '0' then
						base_mapped		<= std_logic_vector(to_unsigned(1, mod_len));
						mode2			<= '0';
						reset1			<= '1';
					elsif red_result = '0' then
						red_result		<= '1';
						reset1			<= '0';						
					elsif flag1 = '1' and red_result = '1' then
						result			<= mult_result;
						flag			<= '1';
						mode1			<= '0';
						red_result		<= '0';
					end if;
				end if;
			end if;
		end if;
	end process;
end architecture arch_fast_mod_exponentiation;