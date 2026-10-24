// =============================================================================
// File Name   : Lab4_Softmax.sv
// Description : Lab 4 - Softmax with Max Subtraction
// =============================================================================

module NORM (
    input  logic               clk,
    input  logic               rst_n,         
    input  logic               mac_out_valid, 
    input  logic signed [15:0] S_in,          
    input  logic signed [15:0] best_score_in, 
    output logic               S_busy,        
    output logic               out_valid,     
    output logic        [15:0] exp_out        
);

    typedef enum logic [1:0] {
        IDLE    = 2'b00,
        LOAD    = 2'b01,
        PROCESS = 2'b10,
        DONE    = 2'b11
    } state_t;

    state_t state, next_state;
    logic [6:0] cnt; 
    logic signed [15:0] reg_file [0:63];
    logic signed [15:0] M_i; 
    
    logic signed [16:0] S; 
    logic        [15:0] lut_out;

    // FSM Next State Logic
    always_comb begin
        case (state)
            IDLE:    next_state = LOAD;
            LOAD:    next_state = (cnt == 7'd63 && mac_out_valid) ? PROCESS : LOAD;
            PROCESS: next_state = (cnt == 7'd63) ? DONE : PROCESS;
            DONE:    next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end

    // Sequential Logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state     <= IDLE;
            cnt       <= 7'd0;
            S_busy    <= 1'b1;
            out_valid <= 1'b0;
            exp_out   <= 16'd0;
            M_i       <= 16'sd0;
            for (int i = 0; i < 64; i++) reg_file[i] <= 16'd0;
        end else begin
            state  <= next_state;
            S_busy <= (next_state == LOAD) ? 1'b0 : 1'b1;
            
            case (state)
                IDLE: begin
                    cnt       <= 7'd0;
                    out_valid <= 1'b0;
                end
                LOAD: begin
                    if (mac_out_valid) begin
                        reg_file[cnt] <= S_in;
                        if (cnt == 7'd0)  M_i <= best_score_in;
                        cnt <= (cnt == 7'd63) ? 7'd0 : cnt + 1'b1;
                    end
                end
                PROCESS: begin
                    out_valid <= 1'b1;
                    exp_out   <= lut_out;
                    cnt       <= (cnt == 7'd63) ? 7'd0 : cnt + 1'b1;
                end
                DONE: begin
                    out_valid <= 1'b0;
                    cnt       <= 7'd0;
                end
            endcase
        end
    end

    // Datapath Computations
    assign S = (($signed(reg_file[cnt])) - ($signed(M_i))) / 8;

    // Look-Up Table (LUT)
    always_comb begin
        case (S)
             17'sd0:  lut_out = 16'h8000;
            -17'sd1:  lut_out = 16'h2F17;
            -17'sd2:  lut_out = 16'h1153;
            -17'sd3:  lut_out = 16'h065F;
            -17'sd4:  lut_out = 16'h0258;
            -17'sd5:  lut_out = 16'h00DD;
            -17'sd6:  lut_out = 16'h0051; 
            -17'sd7:  lut_out = 16'h001E; 
            -17'sd8:  lut_out = 16'h000B;
            -17'sd9:  lut_out = 16'h0004;
            -17'sd10: lut_out = 16'h0001;
            default:  lut_out = 16'h0000; 
        endcase
    end

endmodule