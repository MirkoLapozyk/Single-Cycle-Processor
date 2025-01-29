library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;

entity register_file is
	port( rst, clk: in std_logic;
	      addr_RF1, addr_RF2, addr_RFD: in std_logic_vector(4 downto 0);	-- indirizzi source e destination register
	      data_RF1, data_RF2: out std_logic_vector(31 downto 0);            -- valori source register
	      data_RFD: in std_logic_vector(31 downto 0);	                -- valore destination register
	      PC: out std_logic_vector(31 downto 0);
	      next_PC: in std_logic_vector(31 downto 0)
	       	    );
end entity;


architecture arch of register_file is

	type reg_file_type is array (0 to 31) of std_logic_vector(31 downto 0);	
	signal reg_file: reg_file_type;                         --creazione registri.

	procedure initialize_regfile(signal regs:out reg_file_type) is   -- inizializzazione memoria a 0
	begin
		for i in 0 to 31 loop
			regs(i)<=std_logic_vector(to_unsigned(0,32));
		end loop;
	end procedure;


begin    

reg_file(0) <= x"00000000"; -- hardwired zero
funzionamento: process(all)
        
     begin
                     data_RF1 <= reg_file(to_integer(unsigned(addr_RF1))); -- lettura registro s1
                     data_RF2 <= reg_file(to_integer(unsigned(addr_RF2))); -- lettura registro s2
                     reg_file(to_integer(unsigned(addr_RFD))) <= data_RFD; -- scrittura registro rd
end process;


program_counter: process(clk, rst)

begin
        if rst ='1' then
        
                 initialize_regfile(reg_file);
                  PC <= (others => '0');
                  
        elsif rising_edge(clk) then
                     
                  PC <= next_PC;
        end if;
end process;       


end architecture;