# GembProc

A simple adaptable CPU designed for implementing in embeded FPGA solutions that require a general purpose CPU.

Modeled using explicit behavioral modeling style this procesor is a Turing complete machine with 11 named instructions, some of which are general instructions expanded using one or two arguments.
This model if not potimised is very easy to modify to meet user requirements.

Designed for implementation in Xilinx 7th gen FPGA (Artix7, Spartan7), the procesor implements 16k of internal distruibuted RAM with a 255 byte phisical stack, and can acces 16k of external read only memmory, however both values can be modified and ROM memmory can be removed all together so full 32k of memmory can be used as RAM (size depends on the chip).

Input and output ports are organised in two byte vectors and can be extended to 255 ports per vector (255 in, 255 out), there is an example of interfacing in tne code.
The processor has 4 general purpose registers organised in a byte vector, state register is indexed as last genereal purpose register index + 1.

The ALU can perform logical and arithmetic operations on general purpose registers and single bit manipulations on each of the registers including the state register.

The conditional jump operation can perform compariosons of registers and jump to the address pased to the instruction.

## Programing

Processor instructions and memmory are loaded in to the ROM memmory by the Vivado tool from a .mem file (BOOT_ROM.mem in this case).
Each bye of data is writen in their respective line representing a memmory addres altho using @(memmory location) gives more flexibility in addressing the memmory.
The Ass program complexity rises the machine code becomes to intricate to do by hand, an **Assembly compiler** was made to help with programing the low level Assembly code. Raw source code for the compiler is provided in the repo. 

### The compiler

The compiler has no natural language processing and scans the texst file for keywords and reads the rest of the line acording to the keyword. 

#define keyword is used to define new indentifiers for values  
example: 
#define A 0

# (label name) syntax is used for creating labels that point to the next instruction in the code and are used for jumping around in the program
example: 
 # loop  
 LDR A 456 


#### Instruction set

> NOP  00                                                      
> HLT  01                                                      
> LDR  02  (Register to load in to) (address[7:0])  (address[15:8])    
> STR  03  (Register to store) (address[7:0])  (address[15:8])       
> OUT  04  (Register to output) (Port to store to)                   
> IN   05  (Register to load in to) (Port from witch to load)     
> ALU  06  (Operation) (second operator)                             
> JMP  07  (address[7:0]) (address[15:8])                            
> JPC  08  (Argument) (address[7:0]) (address[15:8])                   
> PUSH 09  (Register to push to the stack)                         
> POP  0a  (Register to pop to from the stack)    






