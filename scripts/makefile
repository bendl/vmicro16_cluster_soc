
HOME_DIR=../

TBNAME=tb_vmicro16_soc
TB=$(HOME_DIR)verilog/test/$(TBNAME)

SRC_VC=$(HOME_DIR)filelists/vmicro16_soc.vc
SRCS=$(shell cat $(SRC_VC)) $(TB).v
INC_DIR=$(HOME_DIR)verilog/includes

COMPILER=iverilog
SIMULATOR=vvp
VIEWER=gktwave

COFLAGS=-v -o
SIMFLAGS=-v

OUTFILE=a.out

.PHONY: clean

all: compile

pre:
	iverilog -E -o preprocessed.v -I$(INC_DIR) $(SRCS)

clean:
	rm -rf *

compile: $(SRCS)
	$(COMPILER) -o soc.out -s tb_vmicro16_soc -I$(INC_DIR) $(SRCS)

sim: soc.out
	vvp soc.out

soc.out: compile

$(TBNAME).vcd: sim

wave: $(TBNAME).vcd
	gktwave $(TBNAME).vcd
