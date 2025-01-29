library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity SingleCycleProcessor_tb is
end SingleCycleProcessor_tb;

architecture behavior of SingleCycleProcessor_tb is
    
    signal rst, irq, clk, wfi :  std_logic;
    signal data_PM, istruzione: std_logic_vector(31 downto 0);
    signal instruction_out, instruction_in: std_logic_vector(31 downto 0);
    signal addr_PM:  std_logic_vector(5 downto 0); 
    signal data_DM:  std_logic_vector(31 downto 0);
    signal addr_DM:  std_logic_vector(8 downto 0);
    signal data_RF1, data_RF2:  std_logic_vector (31 downto 0);
    signal data_RFD:  std_logic_vector (31 downto 0);
    signal addr_RF1,addr_RF2, addr_RFD:  std_logic_vector (4 downto 0);
    signal PC, next_PC: std_logic_vector (31 downto 0);
    signal read_DM, write_DM, B, H, W: std_logic;
        
Component Single_Cycle_CPU
	Port ( irq: in std_logic;
		 istruzione: in std_logic_vector(31 downto 0);
	     data_DM: inout std_logic_vector(31 downto 0);
	     addr_DM: out std_logic_vector(8 downto 0);
         data_RF1, data_RF2: in std_logic_vector (31 downto 0);
         data_RFD: out std_logic_vector (31 downto 0);
         addr_RF1,addr_RF2, addr_RFD: out std_logic_vector (4 downto 0);
	     PC: in std_logic_vector (31 downto 0);
	     next_PC: out std_logic_vector (31 downto 0);
		 read_DM, write_DM, B, H, W, wfi :out std_logic
		);
END Component;

Component data_mem
	Port ( addr_DM: in std_logic_vector(8 downto 0);    --gli indirizzi sono riferiti ai byte perciò con una memoria da 128 posti (32 bit) ho 512 byte, quindi 9 bit per indirizzarli tutti
       data_DM: inout std_logic_vector(31 downto 0); 
       write_DM, read_DM, B, H, W : in std_logic
		);
END Component;

Component prog_mem
	Port (
	     rst,clk: in std_logic;
	     addr_PM: in std_logic_vector(5 downto 0);
	     data_PM: out std_logic_vector(31 downto 0)
		);
END Component;

Component register_file
	Port (rst, clk: in std_logic;
	      addr_RF1, addr_RF2, addr_RFD: in std_logic_vector(4 downto 0);	-- indirizzi source e destination register
	      data_RF1, data_RF2: out std_logic_vector(31 downto 0);            -- valori source register
	      data_RFD: in std_logic_vector(31 downto 0);	                -- valore destination register
	      PC: out std_logic_vector(31 downto 0);
	      next_PC: in std_logic_vector(31 downto 0)
		);
END Component;

Component ir
    Port (
        instruction_in: in std_logic_vector(31 downto 0);
        instruction_out: out std_logic_vector(31 downto 0);
        wfi, clk, irq: in std_logic );
END Component;

begin
    U1: Single_Cycle_CPU
        port map (
            -- Testbench
            irq => irq,
            wfi => wfi,
            PC => PC,
            next_PC => next_PC,
            data_RF1 => data_RF1,
            data_RF2 => data_RF2,
            data_RFD => data_RFD,
            addr_RF1 => addr_RF1,
            addr_RF2 => addr_RF2,
            addr_RFD => addr_RFD,
            
            -- Data Memory
            read_DM => read_DM,
            write_DM => write_DM,
            addr_DM => addr_DM,
            data_DM => data_DM,
            B => B,
            W => W,
            H => H,
            
            -- Instruction Register
            istruzione => istruzione
        );
        
    U2: register_file
        port map ( rst => rst,
            clk => clk,
            PC => PC,
            next_PC => next_PC,
            data_RF1 => data_RF1,
            data_RF2 => data_RF2,
            data_RFD => data_RFD,
            addr_RF1 => addr_RF1,
            addr_RF2 => addr_RF2,
            addr_RFD => addr_RFD
        );

    U3: prog_mem
        port map (
            clk => clk,
             rst => rst,
             addr_PM => addr_PM,
            data_PM => data_PM
        );

    U4: data_mem
        port map (
             read_DM => read_DM,
            write_DM => write_DM,
            addr_DM => addr_DM,
            data_DM => data_DM,
            B => B,
            W => W,
            H => H
        );
     U5: ir
     port map (
            instruction_in => instruction_in,
            instruction_out => instruction_out,
            clk => clk,
            wfi => wfi,
            irq => irq
     );
     
addr_PM <= PC(5 downto 0);
instruction_in <= data_PM;
istruzione <= instruction_out;

    clock : process
    begin
        clk <= '0';
        wait for 100 ns;
        clk <= '1';
        wait for 100 ns;
    end process;

    test: process
    begin
        irq <= '1';
        rst <= '1';
        wait for 100 ns;
        rst <='0';
        irq <= '0';
        wait for 1500 ns;
        irq <='1';
        wait for 150 ns;
        irq <='0';
        wait;
    end process;

end behavior;
