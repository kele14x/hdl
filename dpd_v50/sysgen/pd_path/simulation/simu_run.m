% clear others
clear;

% start
simu_env;
clc;

% ------
fprintf('>>: start simulation ----------\n');
sim('pd_path_sg.slx', 22000);

clc;
fprintf('>>: stop simulation ----------\n');

% verify output
simu_result;
