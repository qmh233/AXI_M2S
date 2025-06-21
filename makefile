######################## Parameters #############################
# Object Verilog Files'catalog
	MODULES = ./src/AXI_Lite_Master_IF.v \
			  ./src/AXI_Lite_Slave_IF.v \
			  ./tb/Master_Controller_X0.v \
			  ./tb/Slave_RegFile.v \
			  ./tb/Clock_Reset.v \
			  ./tb/testbench.v

# VCD File's name(.vcd) 
	VcdFile = wave.vcd
	GtkwFile = signal.gtkw
	
# elf File's name(.out) 
	ElfFile = run.out
################################################################

# make all
all: compile run sim

# only make compile
compile:
	iverilog -o $(ElfFile) $(MODULES)

# only make visual(make .elf file to the vcd file)
run:
	vvp -n $(ElfFile)

# only open the wave
sim:
	gtkwave $(VcdFile) $(GtkwFile)

# clear middle files
clean:
	rm -rf *.out