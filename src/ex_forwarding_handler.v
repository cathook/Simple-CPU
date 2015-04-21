module ExForwardingHandler (
    input [4:0] reg_read_addr_i,  // Address of the register to be wrote back.
    input [31:0] reg_read_data_i,  // Data to be wrote.
    input [4:0] reg_write_addr_from_ex_to_mem_i,  // Previous register address.
    input [31:0] reg_write_data_from_ex_to_mem_i,  // Previous data to be WB.
    input reg_write_ctrl_from_ex_to_mem_i,  // Previous WB flag.
    input [4:0] reg_write_addr_from_mem_to_wb_i,  // P-previous reg address.
    input [31:0] reg_write_data_from_mem_to_wb_i,  // P-previous data to be WB.
    input reg_write_ctrl_from_mem_to_wb_i,  // P-previous WB flag.

    output [31:0] data_o  // The output.
);

// Case 1 -- The previous instruction is lw:
//     No need to consider, because in this case the HazardHandler will stall
//     the whole pipeline a cycle time.
// Case 2 -- The previous instruction is not lw and will write back.
//     Then, the value to be write back must be the result of ALU, and this
//     value has been already calculated at last cycle time and stores in the
//     ExToMem pipeline now, we can just forward it.
// Case 3 -- The previous instruction will not write back:
//     No need to consider.
// Case 4 -- The pre-previous instrction will write back to the same register:
//     No matter the value is loaded from the data memory or calculated by the
//     ALU, it must just be stores in the MemToWB pipeline and we can just
//     forward it.
// Case 5 -- The pre-pre-previous instruction will wirte back:
//     At the last cycle time, the value must be write back to the register, and
//     at that time this instruction just got the right value.

// Finally, we can just simplify:
//   If the previous instruction will write back to the same register, doing
//   forwarding;
//   If the pre-previous instruction will write back to the same register, doing
//   forwarding;
//   Otherwise do not forwarding.

assign data_o = (reg_write_ctrl_from_ex_to_mem_i &&
                 reg_read_addr_i == reg_write_addr_from_ex_to_mem_i ?
                     reg_write_data_from_ex_to_mem_i :
                 reg_write_ctrl_from_mem_to_wb_i &&
                 reg_read_addr_i == reg_write_addr_from_mem_to_wb_i ?
                     reg_write_data_from_mem_to_wb_i :
                 reg_read_data_i);

endmodule
