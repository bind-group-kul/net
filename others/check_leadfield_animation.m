clear;clc;
headmodel_filename = '/Users/mingqi.zhao/CodeAndDataSpace/data/pilot/pilot_net_2.13/dataset2/mr_data/anatomy_prepro_headmodel.mat';

load(headmodel_filename);

graymatter_voxels_leadfield = leadfield.leadfield(leadfield.inside == 1);
graymatter_voxels_position = leadfield.pos(leadfield .inside == 1,:);

%% load template file
net_path = net();
template_sfp = [net_path, filesep, 'template', filesep, 'electrode_position', filesep, 'bp128_corr.sfp'];
locs = readlocs(template_sfp);

for index = 1:1:length(graymatter_voxels_leadfield)
    voxel_leadfield = graymatter_voxels_leadfield{index}; %the numbers are x y z oscilation strength for each channel?
    voxel_position = graymatter_voxels_position(index,:).*10; % in mm
    %% calculate power for each electrode
    power = voxel_leadfield(:,1).^2 + voxel_leadfield(:,2).^2 + voxel_leadfield(:,3).^2;    
    [im_handler, z, grid, x, y] = topoplot(power, locs, 'electrodes', 'ptslabels', 'plotdisk', 'on', 'noplot', 'on');
    x=x(1,:);
    y=y(:,1)';
    imagesc('XData', x, 'YData', y, 'CData', z);
    xlim([x(1),x(end)]);xlabel('x');
    ylim([y(1),y(end)]);ylabel('y');
    title(['\fontsize{20}', 'scalp activation of voxel ', num2str(voxel_position(1)),', ',  num2str(voxel_position(2)),', ',num2str(voxel_position(3))]);
    M(index)=getframe;
end