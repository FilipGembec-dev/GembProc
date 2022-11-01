#include <iostream>
#include <fstream>
#include <stdlib.h>
#include <string>
#include <algorithm>
#include "dataset.h"
#include <map>




using namespace std;

string dec_to_hex(int initial_decimal) {
    int decimal = initial_decimal;  
    int remainder, product = 1;
    string hex_dec = "";
    while (decimal != 0) {
        remainder = decimal % 16;
        char ch;
        if (remainder >= 10)
        ch = remainder + 55;
        else
        ch = remainder + 48;
        hex_dec += ch;
    
        decimal = decimal / 16;
        product *= 10;
    }
    reverse(hex_dec.begin(), hex_dec.end());

        if(initial_decimal == 0){
            hex_dec = "0";
        }
 
    return hex_dec;
}


string format_memloc(int val){
    string argument;
                argument = dec_to_hex(val);
                switch(argument.size()){
                    case 4: break;
                    case 3: argument = "0" + argument; break;
                    case 2: argument = "00" + argument; break;
                    case 1: argument = "000" + argument; break;
                    default: cout << "Invalid value" << endl; return 0; break;
                } 
    return argument;
}

map<string, string> macro; //defining a key value pair for storing defined values
//key value filter for checking for macros
string KVP_filter(string key){
    string input_key = key;
    key = macro[key];
    if(key.size() == 0){
        key = input_key;
    }
    return key;
}
map<string, string> label; //defining a key value pair for storing label values
//key value pair for checkign for labels
string label_filter(string key){
    string input_key = key;
    key = label[key];
    if(key.size() == 0){
        key = input_key;
    }
    return key;
}

int main(int argc, char *argv[]){

    if(argc > 2){
        cout << "Too many arguments" << endl;
        return 0;
    }




    //reading instructions
    fstream mem_file;
    mem_file.open("mem.mem", ios::out); // creating the memory file
    fstream code_file; 
    code_file.open(argv[1],ios::in);   
    if(!code_file) {
        cout<<"No such file: " << argv[1] << endl;
        goto exit; 
    } 
    else { 
        
        for(int j = 0; j <= 1; j++){
            if(j == 1){
                code_file.open(argv[1],ios::in);
            } 
            unsigned int memmory_index = 0;
            while (!code_file.eof()) {
                string ch;
                code_file >> ch;

                if(ch == "#"){
                    if(j == 0){
                        string key;
                        code_file >> key;
                        string value;
                        value = to_string(memmory_index);
                        label.insert(make_pair(key, value));   
                        cout << "Label " << key << " = "<< value << endl;  
                    }               
                        continue;
                }     
                else if(ch == "#define"){
                    if(j == 0){
                        string key;
                        code_file >> key;
                        string value;
                        code_file >> value;
                        macro.insert(make_pair(key, value));
                        cout << key << " = " << value << endl; 
                    }else{
                        string key;
                        code_file >> key; 
                    }
                    continue;
                }
                else if(ch == "@"){
                    string argument;
                    code_file >> argument;
                    //where
                    argument = label_filter(argument);
                    argument = dec_to_hex(stoi(argument));
                    switch(argument.size()){
                        case 4: break;
                        case 3: argument = "0" + argument; break;
                        case 2: argument = "00" + argument; break;
                        case 1: argument = "000" + argument; break;
                        default: cout << "Invalid value" << endl; goto exit; break;
                    }
                    if(j == 1) 
                        mem_file << "@" <<  argument; 
                    //awhat
                    code_file >> argument;
                    argument = dec_to_hex(stoi(argument));
                    switch(argument.size()){
                        case 2: break;
                        case 1: argument = "0" + argument; break;
                        default: cout << "Invalid value" << endl; goto exit; break;
                    }               
                    if(j == 1)  
                        mem_file << " " << argument << endl;
                    continue;
                }
                else if(ch == "NOP"){
                    if(j == 1) 
                        mem_file << "@" << format_memloc(memmory_index) << " " << NOP << endl; 
                    memmory_index++;  
                    continue;  
                }
                else if(ch == "HLT"){
                    if(j == 1) 
                        mem_file << "@" << format_memloc(memmory_index) << " " << HLT << endl; 
                    memmory_index++;
                    continue;
                }
                else if(ch == "LDR"){
                    if(j == 1){
                        mem_file << "@" << format_memloc(memmory_index) << " " << LDR << endl; 
                        memmory_index++;
                        string argument;
                        //argument
                        code_file >> argument;
                            argument = KVP_filter(argument);
                            if(j == 1) argument = dec_to_hex(stoi(argument));
                            switch(argument.size()){
                                case 2: break;
                                case 1: argument = "0" + argument; break;
                                default: cout << "Invalid value" << endl; goto exit; break;
                            
                            }               
                        mem_file << "@" << format_memloc(memmory_index) << " " << argument[0] << argument[1] << endl; 
                        memmory_index++;
                        
                    
                        //address
                        code_file >> argument;

                            argument = label_filter(argument);
                            argument = KVP_filter(argument);
                            cout << argument << endl;
                            argument = dec_to_hex(stoi(argument));
                            
                            switch(argument.size()){
                                case 4: break;
                                case 3: argument = "0" + argument; break;
                                case 2: argument = "00" + argument; break;
                                case 1: argument = "000" + argument; break;
                                default: cout << "Invalid value" << endl; goto exit; break;
                            }
                                mem_file << "@" << format_memloc(memmory_index) << " " << argument[2] << argument[3] << endl; 
                            memmory_index++;  
                                mem_file << "@" << format_memloc(memmory_index) << " " << argument[0] << argument[1] << endl; 
                            memmory_index++;
                            continue;
                    }else{
                        string argument;
                        code_file >> argument;
                        code_file >> argument;
                        memmory_index = memmory_index + 4;
                        cout << "Exiting LDR " << j << endl;
                        continue;
                    }

                }
                else if(ch == "STR"){
                    if(j == 1){
                            mem_file << "@" << format_memloc(memmory_index) << " " << STR << endl; 
                        memmory_index++;
                        string argument;
                        //argument
                        code_file >> argument;
                            argument = KVP_filter(argument);
                            if(j == 1) argument = dec_to_hex(stoi(argument));
                            switch(argument.size()){
                                case 2: break;
                                case 1: argument = "0" + argument; break;
                                default: cout << "Invalid value" << endl; goto exit; break;
                            
                        }               
                            mem_file << "@" << format_memloc(memmory_index) << " " << argument[0] << argument[1] << endl; 
                        memmory_index++;
                        
                    
                        //address
                        code_file >> argument;

                            argument = label_filter(argument);
                            argument = KVP_filter(argument);
                            cout << argument << endl;
                            argument = dec_to_hex(stoi(argument));
                            
                            switch(argument.size()){
                                case 4: break;
                                case 3: argument = "0" + argument; break;
                                case 2: argument = "00" + argument; break;
                                case 1: argument = "000" + argument; break;
                                default: cout << "Invalid value" << endl; goto exit; break;
                            }
                                mem_file << "@" << format_memloc(memmory_index) << " " << argument[2] << argument[3] << endl; 
                            memmory_index++;  
                                mem_file << "@" << format_memloc(memmory_index) << " " << argument[0] << argument[1] << endl; 
                            memmory_index++;
                            
                    }else{
                        string argument;
                        code_file >> argument;
                        code_file >> argument;
                        memmory_index = memmory_index + 4;
                        continue;
                    }
                }        
                else if(ch == "OUT"){
                    if(j == 1){ 
                        mem_file << "@" << format_memloc(memmory_index) << " " << OUT << endl; 
                        memmory_index++;
                        string argument;
                        //argument0
                        for(int i = 0; i < 2; i++){
                            code_file >> argument;
                            argument = KVP_filter(argument);
                            argument = dec_to_hex(stoi(argument));
                            switch(argument.size()){
                                case 2: break;
                                case 1: argument = "0" + argument; break;
                                default: cout << "Invalid value" << endl; goto exit; break;
                            }               
                            if(j == 1) 
                                mem_file << "@" << format_memloc(memmory_index) << " " << argument[0] << argument[1] << endl; 
                            memmory_index++;
                            
                        }
                        continue;
                    } else{
                        string argument;
                        memmory_index = memmory_index + 3;
                        code_file >> argument;
                        code_file >> argument;
                    }
                }
                else if(ch == "INN"){
                    if(j == 1){ 
                        mem_file << "@" << format_memloc(memmory_index) << " " << INN << endl; 
                        memmory_index++;
                        string argument;
                        //argument0
                        for(int i = 0; i < 2; i++){
                            code_file >> argument;
                            argument = KVP_filter(argument);
                            argument = dec_to_hex(stoi(argument));
                            switch(argument.size()){
                                case 2: break;
                                case 1: argument = "0" + argument; break;
                                default: cout << "Invalid value" << endl; goto exit; break;
                            }               
                            if(j == 1) 
                                mem_file << "@" << format_memloc(memmory_index) << " " << argument[0] << argument[1] << endl; 
                            memmory_index++;
                            
                        }
                        continue;
                    } else{
                        string argument;
                        memmory_index = memmory_index + 3;
                        code_file >> argument;
                        code_file >> argument;
                    }
                }        
                else if(ch == "ALU"){
                    if(j == 1){ 
                        mem_file << "@" << format_memloc(memmory_index) << " " << ALU << endl; 
                        memmory_index++;
                        string argument;
                        //argument0
                        for(int i = 0; i < 2; i++){
                            code_file >> argument;
                            argument = KVP_filter(argument);
                            argument = dec_to_hex(stoi(argument));
                            switch(argument.size()){
                                case 2: break;
                                case 1: argument = "0" + argument; break;
                                default: cout << "Invalid value" << endl; goto exit; break;
                            }               
                            if(j == 1) 
                                mem_file << "@" << format_memloc(memmory_index) << " " << argument[0] << argument[1] << endl; 
                            memmory_index++;
                            
                        }
                        continue;
                    } else{
                        string argument;
                        memmory_index = memmory_index + 3;
                        code_file >> argument;
                        code_file >> argument;
                    }
                }
                else if(ch == "JMP"){
                    if(j == 1) {
                        mem_file << "@" << format_memloc(memmory_index) << " " << JMP << endl; 
                        memmory_index++;
                        string argument;
                        
                        //address
                        code_file >> argument;
                        argument = label_filter(argument);
                        argument = KVP_filter(argument);
                        argument = dec_to_hex(stoi(argument));
                        switch(argument.size()){
                            case 4: break;
                            case 3: argument = "0" + argument; break;
                            case 2: argument = "00" + argument; break;
                            case 1: argument = "000" + argument; break;
                            default: cout << "Invalid value" << endl; goto exit; break;
                        }
                        if(j == 1) 
                            mem_file << "@" << format_memloc(memmory_index) << " " << argument[2] << argument[3] << endl; 
                        memmory_index++;  
                        if(j == 1) 
                            mem_file << "@" << format_memloc(memmory_index) << " " << argument[0] << argument[1] << endl; 
                        memmory_index++;    
                        continue;
                    }else{
                        string argument;
                        memmory_index = memmory_index + 3;
                        code_file >> argument;
                    }         
                }       
                else if(ch == "JPC"){
                    if(j == 1){
                        mem_file << "@" << format_memloc(memmory_index) << " " << JPC << endl; 
                        memmory_index++;
                        string argument;
                        //argument
                        code_file >> argument;
                            argument = KVP_filter(argument);
                            if(j == 1) argument = dec_to_hex(stoi(argument));
                            switch(argument.size()){
                                case 2: break;
                                case 1: argument = "0" + argument; break;
                                default: cout << "Invalid value" << endl; goto exit; break;
                            
                            }               
                        mem_file << "@" << format_memloc(memmory_index) << " " << argument[0] << argument[1] << endl; 
                        memmory_index++;
                        
                    
                        //address
                        code_file >> argument;

                            argument = label_filter(argument);
                            argument = KVP_filter(argument);
                            cout << argument << endl;
                            argument = dec_to_hex(stoi(argument));
                            
                            switch(argument.size()){
                                case 4: break;
                                case 3: argument = "0" + argument; break;
                                case 2: argument = "00" + argument; break;
                                case 1: argument = "000" + argument; break;
                                default: cout << "Invalid value" << endl; goto exit; break;
                            }
                                mem_file << "@" << format_memloc(memmory_index) << " " << argument[2] << argument[3] << endl; 
                            memmory_index++;  
                                mem_file << "@" << format_memloc(memmory_index) << " " << argument[0] << argument[1] << endl; 
                            memmory_index++;
                            cout << "Exiting JPC " << j << endl;
                            continue;
                    }else{
                        string argument;
                        code_file >> argument;
                        code_file >> argument;
                        memmory_index = memmory_index + 4;
                        continue;
                    }    
                }
                else if(ch == "PUSH"){
                    if(j == 1){ 
                        mem_file << "@" << format_memloc(memmory_index) << " " << PSH << endl; 
                        memmory_index++;
                        string argument;
                        //argument
                        code_file >> argument;
                        argument = KVP_filter(argument);
                        argument = dec_to_hex(stoi(argument));
                        switch(argument.size()){
                            case 2: break;
                            case 1: argument = "0" + argument; break;
                            default: cout << "Invalid value" << endl; goto exit; break;
                        }               
                        if(j == 1) 
                            mem_file << "@" << format_memloc(memmory_index) << " " << argument[0] << argument[1] << endl; 
                        memmory_index++;    
                        continue;    
                    }else{
                        memmory_index = memmory_index + 2;
                        string argument;
                        code_file >> argument;
                    }

                }
                else if(ch == "POP"){
                    if(j == 1){ 
                        mem_file << "@" << format_memloc(memmory_index) << " " << POP << endl; 
                        memmory_index++;
                        string argument;
                        //argument
                        code_file >> argument;
                        argument = KVP_filter(argument);
                        argument = dec_to_hex(stoi(argument));
                        switch(argument.size()){
                            case 2: break;
                            case 1: argument = "0" + argument; break;
                            default: cout << "Invalid value" << endl; goto exit; break;
                        }               
                        if(j == 1) 
                            mem_file << "@" << format_memloc(memmory_index) << " " << argument[0] << argument[1] << endl; 
                        memmory_index++;    
                        continue;    
                    }else{
                        memmory_index = memmory_index + 2;
                        string argument;
                        code_file >> argument;
                    }

                 
            }

        }
        code_file.close();
    }

        exit:
        code_file.close(); 
        mem_file.close();
        return 0;
    }  
} 
