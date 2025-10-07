function combine_data(prefix, suffix, vars, num_ranks, xyz_filename, out_dir)

% combine data from different ranks into one file
% vars is a list of the variables to combine
% this code assumes that all data files are the same length in time
  
for i = 1:length(vars)  
    for j = 0:num_ranks-1

	    filename = strcat(prefix, num2str(vars{i}), num2str(j), suffix);   

        % load in data file
        load(filename);
        if vars{i} == 'p'
            data = P_blk;
        elseif vars{i} == 'u'
            data = U_blk;
        elseif vars{i} == 'v'
            data = V_blk;
        elseif vars{i} == 'w'
            data = W_blk;
        elseif vars{i} == 'T'
            data = T_blk;
        elseif vars{i} == 'rho'
           data = Rho_blk;
        end
         
        if i == 1 & j == 0
            % load in grid file
            load(xyz_filename);

            % get dimensions
            blockT = size(data{1},1);
            numT = size(data{1},1) * num_ranks;
            numX = size(xDATA{1},1);
            numY = size(xDATA{1},2);
            numZ = size(xDATA{1},3) + size(xDATA{3},3) + size(xDATA{4},3) - 2;

            q = zeros(numT, numX, numY, numZ);
            x = zeros(numX, numY, numZ);
            y = zeros(numX, numY, numZ);
            z = zeros(numX, numY, numZ);

            % make matrices with xyz data
            x1 = xDATA{1}; y1 = yDATA{1}; z1 = zDATA{1};
            x2 = xDATA{2}; y2 = yDATA{2}; z2 = zDATA{2};
            x3 = xDATA{3}; y3 = yDATA{3}; z3 = zDATA{3};
            x4 = xDATA{4}; y4 = yDATA{4}; z4 = zDATA{4};
            x5 = xDATA{5}; y5 = yDATA{5}; z5 = zDATA{5};

            centerBlock_x = cat(2, x3(:,1:end-1,:), x5(:,:,:), x2(:,2:end,:));
            centerBlock_y = cat(2, y3(:,1:end-1,:), y5(:,:,:), y2(:,2:end,:));
            centerBlock_z = cat(2, z3(:,1:end-1,:), z5(:,:,:), z2(:,2:end,:));

            x = cat(3, x4(:,:,1:end-1), centerBlock_x, x1(:,:,2:end));
            y = cat(3, y4(:,:,1:end-1), centerBlock_y, y1(:,:,2:end));
            z = cat(3, z4(:,:,1:end-1), centerBlock_z, z1(:,:,2:end));

            size(x);
            size(y);
            size(z);

            save(strcat(out_dir,'xyz.mat'), 'x', 'y', 'z', '-v7.3');
            clear x y z
        end

        start_tid = j*blockT+1;
        end_tid = start_tid + blockT - 1;

        % make matrices with xyz data
        d1 = data{1};
        d2 = data{2};
        d3 = data{3}; 
        d4 = data{4}; 
        d5 = data{5}; 

        centerBlock = cat(3, d3(:,:,1:end-1,:), d5(:,:,:,:), d2(:,:,2:end,:));
        q(start_tid:end_tid,:,:,:) = cat(4, d4(:,:,:,1:end-1), centerBlock, d1(:,:,:,2:end));

	fprintf(strcat('\n on block ', num2str(j), ' of ', num2str(num_ranks)))   
    end

    f_name = strcat(out_dir, vars{i}, '_dat.mat');
    save(f_name, 'q', '-v7.3');
    clear q
end

end
