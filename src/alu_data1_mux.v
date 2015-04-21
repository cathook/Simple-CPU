module ALUData1Mux (
    input [31:0] data_from_reg_i,  // Data from the register.
    input [31:0] data_from_shift_i,  // Data from the shift amount.
    input use_shift_ctrl_i,  // Control flag:
                             //     0 -> data from register
                             //     1 -> data from shift amount.

    output [31:0] data_o  // The output data.
);

assign data_o = (use_shift_ctrl_i ?  data_from_shift_i : data_from_reg_i);

endmodule
