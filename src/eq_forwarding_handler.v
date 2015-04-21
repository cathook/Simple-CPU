module EqForwardingHandler (
    input [4:0] reg_read_addr_i,  // Address of the register.
    input [31:0] reg_read_data_i,  // Data of the register.
    input reg_write_ctrl_from_ex_to_mem_i,  // Flag for writing back or not.
    input [4:0] reg_write_addr_from_ex_to_mem_i,  // Previous WB address.
    input [31:0] reg_write_data_from_ex_to_mem_i,  // Previous WB data.

    output [31:0] reg_data_o  // The result data.
);

// case 1 -- The previous instruction is lw:
//     It doesn't need to consider because HazardHandler will let stall be
//     on and the pipeline will be pause in a cycle time.
// case 2 -- The previous instruction will write back the the same register:
//     Same as case 1.
// case 3 -- The pre-previous (2 cycle time ago) instruction be lw:
//     Same as case 1.
// case 4 -- The pre-previous instruction will write back and no read memory
//     We can forward the result of ALU from ExToMem.
// case 5 -- The pre-pre-previous instruction will write back:
//     Well..., the write back task must be done at the same time.

// Finally, we found that we just needs to check that whether the pre-previous
// instruction will write back or not; And whether the pre-previous instrcution
// write back to the same register or not.

assign reg_data_o = (reg_write_ctrl_from_ex_to_mem_i  &&
                     reg_read_addr_i == reg_write_addr_from_ex_to_mem_i ?
                     reg_write_data_from_ex_to_mem_i : reg_read_data_i);

endmodule
