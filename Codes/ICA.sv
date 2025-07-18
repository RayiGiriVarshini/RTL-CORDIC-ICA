
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03.12.2024 14:13:29
// Design Name: 
// Module Name: ICA
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module ICA#(
    parameter DATA_WIDTH = 16,
    parameter CORDIC_WIDTH = 22,
    parameter ANGLE_WIDTH = 16,
    parameter CORDIC_STAGES = 16
)(
    input clk,
    input nreset,
  //output s_est, // we will write the estimated vvector directly into the memory
    output reg done_ica
);
    // Registers and wires
  	reg [3:0] i, state;
  	reg [2:0] k;
    reg enable_gso, done_gso, nreset_gso;
    reg enable_norm, done_norm, nreset_norm;
    reg enable_update, done_update, nreset_update;
    reg enable_est, done_est, nreset_est;
    reg converge;

    wire [15:0] gso_output [6:0];
    reg [15:0] wnew [6:0];
    reg [15:0] wdiff;
    reg [15:0] epsilon; // Predefined value in the initial block
    reg [15:0] theta_w0 [5:0];
    reg [15:0] theta_w1 [5:0];
    reg [15:0] theta_w2 [5:0];
    reg [15:0] theta_w3 [5:0];
    reg [15:0] theta_w4 [5:0];
    reg [15:0] theta_w5 [5:0];
  	reg [15:0] theta_w6 [5:0];
  	reg [15:0] theta_w7 [5:0];
  	wire [15:0] theta_norm [5:0];
    reg enable_demux;
    reg [DATA_WIDTH-1:0] wold[6:0];

    // GSO module instantiation
    GSO_7D_rot gso(
        .clk(clk),
        .k(k),
        .i(i),
        .wnew(wnew),
        .theta1(theta_w0),
        .theta2(theta_w1),
        .theta3(theta_w2),
        .theta4(theta_w3),
        .theta5(theta_w4),
        .theta6(theta_w5),
        .enable_gso(enable_gso),
        .nreset_gso(nreset_gso),
        .done_gso(done_gso),
        .gso_out(gso_output)
    );

    // NUE module instantiation
    normalize_wdiff_update_estimate_7D nue(
        .clk(clk),
        .k(k),
      	.i(i),
        .norm_in(gso_output),
        .enable_norm(enable_norm),
        .enable_update(enable_update),
        .enable_estimate(enable_est),
        .nreset_norm(nreset_norm),
        .nreset_update(nreset_update),
        .nreset_estimate(nreset_est),
        .done_wdiff(done_norm),
        .done_update(done_update),
        .done_estimate(done_est),
      	.win_old(wold),// about this part how are we are giving it back as an input to Norm block
      	// or we can have a reg taking this output vector in it
      	.norm_out(wold),
        .wdiff(wdiff),
        .theta_out(theta_norm),
        .w_updated(wnew)
    );

    // Demultiplexer instantiation
  // we need to implement as case based logic not from clk, as it passing its value to a reg which has to store a value
    demux8to1_enable dmm(
        .k(k),
        .theta_norm(theta_norm),
        .enable_demux(enable_demux),
        .theta1(theta_w0),
        .theta2(theta_w1),
        .theta3(theta_w2),
        .theta4(theta_w3),
        .theta5(theta_w4),
      	.theta6(theta_w5),
      	.theta7(theta_w6), // useless
      	.theta8(theta_w7) // useless
    );
// whenever we are going back to state 0 or start state then we have to make nreset = 0 and enable = 0
  // we have to write code corresponding to above
  
  // should we make nreset of a exactly after it has been used or in the start mode.
  
    // State machine
    always @(posedge clk) begin
        if (nreset) begin
            case (state)
                4'd0: begin // Start state
                  if (k == 3'd0) // Skip GSO
                        state = 4'd2;
                    else begin
                        nreset_gso = 4'd0;
                        state = 4'd1;
                    end
                end
                
                4'd1: begin // GSO state
                    nreset_gso = 1;
                    enable_gso = 1;
                    if (done_gso) begin
                        enable_gso = 0;
                        nreset_norm = 0;
                        state = 4'd2;
                    end
                end
                
                4'd2: begin // Normalization state
                  if (k == 3'd6) begin
                        state = 4'd4; // Proceed to estimation
                    end else begin
                        nreset_norm = 1;
                        enable_norm = 1;
                        if (done_norm) begin
                            enable_norm = 0;
                            if (i == 4'd0) begin
                                nreset_update = 0;
                                state = 4'd3;
                            end else begin
                                if (wdiff < epsilon) begin
                                    enable_demux = 1;
                                    nreset_est = 0;
                                    state = 4'd4;
                                end else begin
                                    if (i == 4'd15) begin
                                        nreset_est = 0;
                                        state = 4'd4;
                                    end else begin
                                        nreset_update = 0;
                                        state = 4'd3;
                                    end
                                end
                            end
                        end
                    end
                end
                
                4'd3: begin // Update state
                    nreset_update = 1;
                    enable_update = 1;
                    i = i + 4'd1;
                    if (done_update) begin
                        enable_update = 0;
                        
                        state = 4'd0; // Go back to begin state
                    end
                end
                
                4'd4: begin // Estimation state
                    nreset_est = 1;
                    enable_est = 1;
                    if (done_est) begin
                        enable_est = 0;
                        i = 4'd1;
                        k = k + 3'd1;
                      if (k == 3'd7) begin
                            state = 4'd5;
                        end else begin
                            state = 4'd0; // go back to begin state
                        end
                    end
                end
                
                4'd5: begin // Completion state
                    done_ica = 1;
                end
            endcase
        end 
      else begin
            // Reset logic
            enable_gso = 0;
            enable_norm = 0;
            enable_update = 0;
            enable_est = 0;
            
            nreset_gso = 0;
            nreset_norm = 0;
            nreset_update = 0;
            nreset_est = 0;
            
//            done_gso = 0;
//            done_norm = 0;
//            done_update = 0;
//            done_est = 0;
            
            converge = 0;
            i = 4'd0;
            k = 3'd0;
            //wdiff = 0;
            state = 0;
            done_ica = 0;
            
            //wnew = '{default: 16'd0};
            epsilon = 16'd10;
            
//            theta_w0 = '{default: 16'd0};
//    theta_w1 = '{default: 16'd0};
//    theta_w2 = '{default: 16'd0};
//    theta_w3 = '{default: 16'd0};
//    theta_w4 = '{default: 16'd0};
//    theta_w5 = '{default: 16'd0};
//    theta_w6 = '{default: 16'd0};
//    theta_w7 = '{default: 16'd0};
        end
    end
endmodule

module demux8to1_enable (
    input [2:0] k, // 3-bit select line for 8 outputs
    input [15:0] theta_norm [5:0], // Input data
    input enable_demux, // Enable signal
    output [15:0] theta1 [5:0],
    output [15:0] theta2 [5:0],
    output [15:0] theta3 [5:0],
    output [15:0] theta4 [5:0],
    output [15:0] theta5 [5:0],
    output [15:0] theta6 [5:0],
    output [15:0] theta7 [5:0],
    output [15:0] theta8 [5:0]
);

    // Default values for all outputs
    wire [15:0] zeros = 16'h0000;

    // Assign each element of theta1
    assign theta1[0] = (enable_demux && k == 3'b000) ? theta_norm[0] : zeros;
    assign theta1[1] = (enable_demux && k == 3'b000) ? theta_norm[1] : zeros;
    assign theta1[2] = (enable_demux && k == 3'b000) ? theta_norm[2] : zeros;
    assign theta1[3] = (enable_demux && k == 3'b000) ? theta_norm[3] : zeros;
    assign theta1[4] = (enable_demux && k == 3'b000) ? theta_norm[4] : zeros;
    assign theta1[5] = (enable_demux && k == 3'b000) ? theta_norm[5] : zeros;

    // Assign each element of theta2
    assign theta2[0] = (enable_demux && k == 3'b001) ? theta_norm[0] : zeros;
    assign theta2[1] = (enable_demux && k == 3'b001) ? theta_norm[1] : zeros;
    assign theta2[2] = (enable_demux && k == 3'b001) ? theta_norm[2] : zeros;
    assign theta2[3] = (enable_demux && k == 3'b001) ? theta_norm[3] : zeros;
    assign theta2[4] = (enable_demux && k == 3'b001) ? theta_norm[4] : zeros;
    assign theta2[5] = (enable_demux && k == 3'b001) ? theta_norm[5] : zeros;

    // Assign each element of theta3
    assign theta3[0] = (enable_demux && k == 3'b010) ? theta_norm[0] : zeros;
    assign theta3[1] = (enable_demux && k == 3'b010) ? theta_norm[1] : zeros;
    assign theta3[2] = (enable_demux && k == 3'b010) ? theta_norm[2] : zeros;
    assign theta3[3] = (enable_demux && k == 3'b010) ? theta_norm[3] : zeros;
    assign theta3[4] = (enable_demux && k == 3'b010) ? theta_norm[4] : zeros;
    assign theta3[5] = (enable_demux && k == 3'b010) ? theta_norm[5] : zeros;

    // Similarly assign for theta4, theta5, theta6, theta7, and theta8
    assign theta4[0] = (enable_demux && k == 3'b011) ? theta_norm[0] : zeros;
    assign theta4[1] = (enable_demux && k == 3'b011) ? theta_norm[1] : zeros;
    assign theta4[2] = (enable_demux && k == 3'b011) ? theta_norm[2] : zeros;
    assign theta4[3] = (enable_demux && k == 3'b011) ? theta_norm[3] : zeros;
    assign theta4[4] = (enable_demux && k == 3'b011) ? theta_norm[4] : zeros;
    assign theta4[5] = (enable_demux && k == 3'b011) ? theta_norm[5] : zeros;

    assign theta5[0] = (enable_demux && k == 3'b100) ? theta_norm[0] : zeros;
    assign theta5[1] = (enable_demux && k == 3'b100) ? theta_norm[1] : zeros;
    assign theta5[2] = (enable_demux && k == 3'b100) ? theta_norm[2] : zeros;
    assign theta5[3] = (enable_demux && k == 3'b100) ? theta_norm[3] : zeros;
    assign theta5[4] = (enable_demux && k == 3'b100) ? theta_norm[4] : zeros;
    assign theta5[5] = (enable_demux && k == 3'b100) ? theta_norm[5] : zeros;

    assign theta6[0] = (enable_demux && k == 3'b101) ? theta_norm[0] : zeros;
    assign theta6[1] = (enable_demux && k == 3'b101) ? theta_norm[1] : zeros;
    assign theta6[2] = (enable_demux && k == 3'b101) ? theta_norm[2] : zeros;
    assign theta6[3] = (enable_demux && k == 3'b101) ? theta_norm[3] : zeros;
    assign theta6[4] = (enable_demux && k == 3'b101) ? theta_norm[4] : zeros;
    assign theta6[5] = (enable_demux && k == 3'b101) ? theta_norm[5] : zeros;

    assign theta7[0] = (enable_demux && k == 3'b110) ? theta_norm[0] : zeros;
    assign theta7[1] = (enable_demux && k == 3'b110) ? theta_norm[1] : zeros;
    assign theta7[2] = (enable_demux && k == 3'b110) ? theta_norm[2] : zeros;
    assign theta7[3] = (enable_demux && k == 3'b110) ? theta_norm[3] : zeros;
    assign theta7[4] = (enable_demux && k == 3'b110) ? theta_norm[4] : zeros;
    assign theta7[5] = (enable_demux && k == 3'b110) ? theta_norm[5] : zeros;

    assign theta8[0] = (enable_demux && k == 3'b111) ? theta_norm[0] : zeros;
    assign theta8[1] = (enable_demux && k == 3'b111) ? theta_norm[1] : zeros;
    assign theta8[2] = (enable_demux && k == 3'b111) ? theta_norm[2] : zeros;
    assign theta8[3] = (enable_demux && k == 3'b111) ? theta_norm[3] : zeros;
    assign theta8[4] = (enable_demux && k == 3'b111) ? theta_norm[4] : zeros;
    assign theta8[5] = (enable_demux && k == 3'b111) ? theta_norm[5] : zeros;

endmodule
