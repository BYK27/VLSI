// `include "src/synthesis/modules/register.v"
// `include "src/synthesis/modules/alu.v"
// `include "src/synthesis/modules/bcd.v"
// `include "src/synthesis/modules/memory.v"
// `include "src/synthesis/modules/cpu.v"


module top #(parameter DIVISOR = 50000000,
             parameter FILE_NAME = "mem_init.mif",
             parameter ADDR_WIDTH = 6,
             parameter DATA_WIDTH = 16)
            (input clk,
             input rst_n,
             input [2:0] btn,
             input [9:0] sw,
             output [9:0] led,
             output [27:0] hex);
    
    
    //wires
    wire clk_devided;
    wire mem_we;
    wire[ADDR_WIDTH-1 : 0] mem_addr;
    wire[DATA_WIDTH-1 : 0] mem_data;
    wire[DATA_WIDTH-1 : 0] mem_in;
    wire[ADDR_WIDTH-1 : 0] pc;
    wire[ADDR_WIDTH-1 : 0] sp;
    wire[3:0] bcd_0_tens;
    wire[3:0] bcd_0_ones;
    wire[3:0] bcd_1_tens;
    wire[3:0] bcd_1_ones;
    
    
    
    clk_div clk_div_inst(.clk(clk), .rst_n(rst_n), .out(clk_devided));
    
    cpu #(ADDR_WIDTH, DATA_WIDTH) cpu_inst (
    .clk(clk_devided),
    .rst_n(rst_n),
    .mem_in(mem_in),
    .in(sw[3:0]),
    .mem_we(mem_we),
    .mem_addr(mem_addr),
    .mem_data(mem_data),
    .out(led[4:0]),
    .pc(pc),
    .sp(sp)
    );
    
    memory #(ADDR_WIDTH, DATA_WIDTH) memory_inst (
    .clk(clk_devided),
    .we(mem_we),
    .addr(mem_addr),
    .data(mem_data),
    .out(mem_in)
    );
    
    bcd bcd_inst_0 (
    .in(sp),
    .ones(bcd_0_ones),
    .tens(bcd_0_tens)
    );
    
    bcd bcd_inst_1 (
    .in(pc),
    .ones(bcd_1_ones),
    .tens(bcd_1_tens)
    );
    
    ssd ssd_inst_0_ones (
    .in(bcd_0_ones),
    .out(hex[27:21])
    );
    
    ssd ssd_inst_0_tens (
    .in(bcd_0_tens),
    .out(hex[20:14])
    );
    
    ssd ssd_inst_1_ones (
    .in(bcd_1_ones),
    .out(hex[13:7])
    );
    
    ssd ssd_inst_1_tens (
    .in(bcd_1_tens),
    .out(hex[6:0])
    );
    
endmodule
