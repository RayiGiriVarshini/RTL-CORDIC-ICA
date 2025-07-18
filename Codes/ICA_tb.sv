`timescale 1ns / 1ps

module ICA_tb;

    // Parameters
    parameter DATA_WIDTH = 16;
    parameter CORDIC_WIDTH = 22;
    parameter ANGLE_WIDTH = 16;
    parameter CORDIC_STAGES = 16;

    // Inputs
    reg clk;
    reg nreset;

    // Outputs
    wire done_ica;

    // Instantiate the Unit Under Test (UUT)
    ICA #(
        .DATA_WIDTH(DATA_WIDTH),
        .CORDIC_WIDTH(CORDIC_WIDTH),
        .ANGLE_WIDTH(ANGLE_WIDTH),
        .CORDIC_STAGES(CORDIC_STAGES)
    ) uut (
        .clk(clk),
        .nreset(nreset),
        .done_ica(done_ica)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100 MHz clock
    end

    // Test sequence
    initial begin
        // Initialize inputs
        nreset = 0;

        // Wait for global reset
        #20;
        
        
        // Release reset
        nreset = 1;

        // Wait for the process to complete
        wait (done_ica);
        $display("ICA computation completed.");

        // Finish simulation
        #10;
        $stop;
    end
endmodule

