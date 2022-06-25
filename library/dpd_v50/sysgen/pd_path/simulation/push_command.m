function [addr, din, we] = push_command(addr, din, we, one_addr, one_data, wren)
addr.signals.values = [addr.signals.values; one_addr];
din.signals.values = [din.signals.values; to_unsigned(one_data)];
we.signals.values = [we.signals.values; wren];
end

function d = to_unsigned(d)
d(d < 0) = d(d < 0) + 2^32;
end