module clk_div #(parameter DIVISOR = 50_000_000)
                (input clk,
                 input rst_n,
                 output out);
    
    reg out_data;
    reg[31:0] counter;
    
    assign out = out_data;
    
    always @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            counter <= 32'h0000;
            out_data = 1'b0;
        end
        else begin
            if (counter == DIVISOR - 1) begin
                counter <= 32'h0000;
                out_data = ~out_data;
            end
            else begin
                counter <= counter + 1'b1;
            end
        end
    end
endmodule
