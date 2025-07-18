module ip_upscale #(
        parameter DATA_WIDTH = 16,
        parameter CORDIC_WIDTH = 22
    ) (
	    input [DATA_WIDTH-1:0] x_in,
        input [DATA_WIDTH-1:0] y_in,
        output [CORDIC_WIDTH-1:0] x_out,
        output [CORDIC_WIDTH-1:0] y_out

    );
    
    assign x_out = {x_in,{CORDIC_WIDTH-DATA_WIDTH{1'b0}}};
    assign y_out = {y_in,{CORDIC_WIDTH-DATA_WIDTH{1'b0}}};
	
endmodule