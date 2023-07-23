clear all

A = load('C:\SoliD\KU\Net\Share\NET_v2.20\Net_prb_SoliD\dataset1\mr_data\anatomy_prepro_headmodel.mat');
B = load('C:\SoliD\KU\Net\Share\NET_v2.20\Net_prb_SoliD_MAC\dataset1\mr_data\anatomy_prepro_headmodel.mat');


[Anonz Aval] = find(A.leadfield.inside == 1);
[Bnonz Bval] = find(B.leadfield.inside == 1);

Nnz = length(Anonz);
Nec = length(A.leadfield.label);
A_L = zeros(Nnz, Nec, 3);
B_L = A_L;

for a = 1:length(Anonz)
    A_L(a,:,:) = A.leadfield.leadfield{Anonz(a)};
    B_L(a,:,:) = B.leadfield.leadfield{Anonz(a)};
end

src = 1000;
figure, hold on
plot(A_L(src,:,3), '-sb')
plot(B_L(src,:,3), '-ok')