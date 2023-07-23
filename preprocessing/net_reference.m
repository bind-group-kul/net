function net_reference(processedeeg_filename,reference)

dataset_dir=fileparts(fileparts(processedeeg_filename));

net_dir=net('dir');

headmodel_filename=[dataset_dir filesep 'mr_data' filesep 'anatomy_prepro_headmodel.mat'];

img_filename=[dataset_dir filesep 'mr_data' filesep 'anatomy_prepro.nii'];

template_image=[net_dir filesep 'template' filesep 'tissues_MNI' filesep 'mni_template.nii'];

electrode_file=[dataset_dir filesep 'mr_data' filesep 'electrode_positions.sfp'];

if strcmp(reference.enable, 'on')
        if nargin<2
        reference.type = 'average';
    end
    
    if ~isfield(reference, 'type')
        reference.type = reference;
    end
    
    D=spm_eeg_load(processedeeg_filename);
    
    list_eeg = selectchannels(D,'EEG');
    nchan = length(list_eeg);
    
    
    switch reference.type
        
        case 'average'
            
            
            Refmatrix = eye(nchan)-ones(nchan)*1/nchan;
            
            
        case 'infinity'
            
            Refmatrix = net_infinity_reference(headmodel_filename);
            
            
        case 'mastoid'
            
            %coord_mni=[-75 8 -51; 75 8 -51]; %these are actually left and right preauriculars (in front of the ears), not left and right mastoids (bony spot that behind left and right ear lobes) 
            coord_mni = [-71, -52, -55; % L mastoid    % updated by M.Z. 26 June 2019
                          71, -52, -55]; % R mastoid
            coord_ind = net_set_fiducials(coord_mni,img_filename,template_image);
            elec_pos=ft_read_sens(electrode_file);
            dd=pdist2(elec_pos.chanpos,coord_ind);
            [val,index]=min(dd,[],1);
            nchan=size(elec_pos.chanpos,1);
            tmp_matrix=zeros(nchan,nchan);
            tmp_matrix(:,index)=0.5*ones(nchan,2);
            Refmatrix = eye(nchan)-tmp_matrix;
            
            
            
        case 'frontal'
            
            coord_mni=[0 88 -12];
            coord_ind = net_set_fiducials(coord_mni,img_filename,template_image);
            elec_pos=ft_read_sens(electrode_file);
            dd=pdist2(elec_pos.chanpos,coord_ind);
            [val,index]=min(dd,[],1);
            nchan=size(elec_pos.chanpos,1);
            tmp_matrix=zeros(nchan,nchan);
            tmp_matrix(:,index)=ones(nchan,1);
            
%             tmp_matrix=zeros(nchan,nchan);
%             sens = sensors(D,'EEG');
%             if strcmp(sens.type,'egi128')
%                 tmp_matrix(:,17)=ones(nchan,1);
%                 
%             elseif strcmp(sens.type,'egi256')
%                 tmp_matrix(:,31)=ones(nchan,1);
%                 
%             else
%                 disp('error: EEG system unknown');
%             end
            
            Refmatrix = eye(nchan)-tmp_matrix;
            
            
    end
    
    
    data_eeg = D(list_eeg,:,1);
    data_eeg=Refmatrix*data_eeg;
    D(list_eeg,:,1)=data_eeg;
    
    D.save;
    
end
