// axis_ptt_gate.v
// Gating block for AXI4-Stream using a push-to-talk enable.
// When ptt_en = 1: passes s_axis -> m_axis.
// When ptt_en = 0: m_axis_tvalid = 0, s_axis_tready = 0 (backpressure upstream).

`timescale 1ns/1ps

module axis_ptt_gate #(
    parameter integer DATA_WIDTH = 16
)(
    input  wire                     aclk,
    input  wire                     aresetn,   // active-low

    input  wire                     ptt_en,    // 1 = allow TX, 0 = block

    // Slave AXI-Stream (from TX FIR)
    input  wire [DATA_WIDTH-1:0]    s_axis_tdata,
    input  wire                     s_axis_tvalid,
    output wire                     s_axis_tready,
    input  wire                     s_axis_tlast,

    // Master AXI-Stream (to DAC)
    output wire [DATA_WIDTH-1:0]    m_axis_tdata,
    output wire                     m_axis_tvalid,
    input  wire                     m_axis_tready,
    output wire                     m_axis_tlast
);

    // When disabled: hold s_axis_tready low to apply backpressure,
    // and deassert m_axis_tvalid so downstream sees idle.
    assign s_axis_tready = ptt_en ? m_axis_tready : 1'b0;
    assign m_axis_tdata  = s_axis_tdata;
    assign m_axis_tlast  = s_axis_tlast;
    assign m_axis_tvalid = ptt_en ? s_axis_tvalid : 1'b0;

endmodule
