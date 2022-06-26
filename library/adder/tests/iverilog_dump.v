module iverilog_dump();
initial begin
    $dumpfile("adder.vcd");
    $dumpvars(0, adder);
end
endmodule
