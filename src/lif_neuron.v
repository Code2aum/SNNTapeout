// ================================================================
//  lif_neuron.v  —  Leaky Integrate-and-Fire Neuron Core
//  Target: TinyTapeout Sky130
//  Fully synthesizable — no floating point, no latches
// ================================================================
`default_nettype none

module lif_neuron #(
    // ── Parameters: change these to tune neuron behavior ──────
    parameter DATA_WIDTH   = 16,        // bits of membrane precision
    parameter WEIGHT_WIDTH = 8,         // bits of input current
    parameter THRESHOLD    = 16'h0100,  // fire threshold (256 in decimal)
    parameter LEAK_SHIFT   = 4,         // leak = V >> 4  (divide by 16)
    parameter V_RESET      = 16'h0000,  // membrane value after spike
    parameter REFRACTORY   = 4'd4       // quiet cycles after spike
)(
    // ── Inputs ─────────────────────────────────────────────────
    input  wire                    clk,      // master clock
    input  wire                    rst_n,    // reset (0 = active reset)
    input  wire                    enable,   // 1 = neuron is running
    input  wire [WEIGHT_WIDTH-1:0] i_input,  // incoming current magnitude
    input  wire                    i_valid,  // 1 = current is real this cycle
    // ── Outputs ────────────────────────────────────────────────
    output reg                     spike_out, // 1 = neuron just fired
    output wire [DATA_WIDTH-1:0]   v_mem_out  // current membrane potential
);

    // ── Internal registers ─────────────────────────────────────
    reg [DATA_WIDTH-1:0] v_mem;       // actual membrane potential
    reg [DATA_WIDTH-1:0] v_next;      // computed next value
    reg [3:0]            refrac_cnt;  // refractory countdown
    reg                  in_refrac;   // 1 = currently in refractory

    // ── Connect membrane to output pin ──────────────────────────
    assign v_mem_out = v_mem;

    // ── Zero-extend 8-bit input to 16 bits ─────────────────────
    wire [DATA_WIDTH-1:0] i_ext =
        {{(DATA_WIDTH-WEIGHT_WIDTH){1'b0}}, i_input};

    // ── COMBINATIONAL: compute next membrane potential ──────────
    always @(*) begin
        v_next = v_mem;  // default: hold current value

        if (!in_refrac) begin
            // Step 1: Apply leak  (V = V - V/16)
            v_next = v_mem - (v_mem >> LEAK_SHIFT);

            // Step 2: Integrate input current if valid
            if (i_valid)
                v_next = v_next + i_ext;

            // Step 3: Clamp to zero — prevent negative wrap-around
            if (v_next[DATA_WIDTH-1])
                v_next = {DATA_WIDTH{1'b0}};
        end
    end

    // ── SEQUENTIAL: register updates + spike generation ─────────
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            v_mem      <= V_RESET;
            spike_out  <= 1'b0;
            refrac_cnt <= 4'd0;
            in_refrac  <= 1'b0;

        end else if (!enable) begin
            spike_out <= 1'b0;

        end else begin
            spike_out <= 1'b0;

            if (in_refrac) begin
                if (refrac_cnt == 4'd0)
                    in_refrac <= 1'b0;
                else
                    refrac_cnt <= refrac_cnt - 1'b1;

            end else begin
                v_mem <= v_next;

                if (v_next >= THRESHOLD) begin
                    spike_out  <= 1'b1;
                    v_mem      <= V_RESET;
                    in_refrac  <= 1'b1;
                    refrac_cnt <= REFRACTORY-1;
                end
            end
        end
    end

endmodule