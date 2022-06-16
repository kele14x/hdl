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

% s
s = (0:(num_states - 1))';
irb = floor(s * 2 / 12);
ire = rem(s * 2 + 1, 12);

% Required bits for each state
required_bits = irb * bits_rb + (ire + 1) * bfp * 2 + 8;

% Required words for each state
required_words = ceil(required_bits / 64);

% Which state require new word from input
state_eat_new_word = required_words ~= circshift(required_words, 1);
state_eat_new_word_hex = dec2hex(sum(state_eat_new_word .* (2 .^ s)));

% Which state contains extra RE pair
state_extra_re_pair = state_eat_new_word & ~circshift(state_eat_new_word, -1);
state_extra_re_pair_hex = dec2hex(sum(state_extra_re_pair .* (2 .^ s)));

%
state_lsb = mod(64 - required_bits, 64);