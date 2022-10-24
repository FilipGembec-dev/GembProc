
module processor#(memmoryFile = "BOOT_ROM.mem")(
    input CLK100MHZ, rst, [7:0] IN00, output [7:0] OUT00
    );
    
    
    reg hltreg = 0; //halt register
    wire sys_clock; //system clock register
    assign sys_clock = CLK100MHZ &! hltreg; //anding the input clock and the inverse of the halt register
    
    //defining workign memmory
    reg [7:0] M [(((2**15) - 1) - 255):0]; //8 bit data buss with 16 bit address buss

  
    //workign registers organised in a vector
    reg [7:0] REG[3:0];
    //register for keeping the value of the indexed register
    reg [7:0] regKeep = 'h00;
    //register for keeping the operation index
    reg [7:0] opKeep = 'h00;
    
    //assigning results of mathematical operations using working registers as input arguments
    wire [7:0] SUM[7:0];
    assign SUM[0] = REG[0] + REG[1];
    assign SUM[1] = REG[0] - REG[1];
    assign SUM[2] = REG[0] * REG[1];
    assign SUM[3] = REG[0] / REG[1];
    assign SUM[4] = REG[0] & REG[1];
    assign SUM[5] = REG[0] | REG[1];
    assign SUM[6] = REG[0] ^ REG[1];
    genvar j;
    generate
     for(j = 0; j <= 7; j = j + 1)begin
        assign SUM[7][j] = !REG[0][j];
     end
    endgenerate
    
    //8 bit registers in vector array for storing the output data
    reg [7:0] OUT [2:0];
    assign OUT00 = OUT[0];
    //8 bit wires in vector array for organising values from input ports
    wire [7:0] IN [2:0];
    assign IN[0] = IN00;
        
    //intruction register
    reg [7:0] inst = 'h00;
    
    //memmory counter
    reg [15:0] memCNTR = 'h0000;
    //16 bit register for storing the memmory to jump to
    reg [15:0] memJMP = 'h0000;
    //16 bit register for keeping the value of memCNTR
    reg [15:0] addressKeep = 'h0000;

    //implementing a 255 byte stack
    reg [7:0] STACK [255:0];
    reg [7:0] stackPointer = 'h00;
    
    integer i = 0;    

    //state machine for adding function and time domain to processor elements
    reg [3:0] T = 'h00; //register for keeping the time domain of state machine
    always@(posedge (sys_clock ^ rst))begin
        if(!rst) begin  //if reset line is low execute processor operations
            T <= T + 1;
            case(T) //instruction fetch
                'h00: begin inst <= M[memCNTR]; memCNTR <= memCNTR + 1; end
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
                        'h01: begin memCNTR <= memCNTR + 1; regKeep <= M[memCNTR]; end
                        'h02: begin memJMP[7:0] <= M[memCNTR]; memCNTR <= memCNTR + 1; end
                        'h03: begin memJMP[15:8] <= M[memCNTR]; memCNTR <= memCNTR + 1; end
                        'h04: begin addressKeep <= memCNTR; memCNTR <= memJMP; end
                        'h05: begin REG[regKeep] <= M[memCNTR]; memCNTR <= addressKeep; memJMP <= 'h0000; end
                    endcase
                end
                'h03: begin//STR <start register> <address0> <address1>
                    case(T)
                        'h01: begin memCNTR <= memCNTR + 1; regKeep <= M[memCNTR]; end
                        'h02: begin memJMP[7:0] <= M[memCNTR]; memCNTR <= memCNTR + 1; end
                        'h03: begin memJMP[15:8] <= M[memCNTR]; memCNTR <= memCNTR + 1; end
                        'h04: begin addressKeep <= memCNTR; memCNTR <= memJMP; end
                        'h05: begin M[memCNTR] <= REG[regKeep]; memCNTR <= addressKeep; memJMP <= 'h0000; end
                    endcase
                end
                'h04: begin//OUT <start register> <destination output port>
                    case(T)
                        'h01: begin regKeep <= M[memCNTR]; memCNTR <= memCNTR + 1; end
                        'h02: begin OUT[M[memCNTR]] <= REG[regKeep]; memCNTR <= memCNTR + 1; end
                    endcase
                end
                'h05: begin//IN <destination register> <start input port>
                    case(T)
                        'h01: begin regKeep <= M[memCNTR]; memCNTR <= memCNTR + 1; end
                        'h02: begin  REG[regKeep] <= IN[M[memCNTR]]; memCNTR <= memCNTR + 1; end
                    endcase
                end
                'h06: begin//ALU <operation> <result destination register>
                    case(T)
                        'h01: begin regKeep <= M[memCNTR]; memCNTR <= memCNTR + 1; end
                        'h02: begin REG[M[memCNTR]] <= SUM[regKeep]; memCNTR <= memCNTR + 1; end
                    endcase
                end
                'h07: begin //JMP <address0> <address1>
                    case(T)
                        'h01: begin memJMP[7:0] <= M[memCNTR]; memCNTR <= memCNTR + 1; end
                        'h02: begin memJMP[15:8] <= M[memCNTR]; end
                        'h03: begin memCNTR <= memJMP; memJMP <= 'h0000; end
                    endcase
                end
                'h08: begin //JPC <argument operation> <address0> <address1>
                    case(T)
                        'h01: begin opKeep <= M[memCNTR]; memCNTR <= memCNTR + 1; end
                        'h02: begin memJMP[7:0] <= M[memCNTR]; memCNTR <= memCNTR + 1; end
                        'h03: begin memJMP[15:8] <= M[memCNTR]; memCNTR <= memCNTR + 1; end
                        'h04: begin
                            case(opKeep)
                                'h00:begin if(REG[0] == REG[1]) memCNTR <= memJMP; end
                                'h01:begin if(REG[0] > REG[1]) memCNTR <= memJMP; end
                                'h02:begin if(REG[0] < REG[1]) memCNTR <= memJMP; end
                            endcase
                        end
                     endcase
                end
                'h09: begin//PUSH <start register>
                    case(T)
                        'h01: regKeep <= M[memCNTR];
                        'h02: STACK[stackPointer] <= REG[regKeep];
                        'h03: begin stackPointer <= stackPointer + 1; memCNTR <= memCNTR + 1; end
                    endcase
                end        
                'h0a: begin//POP <destination register>
                    case(T)
                        'h01: begin regKeep <= M[memCNTR]; stackPointer <= stackPointer - 1; end
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
        end
       


    end
    
    
endmodule
