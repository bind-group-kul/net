img_filename_orig=[ddx filesep 'anatomy.nii'];

img_filename=[ddx filesep 'anatomy_prepro.nii'];

imgmni_filename=[ddx filesep 'anatomy_prepro_mni.nii'];

anat_filename=[NET_folder filesep 'template' filesep 'tissues_MNI' filesep options.sMRI.template '.nii'];

tpm_filename=[NET_folder filesep 'template' filesep 'tissues_MNI' filesep options.sMRI.tpm '.nii'];

tpmref_filename=[NET_folder filesep 'template' filesep 'tissues_MNI' filesep 'eTPM6.nii'];

segimg_filename=[ddx filesep 'anatomy_prepro_segment.nii'];

bx_filename = [ddx filesep 'bx_sMRI.mat'];

elec_filename=[ddx filesep 'electrode_positions.sfp'];

headmodel_filename=[ddx filesep 'anatomy_prepro_headmodel.mat'];

raweeg_filename=[ddy filesep 'raw_eeg.mat'];

processedeeg_filename=[ddy filesep 'processed_eeg.mat'];

source_filename=[ddz filesep 'sources_eeg.mat'];