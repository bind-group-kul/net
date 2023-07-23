% SetStiffnessMatrix.m
% Ernesto Cuartas M (ECM), 24/04/2017
% Email:  ecuartasmo@unal.edu.co

function [ mA, c_idx, Cidx, Nz] = SetStiffnessMatrixMac( cfg )

fncidx = [ cfg.folder filesep 'tmp' filesep 'cidx.bin'];
fnAbin = [ cfg.folder filesep 'tmp' filesep 'A_bin.bin'];
fnIbin = [ cfg.folder filesep 'tmp' filesep 'I_bin.bin'];
fnJbin = [ cfg.folder filesep 'tmp' filesep 'J_bin.bin'];

% Reading binary data from BioCalc.exe
tic
fid1 = fopen(fnAbin, 'r');
[As, count] = fread(fid1,'double', 'n');
fclose(fid1);

fid2 = fopen(fnIbin, 'r');
[Is, count] = fread(fid2,'int', 'n');
fclose(fid2);

fid3 = fopen(fnJbin, 'r');
[Js, count] = fread(fid3,'int', 'n');
fclose(fid3);

fid = fopen(fncidx, 'r');
[Cidx, count] = fread(fid,'int64', 'n');
fclose(fid);
tread = toc;

fprintf('Read Binary elapsed time: %f\n', tread);

Nz = Is(length(Is),1) + 1;

mA = sparse(Is+1, Js+1, As, Nz, Nz, length(As));

c_idx = zeros(cfg.Size(1)+1, cfg.Size(2)+1, cfg.Size(3)+1);

pos = 0;

% Non Zeros vector Cidx to Matrix c_idx
for c = 1: cfg.Size(3)+1
    for b = 1: cfg.Size(2)+1
        for a = 1: cfg.Size(1)+1
            pos = pos +1;
            c_idx(a,b,c) = Cidx(pos);
        end
    end    
end
