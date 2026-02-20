`timescale 1ns/1ps
`default_nettype none

module tb ();

    reg        clk, rst_n, ena;
    reg  [7:0] ui_in;
    wire [7:0] uo_out;   // [7]=spike, [6:0]=v_mem[6:0]
    wire [7:0] uio_out;  // v_mem[14:7] debug bits
    wire [7:0] uio_oe;

    tt_um_lif_neuron dut (
        .clk    (clk),
        .rst_n  (rst_n),
        .ena    (ena),
        .ui_in  (ui_in),
        .uo_out (uo_out),
        .uio_in (8'b0),
        .uio_out(uio_out),
        .uio_oe (uio_oe)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        $dumpfile("tb.fst");
        $dumpvars(0, tb);
        #1;
    end

endmodule