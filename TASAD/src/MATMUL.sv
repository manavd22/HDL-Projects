`timescale 1ns/1ps

module MATMUL #(
    parameter N           = 64,
    parameter INDEX_WIDTH = 6,
    parameter ADDR_WIDTH  = 12,
    parameter DATA_WIDTH  = 8,
    parameter ACC_WIDTH   = 16
)(
    input  logic                                clk1, 
    input  logic                                clk2, 
    input  logic                                rst_n,
    input  logic                                enable,

    input  logic signed [DATA_WIDTH-1:0]        ROM_Q_Q,
    input  logic signed [DATA_WIDTH-1:0]        ROM_K_Q,

    output logic                                ROM_Q_OE,
    output logic                                ROM_K_OE,

    output logic signed [ACC_WIDTH-1:0]         best_score, 
    output logic                                row_valid, 

    output logic signed [ACC_WIDTH-1:0]         mac_array_out [0:N-1],
    output logic                                mac_array_valid,
    output logic                                done,

    output logic signed [ACC_WIDTH-1:0]         mac_serial_out,
    output logic                                mac_out_valid
);

    // 1. CLOCK DOMAIN CROSSING
    logic req_load_clk1;
    logic [1:0] req_load_sync; 
    
    always_ff @(posedge clk2 or negedge rst_n) begin
        if(!rst_n) req_load_sync <= 2'b00;
        else       req_load_sync <= {req_load_sync[0], req_load_clk1};
    end

    // 2. LOAD K_MATRIX
    logic signed [DATA_WIDTH-1:0] k_mem [0:N-1][0:N-1];
    logic [INDEX_WIDTH-1:0] wr_row, wr_col;
    logic [1:0] state_clk2;
    logic load_k_done;

    always_ff @(posedge clk2 or negedge rst_n) begin
        if(!rst_n) begin
            wr_row      <= '0;
            wr_col      <= '0;
            ROM_K_OE    <= 1'b0;
            state_clk2  <= '0;
            load_k_done <= 1'b0;
        end else begin
            case(state_clk2)
                0: begin 
                    if(req_load_sync[1] && !load_k_done) begin 
                        ROM_K_OE   <= 1'b1; 
                        wr_row     <= '0;
                        wr_col     <= '0;
                        state_clk2 <= 2'd1; 
                    end
                end
                1: state_clk2 <= 2'd2; 
                2: begin 
                    k_mem[wr_row][wr_col] <= ROM_K_Q; 
                    if (wr_col == N-2 && wr_row == N-1) ROM_K_OE <= 1'b0; 
                    
                    if(wr_col == N-1) begin
                        wr_col <= '0;
                        if(wr_row == N-1) begin
                            state_clk2  <= 2'd3; 
                            load_k_done <= 1'b1;
                        end else begin
                            wr_row <= wr_row + 1'b1;
                        end
                    end else begin
                        wr_col <= wr_col + 1'b1;
                    end
                end
                3: /* Hold state */ ;
            endcase
        end
    end

    logic [1:0] k_done_sync;
    always_ff @(posedge clk1 or negedge rst_n) begin
        if(!rst_n) k_done_sync <= 2'b00;
        else       k_done_sync <= {k_done_sync[0], load_k_done};
    end

    // 3. COMBINATIONAL LOGIC: MAX TREE
    logic signed [ACC_WIDTH-1:0] max_lvl1 [0:7];
    logic signed [ACC_WIDTH-1:0] next_max_lvl1 [0:7];
    logic signed [ACC_WIDTH-1:0] next_best_score;

    always_comb begin
        for (int idx = 0; idx < 8; idx++) begin
            next_max_lvl1[idx] = mac_array_out[idx*8];
            for (int k = 1; k < 8; k++) begin
                if ($signed(mac_array_out[idx*8+k]) > $signed(next_max_lvl1[idx])) begin
                    next_max_lvl1[idx] = mac_array_out[idx*8+k];
                end
            end
        end

        next_best_score = max_lvl1[0];
        for (int k = 1; k < 8; k++) begin
            if ($signed(max_lvl1[k]) > $signed(next_best_score)) begin
                next_best_score = max_lvl1[k];
            end
        end
    end

    // 4. FSM & MAC ARRAY
    typedef enum logic [2:0] {
        S_IDLE       = 3'd0,
        S_WAIT_K     = 3'd1,
        S_WAIT_ROM_Q = 3'd2, 
        S_MAC        = 3'd3,
        S_MAX_TREE_1 = 3'd4, 
        S_MAX_TREE_2 = 3'd5, 
        S_STREAM     = 3'd6, 
        S_DONE       = 3'd7
    } mac_state_t;

    mac_state_t state_clk1;
    logic [5:0] row_cnt, step_cnt, stream_cnt;   
    logic signed [DATA_WIDTH-1:0] k_read [0:N-1];

    generate
        for(genvar g=0; g<N; g++) begin : K_BANKS
            assign k_read[g] = k_mem[g][step_cnt];
        end
    endgenerate

    always_ff @(posedge clk1 or negedge rst_n) begin
        if(!rst_n) begin
            state_clk1      <= S_IDLE;
            req_load_clk1   <= 1'b0;
            ROM_Q_OE        <= 1'b0;
            best_score      <= '0;
            row_cnt         <= '0;
            step_cnt        <= '0;
            row_valid       <= 1'b0;
            mac_array_valid <= 1'b0;
            mac_out_valid   <= 1'b0;
            done            <= 1'b0;
            mac_serial_out  <= '0;
            stream_cnt      <= '0;
            for(int i=0; i<N; i++) mac_array_out[i] <= '0;
            for(int i=0; i<8; i++) max_lvl1[i]      <= '0;
        end else begin
            mac_out_valid   <= 1'b0; 
            row_valid       <= 1'b0;
            mac_array_valid <= 1'b0;
            
            case(state_clk1)
                S_IDLE: begin
                    if(enable) begin
                        req_load_clk1 <= 1'b1; 
                        state_clk1    <= S_WAIT_K;
                        row_cnt       <= '0;
                    end
                end
                
                S_WAIT_K: begin 
                    if (k_done_sync[1]) begin
                        ROM_Q_OE   <= 1'b1; 
                        state_clk1 <= S_WAIT_ROM_Q;
                    end
                end

                S_WAIT_ROM_Q: begin
                    state_clk1 <= S_MAC;
                    step_cnt   <= '0;
                end
                
                S_MAC: begin
                    for (int i=0; i<N; i++) begin
                        if (step_cnt == 0)
                            mac_array_out[i] <= $signed(ROM_Q_Q) * $signed(k_read[i]); 
                        else
                            mac_array_out[i] <= $signed(mac_array_out[i]) + ($signed(ROM_Q_Q) * $signed(k_read[i])); 
                    end

                    if (step_cnt == 62) ROM_Q_OE <= 1'b0; 

                    if (step_cnt == 63) begin
                        state_clk1      <= S_MAX_TREE_1;
                        mac_array_valid <= 1'b1; 
                    end else begin
                        step_cnt <= step_cnt + 1'b1;
                    end
                end

                S_MAX_TREE_1: begin
                    for (int i=0; i<8; i++) max_lvl1[i] <= next_max_lvl1[i];
                    state_clk1 <= S_MAX_TREE_2;
                end

                S_MAX_TREE_2: begin
                    best_score <= next_best_score;
                    row_valid  <= 1'b1; 
                    state_clk1 <= S_STREAM;
                    stream_cnt <= '0;
                end

                S_STREAM: begin
                    mac_serial_out <= mac_array_out[stream_cnt];
                    mac_out_valid  <= 1'b1;

                    if (stream_cnt == 63) begin
                        if (row_cnt == 63) begin
                            state_clk1 <= S_DONE; 
                        end else begin
                            row_cnt    <= row_cnt + 1'b1;
                            ROM_Q_OE   <= 1'b1;   
                            state_clk1 <= S_WAIT_ROM_Q;
                        end
                    end else begin
                        stream_cnt <= stream_cnt + 1'b1;
                    end
                end

                S_DONE: done <= 1'b1;
            endcase
        end
    end
endmodule