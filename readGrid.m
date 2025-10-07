function [xyz, ind] = readGrid(pbin)

fh = fopen(pbin,'r');
endian = 'l';
magic_number = fread(fh,1,'int64',endian); % magic number
if magic_number ~= 1235813 
    endian = 'b';
end
fread(fh,1,'int64',endian); % skip version
np = fread(fh,1,'int64',endian); % number of points
assert(2 == fread(fh,1,'int64',endian)); % 0:no data, 1:delta, 2:index
buf = fread(fh,3*np,'double',endian); % always double for consistency w/ other pbins
ind = fread(fh,np,'int64',endian); % global index (should equal ordering in ascii file)
fclose(fh);

xyz = zeros(np,3);
for i=1:np
    for j=1:3
        xyz(1+ind(i),j) = buf(3*(i-1)+j);
    end
end

end