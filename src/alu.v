module ALU (
    input [31:0] data1_i,  // Input data1.
    input [31:0] data2_i,  // Input data2.
    input [2:0] ctrl_i,  // The control flag:
                         //     000 -> +
                         //     001 -> -
                         //     010 -> &
                         //     011 -> |
                         //     100 -> *

    output [31:0] data_o  // The output data.
);

assign data_o = (ctrl_i[2:0] == 3'b000 ? (data1_i + data2_i) :
                 ctrl_i[2:0] == 3'b001 ? (data1_i - data2_i) :
                 ctrl_i[2:0] == 3'b010 ? (data1_i & data2_i) :
                 ctrl_i[2:0] == 3'b011 ? (data1_i | data2_i) :
                 ctrl_i[2:0] == 3'b100 ? (data1_i * data2_i) :
                 0);

endmodule
