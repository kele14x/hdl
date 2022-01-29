VIVADO := vivado -mode batch -nolog -nojou -notrace -source

PART := xczu19eg-ffvc1760-2-i

CLEAN_TARGET += prj_dir/

.PHONY: all project clean

project:
	$(VIVADO) ../scripts/common.tcl -tclargs --filesets $(DESIGN).flt

all: project

clean: 
	-rm -rf $(CLEAN_TARGET)

help:
	@echo
	@echo "Design: $(DESIGN)"
	@echo "Type 'make <target>' to start, where <target> could be:"
	@echo "  project  - Create Vivado project"
	@echo "  all      - Do all jobs"
	@echo "  clean    - Clean output files"
	@echo "  help     - Print this message"
	@echo
