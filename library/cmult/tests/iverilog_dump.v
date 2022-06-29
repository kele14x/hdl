module iverilog_dump();
initial begin
    $dumpfile("cmult.vcd");
    $dumpvars(0, cmult);
end
endmodule
