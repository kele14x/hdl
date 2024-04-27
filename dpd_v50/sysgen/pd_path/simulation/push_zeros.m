function [addr, din, we] = push_zeros(addr, din, we, num)

addr.signals.values = [addr.signals.values; zeros(num,1)];
din.signals.values = [din.signals.values; zeros(num,1)];
we.signals.values = [we.signals.values; zeros(num,1)];

end