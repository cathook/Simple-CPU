module CPU (
    input start_i,  // Start or not.
    input rst_i,  // Resets the cpu or not.

    input clk_i  // Note: stages work on posedge, pipelines work on negedge.
);

// I assume that each stage/pipeline can do their tasks just in half of a clock
// cycle, so I can let stages work at posedge of the clock, pipelines stores the
// data from the left stage into its own register.  And then once posedge
// occured, the stages must be able to get the data from left stage by pipeline
// (At that time, the pipelines will do nothing while remain the data
// unchanged); then with a few time past, each stages are all done their tasks,
// the result of them are all stabled, and then negedge occured, so pipeline
// can grab the correct data this time and store them for the next posedge...
wire stage_clk = clk_i;  // Clocks for the stages.
wire pipeline_clk = ~clk_i;  // Clocks for the pipelines.

///////////////////////////////////////////////////////////////////////////

PC PC (
    .pc_i (PCMux.pc_o),

    .stall_ctrl_i ((~start_i) ||
                   HazardHandler.stall_ctrl_o || CachedDataMemory.stall_ctrl_o),

    .rst_i (rst_i),
    .clk_i (pipeline_clk)  // Consider PC be a pipeline too.
);

///////////////////////////////////////////////////////////////////////////

InstructionMemory InstructionMemory (
    .addr_i(PC.pc_o),

    .rst_i (rst_i),
    .clk_i (stage_clk)
);

PCAdder PCAdder (
    .pc_i (PC.pc_o),

    .rst_i (rst_i),
    .clk_i (stage_clk)
);

///////////////////////////////////////////////////////////////////////////

IFToID IFToID (
    .pc_i (PCAdder.pc_o),
    .instr_i (InstructionMemory.instr_o),

    .flush_ctrl_i ((~start_i) || Control.flush_ctrl_o),  // Always clean if
                                                         // start_i is 0.

    // Here note that the priority of stall is higher than flush, because while
    // stalling, the IFToID should get the same input instead of cleaning.
    .stall_ctrl_i (HazardHandler.stall_ctrl_o || CachedDataMemory.stall_ctrl_o),

    .rst_i (rst_i),
    .clk_i (pipeline_clk)
);

///////////////////////////////////////////////////////////////////////////

wire [31:0] instruction = IFToID.instr_o;
wire [5:0] opcode = instruction[31:26];
wire [4:0] reg_addr1 = instruction[25:21];
wire [4:0] reg_addr2 = instruction[20:16];
wire [4:0] reg_addr3 = instruction[15:11];
wire [4:0] shift = instruction[10:6];
wire [5:0] funct = instruction[5:0];

wire [31:0] if_to_id_pc_o = IFToID.pc_o;
wire [31:0] sign_extended_value = {{16{instruction[15]}}, {instruction[15:0]}};

// Jump destination: replacing the last 28 bit of the pc + 4.
wire [31:0] jump_dest = {if_to_id_pc_o[31:28], instruction[25:0], 2'b00};

Registers Registers (
    .read_addr1_i (reg_addr1),
    .read_addr2_i (reg_addr2),

    .rst_i (rst_i),
    .clk_i (stage_clk)
);

Control Control (
    .opcode_i (opcode),
    .funct_i (funct)
);

// Some instructions will write back to addr3 while some are addr2.
wire [4:0] reg_write_addr = (Control.reg_write_addr2_ctrl_o ?
                             reg_addr2 : reg_addr3);

HazardHandler HazardHandler (
    .addr1_i (reg_addr1),
    .chk_addr1_ctrl_i (Control.use_reg1_ctrl_o),  // For "j", no needs to check.
    .addr2_i (reg_addr2),
    .chk_addr2_ctrl_i (Control.use_reg2_ctrl_o),
    .immed_ctrl_i (Control.immed_ctrl_o),  // For "beq", it runs immediately.
    .reg_write_ctrl_from_id_to_ex_i (IDToEx.reg_write_ctrl_o),
    .reg_write_addr_from_id_to_ex_i (IDToEx.reg_write_addr_o),
    .mem_read_ctrl_from_id_to_ex_i (IDToEx.mem_read_ctrl_o),
    .reg_write_addr_from_ex_to_mem_i (ExToMem.reg_write_addr_o),
    .mem_read_ctrl_from_ex_to_mem_i (ExToMem.mem_read_ctrl_o)
);


EqForwardingHandler EqForwardingHandler1 (  // Forwarding from ExToMem.  (Note
                                            // that it no needs to forwarding
                                            // from MemToWB because it already
                                            // write into the registers at this
                                            // stage.  IDToEx is no need either
                                            // because it handled by
                                            // HazardHandler.)
    .reg_read_addr_i (reg_addr1),
    .reg_read_data_i (Registers.read_data1_o),
    .reg_write_ctrl_from_ex_to_mem_i (ExToMem.reg_write_ctrl_o),
    .reg_write_addr_from_ex_to_mem_i (ExToMem.reg_write_addr_o),
    .reg_write_data_from_ex_to_mem_i (ExToMem.reg_write_data_o)
);

EqForwardingHandler EqForwardingHandler2 (  // Forwarding from ExToMem
    .reg_read_addr_i (reg_addr2),
    .reg_read_data_i (Registers.read_data2_o),
    .reg_write_ctrl_from_ex_to_mem_i (ExToMem.reg_write_ctrl_o),
    .reg_write_addr_from_ex_to_mem_i (ExToMem.reg_write_addr_o),
    .reg_write_data_from_ex_to_mem_i (ExToMem.reg_write_data_o)
);

PCMux PCMux (
    .next_pc_i (PCAdder.pc_o),
    .beq_pc_i (
        // For "beq" and equal, the new pc will be the current "pc + 4" add by
        // sign_extended_value * 4 (i.e. offset 2 bit).
        EqForwardingHandler1.reg_data_o == EqForwardingHandler2.reg_data_o ?
        if_to_id_pc_o + {sign_extended_value[29:0], 2'b00} : if_to_id_pc_o),
    .jump_pc_i (jump_dest),
    .ctrl_i (Control.pc_mux_ctrl_o)
);

///////////////////////////////////////////////////////////////////////////

// If hazard occured and the pipeline should be stall, do not throw the
// control flags to the next stage.
wire [7:0] ctrl_signals = HazardHandler.stall_ctrl_o ? 8'b0 : {
                              Control.use_shift_ctrl_o,
                              Control.use_sign_extend_ctrl_o,
                              Control.alu_ctrl_o,
                              Control.reg_write_ctrl_o,
                              Control.mem_read_ctrl_o,
                              Control.mem_write_ctrl_o
                          };

IDToEx IDToEx (
    .reg_read_addr1_i (reg_addr1),
    .reg_read_data1_i (Registers.read_data1_o),
    .reg_read_addr2_i (reg_addr2),
    .reg_read_data2_i (Registers.read_data2_o),
    .shift_i (shift),
    .sign_extended_value_i (sign_extended_value),
    .reg_write_addr_i (reg_write_addr),

    .use_shift_ctrl_i (ctrl_signals[7:7]),
    .use_sign_extend_ctrl_i (ctrl_signals[6:6]),
    .alu_ctrl_i (ctrl_signals[5:3]),
    .reg_write_ctrl_i (ctrl_signals[2:2]),
    .mem_read_ctrl_i (ctrl_signals[1:1]),
    .mem_write_ctrl_i (ctrl_signals[0:0]),

    .stall_ctrl_i (CachedDataMemory.stall_ctrl_o),

    .rst_i (rst_i),
    .clk_i (pipeline_clk)
);

///////////////////////////////////////////////////////////////////////////

ExForwardingHandler ExForwardingHandler1 (  // Forwarding from ExToMem, MemToWB
    .reg_read_addr_i (IDToEx.reg_read_addr1_o),
    .reg_read_data_i (IDToEx.reg_read_data1_o),

    .reg_write_addr_from_ex_to_mem_i (ExToMem.reg_write_addr_o),
    .reg_write_data_from_ex_to_mem_i (ExToMem.reg_write_data_o),
    .reg_write_ctrl_from_ex_to_mem_i (ExToMem.reg_write_ctrl_o),

    .reg_write_addr_from_mem_to_wb_i (MemToWB.reg_write_addr_o),
    .reg_write_data_from_mem_to_wb_i (MemToWB.reg_write_data_o),
    .reg_write_ctrl_from_mem_to_wb_i (MemToWB.reg_write_ctrl_o)
);

ExForwardingHandler ExForwardingHandler2 (  // Forwarding from ExToMem, MemToWB
    .reg_read_addr_i (IDToEx.reg_read_addr2_o),
    .reg_read_data_i (IDToEx.reg_read_data2_o),

    .reg_write_addr_from_ex_to_mem_i (ExToMem.reg_write_addr_o),
    .reg_write_data_from_ex_to_mem_i (ExToMem.reg_write_data_o),
    .reg_write_ctrl_from_ex_to_mem_i (ExToMem.reg_write_ctrl_o),

    .reg_write_addr_from_mem_to_wb_i (MemToWB.reg_write_addr_o),
    .reg_write_data_from_mem_to_wb_i (MemToWB.reg_write_data_o),
    .reg_write_ctrl_from_mem_to_wb_i (MemToWB.reg_write_ctrl_o)
);

ALUData1Mux ALUData1Mux (
    .data_from_reg_i (ExForwardingHandler1.data_o),
    .data_from_shift_i ({{27{1'b0}}, IDToEx.shift_o}),
    .use_shift_ctrl_i (IDToEx.use_shift_ctrl_o)
);

ALUData2Mux ALUData2Mux (
    .data_from_reg_i (ExForwardingHandler2.data_o),
    .data_from_sign_extend_i (IDToEx.sign_extended_value_o),
    .use_sign_extend_ctrl_i (IDToEx.use_sign_extend_ctrl_o)
);

ALU ALU (
    .data1_i (ALUData1Mux.data_o),
    .data2_i (ALUData2Mux.data_o),
    .ctrl_i (IDToEx.alu_ctrl_o)
);

///////////////////////////////////////////////////////////////////////////

ExToMem ExToMem (
    .reg_write_ctrl_i (IDToEx.reg_write_ctrl_o),
    .reg_write_addr_i (IDToEx.reg_write_addr_o),
    .reg_write_data_i (ALU.data_o),
    .mem_addr_i (ALU.data_o),
    .mem_read_ctrl_i (IDToEx.mem_read_ctrl_o),
    .mem_write_ctrl_i (IDToEx.mem_write_ctrl_o),
    .mem_write_data_i (ExForwardingHandler2.data_o),

    .stall_ctrl_i (CachedDataMemory.stall_ctrl_o),

    .rst_i (rst_i),
    .clk_i (pipeline_clk)
);

///////////////////////////////////////////////////////////////////////////

CachedDataMemory CachedDataMemory(
    .addr_i (ExToMem.mem_addr_o),
    .read_ctrl_i (ExToMem.mem_read_ctrl_o),
    .write_ctrl_i (ExToMem.mem_write_ctrl_o),
    .write_data_i (ExToMem.mem_write_data_o),

    .rst_i (rst_i),
    .clk_i (stage_clk)
);

///////////////////////////////////////////////////////////////////////////

MemToWB MemToWB (
    .reg_write_ctrl_i (ExToMem.reg_write_ctrl_o),
    .reg_write_addr_i (ExToMem.reg_write_addr_o),
    .reg_write_data_i (ExToMem.mem_read_ctrl_o ? CachedDataMemory.read_data_o :
                                                 ExToMem.reg_write_data_o),

    .stall_ctrl_i (CachedDataMemory.stall_ctrl_o),
    .rst_i (rst_i),
    .clk_i (pipeline_clk)
);

///////////////////////////////////////////////////////////////////////////

assign Registers.write_ctrl_i = MemToWB.reg_write_ctrl_o;
assign Registers.write_addr_i = MemToWB.reg_write_addr_o;
assign Registers.write_data_i = MemToWB.reg_write_data_o;

///////////////////////////////////////////////////////////////////////////

/*

integer i, j;
reg [31:0] tmp;
always @ (posedge clk_i) begin
    #15
    $display("");
    $display("================== meow ===================\n");
    $display("");
    $display("(%d)Decode: opcode = %b", if_to_id_pc_o - 4, opcode);
    $display("                    funct = %b, reg[%b/%b/%b] = %d, %d",
             funct, reg_addr1, reg_addr2, reg_addr3, Registers.read_data1_o, Registers.read_data2_o);
    $display("                    sign_extended = %d, jump_dest = %d, beq_dest(if eq) = %d",
             sign_extended_value, jump_dest, if_to_id_pc_o + {sign_extended_value[29:0], 2'b00});
    $display("                    alu:%b use:%b%b sign: %b, flush: %b, pc_mux: %b, immed: %b, write_addr2: %b, wb? %b",
             Control.alu_ctrl_o, Control.use_reg1_ctrl_o, Control.use_reg2_ctrl_o, Control.use_sign_extend_ctrl_o, Control.flush_ctrl_o, Control.pc_mux_ctrl_o, Control.immed_ctrl_o, Control.reg_write_addr2_ctrl_o, Control.reg_write_ctrl_o);
    $display("                    stall: %b, eq1 = %d, eq2 = %d",
             HazardHandler.stall_ctrl_o, EqForwardingHandler1.reg_data_o, EqForwardingHandler2.reg_data_o);
    $display("");
    $display("(%d)Execute: alu_ctrl = %b, alu_res = %d (source: %d, %d ",
             if_to_id_pc_o - 8, IDToEx.alu_ctrl_o, ALU.data_o, ExForwardingHandler1.data_o, ALUData2Mux.data_o);
    $display("                     (use_sign_ext? %b %d)) for mem %d",
             IDToEx.use_sign_extend_ctrl_o, IDToEx.sign_extended_value_o, ExForwardingHandler2.data_o);
    $display("");
    $display("(%d)Memory: address = %d, read/write = %b/%b, data = %d, res = %d",
             if_to_id_pc_o - 12, ExToMem.mem_addr_o, ExToMem.mem_read_ctrl_o, ExToMem.mem_write_ctrl_o, ExToMem.mem_write_data_o, CachedDataMemory.read_data_o);
    $display("                    reg = %b, wb %b reg_data = %d, stall? %b",
             ExToMem.reg_write_addr_o, ExToMem.reg_write_ctrl_o, ExToMem.reg_write_data_o, CachedDataMemory.stall_ctrl_o);
    $display("                    enable = %b, addr = %d, ack = %b",
             CachedDataMemory.DataMemory.enable_i, CachedDataMemory.DataMemory.addr_i, CachedDataMemory.DataMemory.ack_o);
    $write("                     input_data = /");
    for (i = 0; i < CachedDataMemory.DataMemory.pBlockSize; i = i + 4) begin
        tmp = CachedDataMemory.data_memory_write_data >> i * 8;
        $write("%5d/", tmp);
    end
    $display("");
    $write("                    result_data = /");
    for (i = 0; i < CachedDataMemory.DataMemory.pBlockSize; i = i + 4) begin
        tmp = CachedDataMemory.DataMemory.read_data_o >> i * 8;
        $write("%5d/", tmp);
    end
    $display("");
    $display("                    index = %d, offset = %d, tag[v%b]? %d == %d",
             CachedDataMemory.index,CachedDataMemory.offset, CachedDataMemory.cache_valid[CachedDataMemory.index], CachedDataMemory.cache_tag[CachedDataMemory.index], CachedDataMemory.tag);
    $write(  "                    data = /");
    for (i = 0; i < CachedDataMemory.DataMemory.pBlockSize; i = i + 4) begin
        tmp = CachedDataMemory.cache_data[CachedDataMemory.index] >> i * 8;
        $write("%5d/", tmp);
    end
    $display("");
    $display("(%d)WriteBack: reg = %b, wb? %b, reg_data = %d",
             if_to_id_pc_o - 16, MemToWB.reg_write_addr_o, MemToWB.reg_write_ctrl_o, MemToWB.reg_write_data_o);
    $display("");
end

// */

endmodule
