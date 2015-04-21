`define CYCLE_TIME 50

module TestBench ();

reg clk;
reg start;
integer i, outfile, outfile2, counter;
integer stall, flush;

always #(`CYCLE_TIME / 2) clk = ~clk;

CPU CPU (
    .clk_i (clk),
    .start_i (start),
    .rst_i (~start)
);

reg done;


reg [1:0] prev_cached_data_memory_state;
reg cache_miss;

reg [31:0] tmp_for_output;
integer stall_ct;


initial begin
    start = 0;
    clk = 1;
    counter = 0;
    stall = 0;
    flush = 0;
    done = 0;
    prev_cached_data_memory_state = 2'b0;
    cache_miss = 1'b0;
    stall_ct = 32'b0;


    for (i = 0; i < CPU.InstructionMemory.pInstructionSize; i = i + 1) begin
        CPU.InstructionMemory.instruction[i] = ~(32'b0);
    end
    // Loads the instructions into the instruction memory.
    $readmemb("instruction.txt", CPU.InstructionMemory.instruction);

    // Opens the output file.
    outfile = $fopen("output.txt") | 1;
    outfile2 = $fopen("cache.txt") | outfile;

    #(`CYCLE_TIME / 4 * 7);
    start = 1;
end


reg [21:0] tag;
reg [4:0] index;
reg [31:0] address;


always @ (posedge clk) begin
    #(`CYCLE_TIME / 5 * 2)

    // Prints the information about DataCache.
    if (CPU.CachedDataMemory.stall_ctrl_o) begin
        if (prev_cached_data_memory_state == 0 &&
            CPU.CachedDataMemory.state == 2'h2 && stall_ct == 0) begin
            if (CPU.CachedDataMemory.read_ctrl_i) begin
                $fdisplay(outfile2, "Cycle: %d, Read Miss , Address: %h, Read Data : %h",
                          counter, CPU.CachedDataMemory.addr_i, CPU.CachedDataMemory.read_data_o);
            end else begin
                $fdisplay(outfile2, "Cycle: %d, Write Miss, Address: %h, Write Data: %h",
                          counter, CPU.CachedDataMemory.addr_i, CPU.CachedDataMemory.write_data_i);
            end
            stall_ct = stall_ct + 1;
        end else if (prev_cached_data_memory_state == 0 &&
                     CPU.CachedDataMemory.state == 2'h1 && stall_ct == 0) begin
            if (CPU.CachedDataMemory.read_ctrl_i) begin
                $fdisplay(outfile2, "Cycle: %d, Read Miss , Address: %h, Read Data : %h (Write Back!)",
                          counter, CPU.CachedDataMemory.addr_i, CPU.CachedDataMemory.read_data_o);
            end else begin
                $fdisplay(outfile2, "Cycle: %d, Write Miss, Address: %h, Write Data: %h (Write Back!)",
                          counter, CPU.CachedDataMemory.addr_i, CPU.CachedDataMemory.write_data_i);
            end
            stall_ct = stall_ct + 1;
        end
        cache_miss = 1'b1;
    end else begin
        if (CPU.CachedDataMemory.read_ctrl_i && !cache_miss) begin
            $fdisplay(outfile2, "Cycle: %d, Read Hit  , Address: %h, Read Data : %h",
                      counter, CPU.CachedDataMemory.addr_i, CPU.CachedDataMemory.read_data_o);
        end else if (CPU.CachedDataMemory.write_ctrl_i && !cache_miss) begin
            $fdisplay(outfile2, "Cycle: %d, Write Hit , Address: %h, Write Data: %h",
                      counter, CPU.CachedDataMemory.addr_i, CPU.CachedDataMemory.write_data_i);
        end
        cache_miss = 1'b0;
        stall_ct = 32'b0;
    end
    prev_cached_data_memory_state = CPU.CachedDataMemory.state;

    #(`CYCLE_TIME / 5)

    // Runs at most 300 cycles.
    if (counter >= 300) begin $finish; end

    if ((CPU.HazardHandler.stall_ctrl_o || CPU.CachedDataMemory.stall_ctrl_o) &&
        CPU.Control.pc_mux_ctrl_o == 0) stall = stall + 1;
    if (CPU.Control.flush_ctrl_o == 1) flush = flush + 1;

    // print PC
    $fdisplay(outfile, "cycle = %d, Start = %b, Stall = %d, Flush = %d", counter, start, stall, flush);
    $fdisplay(outfile, "PC = %d", CPU.PC.pc_o);

    // Prints the result of registers and memory.
    $fdisplay(outfile, "Registers");
    $fdisplay(outfile, "R0(r0) = %h, R8 (t0) = %h, R16(s0) = %h, R24(t8) = %h", CPU.Registers.register[0], CPU.Registers.register[8] , CPU.Registers.register[16], CPU.Registers.register[24]);
    $fdisplay(outfile, "R1(at) = %h, R9 (t1) = %h, R17(s1) = %h, R25(t9) = %h", CPU.Registers.register[1], CPU.Registers.register[9] , CPU.Registers.register[17], CPU.Registers.register[25]);
    $fdisplay(outfile, "R2(v0) = %h, R10(t2) = %h, R18(s2) = %h, R26(k0) = %h", CPU.Registers.register[2], CPU.Registers.register[10], CPU.Registers.register[18], CPU.Registers.register[26]);
    $fdisplay(outfile, "R3(v1) = %h, R11(t3) = %h, R19(s3) = %h, R27(k1) = %h", CPU.Registers.register[3], CPU.Registers.register[11], CPU.Registers.register[19], CPU.Registers.register[27]);
    $fdisplay(outfile, "R4(a0) = %h, R12(t4) = %h, R20(s4) = %h, R28(gp) = %h", CPU.Registers.register[4], CPU.Registers.register[12], CPU.Registers.register[20], CPU.Registers.register[28]);
    $fdisplay(outfile, "R5(a1) = %h, R13(t5) = %h, R21(s5) = %h, R29(sp) = %h", CPU.Registers.register[5], CPU.Registers.register[13], CPU.Registers.register[21], CPU.Registers.register[29]);
    $fdisplay(outfile, "R6(a2) = %h, R14(t6) = %h, R22(s6) = %h, R30(s8) = %h", CPU.Registers.register[6], CPU.Registers.register[14], CPU.Registers.register[22], CPU.Registers.register[30]);
    $fdisplay(outfile, "R7(a3) = %h, R15(t7) = %h, R23(s7) = %h, R31(ra) = %h", CPU.Registers.register[7], CPU.Registers.register[15], CPU.Registers.register[23], CPU.Registers.register[31]);

    // Prints the data memory.
    for (i = 0; i < $min(CPU.CachedDataMemory.DataMemory.pMemorySize, 32); i = i + 4) begin
        tmp_for_output = CPU.CachedDataMemory.DataMemory.memory[i / CPU.CachedDataMemory.DataMemory.pBlockSize] >> (i % CPU.CachedDataMemory.DataMemory.pBlockSize * 8);
        $fdisplay(outfile, "Data Memory: 0x%X = %10d", i, tmp_for_output);
    end

    $fdisplay(outfile, "\n");

    counter = counter + 1;
end

endmodule
