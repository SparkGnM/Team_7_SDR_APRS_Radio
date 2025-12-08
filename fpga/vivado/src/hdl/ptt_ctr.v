`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/04/2025 12:39:24 AM
// Design Name: 
// Module Name: ptt_ctr
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


// ptt_ctrl.v
// Simple push-to-talk controller.
// BTN2 (active-high) -> tx_active signal.
// While button held: tx_active=1 (TX mode), else 0 (RX mode).

module ptt_ctrl #(
    parameter integer DEBOUNCE_CYCLES = 1_000_000  // adjust for your clk (e.g. ~10ms at 100MHz)
)(
    input  wire clk,
    input  wire resetn,      // active-low
    input  wire ptt_btn,     // raw button (BTN2)
    output reg  tx_active    // 1 = TX mode, 0 = RX mode
);

    // sync + simple debounce
    reg btn_sync0, btn_sync1;
    reg [$clog2(DEBOUNCE_CYCLES):0] db_cnt;
    reg btn_stable;

    always @(posedge clk) begin
        if (!resetn) begin
            btn_sync0  <= 1'b0;
            btn_sync1  <= 1'b0;
            btn_stable <= 1'b0;
            db_cnt     <= 0;
        end else begin
            // 2-flop sync
            btn_sync0 <= ptt_btn;
            btn_sync1 <= btn_sync0;

            // debouncer: increment while level is constant
            if (btn_sync1 == btn_stable) begin
                db_cnt <= 0;
            end else begin
                if (db_cnt == DEBOUNCE_CYCLES) begin
                    btn_stable <= btn_sync1;
                    db_cnt     <= 0;
                end else begin
                    db_cnt <= db_cnt + 1'b1;
                end
            end
        end
    end

    // While button is stably pressed -> TX
    always @(posedge clk) begin
        if (!resetn)
            tx_active <= 1'b0;
        else
            tx_active <= btn_stable;
    end

endmodule
