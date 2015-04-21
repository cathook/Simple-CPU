module ALUData2Mux (
    input [31:0] data_from_reg_i,  // Data from the register.
    input [31:0] data_from_sign_extend_i,  // Data from the sign extend oper.
    input use_sign_extend_ctrl_i,  // Control flag:
                                   //     0 -> data from register
                                   //     1 -> data from sign extend

    output [31:0] data_o  // The output data.
);

assign data_o = (use_sign_extend_ctrl_i ?
                 data_from_sign_extend_i : data_from_reg_i);

endmodule
