// ================================================================
//  project.v  —  TinyTapeout Sky130 Top-Level Wrapper
//  Module name MUST match info.yaml → top_module field EXACTLY
//  Pin interface is FIXED by TinyTapeout — do not rename ports
// ================================================================
`default_nettype none

module tt_um_lif_neuron (
    input  wire [7:0] ui_in,    // 8 dedicated input pins
    output wire [7:0] uo_out,   // 8 dedicated output pins
    input  wire [7:0] uio_in,   // 8 bidirectional pins (input path)
    output wire [7:0] uio_out,  // 8 bidirectional pins (output path)
    output wire [7:0] uio_oe,   // bidir output-enable (1 = output mode)
    input  wire       ena,      // enable from TinyTapeout controller
    input  wire       clk,      // system clock
    input  wire       rst_n     // active-low reset
);

    // ── Internal wires ───────────────────────────────────────────
    wire        spike;
    wire [15:0] v_mem;

    // ── Instantiate the LIF neuron core ─────────────────────────
    lif_neuron #(
        .DATA_WIDTH   (16),
        .WEIGHT_WIDTH (8),
        .THRESHOLD    (16'h0100),
        .LEAK_SHIFT   (4),
        .V_RESET      (16'h0000),
        .REFRACTORY   (4)
    ) lif_inst (
        .clk       (clk),
        .rst_n     (rst_n),
        .enable    (ena),
        .i_input   (ui_in),
        .i_valid   (1'b1),
        .spike_out (spike),
        .v_mem_out (v_mem)
    );

    // ── Pin Mapping ──────────────────────────────────────────────
    // uo_out[7]   = spike         (MSB = spike flag)
    // uo_out[6:0] = v_mem[6:0]   (lower 7 membrane bits)
    assign uo_out = {spike, v_mem[6:0]};

    // uio_out = v_mem[14:7]       (upper 8 membrane bits)
    assign uio_out = v_mem[14:7];

    // All bidir pins → output mode
    assign uio_oe  = 8'hFF;

    // Suppress unused-input lint warnings
    wire _unused = &{uio_in, v_mem[15], v_mem[6:0]};

endmodule