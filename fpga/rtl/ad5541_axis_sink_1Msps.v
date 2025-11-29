`timescale 1ns / 1ps
// ============================================================================
// AD5541 AXI-Stream Sink Wrapper (3-wire SPI, ~1.04 MSPS @ 100 MHz)
//
// - Consumes 16-bit words on s_axis_*.
// - Shifts them MSB-first on DIN with 16 SCLK pulses while CS is low.
// - Back-pressures upstream via s_axis_tready while busy.
//
// Fabric clock: 100 MHz
//   SCLK_DIV = 3 -> SCLK = 100 MHz / (2*3) = 16.67 MHz
//   Update rate ≈ SCLK / 16 ≈ 1.04 MSPS
// ============================================================================

module ad5541_axis_sink_1Msps (
    input  wire        clk,          // 100 MHz fabric clock
    input  wire        rst_n,        // active-low reset

    // AXI-Stream slave (from TX FIR)
    input  wire [15:0] s_axis_tdata,
    input  wire        s_axis_tvalid,
    output reg         s_axis_tready,

    // AD5541 interface
    output reg         dac_cs_n,
    output reg         dac_sclk,
    output reg         dac_din
);

    localparam integer SCLK_DIV = 3;

    localparam [1:0]
        ST_IDLE  = 2'd0,
        ST_SHIFT = 2'd1;

    reg [1:0]  state;

    // SCLK divider
    reg [$clog2(SCLK_DIV)-1:0] div_cnt;
    wire                       tick = (div_cnt == 0);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            div_cnt <= 0;
        else
            div_cnt <= div_cnt + 1'b1;
    end

    reg [15:0] shift_reg;
    reg [4:0]  bit_cnt;   // up to 16 bits

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state         <= ST_IDLE;
            dac_cs_n      <= 1'b1;
            dac_sclk      <= 1'b0;
            dac_din       <= 1'b0;
            s_axis_tready <= 1'b1;
            shift_reg     <= 16'd0;
            bit_cnt       <= 0;
        end else begin
            case (state)
                // -----------------------------------------------------
                ST_IDLE: begin
                    dac_cs_n      <= 1'b1;
                    dac_sclk      <= 1'b0;
                    s_axis_tready <= 1'b1;

                    if (s_axis_tvalid) begin
                        // latch new sample
                        shift_reg     <= s_axis_tdata;
                        bit_cnt       <= 16;
                        s_axis_tready <= 1'b0;   // busy now
                        dac_cs_n      <= 1'b0;   // start frame
                        state         <= ST_SHIFT;
                    end
                end

                // -----------------------------------------------------
                ST_SHIFT: begin
                    if (tick) begin
                        dac_sclk <= ~dac_sclk;

                        if (dac_sclk == 1'b0) begin
                            // on SCLK low: present next bit (MSB first)
                            dac_din   <= shift_reg[15];
                            shift_reg <= {shift_reg[14:0], 1'b0};
                        end else begin
                            // on SCLK rising edge: DAC latches DIN
                            bit_cnt <= bit_cnt - 1'b1;

                            if (bit_cnt == 1) begin
                                // last bit latched; end frame
                                dac_cs_n      <= 1'b1;
                                dac_sclk      <= 1'b0;
                                s_axis_tready <= 1'b1;
                                state         <= ST_IDLE;
                            end
                        end
                    end
                end

                default: state <= ST_IDLE;
            endcase
        end
    end

endmodule
