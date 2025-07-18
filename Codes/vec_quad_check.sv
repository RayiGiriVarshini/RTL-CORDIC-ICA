module vec_quad_check(
        input clk,
        input nreset,
        input enable,
        input x_in_MSB,
        input y_in_MSB,
        output [1:0] quad_out
    );
    
    reg [1:0] quad;    
    always @(posedge clk or negedge nreset) begin
        if (~nreset)
            quad <= 2'b00;
        else if (enable)
            quad <= {y_in_MSB,x_in_MSB};
    end
    
    assign quad_out = enable ? {y_in_MSB,x_in_MSB} : quad;
    
endmodule