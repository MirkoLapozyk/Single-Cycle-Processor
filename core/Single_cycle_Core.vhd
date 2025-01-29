library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;

entity single_cycle_cpu is

	port(wfi: out std_logic:='0';
	     irq: in std_logic;
	     istruzione: in std_logic_vector(31 downto 0);
         data_DM: inout std_logic_vector(31 downto 0);
	     addr_DM: out std_logic_vector(8 downto 0);
         data_RF1, data_RF2: in std_logic_vector (31 downto 0);
         data_RFD: out std_logic_vector (31 downto 0);
         addr_RF1,addr_RF2, addr_RFD: out std_logic_vector (4 downto 0);
	     PC: in std_logic_vector (31 downto 0);
	     next_PC: out std_logic_vector (31 downto 0):=x"00000000";
		 read_DM, write_DM, B, H, W :out std_logic
         );
		 
end single_cycle_cpu;


architecture funzionamento of single_cycle_cpu is

signal Operando1, Operando2, OperandoD: std_logic_vector (31 downto 0);
type my_state is
		(waiting, attivo);
signal state,next_state: my_state;
begin

Istruzioni: process(istruzione,irq)

variable shift_count : std_logic_vector (31 downto 0);  -- variabile usata per indicare lo spostamento in una istruzione di shift.
variable branch_offset : std_logic_vector (12 downto 0); --il branch utilizza un offset di 12 bit con segno, perciò si utilizza una variabile a 13 bit.
variable jump_offset : std_logic_vector (20 downto 0);  -- stesso discorso per il jump diretto e indiretto.
variable jump_indirect_offset : std_logic_vector (31 downto 0);
variable AUIPC_offset : std_logic_vector (31 downto 0);
variable LUI_offset : std_logic_vector (31 downto 0);
variable store_offset : std_logic_vector (11 downto 0);
variable mult : std_logic_vector (63 downto 0); --variabile per ospitare il risultato di una moltiplicazione tra vettori di 32 bit.
variable valore_PC : std_logic_vector (31 downto 0);

    
begin

	if irq='1' then
		wfi<='0';
	end if;
               case istruzione (6 downto 2) is    --diramazione per la scelta delle istruzioni.
                
                
                when "00100" => case istruzione (14 downto 12) is --OPERATIONS WITH IMMEDIATES 
                                 
                                 when "000" =>  addr_RF1 <= istruzione(19 downto 15); --ADDI
                                                Operando1 <= data_RF1;
                                                data_RFD <= std_logic_vector(signed(istruzione(31 downto 20)) + signed(Operando1));   --il sign extension è fatto in automatico dall'operazione + del pacchetto numeric_std
                                                addr_RFD<= istruzione(11 downto 7);                                                   --che infatti può usare due vettori di lunghezze diverse e restituisce un vettore di lunghezza pari alla massima tra i due operandi
                                                next_PC<=std_logic_vector(unsigned(PC)+4);

                                  when "100" => addr_RF1 <= istruzione(19 downto 15);   --XORI
                                                Operando1 <= data_RF1;
                                                data_RFD <= (Operando1 xor (x"00000" & istruzione(31 downto 20)));
                                                addr_RFD <= istruzione(11 downto 7);
                                                next_PC<=std_logic_vector(unsigned(PC)+4);
                                                
                                  when "010" => addr_RF1 <= istruzione(19 downto 15);   --SLTI
                                                Operando1 <= data_RF1;
                                                if signed(Operando1) < signed(istruzione(31 downto 20)) then
                                                    
                                                     addr_RFD <= istruzione(11 downto 7);
                                                     data_RFD <= x"00000001";
                                                else addr_RFD<= istruzione(11 downto 7);
                                                     data_RFD <= x"00000000";
                                                     
                                                end if;
                                               
                                                next_PC<=std_logic_vector(unsigned(PC)+4);
                                                
                                  when "110" => addr_RF1 <= istruzione(19 downto 15);   --ORI
                                                Operando1 <= data_RF1;
                                                data_RFD <= (Operando1 or (x"00000" & istruzione(31 downto 20)));
                                                addr_RFD<= istruzione(11 downto 7);
                                                next_PC<=std_logic_vector(unsigned(PC)+4);
                                                
                                                
                                  when "001" => addr_RF1 <= istruzione(19 downto 15);   --SLLI
                                                Operando1 <= data_RF1;
                                                shift_count := x"000000" & "000" & istruzione (24 downto 20);
                                                data_RFD <= std_logic_vector(shift_left(unsigned(Operando1), to_integer(unsigned(shift_count(4 downto 0)))));
                                                addr_RFD <= istruzione(11 downto 7);
                                                next_PC<=std_logic_vector(unsigned(PC)+4);
                                                
                                                
                                   
                                  when "101" => if istruzione(30)='0' then    --SRLI
                                                       addr_RF1 <= istruzione(19 downto 15); 
                                                              Operando1 <= data_RF1;
                                                       shift_count := x"000000" & "000" & istruzione (24 downto 20);
                                                       data_RFD <= std_logic_vector(shift_right(unsigned(Operando1), to_integer(unsigned(shift_count(4 downto 0)))));
                                                       addr_RFD <= istruzione(11 downto 7);
                                                              next_PC<=std_logic_vector(unsigned(PC)+4);
                                                             
                                                 else addr_RF1 <= istruzione(19 downto 15); --SRAI
                                                              Operando1 <= data_RF1;
                                                       shift_count := x"000000" & "000" & istruzione (24 downto 20);
                                                       data_RFD <= std_logic_vector(shift_right(signed(Operando1), to_integer(unsigned(shift_count(4 downto 0)))));
                                                       addr_RFD <= istruzione(11 downto 7);
                                                              next_PC<=std_logic_vector(unsigned(PC)+4);
                                                         
                                                 end if;
                                                   
                                                
                                  
                                  when "011" => addr_RF1 <= istruzione(19 downto 15);   --SLTIU
                                                Operando1 <= data_RF1;
                                                if unsigned(Operando1) < unsigned(istruzione(31 downto 20)) then
                                                    
                                                     addr_RFD<= istruzione(11 downto 7);
                                                     data_RFD <= x"00000001";
                                                     
                                                else addr_RFD<= istruzione(11 downto 7);
                                                     data_RFD <= x"00000000";
                                                          
                                                end if;
                                               
                                                next_PC<=std_logic_vector(unsigned(PC)+4);
                                                
                                                
                                  when "111" => addr_RF1 <= istruzione(19 downto 15);   --ANDI
                                                Operando1 <= data_RF1;
                                                data_RFD <= (Operando1 and (x"00000" & istruzione(31 downto 20)));
                                                addr_RFD <= istruzione(11 downto 7);
                                                next_PC<=std_logic_vector(unsigned(PC)+4);
                                                
                                  when others => null;
                                  
                                end case;
                                
                when "01100" =>
                    if istruzione (26 downto 25) = "00" then  
                        case istruzione (14 downto 12) is --DATA PROCESSING
                
                                  
                                  when "000" => if istruzione (30) = '0' then --ADD
                                                   addr_RF1 <= istruzione(19 downto 15);
                                                   addr_RF2 <= istruzione(24 downto 20);								   
                                                      Operando1 <= data_RF1;
                                                   Operando2 <= data_RF2;
                                                   
                                                   data_RFD <= std_logic_vector(signed(Operando1) + signed(Operando2));
                                                   addr_RFD<= istruzione(11 downto 7);
                                                      next_PC<=std_logic_vector(unsigned(PC)+4);
                                                      
                                                 else 
                                                   addr_RF1 <= istruzione(19 downto 15);
                                                   addr_RF2 <= istruzione(24 downto 20);								   
                                                      Operando1 <= data_RF1;
                                                   Operando2 <= data_RF2;
                                                   
                                                   data_RFD <= std_logic_vector(signed(Operando1) - signed(Operando2));
                                                   addr_RFD <= istruzione(11 downto 7);
                                                      next_PC<=std_logic_vector(unsigned(PC)+4);
                                                      
                
                                                 end if;
                                                 
                                                 
                                  when "100" => addr_RF1 <= istruzione(19 downto 15);   --XOR
                                                addr_RF2 <= istruzione(24 downto 20);
                                                Operando1 <= data_RF1;
                                                Operando2 <= data_RF2;
                                                
                                                data_RFD <= (Operando1 xor Operando2);
                                                addr_RFD <= istruzione(11 downto 7);
                                                next_PC <= std_logic_vector(unsigned(PC)+4);
                                                
                                                
                                  when "010" => addr_RF1 <= istruzione(19 downto 15);   --SLT
                                                addr_RF2 <= istruzione(24 downto 20);
                                                Operando1 <= data_RF1;
                                                Operando2 <= data_RF2;
                                                
                                                if signed(Operando1) < signed(Operando2) then
                                                    
                                                     addr_RFD <= istruzione(11 downto 7);
                                                     data_RFD <= x"00000001";
                                                     
                                                else addr_RFD <= istruzione(11 downto 7);
                                                     data_RFD <= x"00000000";
                                                          
                                                end if;
                                               
                                                next_PC<=std_logic_vector(unsigned(PC)+4);
                                                
                                                
                                  when "110" => addr_RF1 <= istruzione(19 downto 15);   --OR
                                                addr_RF2 <= istruzione(24 downto 20);
                                                Operando1 <= data_RF1;
                                                Operando2 <= data_RF2;
                                                
                                                data_RFD <= (Operando1 or Operando2);
                                                addr_RFD <= istruzione(11 downto 7);
                                                next_PC<=std_logic_vector(unsigned(PC)+4);
                                                
                                                
                                  when "001" => addr_RF1 <= istruzione(19 downto 15);   --SLL
                                                addr_RF2 <= istruzione(24 downto 20);
                                                Operando1 <= data_RF1;
                                                Operando2 <= data_RF2;
                                                
                                                shift_count := Operando2;
                                                data_RFD <= std_logic_vector(shift_left(unsigned(Operando1), to_integer(unsigned(shift_count(4 downto 0)))));
                                                addr_RFD<= istruzione(11 downto 7);
                                                next_PC<=std_logic_vector(unsigned(PC)+4);
                                                
                                                
                                   
                                  when "101" => if istruzione(30)='0' then --SRL
                                                       addr_RF1 <= istruzione(19 downto 15);   
                                                       addr_RF2 <= istruzione(24 downto 20);
                                                              Operando1 <= data_RF1;
                                                       Operando2 <= data_RF2;
                                                       shift_count := Operando2;
                                                       
                                                       data_RFD <= std_logic_vector(shift_right(unsigned(Operando1), to_integer(unsigned(shift_count(4 downto 0)))));
                                                       addr_RFD <= istruzione(11 downto 7);
                                                              next_PC<=std_logic_vector(unsigned(PC)+4);
                                                              
                                                      
                                                 else  addr_RF1 <= istruzione(19 downto 15);    --SRA
                                                       addr_RF2 <= istruzione(24 downto 20);
                                                              Operando1 <= data_RF1;
                                                       Operando2 <= data_RF2;
                                                       
                                                       shift_count := Operando2;
                                                       data_RFD <= std_logic_vector(shift_right(signed(Operando1), to_integer(unsigned(shift_count(4 downto 0)))));
                                                       addr_RFD <= istruzione(11 downto 7);
                                                              next_PC<=std_logic_vector(unsigned(PC)+4);
                                                         
                                                 end if;
                                                   
                                                
                                  
                                  when "011" => addr_RF1 <= istruzione(19 downto 15);   --SLTU
                                                addr_RF2 <= istruzione(24 downto 20);
                                                Operando1 <= data_RF1;
                                                Operando2 <= data_RF2;
                                                
                                                
                                                if unsigned(Operando1) < unsigned(Operando2) then
                                                    
                                                     addr_RFD <= istruzione(11 downto 7);
                                                     data_RFD <= x"00000001";
                                                     
                                                else addr_RFD <= istruzione(11 downto 7);
                                                     data_RFD <= x"00000000";
                                                          
                                                end if;
                                               
                                                next_PC<=std_logic_vector(unsigned(PC)+4);
                                                
                                                
                                  when "111" => addr_RF1 <= istruzione(19 downto 15);   --AND
                                                addr_RF2 <= istruzione(24 downto 20);
                                                Operando1 <= data_RF1;
                                                Operando2 <= data_RF2;
                                                
                                                data_RFD <= (Operando1 and Operando2);
                                                addr_RFD <= istruzione(11 downto 7);
                                                next_PC <= std_logic_vector(unsigned(PC)+4);
                                                
                                  when others => null;
                                  
                                end case;
                             elsif istruzione (26 downto 25) = "01" then
                                 case istruzione (14 downto 12) is --MOLTIPLICAZIONI E DIVISIONI
                    
                                    
                                    when "000" => addr_RF1 <= istruzione(19 downto 15);  --MUL
                                                  addr_RF2 <= istruzione(24 downto 20);								   
                                                    --lettura rs1 e rs2
                                                  Operando1 <= data_RF1;
                                                  Operando2 <= data_RF2;
                                                  
                                                  mult := std_logic_vector(unsigned(Operando1) * unsigned(Operando2)); --se devo prendere solo gli ultimi 32 bit è la stessa cosa usare dei vettori signed o unsigned.
                                                  data_RFD <= mult(31 downto 0);  --prendo solo gli ultimi 32 bit.
                                                  addr_RFD <= istruzione(11 downto 7);
                                                  
                                                  next_PC <= std_logic_vector(unsigned(PC)+4);
                                                    							  
                                    
                                    
                                    when "001" => addr_RF1 <= istruzione(19 downto 15);  --MULH
                                                  addr_RF2 <= istruzione(24 downto 20);								   
                                                    --lettura rs1 e rs2
                                                  Operando1 <= data_RF1;
                                                  Operando2 <= data_RF2;
                                                  
                                                  mult := std_logic_vector(signed(Operando1) * signed(Operando2));
                                                  data_RFD <= mult(63 downto 32); --prendo solo i primi 32 bit
                                                  addr_RFD <= istruzione(11 downto 7);
                                                  
                                                  next_PC <= std_logic_vector(unsigned(PC)+4);
                                                    							  
                                    
                                    
                                    when "010" => addr_RF1 <= istruzione(19 downto 15);  --MULHSU
                                                  addr_RF2 <= istruzione(24 downto 20);								   
                                                    --lettura rs1 e rs2
                                                  Operando1 <= data_RF1;
                                                  Operando2 <= data_RF2;
                                                  
                                                  mult := std_logic_vector(signed(Operando1) * to_integer(unsigned(Operando2))); --deve moltiplicare rs1 (signed) con rs2(unsigned) e avere come risultato un signed.
                                                  data_RFD <= mult(63 downto 32); --prendo solo i primi 32 bit
                                                  addr_RFD <= istruzione(11 downto 7);
                                                  
                                                  next_PC <= std_logic_vector(unsigned(PC)+4); 
                                                    							  
                                    
                                    
                                    when "011" => addr_RF1 <= istruzione(19 downto 15);  --MULHU
                                                  addr_RF2 <= istruzione(24 downto 20);								   
                                                    --lettura rs1 e rs2
                                                  Operando1 <= data_RF1;
                                                  Operando2 <= data_RF2;
                                                  
                                                  mult := std_logic_vector(unsigned(Operando1) * unsigned(Operando2));
                                                  data_RFD <= mult(63 downto 32); --prendo solo i primi 32 bit
                                                  addr_RFD <= istruzione(11 downto 7);
                                                  
                                                  next_PC <= std_logic_vector(unsigned(PC)+4);
                                                  							  
                                                  
                                    
                                    
                                    when "100" => addr_RF1 <= istruzione(19 downto 15);  --DIV
                                                  addr_RF2 <= istruzione(24 downto 20);								   
                                                    --lettura rs1 e rs2
                                                  Operando1 <= data_RF1;
                                                  Operando2 <= data_RF2;
                                                  
                                                  data_RFD <= std_logic_vector(signed(Operando1) / signed(Operando2)); --non c'è bisogno di una variabile perchè produce un risulatato a 32bit.
                                                  addr_RFD <= istruzione(11 downto 7);
                                                  
                                                  next_PC <= std_logic_vector(unsigned(PC)+4);
                                                    
                                    
                                    
                                    when "101" => addr_RF1 <= istruzione(19 downto 15);  --DIVU
                                                  addr_RF2 <= istruzione(24 downto 20);								   
                                                    --lettura rs1 e rs2
                                                  Operando1 <= data_RF1;
                                                  Operando2 <= data_RF2;
                                                  
                                                  data_RFD <= std_logic_vector(unsigned(Operando1) / unsigned(Operando2)); --non c'è bisogno di una variabile perchè produce un risulatato a 32bit.
                                                  addr_RFD <= istruzione(11 downto 7);
                                                  
                                                  next_PC <= std_logic_vector(unsigned(PC)+4);
                                                              
                                    
                                    
                                    when "110" => addr_RF1 <= istruzione(19 downto 15);  --REM
                                                  addr_RF2 <= istruzione(24 downto 20);								   
                                                    --lettura rs1 e rs2
                                                  Operando1 <= data_RF1;
                                                  Operando2 <= data_RF2;
                                                  
                                                  data_RFD <= std_logic_vector(signed(Operando1) rem signed(Operando2)); 
                                                  addr_RFD <= istruzione(11 downto 7);
                                                  
                                                  next_PC <= std_logic_vector(unsigned(PC)+4);
                                                               
                                    
                                    
                                    when "111" => addr_RF1 <= istruzione(19 downto 15);  --REMU
                                                  addr_RF2 <= istruzione(24 downto 20);								   
                                                    --lettura rs1 e rs2
                                                  Operando1 <= data_RF1;
                                                  Operando2 <= data_RF2;
                                                  
                                                  data_RFD <= std_logic_vector(unsigned(Operando1) rem unsigned(Operando2)); --non c'è bisogno di una variabile perchè produce un risulatato a 32bit.
                                                  addr_RFD <= istruzione(11 downto 7);
                                                  
                                                  next_PC <= std_logic_vector(unsigned(PC)+4);
                                                              
                                    
                                    when others => null;
                                    
                                end case;
                             end if;
                              
                when "11000" => case istruzione (14 downto 12) is --CONDITIONAL JUMPS
                                    
                                    
                                      when "000" => addr_RF1 <= istruzione(19 DOWNTO 15); --BEQ
                                                    addr_RF2 <= istruzione(24 downto 20);								   
                                                        Operando1 <= data_RF1;
                                                    Operando2 <= data_RF2;
                                                    
                                                    
                                                    if Operando1 = Operando2 then
                                                       branch_offset := istruzione(31) & istruzione(7) & istruzione(30 downto 25) & istruzione(11 downto 8) & '0';
                                                       next_PC <= std_logic_vector(signed(PC) + signed(branch_offset));
                                                                                        
                                                    else
                                                       next_PC <= std_logic_vector(unsigned(PC) + 4);
                                                       
                                                    end if;
                                                        
                                                    
                                      when "100" => addr_RF1 <= istruzione(19 DOWNTO 15); --BLT
                                                    addr_RF2 <= istruzione(24 downto 20);								   
                                                        Operando1 <= data_RF1;
                                                    Operando2 <= data_RF2;
                                                    
                                                    
                                                    if signed(Operando1) < signed(Operando2) then
                                                       branch_offset := istruzione(31) & istruzione(7) & istruzione(30 downto 25) & istruzione(11 downto 8) & '0';
                                                       next_PC <= std_logic_vector(signed(PC) + signed(branch_offset));
                                                                                        
                                                    else
                                                       next_PC <= std_logic_vector(unsigned(PC) + 4);
                                                       
                                                    end if;
                                                        
                                                    
                                      when "110" => addr_RF1 <= istruzione(19 DOWNTO 15); --BLTU
                                                    addr_RF2 <= istruzione(24 downto 20);								   
                                                        Operando1 <= data_RF1;
                                                    Operando2 <= data_RF2;
                                                    
                                                    
                                                    if unsigned(Operando1) < unsigned(Operando2) then
                                                       branch_offset := istruzione(31) & istruzione(7) & istruzione(30 downto 25) & istruzione(11 downto 8) & '0';
                                                       next_PC <= std_logic_vector(signed(PC) + signed(branch_offset));
                                                                                        
                                                    else
                                                       next_PC <= std_logic_vector(unsigned(PC) + 4);
                                                       
                                                    end if;
                                                        
                                                    
                                      when "001" => addr_RF1 <= istruzione(19 DOWNTO 15); --BNE
                                                    addr_RF2 <= istruzione(24 downto 20);								   
                                                        Operando1 <= data_RF1;
                                                    Operando2 <= data_RF2;
                                                    
                                                    
                                                    if Operando1 /= Operando2 then
                                                       branch_offset := istruzione(31) & istruzione(7) & istruzione(30 downto 25) & istruzione(11 downto 8) & '0';
                                                       next_PC <= std_logic_vector(signed(PC) + signed(branch_offset));
                                                                                        
                                                    else
                                                       next_PC <= std_logic_vector(unsigned(PC) + 4);
                                                       
                                                    end if;
                                                        
                                                    
                                      when "101" => addr_RF1 <= istruzione(19 DOWNTO 15); --BGE
                                                    addr_RF2 <= istruzione(24 downto 20);								   
                                                        Operando1 <= data_RF1;
                                                    Operando2 <= data_RF2;
                                                    
                                                    
                                                    if signed(Operando1) >= signed(Operando2) then
                                                       branch_offset := istruzione(31) & istruzione(7) & istruzione(30 downto 25) & istruzione(11 downto 8) & '0';
                                                       next_PC <= std_logic_vector(signed(PC) + signed(branch_offset));
                                                                                        
                                                    else
                                                       next_PC <= std_logic_vector(unsigned(PC) + 4);
                                                       
                                                    end if;
                                                        
                                      
                                      when "111" => addr_RF1 <= istruzione(19 DOWNTO 15); --BGEU
                                                    addr_RF2 <= istruzione(24 downto 20);								   
                                                        Operando1 <= data_RF1;
                                                    Operando2 <= data_RF2;
                                                    
                                                    
                                                    if unsigned(Operando1) >= unsigned(Operando2) then
                                                       branch_offset := istruzione(31) & istruzione(7) & istruzione(30 downto 25) & istruzione(11 downto 8) & '0';
                                                       next_PC <= std_logic_vector(signed(PC) + signed(branch_offset));
                                                                                        
                                                    else
                                                       next_PC <= std_logic_vector(unsigned(PC) + 4);
                                                       
                                                    end if;
                                                        
                                      when others => null;
                                      
                                end case;			
                                                    
                
                when "11011" => jump_offset := istruzione(31) & istruzione(19 downto 12) & istruzione(20) & istruzione(30 downto 21) & '0'; --JAL
                                data_RFD <= std_logic_vector(unsigned(PC) + 4); --salvataggio con link register della prossima istruzione.
                                addr_RFD <= istruzione (11 downto 7);
                                
                                next_PC <= std_logic_vector(signed(PC) + signed(jump_offset)); -- aggiornamento PC.
                                
                                
                                
                
                when "11001" => addr_RF1 <= istruzione(19 downto 15); --JALR
                                
                                Operando1 <= data_RF1;
                                
                                jump_indirect_offset := std_logic_vector(signed(istruzione(31 downto 20)) + signed(Operando1)); 
                                data_RFD <= std_logic_vector(unsigned(PC) + 4); --salvataggio con link register della prossima istruzione.
                                addr_RFD <= istruzione (11 downto 7);
                                
                                next_PC <= jump_indirect_offset(31 downto 1) & '0'; -- aggiornamento PC.
                                
                                
                                
                when "00101" => AUIPC_offset := istruzione(31 downto 12) & x"000";   --AUIPC
                                data_RFD <= std_logic_vector(signed(AUIPC_offset) + signed(PC));
                                addr_RFD <= istruzione(11 downto 7);
                                
                                next_PC <= std_logic_vector(unsigned(PC) + 4);
                                
                                
                                
                when "01101" => LUI_offset := istruzione(31 downto 12) & x"000";   --LUI
                                data_RFD <= std_logic_vector(signed(AUIPC_offset));
                                addr_RFD <= istruzione(11 downto 7);
                                
                                next_PC <= std_logic_vector(unsigned(PC) + 4);
                                
                                				
                
                when "00000" => case istruzione (14 downto 12) is --LOAD
                
                                when "000" => addr_RF1 <= istruzione(19 downto 15); --LB
                                              
                                              Operando1 <= data_RF1;
                                              
                                              B <= '1';
                                              addr_DM <= std_logic_vector(resize((signed(Operando1) + signed(istruzione(31 downto 20))), 9));  --non sono sicuro lo faccia bene il resize, in caso usare una variabile di appoggio e selezionare manualmente variabile (8 downto 0).
                                              write_DM <= '0'; read_DM <= '1'; 
                                              OperandoD <= std_logic_vector(resize(signed(data_DM(7 downto 0)), 32));
                                              addr_RFD <= istruzione(11 downto 7);
                                              data_RFD <= OperandoD;
                                              
                                              next_PC <= std_logic_vector(unsigned(PC) + 4);
                                              
                                              
                                
                                                
                                when "100" => addr_RF1 <= istruzione(19 downto 15); --LBU
                                              
                                              Operando1 <= data_RF1;
                                              
                                              B <= '1';
                                              addr_DM <= std_logic_vector(resize((signed(Operando1) + signed(istruzione(31 downto 20))), 9));
                                              write_DM <= '0'; read_DM <= '1'; 
                                              OperandoD <= data_DM;
                                              addr_RFD <= istruzione(11 downto 7);
                                              data_RFD <= OperandoD;
                                              
                                              next_PC <= std_logic_vector(unsigned(PC) + 4);
                                              
                                
                                
                                when "010" => addr_RF1 <= istruzione(19 downto 15); --LW
                                              
                                              Operando1 <= data_RF1;
                                              
                                              W <= '1';
                                              addr_DM <= std_logic_vector(resize((signed(Operando1) + signed(istruzione(31 downto 20))), 9));
                                              write_DM <= '0'; read_DM <= '1'; 
                                              OperandoD <= data_DM;
                                              addr_RFD <= istruzione(11 downto 7);
                                              data_RFD <= OperandoD;
                                              
                                              next_PC <= std_logic_vector(unsigned(PC) + 4);
                                              
                                
                                when "001" => addr_RF1 <= istruzione(19 downto 15); --LH
                                              
                                              Operando1 <= data_RF1;
                                              
                                              H <= '1';
                                              addr_DM <= std_logic_vector(resize((signed(Operando1) + signed(istruzione(31 downto 20))),9));
                                              write_DM <= '0'; read_DM <= '1'; 
                                              OperandoD <=  std_logic_vector(resize(signed(data_DM(15 downto 0)), 32));
                                              addr_RFD <= istruzione(11 downto 7);
                                              data_RFD <= OperandoD;
                                              
                                              next_PC <= std_logic_vector(unsigned(PC) + 4);
                                              
                                
                                
                                when "101" => addr_RF1 <= istruzione(19 downto 15); --LHU
                                              
                                              Operando1 <= data_RF1;
                                              
                                              H <= '1';
                                              addr_DM <= std_logic_vector(resize((signed(Operando1) + signed(istruzione(31 downto 20))),9));
                                              write_DM <= '0'; read_DM <= '1'; 
                                              OperandoD <= data_DM;
                                              addr_RFD <= istruzione(11 downto 7);
                                              data_RFD <= std_logic_vector(OperandoD);
                                              
                                              next_PC <= std_logic_vector(unsigned(PC) + 4);
                                              
                                             
                
                                when others => null;
                                
                                end case;
                                
                when "01000" => case istruzione (14 downto 12) is --STORE
                                
                                when "000" => addr_RF1 <= istruzione(19 downto 15); --SB
                                              addr_RF2 <= istruzione(24 downto 20);
                                                
                                              Operando1 <= data_RF1; --lettura rs1 (base register).
                                              Operando2 <= data_RF2; --lettura rs2 (dato di cui fare la store).
                                              
                                              B <= '1';  --operazione che si riferisce al byte.
                                              store_offset := istruzione(31 downto 25) & istruzione(11 downto 7);
                                              addr_DM <= std_logic_vector(resize((signed(Operando1) + signed(store_offset)),9));
                                              data_DM <= Operando2;
                                              write_DM <= '1'; read_DM <= '0'; 
                                              next_PC <= std_logic_vector(unsigned(PC) + 4);
                                              
                                
                                when "001" => addr_RF1 <= istruzione(19 downto 15); --SH
                                              addr_RF2 <= istruzione(24 downto 20);
                                                
                                              Operando1 <= data_RF1; --lettura rs1 (base register).
                                              Operando2 <= data_RF2; --lettura rs2 (dato di cui fare la store).
                                              
                                              H <= '1';  --operazione che si riferisce al byte.
                                              store_offset := istruzione(31 downto 25) & istruzione(11 downto 7);
                                              addr_DM <= std_logic_vector(resize((signed(Operando1) + signed(store_offset)),9));
                                              data_DM <= Operando2;
                                              write_DM <= '1'; read_DM <= '0'; 
                                              next_PC <= std_logic_vector(unsigned(PC) + 4);
                                
                                
                                when "010" => addr_RF1 <= istruzione(19 downto 15); --SW
                                              addr_RF2 <= istruzione(24 downto 20);
                                                
                                              Operando1 <= data_RF1; --lettura rs1 (base register).
                                              Operando2 <= data_RF2; --lettura rs2 (dato di cui fare la store).
                                              
                                              W <= '1';  --operazione che si riferisce al byte.
                                              store_offset := istruzione(31 downto 25) & istruzione(11 downto 7);
                                              addr_DM <= std_logic_vector(resize((signed(Operando1) + signed(store_offset)),9));
                                              data_DM <= Operando2;
                                              write_DM <= '1'; read_DM <= '0'; 
                                              next_PC <= std_logic_vector(unsigned(PC) + 4);
                                              
                                
                                
                                when others => null;
                                
                                end case;
                                                                
                when "11100" =>     if irq='0' then
                                        next_PC <= std_logic_vector(unsigned(PC)+4); --WFI
                                        wfi <= '1';
                                    end if;
                                
                when others => null;
                
                
                end case;
               

end process;
end architecture;