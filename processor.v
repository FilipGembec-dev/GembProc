`timescale 1ns / 1ps
module GembProc1_6#(DataSize = 8, 
                    IRQ0Address = 'd50000)(
    input CLK100MHZ, rst, output reg r_w, reg write, wire [(2 * DataSize) - 1 :0] ExternalIndex, inout [DataSize - 1:0] M_, input IRQ0
    );
    

    parameter Working_Registers = 4;    
    reg IRQ0flag = 0;
    reg IRQ0reset = 0;
    reg hltreg = 0; //halt register
    wire sys_clock; //system clock register
    assign sys_clock = CLK100MHZ &! hltreg; //anding the input clock and the inverse of the halt register
    
    //defining the memory index net
    reg [(2 * DataSize) - 1:0] memCNTR = 'h0000;
    
    
    //register to buffer outgoing memmory
    reg [DataSize - 1:0] DataOutput = 8'h0;
    initial begin r_w = 0; write = 0; end
    

    //tristating the Memmory port
    assign M_ = r_w ? DataOutput : 'hz;
    assign ExternalIndex = memCNTR;

    //workign registers organised in a vector
    reg [DataSize - 1:0] REG[Working_Registers:0];
    //status flag
    initial REG[Working_Registers] = 'h0; // - REG[4][0] = carry 
                            // - REG[4][1] = negativeSign
    //register for keeping the value of the indexed register
    reg [DataSize - 1:0] regKeep = 'h00;
    reg [DataSize - 1:0] regKeep2 = 'h00;
    wire signed [8:0] negativeResultCheck; 
    assign negativeResultCheck = (REG[0] - regKeep2) >= 9'h0;
    //register for keeping the operation index
    reg [DataSize - 1:0] opKeep = 'h00;
    
            
    //intruction register
    reg [DataSize : 0] inst = 'h00;
    

    //16 bit register for storing the memmory to jump to
    reg [(2 * DataSize) - 1:0] memJMP = 'h0000;
    //16 bit register for keeping the value of memCNTR
    reg [(2 * DataSize) - 1:0] addressKeep = 'h0000;
    

    //implementing a 255 byte stack
    reg [DataSize - 1:0] STACK [100:0];
    reg [9:0] stackPointer = 'h00;

    //Chunk of memmory to store a register map during and interupt routine
    reg [(DataSize * 2) - 1 : 0] MemmorysationVector [16:0];
    
    integer i = 0;    
    
    //Reset time domain register flag
    reg ResetT = 'h0;
   
    //state machine for adding function and time domain to processor elements
    reg [7:0] T = 'h00; //register for keeping the time domain of state machine
    always@(posedge (sys_clock ^ rst ^ IRQ0 ^ IRQ0reset ^ ResetT))begin
        if(!rst & !IRQ0 & !IRQ0reset & !ResetT) begin  //if reset line is low execute processor operations
                T <= T + 1;  
            case(T) //instruction fetch
                'h00: begin inst <= M_; memCNTR <= memCNTR + 1; end
            endcase;
            
            case(inst)
                'h00:begin //NOP
                end
                'h01: begin //HLT
                    case(T)
                        'h01: hltreg <= 1;
                    endcase
                end
                'h02: begin//LDR <target register> <address0> <address1>
                    case(T)
                        'h01: begin memCNTR <= memCNTR + 1; regKeep <= M_; end
                        'h02: begin memJMP[7:0] <= M_; memCNTR <= memCNTR + 1; end
                        'h03: begin memJMP[(2 * DataSize) - 1:DataSize] <= M_; memCNTR <= memCNTR + 1; end
                        'h04: begin addressKeep <= memCNTR; memCNTR <= memJMP; end
                        'h05: begin REG[regKeep] <= M_; memCNTR <= addressKeep; memJMP <= 'h0000; ResetT <= 1; end
                    endcase
                end
                'h03: begin//STR <start register> <address0> <address1>
                    case(T)
                        'h01: begin memCNTR <= memCNTR + 1; regKeep <= M_; end
                        'h02: begin memJMP[DataSize - 1:0] <= M_; memCNTR <= memCNTR + 1; end
                        'h03: begin memJMP[(2 * DataSize) - 1:DataSize] <= M_; memCNTR <= memCNTR + 1; end
                        'h04: begin addressKeep <= memCNTR; memCNTR <= memJMP;  r_w <= 1; end
                        'h05: begin DataOutput <= REG[regKeep];  memJMP <= 'h0000;  end
                        'h06: begin write = 1; end
                        'h07: begin write = 0; r_w = 0; memCNTR <= addressKeep; ResetT <= 1; end
                    endcase
                end           
                'h06: begin//ALU <operation> <second operator>
                    case(T)
                        'h01: begin regKeep <= M_; memCNTR <= memCNTR + 1; end
                        'h02: begin regKeep2 <= M_; memCNTR <= memCNTR + 1; end
                        'h03: begin ResetT <= 1;
                              case(regKeep)  
                                    //Register to register logical operations
                                    'h00: REG[0] <= REG[0] & REG[M_];
                                    'h01: REG[0] <= REG[0] | REG[M_];
                                    'h02: REG[0] <= REG[0] ^ REG[M_];
                                    'h03: for(i = 0; i <= 7; i = i + 1) REG[0][i] <= ~REG[0][i];
                                    //Register to register arithmetical operations
                                    'h04: {REG[4][0], REG[0]} <= REG[0] + REG[regKeep2];
                                    'h05: begin REG[0] <= REG[0] - REG[regKeep2]; REG[4][1] = negativeResultCheck ? 1 : 0; end
                                    'h06: begin {REG[1], REG[0]} <= REG[0] * REG[regKeep2]; end
                                    'h07: begin REG[0] <= REG[0] / REG[regKeep2]; end
                                    //Single bit logical operations
                                    'h08: begin REG[0][regKeep2] = ~REG[0][regKeep2]; end //Invert bit
                                    'h09: REG[0][regKeep2] <= 1'h0; //Reset bit
                                    'h0a: REG[0][regKeep2] <= 1'h1; //Set bit 
                                                          
                              endcase
                              end
                    endcase 
                end
                'h07: begin //JMP <address0> <address1>
                    case(T)
                        'h01: begin memJMP[DataSize - 1:0] <= M_; memCNTR <= memCNTR + 1; end
                        'h02: begin memJMP[(2 * DataSize) - 1:DataSize] <= M_; end
                        'h03: begin memCNTR <= memJMP; ResetT <= 1;end
                    endcase
                end
                'h08: begin //JPC <argument operation> <address0> <address1>
                    case(T)
                        'h01: begin opKeep <= M_; memCNTR <= memCNTR + 1; end
                        'h02: begin memJMP[DataSize - 1:0] <= M_; memCNTR <= memCNTR + 1; end
                        'h03: begin memJMP[(2 * DataSize) - 1:DataSize] <= M_; memCNTR <= memCNTR + 1; end
                        'h04: begin ResetT <= 1;
                            case(opKeep)
                                'h00: begin if(REG[0] == REG[1]) memCNTR <= memJMP; end //Checking for equality
                                'h01: begin if(REG[0] > REG[1]) memCNTR <= memJMP; end //Checking if greater then
                                'h02: begin if(REG[0] < REG[1]) memCNTR <= memJMP; end //checking if les than
                                'h03: begin if(REG[4][0] == 1) memCNTR <= memJMP; end // cheking for carry
                                'h04: begin if(REG[4][1] == 1) memCNTR <= memJMP; end // checkign for negative sign
                                'h05: begin if(REG[0] == 8'h00) memCNTR <= memJMP; end // checking if zero
                            endcase
                        end
                   endcase
                end
                'h09: begin//PUSH <start register>
                    case(T)
                        'h01: regKeep <= M_;
                        'h02: STACK[stackPointer] <= REG[regKeep];
                        'h03: begin stackPointer <= stackPointer + 1; memCNTR <= memCNTR + 1; ResetT <= 1; end
                    endcase
                end        
                'h0a: begin//POP <destination register>
                    case(T)
                        'h01: begin regKeep <= M_; stackPointer <= stackPointer - 1; end
                        'h02: REG[regKeep] <= STACK[stackPointer];
                        'h03: begin  memCNTR <= memCNTR + 1; ResetT <= 1; end
                    endcase
                end
                'h0b: begin// EIR
                    case(T)
                        'h01: begin IRQ0flag <= 0; stackPointer = stackPointer - 1; end
                        
                        'h02: begin MemmorysationVector[16] <= STACK[stackPointer]; stackPointer <= stackPointer - 1; end
                        'h03: begin MemmorysationVector[15] <= STACK[stackPointer]; stackPointer <= stackPointer - 1; end
                        'h04: begin MemmorysationVector[14] <= STACK[stackPointer]; stackPointer <= stackPointer - 1; end
                        'h05: begin MemmorysationVector[13] <= STACK[stackPointer]; stackPointer <= stackPointer - 1; end
                        'h06: begin MemmorysationVector[12] <= STACK[stackPointer]; stackPointer <= stackPointer - 1; end
                        'h07: begin MemmorysationVector[11] <= STACK[stackPointer]; stackPointer <= stackPointer - 1; end
                        'h08: begin MemmorysationVector[10] <= STACK[stackPointer]; stackPointer <= stackPointer - 1; end
                        'h09: begin MemmorysationVector[9]  <= STACK[stackPointer]; stackPointer <= stackPointer - 1; end
                        'h0a: begin MemmorysationVector[8]  <= STACK[stackPointer]; stackPointer <= stackPointer - 1; end
                        'h0b: begin MemmorysationVector[7]  <= STACK[stackPointer]; stackPointer <= stackPointer - 1; end
                        'h0c: begin MemmorysationVector[6]  <= STACK[stackPointer]; stackPointer <= stackPointer - 1; end
                        'h0d: begin MemmorysationVector[5]  <= STACK[stackPointer]; stackPointer <= stackPointer - 1; end
                        'h0e: begin MemmorysationVector[4]  <= STACK[stackPointer]; stackPointer <= stackPointer - 1; end
                        'h0f: begin MemmorysationVector[3]  <= STACK[stackPointer]; stackPointer <= stackPointer - 1; end
                        'h10: begin MemmorysationVector[2]  <= STACK[stackPointer]; stackPointer <= stackPointer - 1; end
                        'h11: begin MemmorysationVector[1]  <= STACK[stackPointer]; stackPointer <= stackPointer - 1; end
                        'h12: begin MemmorysationVector[0]  <= STACK[stackPointer]; IRQ0reset <= 1; ResetT <= 1;      end
                    endcase
                end
                'h0c: begin//JSR <Address of subroutine>
                    case(T)
                        'h01: begin addressKeep <= memCNTR + 2; end
                        'h02: begin STACK[stackPointer] <= addressKeep[DataSize - 1 : 0]; stackPointer <= stackPointer + 1; end
                        'h03: begin STACK[stackPointer] <= addressKeep[(2 * DataSize) - 1 : DataSize]; stackPointer <= stackPointer + 1; end  
                        'h04: begin memJMP[DataSize - 1:0] <= M_; memCNTR <= memCNTR + 1; end
                        'h05: begin memJMP[(2 * DataSize) - 1:DataSize] <= M_; end
                        'h06: begin memCNTR <= memJMP; ResetT <= 1; end             
                    endcase
                end
                'h0d: begin //ESR 
                    case(T)
                        'h01: stackPointer <= stackPointer - 1;  
                        'h02: begin memJMP[(2 * DataSize) - 1 : DataSize] <= STACK[stackPointer]; stackPointer <= stackPointer - 1; end
                        'h03: begin memJMP[DataSize - 1 : 0] <= STACK[stackPointer];  end
                        'h04: begin memCNTR <= memJMP; ResetT <= 1; end
                    endcase
                end
                'd256: begin //Hidden instruction for storing the 
                    case(T)
                        //Save everything from the buffer to the stack
                        'h01:begin STACK[stackPointer] <= MemmorysationVector[0]; stackPointer <= stackPointer + 1; end
                        'h02:begin STACK[stackPointer] <= MemmorysationVector[1]; stackPointer <= stackPointer + 1; end
                        'h03:begin STACK[stackPointer] <= MemmorysationVector[2]; stackPointer <= stackPointer + 1; end
                        'h04:begin STACK[stackPointer] <= MemmorysationVector[3]; stackPointer <= stackPointer + 1; end
                        'h05:begin STACK[stackPointer] <= MemmorysationVector[4]; stackPointer <= stackPointer + 1; end
                        'h06:begin STACK[stackPointer] <= MemmorysationVector[5]; stackPointer <= stackPointer + 1; end
                        'h07:begin STACK[stackPointer] <= MemmorysationVector[6]; stackPointer <= stackPointer + 1; end
                        'h08:begin STACK[stackPointer] <= MemmorysationVector[7]; stackPointer <= stackPointer + 1; end
                        'h09:begin STACK[stackPointer] <= MemmorysationVector[8]; stackPointer <= stackPointer + 1; end
                        'h0a:begin STACK[stackPointer] <= MemmorysationVector[9]; stackPointer <= stackPointer + 1; end
                        'h0b:begin STACK[stackPointer] <= MemmorysationVector[10]; stackPointer <= stackPointer + 1; end
                        'h0c:begin STACK[stackPointer] <= MemmorysationVector[11]; stackPointer <= stackPointer + 1; end                       
                        'h0d:begin STACK[stackPointer] <= MemmorysationVector[12]; stackPointer <= stackPointer + 1; end
                        'h0e:begin STACK[stackPointer] <= MemmorysationVector[13]; stackPointer <= stackPointer + 1; end
                        'h0f:begin STACK[stackPointer] <= MemmorysationVector[14]; stackPointer <= stackPointer + 1; end
                        'h10:begin STACK[stackPointer] <= MemmorysationVector[15]; stackPointer <= stackPointer + 1; end
                        'h11:begin STACK[stackPointer] <= MemmorysationVector[16]; stackPointer <= stackPointer + 1;  ResetT <= 1; IRQ0flag <= 0;end
                        
                    endcase
                end
           endcase
        end
        
        //enter the interrupt sub routin
        if(IRQ0 & !rst & !IRQ0flag & !IRQ0reset)begin
            //Do register map saving and jump to IRQ0 address 
            MemmorysationVector[0] <= memCNTR;
            MemmorysationVector[1] <= DataOutput;
            MemmorysationVector[2] <= REG[0];
            MemmorysationVector[3] <= REG[1];
            MemmorysationVector[4] <= REG[2];
            MemmorysationVector[5] <= REG[3];
            MemmorysationVector[6] <= REG[4];
            MemmorysationVector[7] <= regKeep;
            MemmorysationVector[8] <= regKeep2;
            MemmorysationVector[9] <= opKeep;
            MemmorysationVector[10] <= inst;
            MemmorysationVector[11] <= memJMP;
            MemmorysationVector[12] <= addressKeep;
            MemmorysationVector[13] <= T;
            MemmorysationVector[14] <= r_w;
            MemmorysationVector[15] <= write;
            MemmorysationVector[16] <= ResetT;
            //settup work enviroment
            r_w <= 0;
            write <= 0;
            T <= 1;
            memCNTR <= IRQ0Address + 1;
            IRQ0flag <= 1;
            ResetT <= 0;
            inst <= 'd256;
        end
        
        //exit the interrupt sub routine the interrupt sub routine
        if(!IRQ0 & !rst & IRQ0reset & !ResetT)begin 
            //Drop all saved values back to the register system
            memCNTR <= MemmorysationVector[0];
            DataOutput <= MemmorysationVector[1];
            REG[0] <= MemmorysationVector[2];
            REG[1] <= MemmorysationVector[3];
            REG[2] <= MemmorysationVector[4];
            REG[3] <= MemmorysationVector[5];
            REG[4] <= MemmorysationVector[6];
            regKeep <= MemmorysationVector[7];
            regKeep2 <= MemmorysationVector[8];
            opKeep <= MemmorysationVector[9];
            inst <= MemmorysationVector[10];
            memJMP <= MemmorysationVector[11];
            addressKeep <= MemmorysationVector[12];
            T <= MemmorysationVector[13];
            r_w <= MemmorysationVector[14];
            write <= MemmorysationVector[15];
            ResetT <= MemmorysationVector[16];
            
            //reset flags an resets        
            IRQ0reset <= 0;
            IRQ0flag <= 0;
        end
        
        if(!rst & ResetT)begin
            T <= 'h0;
            ResetT <= 0;
        end
        
        if(rst) begin   //if reset line is high reset all values in processor to 0
            hltreg <= 'h0;
            for(i = 0; i <= 3; i = i + 1)begin
                REG[i] <= 0;
            end
            inst <= 'h0;
            memCNTR <= 'h0;
            memJMP <= 'h0;
            addressKeep <= 'h0;
            regKeep <= 'h00;
            opKeep <= 'h00;
            stackPointer <= 'h0;
            ResetT <= 'h0;
        end
       


    end
    
    
endmodule
