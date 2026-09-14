`timescale 1ns / 1ps

module black_scholes (
    input  logic        clk,
    input  logic        rst,
    input  logic        start,
    input  logic signed [15:0] S,
    input  logic signed [15:0] K,
    input  logic signed [15:0] r,
    input  logic signed [15:0] sigma,
    input  logic signed [15:0] T,

    output logic        done,
    output logic signed [15:0] call_price
);

    typedef enum logic [2:0] {
        IDLE, CALC1, CALC2, CALC3, CALC4, DONE
    } state_t;

    state_t state, next_state;

    // FSM state register
    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            state <= IDLE;
        else
            state <= next_state;
    end

    // FSM next-state logic
    always_comb begin
        next_state = state;
        case (state)
            IDLE:   if (start) next_state = CALC1;
            CALC1:  next_state = CALC2;
            CALC2:  next_state = CALC3;
            CALC3:  next_state = CALC4;
            CALC4:  next_state = DONE;
            DONE:   next_state = IDLE;
        endcase
    end

    // Intermediate sign-extended signals and registers
    logic signed [31:0] rate_term, sig_inter, r_inter, s_inter, k_inter;
    logic signed [31:0] numerator, denom;

    // Latched working inputs and outputs for math modules
    logic signed [31:0] ln_input;
    logic signed [15:0] sqrt_input, exp_input, norm1_input, norm2_input;
    logic signed [15:0] ln_result, sqrt_result, exp_result, norm1_result, norm2_result;

    // Module instantiations
    ln        ln_inst    (.x_in(ln_input[15:0]), .ln_out(ln_result));
    sqrt      sqrt_inst  (.x_in(sqrt_input),     .sqrt_out(sqrt_result));
    exp       exp_inst   (.x_in(exp_input),      .exp_out(exp_result));
    norm_cdf  norm1      (.x_in(norm1_input),    .n_out(norm1_result));
    norm_cdf  norm2      (.x_in(norm2_input),    .n_out(norm2_result));

    assign sig_inter = $signed(sigma);
    assign r_inter   = $signed(r);
    assign s_inter   = $signed(S);
    assign k_inter   = $signed(K);

    // State-based computation
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            done        <= 0;
            call_price  <= 0;
            rate_term   <= 0;
            numerator   <= 0;
            denom       <= 0;
            ln_input    <= 0;
            sqrt_input  <= 0;
            exp_input   <= 0;
            norm1_input <= 0;
            norm2_input <= 0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 0;
                end
                
                CALC1: begin
                    ln_input   <= (S <<< 10) / K;
                    sqrt_input <= T;
                    rate_term  <= r + ((sig_inter * sig_inter) >>> 11);
                end

                CALC2: begin
                    numerator <= ((rate_term * T) >>> 10) + ln_result;
                    denom     <= (sig_inter * sqrt_result) >>> 10;
                end

                CALC3: begin
                    exp_input   <= -((r_inter * T) >>> 10);
                    norm1_input <= ((numerator <<< 10) / denom) <<< 2;
                    norm2_input <= (((numerator <<< 10) / denom) - denom) <<< 2;
                end

                CALC4: begin
                    call_price <= ((s_inter * (norm1_result >>> 2)) >>> 10)
                                 - (((k_inter * exp_result) >>> 10) * (norm2_result >>> 2) >>> 10);
                end

                DONE: begin
                    done <= 1;
                end
            endcase
        end
    end

endmodule
