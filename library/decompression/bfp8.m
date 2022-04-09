%% 
clc;
clearvars;
close all;

%%
% bits of BFP format 
bfp = 8;

% Number of bits per RB
bits_rb = 8 + 12 * 2 * bfp;

% Number of bit in one loop cycle. This is LCM of bits_rb and 64.
% (64 is AXIS data width).
bits_lcm = lcm(bits_rb, 64);

% Number of RBs in one loop cycle
num_rb_lcm = bits_lcm / bits_rb;
% Number of REs in on loop cycle
num_re_lcm = num_rb_lcm * 12;

% Number of input words in one loop cycle
num_word_lcm = bits_lcm / 64;

% For output, write two REs at one tick (like uncompressed data)
% Also number of output words in one loop cycle
num_states = num_re_lcm / 2;

% Which state require new word from input
state_eat_new_word = zeros(num_states, 1);
state_eat_new_word_hex = int64(0);
bits = 0;
for s = 0:(num_states - 1)
    irb = floor(s * 2 / 12);
    ire = rem(s * 2 + 1, 12);
    required_bits = irb * bits_rb + (ire + 1) * bfp * 2 + 8;
    fprintf("%d, %d\n", s, required_bits);
    if (required_bits > bits)
        state_eat_new_word(s + 1) = 1;
        state_eat_new_word_hex = state_eat_new_word_hex + 2 ^ s;
        bits = bits + 64;
    end
end
assert(sum(state_eat_new_word) == num_word_lcm);
state_eat_new_word_hex = dec2hex(state_eat_new_word_hex);

% Which state contains extra RE pair
state_extra_re_pair = zeros(num_states, 1);
state_extra_re_pair_hex = int64(0);
for s = 0:(num_states - 1)
    next_s = rem(s + 1, num_states);
    if state_eat_new_word(s + 1) == 1 && state_eat_new_word(next_s + 1) == 0
        state_extra_re_pair(s + 1) = 1;
        state_extra_re_pair_hex = state_extra_re_pair_hex + 2 ^ s;
    end
end
state_extra_re_pair_hex = dec2hex(state_extra_re_pair_hex);
