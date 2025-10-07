%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
% OLIVIA MARTIN - VOLUME SPOD
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
addpath('spod_matlab/');
addpath('LES_data/');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Load data for volume SPOD 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
filename = 'LES_data/p_dat.mat';
load(filename)
fprintf('\nloaded data!\n')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% EXTRACT DATA FOR X >= 0
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
load('../LES_data/xyz.mat');
idx = x(:,1,1) >= -0.00001;
x = x(idx,:,:);
y = y(idx,:,:);
z = z(idx,:,:);
q = q(:,idx,:,:);

save('results/xyz_outside.mat', 'x', 'y', 'z');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SPOD PARAMETERS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
sampsPerBlock = 1000;
opts.mean = 'blockwise';
opts.savedir = 'results/';
opts.savefft = true;
nOverlap = sampsPerBlock/2;
dt = 0.2;

[L,P,f,Lc,A] = spod(q,sampsPerBlock, [], nOverlap, dt, opts);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% save expansion coefficients
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
saveFile = strcat(opts.savedir, 'expCoeff.mat');
save(saveFile, 'A', 'f', 'L');
