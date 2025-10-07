function analyze_volume_data(start_tid, end_tid, rank, num_cores)

% Olivia Martin
% Read in probe data and re-sample into a matrix

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Input parameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% USE INDICES MAPPING IF ALREADY COMPUTED
indicesCellAvail = 0;
indicesFilename = {'volume_data_output/volume_data_indices.mat'};

% START / END / DT OF SAMPLING
start_steps = [start_tid];
end_steps = [end_tid];
dt = 100;

% PROBE NAMES 
prefix = 'probe.';
suffix = '.pcd';
directories = {'../../run1/'}; % directories where probes are
points_files = 'probe.pbin';

% MATLAB FILE WITH X,Y,Z POINT LOCATIONS
block_data_files = 'volDat.mat'; 

% TXT FILE WITH X,Y,Z POINT LOCATIONS
gridPts = importdata('../../volume_probe_fixed.txt');
gridPtsDat = gridPts.data;

% THRESHOLD FOR LOCATING POINTS
threshold = 10^-6;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% LOAD IN GRID AND FIND INDICES MAPPING
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
time_index = 0;

n = str2double(getenv("SLURM_CPUS_PER_TASK"));
parpool("threads", n);  % explicitly start a thread pool

% LOOP OVER DIRECTORIES IN CASE PROBING CHANGED
for n = 1:length(directories)

    % LOAD IN POINT FILE
    pts_file = strcat(directories{n}, points_files);
    pts_file
    [xyz, ind] = readGrid(pts_file); 
    x = xyz(:,1);
    y = xyz(:,2);
    z = xyz(:,3);

    % LOAD IN MATLAB BLOCK DATA FILE
    load(block_data_files);
    numBlocks = length(xDATA);

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % LOOP OVER THE BLOCKS 
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    indicesCell = {};

    % ONLY DO THIS IF MAPPING IS NOT AVAILABLE
    if indicesCellAvail == 0
    for blk = 1:numBlocks

        % GET X,Y,Z
        X = xDATA{blk};
        Y = yDATA{blk};
        Z = zDATA{blk};

        % GET Nx,Ny,Nz
        Nx = size(X,1); 
        Ny = size(X,2); 
        Nz = size(X,3);

	% SET UP MAPPING MATRIX
        indices = zeros(Nx, Ny, Nz);

	% LOOP OVER X
        parfor i = 1:Nx

            % SETUP TMP VECTOR SO WE CAN PARALLELIZE 
            indices_tmp = zeros(Ny,Nz);	

	    % LOOP OVER Y & Z
            for j = 1:Ny
                for k = 1:Nz

		     % CHECK IF POINT IS CLOSE ENOUGH TO X,Y,Z IN BLOCK DATA
                     cond1 = (abs(xyz(:,1) - X(i,j,k)) < threshold);
	             cond2 = (abs(xyz(:,2) - Y(i,j,k)) < threshold);
	             cond3 = (abs(xyz(:,3) - Z(i,j,k)) < threshold);
	             idx = find(cond1 & cond2 & cond3);

		     % LENGTH(IDX) SHOULD NOT BE > 1 - THROW AN ERROR HERE
                     if length(idx) == 1
                        indices_tmp(j,k) = idx;
		     elseif length(idx) == 2  % there can be 2 overlapping points but that's it
			indices_tmp(j,k) = idx(1);
                     else
                        error('ERROR - point mapped to multiple points block data matrix');
                     end
                end
            end

	    % STORE INDICES_TMP
            indices(i,:,:) = indices_tmp;

	    % PRINT OUT PROGRESS
	    fprintf(strcat('\n Finished index ', num2str(i), ' out of ', num2str(Nx), '\n'));
        end

	% STORE INDICES IN BLOCK CELL
        indicesCell{blk} = indices;
	end

	% SAVE
        if rank == 0 & indicesCellAvail == 0
           save('volume_data_output/volume_data_xyz.mat', 'zDATA', 'yDATA', 'xDATA', '-v7.3'); 
           save('volume_data_output/volume_data_indices.mat', 'indicesCell', '-v7.3');
        end

    % LOAD MAPPING IF IT'S ALREADY BEEN COMPUTED
    else
	load(indicesFilename{n});
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % LOAD FLOW DATA
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    data_vect = [start_steps(n):dt:end_steps(n)];
    N_time = length(data_vect);

    % COMPUTE NUMBER OF TIMESTEPS TOTAL
    if n == 1
        N_time_tot = 0
	for l = 1:length(directories)
	    vect = [start_steps(n):dt:end_steps(n)];
	    N_time_tot = N_time_tot + length(vect);
	end
    end 

    % SETUP BLOCK DATA FOR FLOW DATA AT FIRST TIME
    if n == 1
    	U_blk = {};
    	V_blk = {};
    	W_blk = {};
    	T_blk = {};
    	P_blk = {};
    	Rho_blk = {};

    	% LOOP OVER BLOCKS AND PRE-ALLOCATE SPACE
    	for i = 1:length(indicesCell)
		X = xDATA{i};
        	Y = yDATA{i};
        	Z = zDATA{i};
		Nx = size(X,1); 
        	Ny = size(X,2); 
        	Nz = size(X,3); 
        	U = zeros(N_time_tot, Nx, Ny, Nz);
        	V = zeros(N_time_tot, Nx, Ny, Nz);
        	W = zeros(N_time_tot, Nx, Ny, Nz);
        	T = zeros(N_time_tot, Nx, Ny, Nz);
        	P = zeros(N_time_tot, Nx, Ny, Nz);
        	Rho = zeros(N_time_tot, Nx, Ny, Nz);

		U_blk{i} = U;
		V_blk{i} = V;
		W_blk{i} = W;
		P_blk{i} = P;
		T_blk{i} = T;
		Rho_blk{i} = Rho;
	end
    end

    % LOOP OVER TIME AND GET FLOW DATA
    for m = 1:N_time

	% READ DATA FROM FILENAME
        file_name = strcat(directories{n}, prefix, num2str(data_vect(m), '%08d'), suffix);
        data = readData(file_name, pts_file);

	% LOOP OVER BLOCKS
        for blk = 1:length(indicesCell)

	    % GET X,Y,Z
            X = xDATA{blk};
            Y = yDATA{blk};
            Z = zDATA{blk};
    
            % GET Nx,Ny,Nz
            Nx = size(X,1); 
            Ny = size(X,2); 
            Nz = size(X,3); 

	    % SETUP TEMPORARY
            U = zeros(Nx, Ny, Nz);
            V = zeros(Nx, Ny, Nz);
            W = zeros(Nx, Ny, Nz);
            T = zeros(Nx, Ny, Nz);
	    P = zeros(Nx, Ny, Nz);
	    Rho = zeros(Nx, Ny, Nz);

            % get indices 
            indices = indicesCell{blk};

            for i = 1:Nx
                for j = 1:Ny
                    for k = 1:Nz
                         if indices(i,j,k) ~= 0
                             U(i,j,k) = data(5, indices(i,j,k));
                             V(i,j,k) = data(6, indices(i,j,k));
                             W(i,j,k) = data(7, indices(i,j,k));
                             T(i,j,k) = data(1, indices(i,j,k));
                             P(i,j,k) = data(8, indices(i,j,k));
                             Rho(i,j,k) = data(9, indices(i,j,k));
		         else
			     error('ERROR - error in assigning data');
			 end
	             end  
                end  
            end  

	   global_time_idx = time_index+m;

	   U_blk{blk}(global_time_idx,:,:,:) = U;
           V_blk{blk}(global_time_idx,:,:,:) = V;
           W_blk{blk}(global_time_idx,:,:,:) = W;
           T_blk{blk}(global_time_idx,:,:,:) = T;
           P_blk{blk}(global_time_idx,:,:,:) = P;
           Rho_blk{blk}(global_time_idx,:,:,:) = Rho;
        end

	% PRINT TIME INDEX
        fprintf(strcat('\n we are at ', num2str(global_time_idx), ' out of ', num2str(N_time_tot), '\n'));

    end

    % adjust starting time index for data in multiple directories
    time_index = time_index + N_time;
end

delete(gcp('nocreate'));

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % Save data
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
save(strcat('volume_data_output/volume_data_u', num2str(rank), '.mat'), 'U_blk', '-v7.3');
save(strcat('volume_data_output/volume_data_v', num2str(rank), '.mat'), 'V_blk', '-v7.3');
save(strcat('volume_data_output/volume_data_w', num2str(rank), '.mat'), 'W_blk', '-v7.3');
save(strcat('volume_data_output/volume_data_p', num2str(rank), '.mat'), 'P_blk', '-v7.3');
save(strcat('volume_data_output/volume_data_T', num2str(rank), '.mat'), 'T_blk', '-v7.3');
save(strcat('volume_data_output/volume_data_rho', num2str(rank), '.mat'), 'Rho_blk', '-v7.3');

end
