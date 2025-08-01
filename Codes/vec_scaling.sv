module vec_scaling #(
        parameter CORDIC_WIDTH = 22
    ) (
		input signed [CORDIC_WIDTH-1:0] x_in,
		input en,
		output reg signed [CORDIC_WIDTH-1:0] scale_out
    );
    
    always @* begin
	    if (en)
            scale_out = {x_in[CORDIC_WIDTH-1],x_in[CORDIC_WIDTH-1:1]} + {{4{x_in[CORDIC_WIDTH-1]}},x_in[CORDIC_WIDTH-1:4]} +
                        {{5{x_in[CORDIC_WIDTH-1]}},x_in[CORDIC_WIDTH-1:5]} + {{7{x_in[CORDIC_WIDTH-1]}},x_in[CORDIC_WIDTH-1:7]} +
                        {{8{x_in[CORDIC_WIDTH-1]}},x_in[CORDIC_WIDTH-1:8]} + {{10{x_in[CORDIC_WIDTH-1]}},x_in[CORDIC_WIDTH-1:10]} +
                        {{11{x_in[CORDIC_WIDTH-1]}},x_in[CORDIC_WIDTH-1:11]} + {{12{x_in[CORDIC_WIDTH-1]}},x_in[CORDIC_WIDTH-1:12]} +
                        {{14{x_in[CORDIC_WIDTH-1]}},x_in[CORDIC_WIDTH-1:14]};                                 
        else
            scale_out = {CORDIC_WIDTH{1'b0}};
    end

endmodule