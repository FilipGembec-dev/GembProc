# GembProc
Custom 8 bit processor coded in Verilog
Working registers are stored in a vector and are from 00 to 03, it can be modified to add more registers by expanding the vector, must have minimal of two working registers.
The same works for INput and OUTput ports, there is an example in the proc code how to expand the number of ports.
Size of stack is 255 bytes.

Instruction set:
  /*NOP                                            00
    HLT                                            01
    LDR <target register> <address0> <address1>    02
    STR <start register> <address0> <address1>     03
    OUT <start register> <destination output port> 04
    IN <destination register> <start input port>   05
    ALU <operation> <result destination register>  06
    JMP <address0> <address1> 		       07
    JPC <argument operation> <address0> <address1> 08
    PUSH <start register> 			       09
    POP <destination register>                     0a*/
