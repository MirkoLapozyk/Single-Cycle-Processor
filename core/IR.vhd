library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

entity IR is
    port (
        instruction_in: in std_logic_vector(31 downto 0);
        instruction_out: out std_logic_vector(31 downto 0);
        wfi, clk, irq: in std_logic
    );
end IR;

architecture Behavioral of IR is

signal sr: std_logic :='1';

begin
process(instruction_in,clk)
begin
    if wfi='0' then
        instruction_out <= instruction_in;
    end if;
end process;
 
--latch: process(wfi,irq)
--    begin
--    case sr is
--        when '0' =>
--            if irq='1' then
--                sr <= '1';
--             end if;
--        when '1' =>
--            if wfi='1' and irq='0' then
--                sr <= '0';
--            end if;
--        when others => null;
--    end case;
--end process;

end Behavioral;
