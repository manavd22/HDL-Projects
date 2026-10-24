`timescale 1ns/1ps
`include "clock_config.vh"

`ifdef SYN
    `include "../syn/TASAD_syn.v"
    `include "/usr/cad/CBDK/Nangate45/2010.12/Front_End/Verilog/NangateOpenCellLibrary.v"
`else
    `include "../src/TASAD.sv"
`endif

`include "ROM.v"
`include "SRAM.sv"

module tb_tasad_application;
    localparam integer DATA_NUM   = 4096;
    localparam integer ADDR_WIDTH = 12;

    logic clk1;
    logic clk2;
    logic rst;

    wire [7:0]  Q;
    wire [7:0]  K;
    wire [15:0] A;
    wire        valid;
    wire        Qbusy;
    wire        Kbusy;

    logic [ADDR_WIDTH-1:0] Q_ROM_A;
    logic [ADDR_WIDTH-1:0] K_ROM_A;
    logic [ADDR_WIDTH-1:0] A_SRAM_A;

    wire        Q_ROM_OE = ~Qbusy;
    wire        K_ROM_OE = ~Kbusy;
    wire        A_SRAM_WEB = ~valid;
    wire [15:0] Q_ROM_DO;
    wire [15:0] K_ROM_DO;
    wire [15:0] A_SRAM_Q;

    assign Q = Q_ROM_DO[7:0];
    assign K = K_ROM_DO[7:0];

    logic [7:0] q_pattern [0:DATA_NUM-1];
    logic [7:0] k_pattern [0:DATA_NUM-1];
`ifdef CHECK_GOLDEN
    logic [15:0] golden_mem [0:DATA_NUM-1];
    integer match_count;
    integer mismatch_count;
    string golden_file;
`endif

    integer i;
    integer q_read_count;
    integer k_read_count;
    integer a_write_count;
    integer clk1_cycles;
    integer a_file_handle;
    string q_file;
    string k_file;
    string a_file;



    TASAD dut (
        .clk1  (clk1),
        .clk2  (clk2),
        .rst   (~rst),
        .Q     (Q),
        .K     (K),
        .A     (A),
        .valid (valid),
        .Qbusy (Qbusy),
        .Kbusy (Kbusy)
    );

    ROM #(.addr_size(ADDR_WIDTH), .mem_size(DATA_NUM), .Bits(8), .Bytes(2)) ROM_Q (
        .CK(clk1), .CS(1'b1), .OE(Q_ROM_OE), .A(Q_ROM_A), .DO(Q_ROM_DO)
    );

    ROM #(.addr_size(ADDR_WIDTH), .mem_size(DATA_NUM), .Bits(8), .Bytes(2)) ROM_K (
        .CK(clk2), .CS(1'b1), .OE(K_ROM_OE), .A(K_ROM_A), .DO(K_ROM_DO)
    );

    SRAM #(.WORDS(DATA_NUM), .DATA_WIDTH(16), .ADDR_WIDTH(ADDR_WIDTH)) SRAM_A_MEM (
        .CK(clk1), .CEB(1'b0), .WEB(A_SRAM_WEB),
        .A(A_SRAM_A), .D(A), .Q(A_SRAM_Q)
    );

    initial clk1 = 1'b0;
    always #(`CYCLE1 / 2.0) clk1 = ~clk1;

    initial clk2 = 1'b0;
    always #(`CYCLE2 / 2.0) clk2 = ~clk2;

    task automatic print_processing_pass;
        begin
            $display("\n");
            $display("        **************************             /\\       /\\");
            $display("        *                        *            /  \\_____/  \\");
            $display("        *  Congratulations !!    *           /             \\");
            $display("        *                        *          |    ||   ||    |");
`ifdef RTL_CORRECT
            $display("        *  Simulation PASS !!    *          |    ||   ||    |");
`else
            $display("        *  Processing PASS !!    *          |    ||   ||    |");
`endif
            $display("        *                        *          |       ^       |");
`ifdef SYN
            $display("        *      SYN LEVEL         *          |  ==  \\_/  ==  |");
`else
            $display("        *      RTL LEVEL         *          |  ==  \\_/  ==  |");
`endif
            $display("        **************************           \\     _w_     /");
            $display("                                              '._       _.'");
            $display("                                                 '-----'");
            $display("\n");
        end
    endtask

    task automatic print_simulation_fail;
        begin
            $display("\n");
            $display("        **************************             /\\       /\\");
            $display("        *                        *            /  \\_____/  \\");
            $display("        *    Simulation FAIL !!  *           /             \\");
            $display("        *                        *          |    \\/   \\/    |");
            $display("        *   Please check errors  *          |    /\\   /\\    |");
`ifdef SYN
            $display("        *      SYN LEVEL         *          |       ^       |");
`else
            $display("        *      RTL LEVEL         *          |       ^       |");
`endif
            $display("        *                        *          |  ==  \\_/  ==  |");
            $display("        **************************           \\     _w_     /");
            $display("                                              '._       _.'");
            $display("                                                 '-----'");
            $display("\n");
        end
    endtask

    // Load input files into the two synchronous ROM models.
    initial begin
`ifdef RTL_CORRECT
        q_file = "Q.dat";
        k_file = "K.dat";
        a_file = "../work/A_rtl_correct_result.dat";
`ifdef CHECK_GOLDEN
        golden_file = "A_rtl.dat";
`endif
`else
        if (!$value$plusargs("QFILE=%s", q_file)) q_file = "../work/Q.dat";
        if (!$value$plusargs("KFILE=%s", k_file)) k_file = "../work/K.dat";
        if (!$value$plusargs("AFILE=%s", a_file)) a_file = "../work/A_rtl.dat";
`ifdef CHECK_GOLDEN
        if (!$value$plusargs("GOLDFILE=%s", golden_file)) golden_file = "../work/A_golden.dat";
`endif
`endif

        $display("[TB] QFILE=%s", q_file);
        $display("[TB] KFILE=%s", k_file);
        $display("[TB] AFILE=%s", a_file);

        $readmemh(q_file, q_pattern);
        $readmemh(k_file, k_pattern);
`ifdef CHECK_GOLDEN
        $readmemh(golden_file, golden_mem);
`endif

        for (i = 0; i < DATA_NUM; i = i + 1) begin
            ROM_Q.Memory_byte0[i] = q_pattern[i];
            ROM_Q.Memory_byte1[i] = 8'h00;
            ROM_K.Memory_byte0[i] = k_pattern[i];
            ROM_K.Memory_byte1[i] = 8'h00;
        end

        a_file_handle = $fopen(a_file, "w");
        if (a_file_handle == 0) begin
            print_simulation_fail();
            $fatal(1, "[TB] Unable to open output file: %s", a_file);
        end

`ifdef CHECK_GOLDEN
        match_count = 0;
        mismatch_count = 0;
`endif

        rst = 1'b1;
        #(`CYCLE1 * 3.25);
        rst = 1'b0;
    end

    // Q ROM address generator (clk1 domain).
    always_ff @(posedge clk1 or posedge rst) begin
        if (rst) begin
            Q_ROM_A <= 0;
            q_read_count <= 0;
        end else if (Q_ROM_OE && q_read_count < DATA_NUM) begin
            q_read_count <= q_read_count + 1;
            if (q_read_count < DATA_NUM-1)
                Q_ROM_A <= Q_ROM_A + 1'b1;
        end
    end

    // K ROM address generator (clk2 domain).
    always_ff @(posedge clk2 or posedge rst) begin
        if (rst) begin
            K_ROM_A <= 0;
            k_read_count <= 0;
        end else if (K_ROM_OE && k_read_count < DATA_NUM) begin
            k_read_count <= k_read_count + 1;
            if (k_read_count < DATA_NUM-1)
                K_ROM_A <= K_ROM_A + 1'b1;
        end
    end

    // Store every valid DUT result in the output SRAM.
    always_ff @(posedge clk1 or posedge rst) begin
        if (rst) begin
            A_SRAM_A <= 0;
            a_write_count <= 0;
        end else if (!A_SRAM_WEB) begin
            if (^A === 1'bx) begin
                print_simulation_fail();
                $fatal(1, "[TB] A contains X/Z at output index %0d: %h", a_write_count, A);
            end
            if (a_write_count < DATA_NUM) begin
                a_write_count <= a_write_count + 1;
                if (a_write_count < DATA_NUM-1)
                    A_SRAM_A <= A_SRAM_A + 1'b1;
            end else begin
                print_simulation_fail();
                $fatal(1, "[TB] DUT generated more than %0d output values", DATA_NUM);
            end
        end
    end

    // Export SRAM contents to A_rtl.dat and optionally compare with golden data.
    initial begin
        wait (rst == 1'b0);
        wait (a_write_count == DATA_NUM);
        @(negedge clk1);

        for (i = 0; i < DATA_NUM; i = i + 1) begin
            $fdisplay(a_file_handle, "%04h", SRAM_A_MEM.MEMORY[i]);
`ifdef CHECK_GOLDEN
            if (SRAM_A_MEM.MEMORY[i] === golden_mem[i]) begin
                match_count = match_count + 1;
            end else begin
                mismatch_count = mismatch_count + 1;
                if (mismatch_count <= 16) begin
                    $display("[TB] MISMATCH index=%0d row=%0d col=%0d gold=%04h rtl=%04h",
                        i, i / 64, i % 64, golden_mem[i], SRAM_A_MEM.MEMORY[i]);
                end
            end
`endif
        end
        $fclose(a_file_handle);

        $display("[TB] Q ROM reads=%0d K ROM reads=%0d A SRAM writes=%0d clk1_cycles=%0d",
            q_read_count, k_read_count, a_write_count, clk1_cycles);
`ifdef CHECK_GOLDEN
        $display("[TB] Attention exact match: %0d / %0d", match_count, DATA_NUM);
        if (mismatch_count != 0) begin
            print_simulation_fail();
            $fatal(1, "[TB] FAIL: %0d / %0d attention values mismatched", mismatch_count, DATA_NUM);
        end
`endif
        print_processing_pass();
        $finish;
    end

    always_ff @(posedge clk1 or posedge rst) begin
        if (rst)
            clk1_cycles <= 0;
        else begin
            clk1_cycles <= clk1_cycles + 1;
            if (clk1_cycles >= `MAX_CLK1_CYCLES) begin
                print_simulation_fail();
                $fatal(1, "[TB] Timeout. Q=%0d K=%0d A=%0d",
                    q_read_count, k_read_count, a_write_count);
            end
        end
    end

`ifdef SYN
    initial begin
        $display("[TB] Annotating ../syn/TASAD_syn.sdf onto DUT");
        $sdf_annotate("../syn/TASAD_syn.sdf", dut);
    end
`endif
`ifdef FSDB
    initial begin
        $fsdbDumpfile("SNU.fsdb");
        $fsdbDumpvars("+struct", "+mda", dut);
        $fsdbDumpvars("+struct", ROM_Q);
        $fsdbDumpvars("+struct", ROM_K);
        $fsdbDumpvars("+struct", SRAM_A_MEM);
        $fsdbDumpvars(0, tb_tasad_application);
    end
`endif
endmodule
