`timescale 1ns/1ps
`include "../src/SNU.sv"
`include "../src/NORM.sv"
`include "../src/MATMUL.sv"

module TASAD #(
    parameter N = 64
)(
    input  logic        clk1,
    input  logic        clk2,
    input  logic        rst,   
    input  logic [7:0]  Q,
    input  logic [7:0]  K,

    output logic [15:0] A,
    output logic        valid,
    output logic        Qbusy,
    output logic        Kbusy
);

    localparam DATA_WIDTH = 8;
    localparam ACC_WIDTH  = 16;

    // =========================================================================
    // 1. MASTER FSM
    // =========================================================================
    typedef enum logic [1:0] {
        ST_IDLE    = 2'd0,
        ST_START   = 2'd1,
        ST_PROCESS = 2'd2,
        ST_DONE    = 2'd3
    } top_state_t;

    top_state_t  top_state, top_next;
    logic        matmul_enable;
    logic [12:0] out_cnt; 
    logic        snu_valid_out;

    always_ff @(posedge clk1 or negedge rst) begin
        if (!rst) begin
            top_state <= ST_IDLE;
            out_cnt   <= 13'd0;
        end else begin
            top_state <= top_next;
            if (snu_valid_out) out_cnt <= out_cnt + 1'b1;
        end
    end

    always_comb begin
        top_next      = top_state;
        matmul_enable = 1'b0;

        case (top_state)
            ST_IDLE:    top_next = ST_START;
            ST_START: begin
                matmul_enable = 1'b1; 
                top_next      = ST_PROCESS;
            end
            ST_PROCESS: if (out_cnt == 13'd4096) top_next = ST_DONE;
            ST_DONE:    top_next = ST_DONE;
            default:    top_next = ST_IDLE;
        endcase
    end

    // =========================================================================
    // 2. MATMUL 
    // =========================================================================
    logic rom_q_oe, rom_k_oe;
    logic signed [ACC_WIDTH-1:0] mac_serial_out, best_score;
    logic mac_out_valid;

    assign Qbusy = ~rom_q_oe;
    assign Kbusy = ~rom_k_oe;

    MATMUL #(
        .N(N),
        .DATA_WIDTH(DATA_WIDTH),
        .ACC_WIDTH(ACC_WIDTH)
    ) u_matmul (
        .clk1            (clk1),
        .clk2            (clk2),
        .rst_n           (rst),
        .enable          (matmul_enable),
        .ROM_Q_Q         (Q),         
        .ROM_K_Q         (K),         
        .ROM_Q_OE        (rom_q_oe),  
        .ROM_K_OE        (rom_k_oe),  
        .best_score      (best_score), 
        .row_valid       (),          
        .mac_array_out   (),          
        .mac_array_valid (), 
        .done            (),
        .mac_serial_out  (mac_serial_out), 
        .mac_out_valid   (mac_out_valid)
    );

    // =========================================================================
    // 3. NORM 
    // =========================================================================
    logic [15:0] exp_data;
    logic        exp_valid;
    logic        softmax_busy;

    NORM u_norm (
        .clk             (clk1),
        .rst_n           (rst),
        .mac_out_valid   (mac_out_valid),
        .S_in            (mac_serial_out[15:0]), 
        .best_score_in   (best_score[15:0]),     
        .S_busy          (softmax_busy),
        .out_valid       (exp_valid),
        .exp_out         (exp_data)
    );

    // =========================================================================
    // 4. SNU (NORMALIZATION)
    // =========================================================================
    SNU #(
        .N(N)
    ) u_snu (
        .CLK             (clk1),
        .RST             (rst), 
        .in_valid        (exp_valid), 
        .S               (exp_data),  
        .A               (A),       
        .A_valid         (snu_valid_out)
    );

    assign valid = snu_valid_out;

endmodule