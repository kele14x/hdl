module iverilog_dump();
initial begin
    $dumpfile("fft.vcd");
    $dumpvars(0, fft);
end
endmodule
