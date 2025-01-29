library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.ALL;


entity data_mem is

port(  addr_DM: in std_logic_vector(8 downto 0);    --gli indirizzi sono riferiti ai byte perciò con una memoria da 128 posti (32 bit) ho 512 byte, quindi 9 bit per indirizzarli tutti
       data_DM: inout std_logic_vector(31 downto 0); 
       write_DM, read_DM, B, H, W : in std_logic
    );

end entity;



architecture comportamento of data_mem is

type DM_type is array (0 to 511) of std_logic_vector (7 downto 0);       -- creazione celle
signal MEMORIA_DATI: DM_type := (others => (others => '0'));               -- inizializzazione celle di memoria a 0
                                                        
begin

funzione: process(all)

begin


if B = '1' then  --istruzione che richiede accesso ai singoli byte.

   if read_DM = '1' and write_DM = '0' then    --doppia condizione su read e write per evitare errori e corruzione di dati

	data_DM <= x"000000" & MEMORIA_DATI(to_integer(unsigned(addr_DM)));
		
   elsif write_DM='1' and read_DM='0' then

	MEMORIA_DATI(to_integer(unsigned(addr_DM))) <= data_DM (7 downto 0);
		
   elsif read_DM='0' and write_DM='0' then

	data_DM <= "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ";

   end if;


elsif H = '1' then  --istruzione che richiede accesso a 16 bit (halfword).

   if read_DM = '1' and write_DM = '0' then    

	data_DM <= x"0000" & MEMORIA_DATI(to_integer(unsigned(addr_DM))) & MEMORIA_DATI(to_integer(unsigned(addr_DM) + 1));
		
   elsif write_DM='1' and read_DM='0' then

	MEMORIA_DATI(to_integer(unsigned(addr_DM))) <= data_DM (15 downto 8);
        MEMORIA_DATI(to_integer(unsigned(addr_DM) + 1)) <= data_DM (7 downto 0);
		
   elsif read_DM='0' and write_DM='0' then

	data_DM <= "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ";

   end if;



elsif W = '1' then   --istruzione che richiede la word intera (32 bit).

   if read_DM = '1' and write_DM = '0' then    

	data_DM <= MEMORIA_DATI(to_integer(unsigned(addr_DM))) & MEMORIA_DATI(to_integer(unsigned(addr_DM) + 1)) & MEMORIA_DATI(to_integer(unsigned(addr_DM) + 2)) &         
        MEMORIA_DATI(to_integer(unsigned(addr_DM) + 3));
		
   elsif write_DM='1' and read_DM='0' then

	MEMORIA_DATI(to_integer(unsigned(addr_DM))) <= data_DM (31 downto 24);
        MEMORIA_DATI(to_integer(unsigned(addr_DM) + 1)) <= data_DM (23 downto 16);
        MEMORIA_DATI(to_integer(unsigned(addr_DM) + 2)) <= data_DM (15 downto 8);
        MEMORIA_DATI(to_integer(unsigned(addr_DM) + 3)) <= data_DM (7 downto 0);
		
   elsif read_DM ='0' and write_DM ='0' then

	data_DM <= "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ";

   end if;

end if;

end process;

end architecture;