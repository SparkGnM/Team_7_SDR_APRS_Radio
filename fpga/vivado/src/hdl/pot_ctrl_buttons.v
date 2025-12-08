// mcp41hv51_btn_ctrl.v
// Single self-contained block to control MCP41HV51 digipot using board buttons.
//
// - Default wiper ≈ 16/18 of full scale (≈ 88.9%), code ≈ 227
// - btns[1] (BTN1) : increment wiper (frequency up)
// - btns[0] (BTN0) : decrement wiper (frequency down)
// - Internal SPI engine (mode 0)
//
// Hook up in BD:
//   clk      = your PL clock (e.g., 100 MHz)
//   resetn   = active-low reset for that clock domain
//   btns[3:0]= btns_4bits external port (BTN0..BTN3)
//   pot_cs_n, pot_sck, pot_mosi -> MCP41HV51 CS, SCK, SDI

`timescale 1ns/1ps

module mcp41hv51_btn_ctrl #(
    // System clock configuration:
    // SCK_DIV = number of clk cycles per half SCK period.
    // Example: clk=100MHz, SCK_DIV=10 -> SCK ≈ 5 MHz
    parameter integer SCK_DIV = 10
)(
    input  wire        clk,
    input  wire        resetn,     // active-low

    input  wire [3:0]  btns,       // btns[0]=BTN0 (down), btns[1]=BTN1 (up)

    // SPI to MCP41HV51
    output reg         pot_cs_n,
    output reg         pot_sck,
    output reg         pot_mosi
);

    // ============================================================
    // 1) Default wiper value: ~16/18 of full-scale
    // ============================================================
    // Ideal D ≈ 255 * (16/18) ≈ 226.7 -> use 227 (0xE3)
    localparam [7:0] DEFAULT_WIPER = 8'd227;

    reg [7:0] wiper_value;

    // ============================================================
    // 2) Button sync + edge detect (BTN0 = down, BTN1 = up)
    // ============================================================
    reg btn0_d0, btn0_d1;
    reg btn1_d0, btn1_d1;

    always @(posedge clk) begin
        if (!resetn) begin
            btn0_d0 <= 1'b0;
            btn0_d1 <= 1'b0;
            btn1_d0 <= 1'b0;
            btn1_d1 <= 1'b0;
        end else begin
            btn0_d0 <= btns[0];
            btn0_d1 <= btn0_d0;

            btn1_d0 <= btns[1];
            btn1_d1 <= btn1_d0;
        end
    end

    wire down_rise =  btn0_d0 & ~btn0_d1; // BTN0 rising edge
    wire up_rise   =  btn1_d0 & ~btn1_d1; // BTN1 rising edge

    // ============================================================
    // 3) Wiper update logic
    // ============================================================
    // Simple +/-1 per button press, saturates at 0..255.
    always @(posedge clk) begin
        if (!resetn) begin
            wiper_value <= DEFAULT_WIPER;
        end else begin
            if (up_rise && !down_rise) begin
                if (wiper_value != 8'hFF)
                    wiper_value <= wiper_value + 1'b1;
            end else if (down_rise && !up_rise) begin
                if (wiper_value != 8'h00)
                    wiper_value <= wiper_value - 1'b1;
            end
            // If both pressed at once, ignore (no change)
        end
    end

    // ============================================================
    // 4) SPI engine internals (mode 0)
    // ============================================================
    // Sends 16 bits: {command_byte, data_byte} = {8'h00, wiper_value}
    // MCP41HV51 command for "Write Wiper 0" is 0x00.

    // SPI FSM states
    localparam [1:0] SPI_IDLE   = 2'd0;
    localparam [1:0] SPI_LOAD   = 2'd1;
    localparam [1:0] SPI_TRANS  = 2'd2;
    localparam [1:0] SPI_FINISH = 2'd3;

    reg [1:0]  spi_state;
    reg [15:0] shift_reg;
    reg [4:0]  bit_cnt;      // counts 16 down to 0
    reg [15:0] div_cnt;      // clock divider
    reg        spi_busy;
    reg        start_req;    // internal start trigger
    reg        change_pending;

    wire div_hit = (div_cnt == SCK_DIV-1);

    // 16-bit frame for the SPI transfer
    wire [15:0] frame;
    assign frame = {8'h00, wiper_value};

    // Generate "start_req" when a button changes wiper_value.
    // If SPI is busy, remember one pending change.
    always @(posedge clk) begin
        if (!resetn) begin
            start_req      <= 1'b0;
            change_pending <= 1'b0;
        end else begin
            start_req <= 1'b0; // default

            // New button event that changed the wiper
            if (up_rise || down_rise) begin
                if (!spi_busy) begin
                    // If idle, trigger immediately
                    start_req      <= 1'b1;
                    change_pending <= 1'b0;
                end else begin
                    // SPI busy -> remember one pending update
                    change_pending <= 1'b1;
                end
            end else if (change_pending && !spi_busy) begin
                // SPI freed up, send the pending value
                start_req      <= 1'b1;
                change_pending <= 1'b0;
            end
        end
    end

    // SPI FSM
    always @(posedge clk) begin
        if (!resetn) begin
            spi_state  <= SPI_IDLE;
            pot_cs_n   <= 1'b1;
            pot_sck    <= 1'b0;
            pot_mosi   <= 1'b0;
            spi_busy   <= 1'b0;
            bit_cnt    <= 5'd0;
            shift_reg  <= 16'd0;
            div_cnt    <= 16'd0;
        end else begin
            case (spi_state)
                SPI_IDLE: begin
                    pot_cs_n  <= 1'b1;
                    pot_sck   <= 1'b0;
                    spi_busy  <= 1'b0;
                    div_cnt   <= 16'd0;

                    if (start_req) begin
                        spi_state <= SPI_LOAD;
                    end
                end

                SPI_LOAD: begin
                    // Build frame {command, data} = {8'h00, wiper_value}
                    shift_reg <= frame;
                    bit_cnt   <= 5'd16;
                    pot_cs_n  <= 1'b0;   // select device
                    pot_sck   <= 1'b0;
                    spi_busy  <= 1'b1;

                    // Present first bit (MSB) on MOSI
                    pot_mosi  <= frame[15];

                    spi_state <= SPI_TRANS;
                end

                SPI_TRANS: begin
                    if (div_hit) begin
                        div_cnt <= 16'd0;
                        pot_sck <= ~pot_sck;

                        if (pot_sck == 1'b0) begin
                            // rising edge about to occur (0->1):
                            // MCP samples MOSI on rising edge in mode 0.
                            // Data already stable from prior falling edge.
                        end else begin
                            // 1->0: falling edge, shift to next bit
                            bit_cnt <= bit_cnt - 1'b1;

                            if (bit_cnt > 1) begin
                                // Shift left, MSB first
                                shift_reg <= {shift_reg[14:0], 1'b0};
                                pot_mosi  <= shift_reg[14]; // next MSB
                            end else begin
                                // All bits have been sent
                                spi_state <= SPI_FINISH;
                            end
                        end
                    end else begin
                        div_cnt <= div_cnt + 1'b1;
                    end
                end

                SPI_FINISH: begin
                    pot_cs_n  <= 1'b1;   // de-select
                    pot_sck   <= 1'b0;
                    spi_busy  <= 1'b0;
                    spi_state <= SPI_IDLE;
                end

                default: spi_state <= SPI_IDLE;
            endcase
        end
    end

endmodule
