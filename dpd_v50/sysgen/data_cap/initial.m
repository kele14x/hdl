
THIS_DATE = hex2dec('20171106');
fprintf(1, 'Design tag is 0x%x\n', THIS_DATE);

cap_ram = 32;       % 64 or 32

% if cap_ram == 64
%     ram_core_depth = 65536;
%     cap_addr_width = 15;
%     
% else
%     ram_core_depth = 32768;
%     cap_addr_width = 14;
%     
% end

    ram_core_depth = 32768;
    cap_addr_width = 14;
    
% 
% 
% b0 = load('para/insamp_s0.txt');
% b0 =[0.1 0.5 -0.2];

Ai = null_item;
Aq = null_item;
Bi = null_item;
Bq = null_item;

tori0 = null_item;
torq0 = null_item;
tori1 = null_item;
torq1 = null_item;

short_per_addr = null_item;
short_per_din = null_item;
short_per_we = null_item;


full_per_addr = null_item;
full_per_din = null_item;
full_per_we = null_item;
full_per_rden = null_item;
