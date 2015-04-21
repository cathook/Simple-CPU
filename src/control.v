module Control (
    input [5:0] opcode_i,  // Opcode.
    input [5:0] funct_i,  // Function code.

    output reg_write_ctrl_o,  // Control flag for writing back or not.
    output mem_read_ctrl_o,  // Control flag for reading the memory or not.
    output mem_write_ctrl_o,  // Control flag for writing the memory or not.
    output [2:0] alu_ctrl_o,  // Control flag for ALU.
    output use_reg1_ctrl_o,  // Ctrl flag for using the reg1 as source of ALU.
    output use_reg2_ctrl_o,  // Ctrl flag for using the reg2 as source of ALU.
    output use_shift_ctrl_o,  // Ctrl flag for using the shift amount or not.
    output use_sign_extend_ctrl_o,  // Ctrl flag for using the sign extended
                                    // value as data2 or not.
    output flush_ctrl_o,  // Ctrl flag for flushing the IDToEx or not.
    output [1:0] pc_mux_ctrl_o,  // Control flag for PCMux.
    output immed_ctrl_o,  // This operation will calculate immediately or not.
    output reg_write_addr2_ctrl_o  // Whether this instruction should write to
                                   // register 2 or not (otherwise: register 3).
);

// For add/sub/and/or/mul/lw/addi, the result of the instruction should be write
// back to the register.
assign reg_write_ctrl_o = (opcode_i == 6'b000000 ||  // add/sub/and/or/mul
                           opcode_i == 6'b100011 ||  // lw
                           opcode_i == 6'b001000);  // addi

// For lw, it needs to get datus from the data memory.
assign mem_read_ctrl_o = (opcode_i == 6'b100011);  // lw

// For sw, it needs to write datus to the data memory.
assign mem_write_ctrl_o = (opcode_i == 6'b101011);  // sw

// Sees alu.v for details about meaning of each value in alu_ctrl.
// Note: For lw, sw, addi, the ALU shell adds the value in register 1 and the
//       sign extended value gived in instruction[15:0].
assign alu_ctrl_o = (opcode_i == 6'b000000 ?  // add, sub, and, or, mul
                        (funct_i == 6'b100000 ? 3'b000 :  // add => +
                         funct_i == 6'b100010 ? 3'b001 :  // sub => -
                         funct_i == 6'b100100 ? 3'b010 :  // and => &
                         funct_i == 6'b100101 ? 3'b011 :  // or => |
                         funct_i == 6'b011000 ? 3'b100 :  // mul => *
                         0) :
                     opcode_i == 6'b100011 ? 3'b000 : // lw => +
                     opcode_i == 6'b101011 ? 3'b000 : // sw => +
                     opcode_i == 6'b001000 ? 3'b000 : // addi => +
                     0);

// The add/sub/and/or/mul/lw/sw/addi/beq instructions will all use the value
// in the register 1.  (It should output this signal because the HazardHandler,
// ForwardingHandler needs this signal).
assign use_reg1_ctrl_o = (opcode_i == 6'b000000 ||  // add, sub, and, or, mul
                          opcode_i == 6'b100011 ||  // lw
                          opcode_i == 6'b101011 ||  // sw
                          opcode_i == 6'b001000 ||  // addi
                          opcode_i == 6'b000100);  // beq

// The add/sub/and/or/mul/sw/beq will use the value in the register 2.  (Note
// that lw, addi will just write data to the register2, so them doesn't need to
// know what the original value in register2).
assign use_reg2_ctrl_o = (opcode_i == 6'b000000 ||  // add, sub, and, or, mul
                          opcode_i == 6'b101011 ||  // sw
                          opcode_i == 6'b000100);  // beq

// This cpu doesn't support sll, srl, so it is always be zero.
assign use_shift_ctrl_o = 0;

// For lw, sw, addi, the ALU should adds the value in the register 1 by the
// value gived by the sign extend operation instead of the value in the
// register 2.
assign use_sign_extend_ctrl_o = (opcode_i == 6'b100011 ||  // lw
                                 opcode_i == 6'b101011 ||  // sw
                                 opcode_i == 6'b001000);  // addi

// When whe got the j/beq instructions, we needs to tell the IFToID pipeline
// to flush the content in it instead of getting the instruction by
// InstructionMemory because at the same time InstrctionMemory has already put
// the wrong instruction to the output port by wrong PC which is
// "the current PC" + 4.
assign flush_ctrl_o = (opcode_i == 6'b000010 ||  // j
                       opcode_i == 6'b000100);  // beq

// For beq, it needs the values in the register1 and register2 in decoding stage
// instead of executing stage.
assign immed_ctrl_o = (opcode_i == 6'b000100);  // beq

assign pc_mux_ctrl_o = (opcode_i == 6'b000010 ? 2'b10 :  // j
                        opcode_i == 6'b000100 ? 2'b01 :  // beq
                        2'b00);  // (just go next)

// For lw/addi, them will also write back to the register, but the register
// address is not register 3 (instruction[15:11]), it is register
// 2 (instruction[20:16]).
assign reg_write_addr2_ctrl_o = (opcode_i == 6'b100011 ||  // lw
                                 opcode_i == 6'b001000);  // addi

endmodule
