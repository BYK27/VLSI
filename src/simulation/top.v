module top; reg[2:0] oc; reg[3:0] a; reg[3:0] b; wire[3:0] f; alu alu_inst(.oc(oc), .a(a), .b(b), .f(f));
reg clk;
reg rst_n;
reg cl;
reg ld;
reg[3:0] in;
reg inc;
reg dec;
reg sr;
reg ir;
reg sl;
reg il;
wire[3:0] out;
register register_inc(.clk(clk), .rst_n(rst_n), .cl(cl), .ld(ld), .in(in), .inc(inc), .dec(dec), .sr(sr), .ir(ir), .sl(sl), .il(il), .out(out));

integer i;

initial begin
    clk   = 1'b0;
    rst_n = 1'b0;
    forever
        #5 clk = ~clk;
end

initial begin
    for (i = 0; i < 2**11; i = i + 1) begin
        {oc, a, b} = i;
        #5;
    end
    #0 $stop();
    
    cl  = 1'b0;
    ld  = 1'b0;
    in  = 4'h0;
    inc = 1'b0;
    dec = 1'b0;
    sr  = 1'b0;
    ir  = 1'b0;
    sl  = 1'b0;
    il  = 1'b0;
    #7;
    
    rst_n = 1'b1;
    repeat (1000) begin
        #10;
        cl  = $urandom % 2;
        ld  = $urandom % 2;
        in  = $urandom % 16;
        inc = $urandom % 2;
        dec = $urandom % 2;
        sr  = $urandom % 2;
        ir  = $urandom % 2;
        sl  = $urandom % 2;
        il  = $urandom % 2;
    end
    $finish;
end

always @(f)
    $display(
    "time = %4d, oc = %3b, a = %4b, b = %4b, f = %4b",
    $time, oc, a, b, f
    );

always @(out)
    $display(
    "time = %4d, cl = %1b, ld = %1b, in = %4b, inc = %1b, dec = %1b, sr = %1b, ir = %1b, sl = %1b, il = %1b, out = %4b",
    $time, cl, ld, in, inc, dec, sr, ir, sl, il, out
    );

endmodule
