
HOME_DIR=../

TB=$(HOME_DIR)verilog/test/tb_vmicro16_soc

SRC_VC=$(HOME_DIR)filelists/vmicro16_soc.vc
SRCS=$(shell cat $(SRC_VC)) $(TB).v
INC_DIR=$(HOME_DIR)verilog/includes

COMPILER=iverilog
SIMULATOR=vvp
VIEWER=gtkwave

COFLAGS=-v -o
SIMFLAGS=-v

OUTFILE=a.out

.PHONY: clean

all: check

pre:
	iverilog -E -o preprocessed.v -I$(INC_DIR) $(SRCS)

clean:
	rm -rf *

check: $(TESTBENCH) $(SRCS)
	$(COMPILER) -I$(INC_DIR) $(SRCS) -s $(TB)

