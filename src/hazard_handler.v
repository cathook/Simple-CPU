module HazardHandler (
    input [4:0] addr1_i,  // Address of the first register.
    input chk_addr1_ctrl_i,  // Flag for whether it needs to check addr1 or not.
    input [4:0] addr2_i,  // Address of the second register.
    input chk_addr2_ctrl_i,  // Flag for whether it needs to check addr2 or not.
    input immed_ctrl_i,  // The register data are needed immediate or not.
    input reg_write_ctrl_from_id_to_ex_i,  // Write back or not.
    input [4:0] reg_write_addr_from_id_to_ex_i,  // Address from IDToEx.
    input mem_read_ctrl_from_id_to_ex_i,  // Will load word or not.
    input [4:0] reg_write_addr_from_ex_to_mem_i,  // Address from ExToMem.
    input mem_read_ctrl_from_ex_to_mem_i,  // Will load word or not.

    output stall_ctrl_o  // Stall the pc or not.
);

// It needs to be stall when the previous or pre-previous instruction (we called
// "the instruction A")'s destination register are the same as the current one
// (It doesn't need to consider the pre-pre-pre one because it was already write
// back at last posedge) and:
//     - case1: The current instruction is "beq"  (i.e. immed_ctrl_i = 1)
//         a. The previous instruction must just about to do ALU to get the
//            result, or maybe worse, about to get the address of the data
//            memory, so hazard occured.
//         b. If the pre-previous instruction is about to load data from the
//            data memory, the result of that operation can only be got after
//            this cycle => hazard occured.
//         Otherwise: We can forwarding the data from ExToMem stage.
//     - case2: The current instruction is not "beq", so we can get the value
//              when it about to run ALU.
//         a. The previous instruction is about to load data from the memory,
//            then it must be just about to get the address of the data memory
//            and the operation about loading the value from the data memory
//            will actually run at next cycle, and the result will accessable at
//            the next-next cycle => hazard occured.
//         Otherwise: At the next cycle time, the current instruction will about
//                    to run ALU, and at that time we can get data from MemToWB
//                    or ExToMem (because it must not be "lw").

assign stall_ctrl_o =
    (chk_addr1_ctrl_i ?  // If the register 1 will be used for this instruction
        (immed_ctrl_i ?  // For the case "beq"
            (reg_write_ctrl_from_id_to_ex_i &&
             addr1_i == reg_write_addr_from_id_to_ex_i ?  // For the case 1-a
                1 :
            addr1_i == reg_write_addr_from_ex_to_mem_i &&  // For the case 1-b
            mem_read_ctrl_from_ex_to_mem_i ?  // Note: no need for checking
                                              // the write back control signal
                                              // because mem read must follows
                                              // by writing back the value.
                1 :
            0) :
        (addr1_i == reg_write_addr_from_id_to_ex_i &&  // For the case 2-a
         mem_read_ctrl_from_id_to_ex_i ?
            1 :
        0)) :
    0) ||
    (chk_addr2_ctrl_i ?  // If the register 2 will be used for this instruction
        (immed_ctrl_i ?  // For the case "beq"
            (reg_write_ctrl_from_id_to_ex_i &&
             addr2_i == reg_write_addr_from_id_to_ex_i ?  // For the case 1-a
                1 :
            addr2_i == reg_write_addr_from_ex_to_mem_i &&  // For the case 1-b
            mem_read_ctrl_from_ex_to_mem_i ?
                1 :
            0) :
        (addr2_i == reg_write_addr_from_id_to_ex_i &&  // For the case 2-a
         mem_read_ctrl_from_id_to_ex_i ?
            1 :
        0)) :
    0);

endmodule
