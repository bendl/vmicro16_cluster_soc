
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

ASM=../sw/demos/asm/addloop.s

.PHONY: clean

all: verilog

pre:
	iverilog -E -o preprocessed.v -I$(INC_DIR) $(SRCS)

clean:
	rm -rf *

verilog: $(SRCS) asm
	$(COMPILER) -o soc.out -s tb_vmicro16_soc -I$(INC_DIR) $(SRCS)

sim: soc.out
	vvp soc.out

soc.out: verilog

$(TBNAME).vcd: sim

wave: $(TBNAME).vcd
	/Applications/gtkwave.app/Contents/Resources/bin/gtkwave $(TBNAME).vcd ../verilog/test/waves/saved.gtkw
	#gktwave $(TBNAME).vcd

asm:
	python3 ../sw/asm.py $(ASM)
