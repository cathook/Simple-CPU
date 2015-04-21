module PCMux (
    input [31:0] next_pc_i,  // PC + 4.
    input [31:0] beq_pc_i,  // PC calculated by beq.
    input [31:0] jump_pc_i,  // PC from jump instruction.
    input [1:0] ctrl_i,  // Control flag:
                         //   00 -> next
                         //   01 -> beq
                         //   10 -> jump

    output [31:0] pc_o  // The result pc.
);

assign pc_o = (ctrl_i == 2'b00 ? next_pc_i :
               ctrl_i == 2'b01 ? beq_pc_i :
               ctrl_i == 2'b10 ? jump_pc_i :
               0);

endmodule
