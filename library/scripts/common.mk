VIVADO := vivado -mode batch -nolog -nojou -source 

CLEAN_TARGET += *.cache
CLEAN_TARGET += *.data
CLEAN_TARGET += *.xpr
CLEAN_TARGET += *.log
CLEAN_TARGET += component.xml
CLEAN_TARGET += *.jou
CLEAN_TARGET +=  xgui
CLEAN_TARGET += *.ip_user_files
CLEAN_TARGET += *.srcs
CLEAN_TARGET += *.hw
CLEAN_TARGET += *.sim
CLEAN_TARGET += .Xil

.PHONY: all project clean

all: project

clean: 
	-rm -rf $(CLEAN_TARGET)

project:
	$(VIVADO) $(LIBRARY_NAME)_prj.tcl
