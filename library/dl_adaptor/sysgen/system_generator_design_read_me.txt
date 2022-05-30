1. open xxx_init.m, change RAT_mode, bw_case, and simulation mode according to your need;
2. run xxx_init.m for parameter configuration
3. use xxx.slx file for module function simulation or verification;
4. use xxx_ctrl.slx for control logic generation, run HDL Netlist to generate HDL project 
5. use VIVADO to open the xxx_ctrl project, remove contraint file, reduce BUFG number to 0, configure out_of_context mode, run synthesis process, export DCP file aftet sysnthesis;
4. use xxx_data.slx for data processing generation, run HDL Netlist to generate HDL project 
5. use VIVADO to open the xxx_data project, remove contraint file, reduce BUFG number to 0, configure out_of_context mode, run synthesis process, export DCP file aftet sysnthesis;
6. copy and update dcp file in the topo project