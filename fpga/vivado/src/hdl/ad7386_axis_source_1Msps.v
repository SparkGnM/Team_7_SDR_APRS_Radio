`timescale 1ns / 1ps
// ============================================================================
// AD7386-4 AXI-Stream Source Wrapper (1-wire SDOA, ~1.0 MSPS @ 100 MHz)
//
// - Uses only SDOA (single channel).
// - CS falling edge starts conversion & frame.
// - 16 SCLK pulses per sample, plus a small CS-high gap.
// - Streams 16-bit samples out on m_axis_*.
//
// Fabric clock: 100 MHz
// Effective params for ~1.0 MSPS:
//   SCLK_DIV  = 3  -> SCLK = 100 MHz / (2 * 3) = 16.67 MHz
//   FRAME_GAP = 4  -> 32*3 + 4 = 100 clk cycles per sample -> 1.0 MSPS
// ============================================================================

module ad7386_axis_source_1Msps (
    input  wire        clk,          // 100 MHz fabric clock
    input  wire        rst_n,        // active-low reset

    // AD7386 digital interface
    output reg         adc_cs_n,
    output reg         adc_sclk,
    input  wire        adc_sdoa,

    // AXI-Stream master (to RX FIR / AXIS switch)
    output reg [15:0]  m_axis_tdata,
    output reg         m_axis_tvalid,
    input  wire        m_axis_tready
);

    // --- local timing parameters for 100 MHz fabric clock ---
    localparam integer SCLK_DIV  = 3;  // fabric_clk / (2*SCLK_DIV) = SCLK
    localparam integer FRAME_GAP = 4;  // CS-high cycles between frames

    localparam [1:0]
        ST_IDLE  = 2'd0,
        ST_SHIFT = 2'd1,
        ST_HOLD  = 2'd2;

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

    // bit counter and shifter
    reg [5:0]   bit_cnt;     // up to 16 bits
    reg [15:0]  shift_reg;

    // CS-high gap counter
    reg [$clog2(FRAME_GAP+1)-1:0] gap_cnt;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state         <= ST_IDLE;
            adc_cs_n      <= 1'b1;
            adc_sclk      <= 1'b0;
            bit_cnt       <= 0;
            shift_reg     <= 16'd0;
            gap_cnt       <= 0;
            m_axis_tdata  <= 16'd0;
            m_axis_tvalid <= 1'b0;
        end else begin
            // default
            m_axis_tvalid <= 1'b0;

            case (state)
                // -----------------------------------------------------
                ST_IDLE: begin
                    adc_cs_n <= 1'b1;
                    adc_sclk <= 1'b0;

                    if (gap_cnt < FRAME_GAP) begin
                        gap_cnt <= gap_cnt + 1'b1;
                    end else if (m_axis_tready) begin
                        // start new frame / conversion
                        adc_cs_n <= 1'b0;   // falling edge starts convert
                        bit_cnt  <= 0;
                        gap_cnt  <= 0;
                        state    <= ST_SHIFT;
                    end
                end

                // -----------------------------------------------------
                ST_SHIFT: begin
                    if (tick) begin
                        adc_sclk <= ~adc_sclk;

                        if (adc_sclk == 1'b0) begin
                            // rising edge: sample SDOA into shift_reg
                            shift_reg <= {shift_reg[14:0], adc_sdoa};
                            bit_cnt   <= bit_cnt + 1'b1;

                            if (bit_cnt == 15) begin
                                // got 16 bits
                                adc_cs_n     <= 1'b1; // end frame
                                adc_sclk     <= 1'b0;
                                m_axis_tdata <= {shift_reg[14:0], adc_sdoa};
                                m_axis_tvalid<= 1'b1;
                                state        <= ST_HOLD;
                            end
                        end
                    end
                end

                // -----------------------------------------------------
                ST_HOLD: begin
                    // keep tvalid high until downstream accepts the word
                    if (m_axis_tready) begin
                        m_axis_tvalid <= 1'b0;
                        state         <= ST_IDLE;
                    end else begin
                        m_axis_tvalid <= 1'b1;
                    end
                end

                default: state <= ST_IDLE;
            endcase
        end
    end

endmodule
