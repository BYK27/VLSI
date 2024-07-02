// `include "src/synthesis/modules/register.v"
// `include "src/synthesis/modules/alu.v"


module cpu #(parameter ADDR_WIDTH = 6,
             parameter DATA_WIDTH = 16)
            (input clk,
             input rst_n,
             input[DATA_WIDTH - 1: 0] mem_in,
             input[DATA_WIDTH - 1: 0] in,
             output mem_we,
             output[ADDR_WIDTH-1:0] mem_addr,
             output[DATA_WIDTH-1:0] mem_data,
             output[DATA_WIDTH-1:0] out,
             output[ADDR_WIDTH-1:0] pc,
             output[ADDR_WIDTH-1:0] sp);
    
    //registers
    reg[ADDR_WIDTH-1 : 0] pc_reg;
    reg[ADDR_WIDTH-1 : 0] sp_reg;
    reg[DATA_WIDTH-1 : 0] mem_data_reg;
    reg[ADDR_WIDTH-1 : 0] mem_addr_reg;
    reg mem_we_reg;
    reg[DATA_WIDTH-1 : 0] source_reg;
    reg[DATA_WIDTH-1 : 0] destination_reg;
    reg[DATA_WIDTH-1 : 0] out_reg;
    
    
    //wires
    wire[ADDR_WIDTH-1 : 0] pc_wire;
    wire[ADDR_WIDTH-1 : 0] sp_wire;
    wire[DATA_WIDTH-1 : 0] ins_low_wire, ins_high_wire;
    wire[DATA_WIDTH-1 : 0] acc_wire;
    
    
    //operands
    reg[2:0] operand_1;
    reg[2:0] operand_2;
    reg[2:0] operand_3;
    reg[15:0] operand_4;
    reg[3:0] operation_instruction;
    
    reg operand_1_addressing;
    reg operand_2_addressing;
    reg operand_3_addressing;
    
    wire [3:0] operand_1_full;
    wire [3:0] operand_2_full;
    wire [3:0] operand_3_full;
    assign operand_1_full = {operand_1_addressing, operand_1};
    assign operand_2_full = {operand_2_addressing, operand_2};
    assign operand_3_full = {operand_3_addressing, operand_3};
    
    
    //alu
    reg[2:0] alu_oc;
    wire[DATA_WIDTH-1 : 0] alu_output;
    reg[DATA_WIDTH-1 : 0] alu_operand_1;
    reg[DATA_WIDTH-1 : 0] alu_operand_2;
    
    
    //triggers for registers
    //pc (0), sp (1), ir_low (2), ir_high (3), acc (4)
    reg[4:0] cl_trigger;
    reg[4:0] ld_trigger;
    reg[4:0] inc_trigger;
    reg[4:0] dec_trigger;
    reg[4:0] sr_trigger;
    reg[4:0] ir_trigger;
    reg[4:0] sl_trigger;
    reg[4:0] il_trigger;
    
    
    //assigns
    assign pc       = pc_wire;
    assign sp       = sp_wire;
    assign mem_addr = mem_addr_reg;
    assign mem_data = mem_data_reg;
    assign mem_we   = mem_we_reg;
    assign out      = out_reg;
    
    //instruction localparams
    localparam MOV      = 4'b0000;
    localparam IN       = 4'b0111;
    localparam OUT      = 4'b1000;
    localparam DIRECT   = 1'b0;
    localparam INDIRECT = 1'b1;
    localparam ADD      = 4'b0001;
    localparam SUB      = 4'b0010;
    localparam MUL      = 4'b0011;
    localparam DIV      = 4'b0100;
    localparam STOP     = 4'b1111;
    
    
    //modules
    register #(ADDR_WIDTH) register_pc(
    .clk(clk),
    .rst_n(rst_n),
    .cl(cl_trigger[0]),
    .ld(ld_trigger[0]),
    .in(pc_reg),              //default value
    .inc(inc_trigger[0]),
    .dec(dec_trigger[0]),
    .sr(sr_trigger[0]),
    .ir(ir_trigger[0]),
    .sl(sl_trigger[0]),
    .il(il_trigger[0]),
    .out(pc_wire)
    );
    
    register #(ADDR_WIDTH) register_sp(
    .clk(clk),
    .rst_n(rst_n),
    .cl(cl_trigger[1]),
    .ld(ld_trigger[1]),
    .in(sp_reg),              //default value
    .inc(inc_trigger[1]),
    .dec(dec_trigger[1]),
    .sr(sr_trigger[1]),
    .ir(ir_trigger[1]),
    .sl(sl_trigger[1]),
    .il(il_trigger[1]),
    .out(sp_wire)
    );
    
    register #(DATA_WIDTH) register_ir_low(
    .clk(clk),
    .rst_n(rst_n),
    .cl(cl_trigger[2]),
    .ld(ld_trigger[2]),
    .in(mem_in),              //default value
    .inc(inc_trigger[2]),
    .dec(dec_trigger[2]),
    .sr(sr_trigger[2]),
    .ir(ir_trigger[2]),
    .sl(sl_trigger[2]),
    .il(il_trigger[2]),
    .out(ins_low_wire)
    );
    
    register #(DATA_WIDTH) register_ir_high(
    .clk(clk),
    .rst_n(rst_n),
    .cl(cl_trigger[3]),
    .ld(ld_trigger[3]),
    .in(mem_in),              //default value
    .inc(inc_trigger[3]),
    .dec(dec_trigger[3]),
    .sr(sr_trigger[3]),
    .ir(ir_trigger[3]),
    .sl(sl_trigger[3]),
    .il(il_trigger[3]),
    .out(ins_high_wire)
    );
    
    register #(DATA_WIDTH) register_acc(
    .clk(clk),
    .rst_n(rst_n),
    .cl(cl_trigger[4]),
    .ld(ld_trigger[4]),
    .in(alu_output),
    .inc(inc_trigger[4]),
    .dec(dec_trigger[4]),
    .sr(sr_trigger[4]),
    .ir(ir_trigger[4]),
    .sl(sl_trigger[4]),
    .il(il_trigger[4]),
    .out(acc_wire)
    );
    
    alu #(DATA_WIDTH) alu_main(
    .oc(alu_oc),
    .a(alu_operand_1),
    .b(alu_operand_2),
    .f(alu_output)
    );
    
    //states:start, fetch, decode, execute
    localparam start        = 3'b000;
    localparam fetch        = 3'b001;
    localparam decode       = 3'b010;
    localparam execute      = 3'b011;
    localparam fetch_second = 3'b100;
    localparam stop         = 3'b101;
    reg[2:0] state_reg, state_next;
    
    //INSTRUCION localparams
    
    //ALU localparams
    reg[2:0] alu_phase;
    localparam alu_phase_place_direct       = 3'b000;
    localparam alu_phase_place_indirect     = 3'b111;
    localparam alu_phase_operand_3_direct   = 3'b001;
    localparam alu_phase_operand_3_indirect = 3'b010;
    localparam alu_phase_operand_2_direct   = 3'b011;
    localparam alu_phase_operand_2_indirect = 3'b100;
    localparam alu_phase_execute            = 3'b101;
    localparam alu_phase_end                = 3'b110;
    
    
    //MOV localparams
    reg[3:0] mov_phase;
    localparam mov_phase_operand_2_direct                       = 4'b0000;
    localparam mov_phase_operand_2_indirect                     = 4'b0001;
    localparam mov_phase_operand_1_direct                       = 4'b0010;
    localparam mov_phase_operand_1_indirect                     = 4'b0011;
    localparam mov_phase_execute                                = 4'b0100;
    localparam mov_phase_end                                    = 4'b0101;
    localparam mov_phase_operand_1_direct_two_word_addressing   = 4'b0110;
    localparam mov_phase_operand_1_indirect_two_word_addressing = 4'b0111;
    localparam mov_phase_execute_two_word_addressing_execute    = 4'b1000;
    
    
    //IN localparams
    reg[2:0] in_phase;
    localparam in_phase_operand_1_direct         = 3'b000;
    localparam in_phase_operand_1_direct_write   = 3'b001;
    localparam in_phase_operand_1_indirect       = 3'b010;
    localparam in_phase_operand_1_indirect_write = 3'b011;
    localparam in_phase_execute                  = 3'b100;
    localparam in_phase_end                      = 3'b101;
    
    //OUT localparams
    reg[2:0] out_phase;
    localparam out_phase_operand_1_direct         = 3'b000;
    localparam out_phase_operand_1_direct_write   = 3'b001;
    localparam out_phase_operand_1_indirect       = 3'b010;
    localparam out_phase_operand_1_indirect_write = 3'b011;
    localparam out_phase_execute                  = 3'b100;
    localparam out_phase_end                      = 3'b101;
    
    
    //sequential logic
    reg[3:0] mov_phase_seq;
    reg[2:0] alu_phase_seq;
    reg[2:0] in_phase_seq;
    reg[2:0] out_phase_seq;
    reg[DATA_WIDTH-1 : 0] source_reg_seq;
    reg[DATA_WIDTH-1 : 0] destination_reg_seq;
    reg[DATA_WIDTH-1 : 0] out_reg_seq;
    reg[2:0] operand_1_seq;
    reg[2:0] operand_2_seq;
    reg[2:0] operand_3_seq;
    reg[15:0] operand_4_seq;
    reg[3:0] operation_instruction_seq;
    reg operand_1_addressing_seq;
    reg operand_2_addressing_seq;
    reg operand_3_addressing_seq;
    
    
    always @(posedge clk, negedge rst_n) begin
        //reset all triggers
        //set clear trigger
        if (!rst_n) begin
            state_reg                 <= start;
            mov_phase_seq             <= mov_phase_operand_2_direct;
            alu_phase_seq             <= alu_phase_place_direct;
            in_phase_seq              <= in_phase_operand_1_direct;
            out_phase_seq             <= out_phase_operand_1_direct;
            source_reg_seq            <= {DATA_WIDTH{1'b0}};
            destination_reg_seq       <= {DATA_WIDTH{1'b0}};
            out_reg_seq               <= {DATA_WIDTH{1'b0}};
            operand_1_seq             <= 3'b000;
            operand_2_seq             <= 3'b000;
            operand_3_seq             <= 3'b000;
            operand_4_seq             <= 16'h0000;
            operation_instruction_seq <= 4'h0;
            operand_1_addressing_seq  <= 1'b0;
            operand_2_addressing_seq  <= 1'b0;
            operand_3_addressing_seq  <= 1'b0;
        end
        else begin
            state_reg                 <= state_next;
            mov_phase_seq             <= mov_phase;
            alu_phase_seq             <= alu_phase;
            in_phase_seq              <= in_phase;
            out_phase_seq             <= out_phase;
            source_reg_seq            <= source_reg;
            destination_reg_seq       <= destination_reg;
            out_reg_seq               <= out_reg;
            operand_1_seq             <= operand_1;
            operand_2_seq             <= operand_2;
            operand_3_seq             <= operand_3;
            operand_4_seq             <= operand_4;
            operation_instruction_seq <= operation_instruction;
            operand_1_addressing_seq  <= operand_1_addressing;
            operand_2_addressing_seq  <= operand_2_addressing;
            operand_3_addressing_seq  <= operand_3_addressing;
        end
    end
    
    always @(*) begin
        //reset all triggers
        state_next  = state_reg;
        cl_trigger  = 5'b00000;
        ld_trigger  = 5'b00000;
        inc_trigger = 5'b00000;
        dec_trigger = 5'b00000;
        sr_trigger  = 5'b00000;
        ir_trigger  = 5'b00000;
        sl_trigger  = 5'b00000;
        il_trigger  = 5'b00000;
        
        //clear all regs
        pc_reg       = 0;
        sp_reg       = 0;
        mem_data_reg = 0;
        mem_addr_reg = 0;
        mem_we_reg   = 0;
        
        alu_operand_1 = 0;
        alu_operand_2 = 0;
        alu_oc        = 0;
        
        //sequential logic
        mov_phase             = mov_phase_seq;
        alu_phase             = alu_phase_seq;
        in_phase              = in_phase_seq;
        out_phase             = out_phase_seq;
        source_reg            = source_reg_seq;
        destination_reg       = destination_reg_seq;
        out_reg               = out_reg_seq;
        operand_1             = operand_1_seq;
        operand_2             = operand_2_seq;
        operand_3             = operand_3_seq;
        operand_4             = operand_4_seq;
        operation_instruction = operation_instruction_seq;
        operand_1_addressing  = operand_1_addressing_seq;
        operand_2_addressing  = operand_2_addressing_seq;
        operand_3_addressing  = operand_3_addressing_seq;
        
        
        case (state_reg)
            
            //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++//
            start:begin
                //load program counter value
                pc_reg     = 4'h8;
                ld_trigger = ld_trigger | (1'b1 << 0);
                state_next = fetch;
            end
            //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++//
            
            
            //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++//
            fetch:begin
                mem_addr_reg = pc_wire;
                state_next   = decode;
                inc_trigger  = inc_trigger | (1'b1 << 0);    //increment PC
            end
            //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++//
            
            
            //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++//
            fetch_second: begin
                operand_4  = ins_high_wire;
                state_next = execute;
            end
            //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++//
            
            
            //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++//
            decode:begin
                operation_instruction = ins_low_wire[15:12];
                operand_1             = ins_low_wire[10:8];
                operand_1_addressing  = ins_low_wire[11];
                operand_2             = ins_low_wire[6:4];
                operand_2_addressing  = ins_low_wire[7];
                operand_3             = ins_low_wire[2:0];
                operand_3_addressing  = ins_low_wire[3];
                
                //operation has two bytes
                if (operand_3_full == 4'b1000)begin
                    mem_addr_reg = pc_wire;
                    state_next   = fetch_second;
                end
                else begin
                    state_next = execute;
                end
                
                case (operation_instruction_seq)
                    MOV: begin
                        if (operand_3_full == 4'b1000) begin
                            mov_phase = mov_phase_operand_2_direct;
                        end
                        else mov_phase = mov_phase_operand_1_direct;
                    end
                    
                    ADD: begin
                        alu_phase = alu_phase_operand_3_direct;
                    end
                    
                    IN: begin
                        if (operand_1_addressing == INDIRECT) in_phase = in_phase_operand_1_direct;
                        else in_phase            = in_phase_operand_1_indirect;
                    end
                    
                    OUT: begin
                        if (operand_1_addressing == INDIRECT) out_phase = out_phase_operand_1_direct;
                        else out_phase           = out_phase_operand_1_indirect;
                    end
                endcase
                
            end
            //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++//
            
            
            //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++//
            execute:begin
                case (operation_instruction)
                    MOV: begin
                        case (mov_phase_seq)
                            mov_phase_operand_2_direct: begin
                                mem_addr_reg             = operand_2;
                                if (operand_2_addressing == INDIRECT) mov_phase = mov_phase_operand_2_indirect;
                                else mov_phase           = mov_phase_operand_1_direct;
                            end
                            
                            mov_phase_operand_2_indirect: begin
                                mem_addr_reg = mem_in;
                                mov_phase    = mov_phase_operand_1_direct;
                            end
                            
                            mov_phase_operand_1_direct: begin
                                source_reg      = mem_in;
                                destination_reg = operand_1;
                                if (operand_1_addressing == INDIRECT) begin
                                    mov_phase    = mov_phase_operand_1_indirect;
                                    mem_addr_reg = operand_1;
                                end
                                else mov_phase = mov_phase_execute;
                            end
                            
                            mov_phase_operand_1_indirect: begin
                                destination_reg = mem_in;
                                mov_phase       = mov_phase_execute;
                            end
                            
                            mov_phase_execute: begin
                                mem_addr_reg = destination_reg;
                                mem_data_reg = source_reg;
                                mem_we_reg   = 1'b1;
                                mov_phase    = mov_phase_end;
                            end
                            
                            mov_phase_operand_1_direct_two_word_addressing: begin
                                source_reg      = operand_4;
                                destination_reg = operand_1;
                                if (operand_1_addressing == INDIRECT) begin
                                    mov_phase    = mov_phase_operand_1_indirect_two_word_addressing;
                                    mem_addr_reg = operand_1;
                                end
                                else mov_phase = mov_phase_execute;
                            end
                            
                            mov_phase_operand_1_indirect_two_word_addressing: begin
                                destination_reg = mem_in;
                                mov_phase       = mov_phase_execute;
                            end
                            
                            mov_phase_end: begin
                                state_next = fetch;
                            end
                        endcase
                    end
                    
                    ADD: begin
                        
                        case (alu_phase_seq)
                            alu_phase_operand_3_direct: begin
                                mem_addr_reg             = operand_3;
                                if (operand_3_addressing == INDIRECT) alu_phase = alu_phase_operand_3_indirect;
                                else alu_phase           = alu_phase_operand_2_direct;
                            end
                            
                            alu_phase_operand_3_indirect: begin
                                mem_addr_reg = mem_in;
                                alu_phase    = alu_phase_operand_2_direct;
                            end
                            
                            alu_phase_operand_2_direct: begin
                                source_reg               = mem_in;
                                mem_addr_reg             = operand_2;
                                if (operand_2_addressing == INDIRECT) alu_phase = alu_phase_operand_2_indirect;
                                else alu_phase           = alu_phase_execute;
                            end
                            
                            alu_phase_operand_2_indirect: begin
                                mem_addr_reg = mem_in;
                                alu_phase    = alu_phase_execute;
                            end
                            
                            alu_phase_execute: begin
                                destination_reg = mem_in;
                                alu_oc          = 3'b000;
                                alu_operand_1   = source_reg;
                                alu_operand_2   = destination_reg;
                                ld_trigger[4]   = 1'b1;
                                
                                
                                if (operand_1_addressing == INDIRECT) begin
                                    mem_addr_reg = operand_1;
                                    alu_phase    = alu_phase_place_indirect;
                                end
                                else alu_phase = alu_phase_place_direct;
                            end
                            
                            alu_phase_place_direct: begin
                                mem_addr_reg = operand_1;
                                mem_data_reg = acc_wire;
                                mem_we_reg   = 1'b1;
                                alu_phase    = alu_phase_end;
                            end
                            
                            alu_phase_place_indirect: begin
                                mem_addr_reg = mem_in;
                                mem_data_reg = acc_wire;
                                mem_we_reg   = 1'b1;
                                alu_phase    = alu_phase_end;
                            end
                            
                            alu_phase_end: begin
                                state_next = fetch;
                            end
                            
                        endcase
                    end
                    
                    SUB: begin
                        
                        case (alu_phase_seq)
                            alu_phase_operand_3_direct: begin
                                mem_addr_reg             = operand_3;
                                if (operand_3_addressing == INDIRECT) alu_phase = alu_phase_operand_3_indirect;
                                else alu_phase           = alu_phase_operand_2_direct;
                            end
                            
                            alu_phase_operand_3_indirect: begin
                                mem_addr_reg = mem_in;
                                alu_phase    = alu_phase_operand_2_direct;
                            end
                            
                            alu_phase_operand_2_direct: begin
                                source_reg               = mem_in;
                                mem_addr_reg             = operand_2;
                                if (operand_2_addressing == INDIRECT) alu_phase = alu_phase_operand_2_indirect;
                                else alu_phase           = alu_phase_execute;
                            end
                            
                            alu_phase_operand_2_indirect: begin
                                mem_addr_reg = mem_in;
                                alu_phase    = alu_phase_execute;
                            end
                            
                            alu_phase_execute: begin
                                destination_reg = mem_in;
                                alu_oc          = 3'b001;
                                alu_operand_1   = source_reg;
                                alu_operand_2   = destination_reg;
                                ld_trigger[4]   = 1'b1;
                                
                                
                                if (operand_1_addressing == INDIRECT) begin
                                    mem_addr_reg = operand_1;
                                    alu_phase    = alu_phase_place_indirect;
                                end
                                else alu_phase = alu_phase_place_direct;
                            end
                            
                            alu_phase_place_direct: begin
                                mem_addr_reg = operand_1;
                                mem_data_reg = acc_wire;
                                mem_we_reg   = 1'b1;
                                alu_phase    = alu_phase_end;
                            end
                            
                            alu_phase_place_indirect: begin
                                mem_addr_reg = mem_in;
                                mem_data_reg = acc_wire;
                                mem_we_reg   = 1'b1;
                                alu_phase    = alu_phase_end;
                            end
                            
                            alu_phase_end: begin
                                state_next = fetch;
                            end
                            
                        endcase
                    end
                    
                    MUL: begin
                        
                        case (alu_phase_seq)
                            alu_phase_operand_3_direct: begin
                                mem_addr_reg             = operand_3;
                                if (operand_3_addressing == INDIRECT) alu_phase = alu_phase_operand_3_indirect;
                                else alu_phase           = alu_phase_operand_2_direct;
                            end
                            
                            alu_phase_operand_3_indirect: begin
                                mem_addr_reg = mem_in;
                                alu_phase    = alu_phase_operand_2_direct;
                            end
                            
                            alu_phase_operand_2_direct: begin
                                source_reg               = mem_in;
                                mem_addr_reg             = operand_2;
                                if (operand_2_addressing == INDIRECT) alu_phase = alu_phase_operand_2_indirect;
                                else alu_phase           = alu_phase_execute;
                            end
                            
                            alu_phase_operand_2_indirect: begin
                                mem_addr_reg = mem_in;
                                alu_phase    = alu_phase_execute;
                            end
                            
                            alu_phase_execute: begin
                                destination_reg = mem_in;
                                alu_oc          = 3'b010;
                                alu_operand_1   = source_reg;
                                alu_operand_2   = destination_reg;
                                ld_trigger[4]   = 1'b1;
                                
                                
                                if (operand_1_addressing == INDIRECT) begin
                                    mem_addr_reg = operand_1;
                                    alu_phase    = alu_phase_place_indirect;
                                end
                                else alu_phase = alu_phase_place_direct;
                            end
                            
                            alu_phase_place_direct: begin
                                mem_addr_reg = operand_1;
                                mem_data_reg = acc_wire;
                                mem_we_reg   = 1'b1;
                                alu_phase    = alu_phase_end;
                            end
                            
                            alu_phase_place_indirect: begin
                                mem_addr_reg = mem_in;
                                mem_data_reg = acc_wire;
                                mem_we_reg   = 1'b1;
                                alu_phase    = alu_phase_end;
                            end
                            
                            alu_phase_end: begin
                                state_next = fetch;
                            end
                            
                        endcase
                    end
                    
                    DIV: begin
                        
                        case (alu_phase_seq)
                            alu_phase_operand_3_direct: begin
                                mem_addr_reg             = operand_3;
                                if (operand_3_addressing == INDIRECT) alu_phase = alu_phase_operand_3_indirect;
                                else alu_phase           = alu_phase_operand_2_direct;
                            end
                            
                            alu_phase_operand_3_indirect: begin
                                mem_addr_reg = mem_in;
                                alu_phase    = alu_phase_operand_2_direct;
                            end
                            
                            alu_phase_operand_2_direct: begin
                                source_reg               = mem_in;
                                mem_addr_reg             = operand_2;
                                if (operand_2_addressing == INDIRECT) alu_phase = alu_phase_operand_2_indirect;
                                else alu_phase           = alu_phase_execute;
                            end
                            
                            alu_phase_operand_2_indirect: begin
                                mem_addr_reg = mem_in;
                                alu_phase    = alu_phase_execute;
                            end
                            
                            alu_phase_execute: begin
                                destination_reg = mem_in;
                                alu_oc          = 3'b011;
                                alu_operand_1   = source_reg;
                                alu_operand_2   = destination_reg;
                                ld_trigger[4]   = 1'b1;
                                
                                
                                if (operand_1_addressing == INDIRECT) begin
                                    mem_addr_reg = operand_1;
                                    alu_phase    = alu_phase_place_indirect;
                                end
                                else alu_phase = alu_phase_place_direct;
                            end
                            
                            alu_phase_place_direct: begin
                                mem_addr_reg = operand_1;
                                mem_data_reg = acc_wire;
                                mem_we_reg   = 1'b1;
                                alu_phase    = alu_phase_end;
                            end
                            
                            alu_phase_place_indirect: begin
                                mem_addr_reg = mem_in;
                                mem_data_reg = acc_wire;
                                mem_we_reg   = 1'b1;
                                alu_phase    = alu_phase_end;
                            end
                            
                            alu_phase_end: begin
                                state_next = fetch;
                            end
                            
                        endcase
                    end
                    
                    IN: begin
                        case (in_phase)
                            
                            in_phase_operand_1_direct: begin
                                source_reg = operand_1;
                                in_phase   = in_phase_execute;
                            end
                            
                            in_phase_operand_1_indirect: begin
                                mem_addr_reg = operand_1;
                                in_phase     = in_phase_operand_1_indirect_write;
                            end
                            
                            in_phase_operand_1_indirect_write: begin
                                source_reg = mem_in;
                                in_phase   = in_phase_execute;
                            end
                            
                            in_phase_execute: begin
                                mem_addr_reg = source_reg;
                                mem_data_reg = in;
                                mem_we_reg   = 1'b1;
                                in_phase     = in_phase_end;
                            end
                            
                            in_phase_end: begin
                                state_next = fetch;
                            end
                            
                        endcase
                    end
                    
                    OUT: begin
                        case (out_phase)
                            
                            out_phase_operand_1_direct: begin
                                mem_addr_reg = operand_1;
                                out_phase    = out_phase_execute;
                            end
                            
                            out_phase_operand_1_indirect: begin
                                mem_addr_reg = operand_1;
                                out_phase    = out_phase_operand_1_indirect_write;
                            end
                            
                            out_phase_operand_1_indirect_write: begin
                                mem_addr_reg = operand_1;
                                out_phase    = out_phase_execute;
                            end
                            
                            out_phase_execute: begin
                                out_reg   = mem_in;
                                out_phase = out_phase_end;
                            end
                            
                            out_phase_end: begin
                                state_next = fetch;
                            end
                            
                        endcase
                    end
                    
                    STOP: begin
                        state_next = stop;
                    end
                    default:begin
                        
                    end
                endcase
            end
            //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++//
            
            
            
            //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++//
            stop: begin
                
            end
            //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++//
            
            default: begin
                
            end
        endcase
    end
    
endmodule
