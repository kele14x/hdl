function [addr, din, we] = write_one_lut(addr, din, we, ramd, offset)
% ramd: 1024, extended for 32*32
% Ram structure
% [A0; A1; A1; A2; A2; A3; ...] : B0
% 
% (1) B0,B2,B4; ... 
% (2) B1,B3,B5, ...
% ramd = B*32 + A

for bb = 0 : 1 : 15
    
    bn = floor(bb / 2);
    b01 = mod(bb, 2);
    
    offa = offset + bn * 16 * 2 + b01 * 256;
    for aa = 0:14
        coef0 = ramd(1+ bb*32 + aa);
        coef1 = ramd(1+ bb*32 + aa + 1);
        
        [addr, din, we] = push_command(addr, din, we, offa + 2*aa + 0, coef0, 1);
        [addr, din, we] = push_command(addr, din, we, offa + 2*aa + 1, coef1, 1);
    end
end

end