`timescale 1ns / 1ps

module top (input [7:0] IN00, [7:0] IN01, output [7:0] OUT00, [7:0] OUT01);
    PULLUP PULLUP_inst(rst);
    
    reg CLK100MHZ = 0;
    
    wire [15:0] ExternalIndex;
    wire [7:0]ExternalData;
    
    reg [7:0] ROM [16383:0];
    initial  //pasting the values from a premade memmory file to the working memmory
        $readmemh("BOOT_ROM.mem", ROM, 0, 16383);
        
    assign ExternalData = ROM[ExternalIndex];    

            
    processor CPU(CLK100MHZ, rst, IN00, OUT00, OUT01, ExternalIndex, ExternalData);



endmodule


module processor(
    input CLK100MHZ, rst, [7:0] IN00, output [7:0] OUT00, [7:0] OUT01, output [15:0] ExternalIndex, input [7:0] ExternalData
    );
    
    
    reg hltreg = 0; //halt register
    wire sys_clock; //system clock register
    assign sys_clock = CLK100MHZ &! hltreg; //anding the input clock and the inverse of the halt register
    
    //defining the memory index net
    reg [15:0] memCNTR = 'h0000;
    
    //defining random access memory
    reg [7:0] RAM [32767:16384];

    //memmory interface
    wire [7:0] M_;
    
    assign ExternalIndex = memCNTR;
    
    //multiplexing memmory interface
    assign M_ = memCNTR < 'd16384 ? ExternalData : RAM[memCNTR];
  
  
      
    //workign registers organised in a vector
    reg [7:0] REG[4:0];
    //status flag
    reg [7:0] REG[4] = 'h0; // - REG[4][0] = carry 
                            // - REG[4][1] = negativeSign
    //register for keeping the value of the indexed register
    reg [7:0] regKeep = 'h00;
    reg [7:0] regKeep2 = 'h00;
    wire signed [8:0] negativeResultCheck; 
    assign negativeResultCheck = (REG[0] - regKeep2) >= 9'h0;
    //register for keeping the operation index
    reg [7:0] opKeep = 'h00;
    
    
    //8 bit registers in vector array for storing the output data
    reg [7:0] OUT [2:0];
    assign OUT00 = OUT[0];
    assign OUT01 = OUT[1];
    //8 bit wires in vector array for organising values from input ports
    wire [7:0] IN [2:0];
    assign IN[0] = IN00;
        
    //intruction register
    reg [7:0] inst = 'h00;
    

    //16 bit register for storing the memmory to jump to
    reg [15:0] memJMP = 'h0000;
    //16 bit register for keeping the value of memCNTR
    reg [15:0] addressKeep = 'h0000;

    //implementing a 255 byte stack
    reg [7:0] STACK [255:0];
    reg [7:0] stackPointer = 'h00;
    
    //implementing a 32 bit timer
    reg [31:0]Timer1 = 'h00000000;
    
    
    
    
    integer i = 0;    
    
    //state machine for adding function and time domain to processor elements
    reg [3:0] T = 'h00; //register for keeping the time domain of state machine
    always@(posedge (sys_clock ^ rst))begin
        if(!rst) begin  //if reset line is low execute processor operations
            Timer1 = Timer1 + 1;
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
                        'h03: begin memJMP[15:8] <= M_; memCNTR <= memCNTR + 1; end
                        'h04: begin addressKeep <= memCNTR; memCNTR <= memJMP; end
                        'h05: begin REG[regKeep] <= M_; memCNTR <= addressKeep; memJMP <= 'h0000; end
                    endcase
                end
                'h03: begin//STR <start register> <address0> <address1>
                    case(T)
                        'h01: begin memCNTR <= memCNTR + 1; regKeep <= M_; end
                        'h02: begin memJMP[7:0] <= M_; memCNTR <= memCNTR + 1; end
                        'h03: begin memJMP[15:8] <= M_; memCNTR <= memCNTR + 1; end
                        'h04: begin addressKeep <= memCNTR; memCNTR <= memJMP; end
                        'h05: begin RAM[memCNTR] <= REG[regKeep]; memCNTR <= addressKeep; memJMP <= 'h0000; end
                    endcase
                end
                'h04: begin//OUT <start register> <destination output port>
                    case(T)
                        'h01: begin regKeep <= M_; memCNTR <= memCNTR + 1; end
                        'h02: begin OUT[M_] <= REG[M_]; memCNTR <= memCNTR + 1; end
                    endcase
                end
                'h05: begin//IN <destination register> <start input port>
                    case(T)
                        'h01: begin regKeep <= M_; memCNTR <= memCNTR + 1; end
                        'h02: begin  REG[regKeep] <= IN[M_]; memCNTR <= memCNTR + 1; end
                    endcase
                end
                'h06: begin//ALU <operation> <second operator>
                    case(T)
                        'h01: begin regKeep <= M_; memCNTR <= memCNTR + 1; end
                        'h02: begin regKeep2 <= M_; memCNTR <= memCNTR + 1; end
                        'h03: begin 
                              case(regKeep)  
                                    //Register to register logical operations
                                    'h00: REG[0] <= REG[0] & REG[M_];
                                    'h01: REG[0] <= REG[0] | REG[M_];
                                    'h02: REG[0] <= REG[0] ^ REG[M_];
                                    'h03: for(i = 0; i <= 7; i = i + 1) REG[0][i] <= ~REG[0][i];
                                    //Register to register arithmetical operations
                                    'h04: {REG[4][0], REG[0]} <= REG[0] + REG[regKeep2] + REG[4][0];
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
                        'h01: begin memJMP[7:0] <= M_; memCNTR <= memCNTR + 1; end
                        'h02: begin memJMP[15:8] <= M_; end
                        'h03: begin memCNTR <= memJMP; end
                    endcase
                end
                'h08: begin //JPC <argument operation> <address0> <address1>
                    case(T)
                        'h01: begin opKeep <= M_; memCNTR <= memCNTR + 1; end
                        'h02: begin memJMP[7:0] <= M_; memCNTR <= memCNTR + 1; end
                        'h03: begin memJMP[15:8] <= M_; memCNTR <= memCNTR + 1; end
                        'h04: begin
                            case(opKeep)
                                'h00: begin if(REG[0] == REG[1]) memCNTR <= memJMP; end //Checking for equality
                                'h01: begin if(REG[0] > REG[1]) memCNTR <= memJMP; end //Checking if greater then
                                'h02: begin if(REG[0] < REG[1]) memCNTR <= memJMP; end //checking if les than
                                'h03: begin if(REG[4][0] == 1) memCNTR <= memJMP; end // cheking for carry
                                'h04: begin if(REG[4][1] == 1) memCNTR <= memJMP; end // checkign for negative sign
                                'h05: begin if(REG[0] == 8'h00) memCNTR <= memJMP; end // checking if zero
                                'h06: begin if({REG[3], REG[2], REG[1], REG[0]} == Timer1) memCNTR <= memJMP; end // testing internal timer
                            endcase
                        end
                   endcase
                end
                'h09: begin//PUSH <start register>
                    case(T)
                        'h01: regKeep <= M_;
                        'h02: STACK[stackPointer] <= REG[regKeep];
                        'h03: begin stackPointer <= stackPointer + 1; memCNTR <= memCNTR + 1; end
                    endcase
                end        
                'h0a: begin//POP <destination register>
                    case(T)
                        'h01: begin regKeep <= M_; stackPointer <= stackPointer - 1; end
                        'h02: REG[regKeep] <= STACK[stackPointer];
                        'h03: begin  memCNTR <= memCNTR + 1; end
                    endcase
                end
                
           endcase
        end
        
        if(rst) begin   //if reset line is high reset all values in processor to 0
            hltreg <= 'h0;
            for(i = 0; i <= 3; i = i + 1)begin
                REG[i] <= 0;
            end
            for(i = 0; i <= 0; i = i + 1)begin
                OUT[i] <= 0;
            end
            inst <= 'h0;
            memCNTR <= 'h0;
            memJMP <= 'h0;
            addressKeep <= 'h0;
            regKeep <= 'h00;
            opKeep <= 'h00;
            stackPointer <= 'h0;
            Timer1 = 'h00000000;
        end
       


    end
    
    
endmodule
