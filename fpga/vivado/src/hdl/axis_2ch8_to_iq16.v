`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/03/2025 03:42:36 PM
// Design Name: 
// Module Name: axis_2ch8_to_iq16
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


// axis_2ch8_to_iq16.v
// Convert 8-bit interleaved I/Q AXIS stream (from 2-channel FIR)
// into a 16-bit I/Q AXIS stream: {I[15:8], Q[7:0]}.
//
// Assumes FIR is configured as:
//   - Input/Output data width = 8 bits
//   - Number of channels      = 2 (interleaved/basic)
//
// Input sequence (s_axis_tdata):
//   cycle 0: I0
//   cycle 1: Q0
//   cycle 2: I1
//   cycle 3: Q1
//   ...
//
// Output sequence (m_axis_tdata):
//   beat 0: {I0, Q0}
//   beat 1: {I1, Q1}
//   ...


module axis_2ch8_to_iq16 (
    input  wire        aclk,
    input  wire        aresetn,

    // AXIS input: 8-bit interleaved I/Q from FIR
    input  wire [7:0]  s_axis_tdata,
    input  wire        s_axis_tvalid,
    output wire        s_axis_tready,
    input  wire        s_axis_tlast,

    // AXIS output: 16-bit I/Q pairs
    output reg  [15:0] m_axis_tdata,
    output reg         m_axis_tvalid,
    input  wire        m_axis_tready,
    output reg         m_axis_tlast
);

    // state 0: expecting I sample
    // state 1: expecting Q sample (and will output {I,Q} pair)
    reg       state;
    reg [7:0] i_reg;

    // We can always accept an I sample.
    // For the Q sample, only accept when we know downstream is ready
    // to take the combined 16-bit pair.
    assign s_axis_tready = (state == 1'b0) ? 1'b1 : m_axis_tready;

    always @(posedge aclk) begin
        if (!aresetn) begin
            state        <= 1'b0;
            i_reg        <= 8'd0;
            m_axis_tdata <= 16'd0;
            m_axis_tvalid<= 1'b0;
            m_axis_tlast <= 1'b0;
        end else begin
            // default outputs
            m_axis_tvalid <= 1'b0;
            m_axis_tlast  <= 1'b0;

            if (s_axis_tvalid && s_axis_tready) begin
                if (state == 1'b0) begin
                    // This sample is I (channel 0)
                    i_reg <= s_axis_tdata;
                    state <= 1'b1;
                end else begin
                    // This sample is Q (channel 1)
                    // Now we can output the full {I,Q} pair
                    m_axis_tdata  <= {i_reg, s_axis_tdata};
                    m_axis_tvalid <= 1'b1;
                    m_axis_tlast  <= s_axis_tlast; // TLAST aligned to the pair
                    state         <= 1'b0;
                end
            end
        end
    end

endmodule
