function gui_connectivity_output(handles)

k = handles.k;
fontsize = handles.fontsize;
fontname = handles.fontname;

fig_name = 'Connectivity analysis sample outputs';

findwindow = findobj('Tag','fig_visual','-and','Name',fig_name);
if ~isempty(findwindow)
    close(findwindow);
end

fig_output = figure('Units','Normalized','Position',[0.01 0.66 0.25 0.25],...
        'NumberTitle','Off','Name',fig_name,'Tag','fig_visual');
fig_output.set('Menubar','none');

mainbox = uiextras.VBox('Parent',fig_output,'Padding',10*min(k));

    uicontrol('Parent',mainbox,'Style','Text','String','Choose output(s) to visualize:',...
        'FontName',fontname,'FontSize',fontsize);    

    hbox = uiextras.HBox('Parent',mainbox,'Spacing',10*min(k),'Padding',5*min(k));
    
        uiextras.Empty('Parent',hbox);

        box_buttons = uiextras.VBox('Parent',hbox,'Padding',5*min(k));
            uicontrol('Parent',box_buttons,'Style','text','String','Connectivity maps',...
                'FontName',fontname,'FontSize',fontsize);
            
            idx_dataset = get(handles.menu_visual_dataset,'Value') - 1;
            search_dir = [handles.outdir filesep 'dataset' num2str(idx_dataset) filesep 'eeg_source'];
            handles.map_list = dir(search_dir);
            s = [{'Choose method'}];
            if isdir([search_dir filesep 'ica_results'])
                ica_list = dir([search_dir filesep 'ica_results']);
                ica_list = ica_list([ica_list.isdir]);
                ica_list = ica_list(~ismember({ica_list.name},{'.','..'}));
                for idx = 1:length(ica_list)
                    s = [s; {['ica_results' filesep ica_list(idx).name]}];
                end
            end
            if isdir([search_dir filesep 'seed_connectivity'])
                s = [s; {'seed_connectivity'}];
            end
            handles.menu_conn_type = uicontrol('Parent',box_buttons,'Style','popupmenu','String',s,...
                'FontName',fontname,'FontSize',fontsize,'Callback',@select_conn_type);            
            
            handles.select_map = uicontrol('Parent',box_buttons,'Style','popupmenu','String','Choose map',...
                'FontName',fontname,'FontSize',fontsize,'Callback',@show_img);
            
            uicontrol('Parent',box_buttons,'Style','text','String','Connectivity matrices',...
                'FontName',fontname,'FontSize',fontsize);
            
            button_matrix = uicontrol('Parent',box_buttons,'Style','pushbutton','String','Plot',...
                'FontName',fontname,'FontSize',fontsize,'Enable','Off','Callback',@show_matrix);
            connmatrixname = dir([search_dir filesep 'seed_connectivity' filesep 'matrix_connectivity' filesep '*' '_matrix_connectivity.mat']); % JS, 08.2023
            if exist([ connmatrixname.folder filesep connmatrixname.name],'file')
                set(button_matrix,'Enable','On');
            end
            
        set(box_buttons,'Sizes',[25*k(2) 25*k(2) 40*k(2) 25*k(2) 30*k(2)])

        uiextras.Empty('Parent',hbox);
    
    set(hbox,'Sizes',[-1 200*k(2) -1])
set(mainbox,'Sizes',[-1 180*k(2)])
    
guidata(fig_output,handles)
end

%% GUI callback functions

                    % --- start function
function template_function(hObject, eventdata, handles)
handles = guidata(gcbo);

guidata(gcbo,handles)
end                 % --- end function

                    % --- start select_conn_type
function select_conn_type(hObject, eventdata, handles)
handles = guidata(gcbo);
    
    set(handles.select_map,'Value',1)
    idx_dataset = get(handles.menu_visual_dataset,'Value') - 1;
    conn_type = get(handles.menu_conn_type,'String');
    conn_type = conn_type(get(handles.menu_conn_type,'Value'));
    if strcmpi(conn_type,'seed_connectivity')
        search_dir = [handles.outdir filesep 'dataset' num2str(idx_dataset) filesep 'eeg_source' filesep char(conn_type) filesep '*/*.nii'];
    else
        search_dir = [handles.outdir filesep 'dataset' num2str(idx_dataset) filesep 'eeg_source' filesep char(conn_type) filesep 'mni' filesep 'rsn' filesep '*.nii'];
    end
    handles.map_list = dir(search_dir);
    s = [{'Choose map'}];
    for m = 1:length(handles.map_list)
        s = [s; {handles.map_list(m).name}];
    end
    set(handles.select_map,'String',s);

guidata(gcbo,handles)
end                 % --- end select_conn_type

                    % --- start show_img
function show_img(hObject, eventdata, handles)
handles = guidata(gcbo);
    
        idx_dataset = get(handles.menu_visual_dataset,'String');
        idx_dataset = idx_dataset(get(handles.menu_visual_dataset,'Value'));

        idx_map = get(handles.select_map,'Value');
        if idx_map > 1
        seedimg_list = get(handles.select_map,'String');
        seedimg_filename = seedimg_list(idx_map);
        seedimg_info = upper(split(seedimg_filename,'_'));
        if strcmpi(seedimg_info(end),'mni.nii')
            title = [char(idx_dataset) ' - Connectivity map: ' char(seedimg_filename{1}(1:end-4)) ' - Template MRI'];
            background_img = handles.anat_filename;
            % Resample map (temporary)
            [bb,vox] = net_world_bb(background_img);
            net_resize_img([handles.map_list(idx_map-1).folder filesep handles.map_list(idx_map-1).name],vox,bb);
        else
            title = [char(idx_dataset) ' - Connectivity map: ' char(seedimg_filename{1}(1:end-4)) ' - Individual MRI'];
            background_img = handles.img_filename;
            % Resample map (temporary)
            [bb,vox] = net_world_bb(background_img);
            net_resize_img([handles.map_list(idx_map-1).folder filesep handles.map_list(idx_map-1).name],vox,bb);
        end
        fig_img = figure('Units','Normalized','Position',[0.3 0.0 0.64 1],...
            'NumberTitle','Off','Name',title);
        nii = load_nii(background_img);
        res_seedimg_filename = [handles.map_list(idx_map-1).folder filesep 'r' handles.map_list(idx_map-1).name];
        seed = load_nii(res_seedimg_filename);
        % Delete resampled map
        delete(res_seedimg_filename);
        %{
        % Adjust values for visualization
        seed_minval = 0; %0.01;
        seed_maxval = max(seed.img(:));
        seed.img(seed.img<0) = 0;
        seed.img(seed.img>0 & seed.img<seed_minval) = seed_minval;
        seed.img(seed.img>seed_maxval) = seed_maxval;
        %}
        
        %opt.setvalue.idx = find(seed.img>0.01);
        %opt.setvalue.val = seed.img(opt.setvalue.idx);
        opt.setvalue.idx = find(seed.img);
        opt.setvalue.val = seed.img(opt.setvalue.idx);
        opt.useinterp = 1;
        opt.usepanel = 1;
        %opt.glblocminmax = [0.01 max(seed.img(:))];
        %opt.setcbarminmax = opt.glblocminmax; %[0.1 5*max(seed.img(:))];
        opt.command = 'init';
        opt.setarea = [0.05 0.05 0.9 0.9];
        set(gcf, 'Pointer', 'watch');
        view_nii(fig_img,nii,opt);
        opt.setcolorindex = 7;
        opt.command = 'update';
        view_nii(fig_img,nii,opt);
        set(gcf, 'Pointer', 'arrow');
        end
        
guidata(gcbo,handles);
end                 % --- end show_img

                    % --- start show_matrix
function show_matrix(hObject, eventdata, handles)
handles = guidata(gcbo);

idx_dataset = get(handles.menu_visual_dataset,'String');
idx_dataset = idx_dataset(get(handles.menu_visual_dataset,'Value'));

path = [handles.outdir filesep 'dataset'];

idx_subj = idx_dataset{1}((length('Dataset ')+1):end); % remove string 'Dataset ', keep number
connmatrixname = dir([path idx_subj filesep 'eeg_source' filesep 'seed_connectivity' filesep 'matrix_connectivity' filesep '*' 'matrix_connectivity.mat']); % JS, 08.2023
conn_data = load([ connmatrixname.folder filesep connmatrixname.name]);

nseed = numel(conn_data.seed_info);
seedname = {};
for ns = 1:nseed
    seedname{ns}  = conn_data.seed_info(ns).label;
    seedname{ns} = upper(strrep(seedname{ns},'_','-'));
end

band = {1:4,4:8,8:13,13:30,30:80};
bandname = {'Delta (1-4 Hz)','Theta (4-8 Hz)','Alpha (8-13 Hz)','Beta (13-30 Hz)','Gamma (30-80 Hz)'};
nband = numel(band);

%{
% load correlation values
% -----------------------
tmp = zeros(nseed,nseed,nf,nsubj);
for i = 1:nsubj
    s = subjects(i);
    load( [ path num2str(s) filesep 'eeg_source' filesep 'seed_connectivity' filesep 'matrix_connectivity.mat'] )
    % l'autocorrelazione di ogni seed con se stesso non viene calcolata ed é posta a 0,
    % ma va modificata (-> nan) per calcolare la connettivitá dentro la network
    corr_matrix(corr_matrix == 0) = nan; 
    tmp(:,:,:,i) = corr_matrix;
end

% organize data for following sections
% ------------------------------------
conn_band = zeros(nseed,nseed,nsubj,nband);         % average over bands
for b = 1:nband
    conn_band(:,:,:,b) = squeeze(nanmean(tmp(:,:,band{b},:),3));
end
conn_band1 = conn_band;
%}

% plot seed connections for each band
idx_dataset = get(handles.menu_visual_dataset,'String');
idx_dataset = idx_dataset(get(handles.menu_visual_dataset,'Value'));

maxval = 0; minval = 0;
for b = 1:nband
    matrixval = nanmean(conn_data.corr_matrix(:,:,band{b}),3);
    maxval = max(maxval,max(matrixval(:)));
    minval = min(minval,min(matrixval(:)));
end

fig = figure('Units','Normalized','Position',[0.05 0.0 0.92 1],...
        'NumberTitle','Off','Name',[char(idx_dataset) ' - Connectivity matrices']);
ncol = round(nband/2);

maxcval = 0; mincval = 0;
for b = 1:nband
    subplot(2,ncol,b)
    imagesc(nanmean(conn_data.corr_matrix(:,:,band{b}),3));
    %caxis(conn_range)
    cax = caxis;
    caxis([minval maxval])
    maxcval = max(maxcval,cax(2));
    mincval = min(mincval,cax(1));
    ax = gca; ax.TickLength = [0,0]; daspect([1 1 1]);
    ax.XTickLabel = seedname; ax.YTickLabel = seedname;
    ax.XTick = 1:nseed; ax.YTick = 1:nseed; xtickangle(ax,45);
    title(bandname{b})
end
colormap(bipolar(256, mincval, maxcval))
cbar_pos = get(subplot(2,ncol,nband),'Position');
colorbar('Location','eastoutside','Position', [cbar_pos(1)+cbar_pos(3)+0.01 cbar_pos(2) 0.01 cbar_pos(4)])
%colorbar('Location','southoutside','Position', [cbar_pos(1) cbar_pos(2)-0.085 cbar_pos(3) 0.02])
%colorbar('Position', [hp4(1)+hp4(3)+0.02  hp4(2)*1.5  0.02  hp4(2)+hp4(3)*2.1])

%%% ONE COLORBAR PER MATRIX
%{
maxcval = 0; mincval = 0;
for b = 1:nband
    splt = subplot(2,ncol,b);
    imagesc(nanmean(conn_data.corr_matrix(:,:,band{b}),3));
    %caxis(conn_range)
    cax = caxis;
%     caxis([minval maxval])
    maxcval = max(maxcval,cax(2));
    mincval = min(mincval,cax(1));
    ax = gca; ax.TickLength = [0,0]; daspect([1 1 1]);
    ax.XTickLabel = seedname; ax.YTickLabel = seedname;
    ax.XTick = 1:nseed; ax.YTick = 1:nseed; xtickangle(ax,45);
    title(bandname{b})
    colorbar
    colormap(splt,bipolar(256,cax(1),cax(2)))
end
% colormap(bipolar(256, mincval, maxcval))
%}

%{
for b = 1:nband
    subplot(2,ncol,b)
    imagesc(nanmean(conn_band1(:,:,:,b),3)),  colormap(redblue)
    ax = gca; ax.TickLength = [0,0]; daspect([1 1 1]);
    ax.XTickLabel = seedname; ax.YTickLabel = seedname;
    ax.XTick = 1:nseed; ax.YTick = 1:nseed; xtickangle(ax,45);
%     ax.XTickLabel = seedname; ax.YTickLabel = netwname;
%     ax.XTick = [2.5,6.5,9.5,11.5,15.5,19.5,22.5]; ax.YTick = 1:nseed;
    title(bandname{b})
end
%}

guidata(gcbo,handles)
end                 % --- end show_matrix