% Before running the script, you'd better to check all lines and change
% them in your own way.
warning off



Threshold_negative = -1; % z-threshold for showing the map of component
Threshold_positive = 2;
% TR = 2;    %  TR



PATH_source = '/Users/quanyingliu/Desktop/NET/testing_data/median_nerve_sti/simbio_eloreta';

subs = dir([PATH_source,filesep,'sw*.nii']);

for isub=1:length(subs)
    
    % Name = subs(isub+3).name;
    
    
    
    fprintf('Preprocessing subject : %s \n',subs(isub).name);
    V = spm_vol([PATH_source,filesep,subs(isub).name]);
    ICdata = spm_read_vols( V );
    
    Arti = zeros(size(ICdata,4),1);
    for i=1:size(ICdata,4)
        IC = ICdata(:,:,:,i);
        %                 IT = ITdata(:,i);
        
        % Skip this step if the component map has already been z-transformed
        IC(find(isnan(IC))) = 0;
        Ind = find(IC);
        IC(Ind) = (IC(Ind)-mean(IC(Ind)))./std(IC(Ind)); % z-score
        
        %            IC(find(IC < Threshold_positive & IC > Threshold_negative)) = 0;
        %            IC = abs(IC);
        IC(find(IC < Threshold_positive)) = 0;
        
        
        %%%%%%%%%%%% visualize the component map
        Curp = which('MRIDOI');
        Curp = fileparts(Curp);
        V.fname = [Curp,'Test3D.nii'];
        V.dt = [16 0];
        spm_write_vol(V,IC);
        
        OP.Anatomi          = [Curp,'/Templates/',filesep,'ch2bet.nii'];
        
        OP.OverlayImg       = V.fname;
        
        OP.interp           = 4;
        OP.Fsize            = [7 7]; % [8 8];
        OP.SliceLabelV      = 'off';
        OP.colorbar         = 'on';
        OP.Direction        = 'Axial';  % 'Sagittal' or 'Coronal' or 'Axial'
        OP.Rescale          = 'on';
        OP.fname            = 'Test';
        OP.Save             = 'off';
        
        MRIDOI(OP)
        clear OP
        
        delete(V.fname);
        
        export_fig( [PATH_source filesep 'Axial' '_' subs(isub).name(1:end-4) '.tif'], '-nocrop', '-r70');
        close all
    end
    
end