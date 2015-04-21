BIN_NAME = cpu

SOURCE_DIR = src
TESTBENCH = testbench.v

SOURCES = $(shell find $(SOURCE_DIR) -type f) $(TESTBENCH)

VERILOG = iverilog


.PHONY: all test clean


all: $(BIN_NAME)

test: $(BIN_NAME)
	./$<

clean:
	-rm $(BIN_NAME)
	-rm output.txt cache.txt

$(BIN_NAME): $(SOURCES)
	$(VERILOG) -o $@ $^
