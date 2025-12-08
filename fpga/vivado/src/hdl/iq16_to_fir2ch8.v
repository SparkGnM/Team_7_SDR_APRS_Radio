`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/03/2025 03:34:41 PM
// Design Name: 
// Module Name: iq16_to_fir2ch8
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

// iq16_to_fir2ch8.v
// Unpacker for FIR input:
//   AXIS in  : 16-bit I/Q word  {I[15:8], Q[7:0]}
//   AXIS out : 8-bit samples, interleaved I, Q, I, Q, ...
//
// Use this module directly in front of the FIR Compiler
// configured as: Data width = 8, Number of channels = 2 (interleaved).


module iq16_to_fir2ch8 (
    input  wire        aclk,
    input  wire        aresetn,

    // AXIS input: 16-bit I/Q
    input  wire [15:0] s_axis_tdata,
    input  wire        s_axis_tvalid,
    output wire        s_axis_tready,
    input  wire        s_axis_tlast,

    // AXIS output: 8-bit interleaved samples to FIR
    output reg  [7:0]  m_axis_tdata,
    output reg         m_axis_tvalid,
    input  wire        m_axis_tready,
    output reg         m_axis_tlast
);

    // state: 0 = send I, 1 = send Q
    reg        phase;
    reg [15:0] iq_reg;
    reg        pair_valid;
    reg        tlast_reg;

    // We only accept a new 16-bit word when
    //  - we are not currently holding a pair, and
    //  - we are at the I phase (phase == 0).
    assign s_axis_tready = (!pair_valid) && (phase == 1'b0);

    always @(posedge aclk) begin
        if (!aresetn) begin
            phase         <= 1'b0;
            iq_reg        <= 16'd0;
            pair_valid    <= 1'b0;
            tlast_reg     <= 1'b0;
            m_axis_tdata  <= 8'd0;
            m_axis_tvalid <= 1'b0;
            m_axis_tlast  <= 1'b0;
        end else begin
            // defaults
            m_axis_tvalid <= 1'b0;
            m_axis_tlast  <= 1'b0;

            // Latch a new I/Q pair when upstream provides one
            if (s_axis_tvalid && s_axis_tready) begin
                iq_reg     <= s_axis_tdata;
                tlast_reg  <= s_axis_tlast;
                pair_valid <= 1'b1;
            end

            // If we have a pair to send and FIR is ready, output I then Q
            if (pair_valid && m_axis_tready) begin
                if (phase == 1'b0) begin
                    // Send I (upper 8 bits) - channel 0
                    m_axis_tdata  <= iq_reg[15:8];
                    m_axis_tvalid <= 1'b1;
                    phase         <= 1'b1;   // next beat: Q
                    // TLAST only asserted on the Q beat
                end else begin
                    // Send Q (lower 8 bits) - channel 1
                    m_axis_tdata  <= iq_reg[7:0];
                    m_axis_tvalid <= 1'b1;
                    m_axis_tlast  <= tlast_reg; // TLAST belongs to the pair
                    phase         <= 1'b0;      // back to I for the next pair
                    pair_valid    <= 1'b0;      // this pair is done
                end
            end
        end
    end
endmodule
