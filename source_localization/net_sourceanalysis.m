function  source=net_sourceanalysis(eeg_filename,headmodel_filename,source_filename,options_source)

NET_folder=net('path');

D = spm_eeg_load(eeg_filename);

[ddx,ffx,ext]=fileparts(headmodel_filename);
headmodel=load(headmodel_filename); %Load the volume conduction model file
[~, subject_info, ~] = fileparts(fileparts(ddx));

deformation_to_mni=[ddx filesep 'iy_anatomy_prepro.nii'];
tpmref_filename=[NET_folder filesep 'template' filesep 'tissues_MNI' filesep 'eTPM6.nii'];
elec_file=[ddx filesep 'electrode_positions.sfp'];

elecpos=readlocs(elec_file);

lead_demean=options_source.lead_demean;
normalize=options_source.lead_normalize;
normalizeparam=options_source.lead_normalizeparam;

leadfield=headmodel.leadfield;

vect=find(leadfield.inside);
Ndipoles=length(vect);
Nchan=length(leadfield.label);
lf=zeros(Nchan,3*Ndipoles);

for ii=1:Ndipoles
    ind=vect(ii);
    lf(:, (3*ii-2):(3*ii))=leadfield.leadfield{ind};
end

if strcmpi(lead_demean,'yes')
    for i=1:size(lf,2)
        lf(:,i) = lf(:,i) - mean(lf(:,i));
    end
end

%optionally apply leadfield normalization
switch normalize
    case 'yes'
        for ii=1:Ndipoles
            tmplf = lf(:, (3*ii-2):(3*ii));
            if normalizeparam==0.5
                % normalize the leadfield by the Frobenius norm of the matrix
                % this is the same as below in case normalizeparam is 0.5
                nrm = norm(tmplf, 'fro');
            else
                % normalize the leadfield by sum of squares of the elements of the leadfield matrix to the power "normalizeparam"
                % this is the same as the Frobenius norm if normalizeparam is 0.5
                nrm = sum(tmplf(:).^2)^normalizeparam;
            end
            if nrm>0
                tmplf = tmplf ./ nrm;
            end
            lf(:, (3*ii-2):(3*ii)) = tmplf;
        end
    case 'column'
        % normalize each column of the leadfield by its norm
        for ii=1:Ndipoles
            tmplf = lf(:, (3*ii-2):(3*ii));
            for j=1:size(tmplf, 2)
                nrm = sum(tmplf(:, j).^2)^normalizeparam;
                tmplf(:, j) = tmplf(:, j)./nrm;
            end
            lf(:, (3*ii-2):(3*ii)) = tmplf;
        end
end

for ii=1:Ndipoles
    ind=vect(ii);
    leadfield.leadfield{ind}=lf(:, (3*ii-2):(3*ii));
end

% --------------------------------------------------------------
% 1. Load EEG file, volume conduction model file and leadfield file

% --------------------------------------------------------------
% 2. Set the parameters for source localisation
data          = spm2fieldtrip(D);
data.label = upper(data.label);
sens          = sensors(D,'EEG');  % revised by QL, 12.02.2016
sens.chanpos = upper(sens.chanpos);
list_eeg      = selectchannels(D,'EEG');
data.label    = data.label(list_eeg);
data.trial{1} = data.trial{1}(list_eeg, :);
data.cov      = D.noisecov_matrix;

% --------------------------------------------
% 3 Source localisation
%disp('NET - The inverse solution...');
cfg = options_source;
cfg.grid     = leadfield;
cfg.vol      = headmodel.vol;
cfg.sens     = sens;
cfg.computekernel = 1;
cfg.keepleadfield = 'yes';
cfg.nAvg     = 1;
cfg.NoiseCov = D.noisecov_matrix;
source = net_source_calc(data,cfg);
source = ft_convert_units(source, 'mm');
source.sensor_data=data.trial{1};
source.elecpos=elecpos;
source.events=D.triggers;

pca_mat = zeros(Ndipoles,3*Ndipoles);

bar_len = 0;
for k=1:Ndipoles
    tic;    
    sigx = source.imagingkernel(1+3*(k-1),:)*source.sensor_data;
    sigy = source.imagingkernel(2+3*(k-1),:)*source.sensor_data;
    sigz = source.imagingkernel(3*k,:)*source.sensor_data;
    [coeff,score] = pca([sigx ; sigy ; sigz]');
    pca_mat(k,3*k-2:3*k) = coeff(:,1)';
    t=toc;
    bar_len = net_progress_bar_t(['NET source: ', subject_info, ': calculate first PCs'], k, Ndipoles, t, bar_len);
end

source.pca_projection=pca_mat;

if strcmpi(options_source.mni_initialize,'yes')

%% generate trasnformation to MNI space
Vt.dim      = headmodel.leadfield.dim;
Vt.pinfo    = [0.000001 ; 0 ; 0];
Vt.dt       = [16 0];
Vt.fname    = [ddx filesep 'tmp.nii'];
Vt.mat      = net_pos2transform(headmodel.leadfield.pos, headmodel.leadfield.dim);

vox_list=find(headmodel.leadfield.inside==1);

for i=1:length(vox_list)
    index=vox_list(i);
    [a,b,c]=ind2sub(headmodel.leadfield.dim,index);
    data_vox=zeros(headmodel.leadfield.dim);
    data_vox(a,b,c)=1;
    Vt.n        = [i 1];
    spm_write_vol(Vt, data_vox);  
end

output_res=options_source.mni_output_res;
smooth_fwhm=options_source.mni_smoothing;
input_images=[ddx filesep 'tmp.nii'];
bb=net_world_bb([tpmref_filename ',1']);
Vx=spm_vol(tpmref_filename);
data=spm_read_vols(Vx);
mask=zeros(size(data,1),size(data,2),size(data,3));
mask(data(:,:,:,1)>0.3)=1;

Vx(1).fname=[ddx filesep 'mask.nii'];
spm_write_vol(Vx(1),mask);

clear matlabbatch;

matlabbatch{1}.spm.util.defs.comp{1}.def = {deformation_to_mni};
matlabbatch{1}.spm.util.defs.out{1}.push.fnames = {input_images};
matlabbatch{1}.spm.util.defs.out{1}.push.weight = {''};
matlabbatch{1}.spm.util.defs.out{1}.push.savedir.saveusr = {ddx};
matlabbatch{1}.spm.util.defs.out{1}.push.fov.bbvox.bb = bb;
matlabbatch{1}.spm.util.defs.out{1}.push.fov.bbvox.vox = [output_res output_res output_res];
matlabbatch{1}.spm.util.defs.out{1}.push.preserve = 0;
matlabbatch{1}.spm.util.defs.out{1}.push.fwhm = [smooth_fwhm smooth_fwhm smooth_fwhm];
matlabbatch{1}.spm.util.defs.out{1}.push.prefix = 'w';

spm_jobman('run', matlabbatch);

clear matlabbatch;

matlabbatch{1}.spm.spatial.coreg.write.ref = {[ddx filesep 'wtmp.nii,1']};
matlabbatch{1}.spm.spatial.coreg.write.source = {[ddx filesep 'mask.nii']};
matlabbatch{1}.spm.spatial.coreg.write.roptions.interp = 0;
matlabbatch{1}.spm.spatial.coreg.write.roptions.wrap = [0 0 0];
matlabbatch{1}.spm.spatial.coreg.write.roptions.mask = 0;
matlabbatch{1}.spm.spatial.coreg.write.roptions.prefix = 'r';

spm_jobman('run', matlabbatch);

Vy=spm_vol([ddx filesep 'rmask.nii']);
[mask_new,xyz]=spm_read_vols(Vy);
mask_new=round(mask_new);
inside=find(mask_new(:)==1);
mat=zeros(length(vox_list),length(inside));
V=spm_vol([ddx filesep 'wtmp.nii']);

bar_len  = 0;
for i=1:length(vox_list)
   tic;
   data=spm_read_vols(V(i));
   mat(i,:)=data(inside);
   t = toc;
   bar_len = net_progress_bar_t(['NET source: ', subject_info, ': extract mask', ], i, length(vox_list), t, bar_len);
   
end

delete([ddx filesep 'tmp.nii']);
delete([ddx filesep 'wtmp.nii']);
delete([ddx filesep 'mask.nii']);
delete([ddx filesep 'rmask.nii']);

source.dim_mni=Vy.dim;
source.transform_mni=Vy.mat;
source.inside_mni=(mask_new(:)==1);
source.pos_mni=xyz';
source.spatial_filter_mni=mat';

end

save(source_filename, '-v7.3','source');  % to save the matrix bigger than 2GB, added by QL, 04.12.2014

