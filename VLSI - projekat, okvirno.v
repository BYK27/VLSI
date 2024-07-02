module register #(parameter DATA_WIDTH = 16)
    (input clk, input rst_n, input cl, input ld,
     input [DATA_WIDTH-1:0] in,
     input inc, input dec,
     input sr, input ir,
     input sl, input il,
     output [DATA_WIDTH-1:0] out);
  
  reg [DATA_WIDTH-1:0] q;

  always @(posedge clk or negedge rst_n) begin
    if (~rst_n)
      q <= 0;
    else if (cl)
      q <= in;
    else if (ld)
      q <= q;
    else if (inc)
      q <= q + 1;
    else if (dec)
      q <= q - 1;
    else if (sr)
      q <= q >> 1;
    else if (ir)
      q <= {q[DATA_WIDTH-2:0], q[DATA_WIDTH-1]};
    else if (sl)
      q <= q << 1;
    else if (il)
      q <= {q[DATA_WIDTH-1], q[DATA_WIDTH-1:1]};
  end

  assign out = q;

endmodule


module alu #(parameter DATA_WIDTH = 16)
    (input [DATA_WIDTH-1:0] a, input [DATA_WIDTH-1:0] b,
     input [3:0] opcode,
     output [DATA_WIDTH-1:0] f);

  assign f = (opcode == 4'b0000) ? a + b :
             (opcode == 4'b0001) ? a - b :
             (opcode == 4'b0010) ? a * b :
             (opcode == 4'b0011) ? (b == 0) ? 0 : a / b :
             (opcode == 4'b0100) ? 0 :
             (opcode == 4'b1111) ? 0 :
             0;

endmodule


module cpu #(parameter ADDR_WIDTH = 6, DATA_WIDTH = 16)
    (input clk, input rst_n,
     input [DATA_WIDTH-1:0] mem_in, in,
     output mem_we,
     output [ADDR_WIDTH-1:0] mem_addr,
     output [DATA_WIDTH-1:0] mem_data,
     output [DATA_WIDTH-1:0] out,
     output [ADDR_WIDTH-1:0] pc,
     output [ADDR_WIDTH-1:0] sp);

  reg [ADDR_WIDTH-1:0] pc_reg, sp_reg;
  reg [5:0] opcode;
  reg [15:0] ir;
  reg [ADDR_WIDTH-1:0] mem_addr_reg;
  reg mem_we_reg;
  reg [DATA_WIDTH-1:0] mem_data_reg, out_reg;

  // Instantiate modules
  register #(DATA_WIDTH) pc_register(.clk(clk), .rst_n(rst_n), .cl(1'b0), .ld(1'b1),
                                      .in(6'b000010), .inc(1'b1), .dec(1'b0),
                                      .sr(1'b0), .ir(1'b0),
                                      .sl(1'b0), .il(1'b0),
                                      .out(pc_reg));

  register #(DATA_WIDTH) sp_register(.clk(clk), .rst_n(rst_n), .cl(1'b0), .ld(1'b1),
                                      .in(6'b000011), .inc(1'b1), .dec(1'b0),
                                      .sr(1'b0), .ir(1'b0),
                                      .sl(1'b0), .il(1'b0),
                                      .out(sp_reg));

  register #(32) ir_register(.clk(clk), .rst_n(rst_n), .cl(1'b0), .ld(1'b1),
                               .in(6'b000100), .inc(1'b1), .dec(1'b0),
                               .sr(1'b0), .ir(1'b0),
                               .sl(1'b0), .il(1'b0),
                               .out(ir));

  register #(DATA_WIDTH) mem_data_register(.clk(clk), .rst_n(rst_n), .cl(1'b0), .ld(1'b1),
                                           .in(6'b000101), .inc(1'b1), .dec(1'b0),
                                           .sr(1'b0), .ir(1'b0),
                                           .sl(1'b0), .il(1'b0),
                                           .out(mem_data_reg));

  register #(ADDR_WIDTH) mem_addr_register(.clk(clk), .rst_n(rst_n), .cl(1'b0), .ld(1'b1),
                                           .in(6'b000110), .inc(1'b1), .dec(1'b0),
                                           .sr(1'b0), .ir(1'b0),
                                           .sl(1'b0), .il(1'b0),
                                           .out(mem_addr_reg));

  alu #(DATA_WIDTH) alu_inst(.a(16'b0), .b(16'b0), .opcode(opcode), .f(out_reg));

  always @(posedge clk or negedge rst_n) begin
    if (~rst_n)
      opcode <= 6'b0;
    else
      opcode <=   [31:26];
  end

  always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
      pc_reg <= 6'b1000;
      sp_reg <= 6'b1111;
    end else if (mem_we_reg) begin
      pc_reg <= pc_reg + 1;
      sp_reg <= sp_reg - 1;
    end
  end

  always @(posedge clk or negedge rst_n) begin
    if (~rst_n)
      mem_we_reg <= 1'b0;
    else if (opcode == 6'b0000)  // MOV
      mem_we_reg <= (ir[3:0] == 4'b1000) ? 1'b0 : 1'b1;
    else if (opcode == 6'b1111)  // STOP
      mem_we_reg <= (ir[3:0] == 4'b0000) ? 1'b1 : 1'b0;
    else
      mem_we_reg <= 1'b0;
  end

  always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
      mem_data_reg <= 16'b0;
      out_reg <= 16'b0;
    end else if (mem_we_reg) begin
      mem_data_reg <= (opcode == 6'b0000) ? (ir[3:0] == 4'b1000) ? out_reg : mem_data_reg;
      out_reg <= (opcode == 6'b1111) ? mem_data_reg : 16'b0;
    end
  end

  assign mem_we = mem_we_reg;
  assign mem_addr = mem_addr_reg;
  assign mem_data = mem_data_reg;
  assign out = out_reg;
  assign pc = pc_reg;
  assign sp = sp_reg;

endmodule
