function gui_activity_output(handles)

k = handles.k;
fontsize = handles.fontsize;
fontname = handles.fontname;

fig_name = 'Activity analysis sample outputs';

findwindow = findobj('Tag','fig_visual','-and','Name',fig_name);
if ~isempty(findwindow)
    close(findwindow);
end

fig_output = figure('Units','Normalized','Position',[0.01 0.66 0.25 0.62],...
        'NumberTitle','Off','Name',fig_name,'Tag','fig_visual');
fig_output.set('Menubar','none');

mainbox = uiextras.VBox('Parent',fig_output,'Padding',10*min(k));

    uicontrol('Parent',mainbox,'Style','Text','String','Choose output(s) to visualize:',...
        'FontName',fontname,'FontSize',fontsize);    

    erp_panel = uix.Panel('Parent',mainbox,'Title','ERP Analysis', ...
    'FontName',fontname,'FontSize',fontsize,'Padding',5*min(k));

        hbox = uiextras.HBox('Parent',erp_panel,'Spacing',10*min(k),'Padding',5*min(k));
    
            uiextras.Empty('Parent',hbox);

            handles.box_erp_buttons = uiextras.VBox('Parent',hbox,'Padding',5*min(k));
                uicontrol('Parent',handles.box_erp_buttons,'Style','text','String','Time-course',...
                    'FontName',fontname,'FontSize',fontsize);

                handles.select_erpchan = uicontrol('Parent',handles.box_erp_buttons,'Style','popupmenu','String','Choose channel',...
                    'FontName',fontname,'FontSize',fontsize,'Tag','erpchan','Callback',@show_erp_signal);
                
                handles.select_erproi = uicontrol('Parent',handles.box_erp_buttons,'Style','popupmenu','String','Choose ROI',...
                    'FontName',fontname,'FontSize',fontsize,'Tag','erproi','Callback',@show_erp_signal);
                
                uicontrol('Parent',handles.box_erp_buttons,'Style','text','String','Topoplot',...
                    'FontName',fontname,'FontSize',fontsize);
                
                handles.select_erptopoplot = uicontrol('Parent',handles.box_erp_buttons,'Style','popupmenu','String','Choose latency',...
                    'FontName',fontname,'FontSize',fontsize,'Tag','erptopoplot','Callback',@show_erp_topoplot);
                
                uicontrol('Parent',handles.box_erp_buttons,'Style','text','String','Source map',...
                    'FontName',fontname,'FontSize',fontsize);
                
                handles.select_erpmap = uicontrol('Parent',handles.box_erp_buttons,'Style','popupmenu','String','Choose map',...
                    'FontName',fontname,'FontSize',fontsize,'Tag','erpmap','Callback',@show_img);

            set(handles.box_erp_buttons,'Sizes',[25*k(2) 25*k(2) 35*k(2) 25*k(2) 35*k(2) 25*k(2) 25*k(2)]) % 40*k(2) 30*k(2)])

            uiextras.Empty('Parent',hbox);

        set(hbox,'Sizes',[-1 200*k(2) -1])

    uiextras.Empty('Parent',mainbox);
        
    erd_ers_panel = uix.Panel('Parent',mainbox,'Title','ERS/ERD Analysis', ...
    'FontName',fontname,'FontSize',fontsize,'Padding',5*min(k));
    
        hbox = uiextras.HBox('Parent',erd_ers_panel,'Spacing',10*min(k),'Padding',5*min(k));

            uiextras.Empty('Parent',hbox);

            handles.box_erd_ers_buttons = uiextras.VBox('Parent',hbox,'Padding',5*min(k));
                
                uicontrol('Parent',handles.box_erd_ers_buttons,'Style','text','String','Time-frequency map',...
                    'FontName',fontname,'FontSize',fontsize);
                
                handles.select_tfchan = uicontrol('Parent',handles.box_erd_ers_buttons,'Style','popupmenu','String','Choose channel',...
                    'FontName',fontname,'FontSize',fontsize,'Tag','tfchan','Callback',@show_tfmap);
                
                handles.select_tfmap = uicontrol('Parent',handles.box_erd_ers_buttons,'Style','popupmenu','String','Choose ROI',...
                    'FontName',fontname,'FontSize',fontsize,'Callback',@show_tfmap);

                uicontrol('Parent',handles.box_erd_ers_buttons,'Style','text','String','Topoplot',...
                    'FontName',fontname,'FontSize',fontsize);
                
                handles.select_topoplot = uicontrol('Parent',handles.box_erd_ers_buttons,'Style','popupmenu','String','Choose condition/freq',...
                    'FontName',fontname,'FontSize',fontsize,'Callback',@show_ers_erd_topoplot);
                
                uicontrol('Parent',handles.box_erd_ers_buttons,'Style','text','String','Source map',...
                    'FontName',fontname,'FontSize',fontsize);

                handles.select_map = uicontrol('Parent',handles.box_erd_ers_buttons,'Style','popupmenu','String','Choose map',...
                    'FontName',fontname,'FontSize',fontsize,'Callback',@show_img);
            set(handles.box_erd_ers_buttons,'Sizes',[25*k(2) 25*k(2) 35*k(2) 25*k(2) 35*k(2) 25*k(2) 25*k(2)]) % 40*k(2) 30*k(2)])

            uiextras.Empty('Parent',hbox);

        set(hbox,'Sizes',[-1 200*k(2) -1])

set(mainbox,'Sizes',[30*k(2) 250*k(2) 10*k(2) 250*k(2)])

idx_dataset = get(handles.menu_visual_dataset,'String');
idx_dataset = idx_dataset(get(handles.menu_visual_dataset,'Value'));
idx_dataset = char(idx_dataset{1}(9:end));

erp_signal_dir = [handles.outdir filesep 'dataset' idx_dataset filesep 'eeg_signal' filesep 'erp_results'];
erp_source_dir = [handles.outdir filesep 'dataset' idx_dataset filesep 'eeg_source' filesep 'erp_results'];
ers_erd_signal_dir = [handles.outdir filesep 'dataset' idx_dataset filesep 'eeg_signal' filesep 'ers_erd_results'];
ers_erd_source_dir = [handles.outdir filesep 'dataset' idx_dataset filesep 'eeg_source' filesep 'ers_erd_results'];

if ~exist([erp_signal_dir filesep 'erp_timecourses_sensor.mat'],'file')
    set(handles.select_erpchan,'Enable','Off')
    set(handles.select_erptopoplot,'Enable','Off')
else    
    erp_filename = [erp_signal_dir filesep 'erp_timecourses_sensor.mat'];
    erp = load(erp_filename);
    chan_list = erp.erp_sensor(1).label;
    s = {'Choose channel'};
    for m = 1:length(chan_list)
        s = [s; chan_list(m)];
    end
    set(handles.select_erpchan,'String',s);
    
    lat_list = erp.erp_sensor(1).time_axis;
    s = {'Choose latency'};
    for m = 1:length(lat_list)
        s = [s; [num2str(lat_list(m)) ' ms']];
    end
    set(handles.select_erptopoplot,'String',s);
    clear erp erp_filename
end

if ~exist([erp_source_dir filesep 'erp_timecourses_roi.mat'],'file') 
    set(handles.select_erproi,'Enable','Off')
else
    erp_filename = [erp_source_dir filesep 'erp_timecourses_roi.mat'];
    erp = load(erp_filename);
    roi_list = erp.erp_roi(1).label;
    s = {'Choose ROI'};
    for m = 1:length(roi_list)
        s = [s; roi_list(m)];
    end
    set(handles.select_erproi,'String',s);
    clear erp erp_filename
end

if ~isdir([erp_source_dir filesep 'ind']) && ~isdir([erp_source_dir filesep 'mni'])
    set(handles.select_erpmap,'Enable','Off')
else
    search_dir = [erp_source_dir filesep '*/*.nii'];
    handles.erp_map_list = dir(search_dir);
    s = {'Choose map'};
    for m = 1:length(handles.erp_map_list)
        s = [s; {handles.erp_map_list(m).name}];
    end
    set(handles.select_erpmap,'String',s);
end    

if ~exist([ers_erd_signal_dir filesep 'ers_erd_sensor.mat'],'file')
    set(handles.select_tfchan,'Enable','Off')
    set(handles.select_topoplot,'Enable','Off')
else    
    ers_erd_filename = [ers_erd_signal_dir filesep 'ers_erd_sensor.mat'];
    ers_erd = load(ers_erd_filename);
    chan_list = ers_erd.ers_erd_sensor(1).label;
    s = {'Choose channel'};
    for m = 1:length(chan_list)
        s = [s; chan_list(m)];
    end
    set(handles.select_tfchan,'String',s);
    
%     lat_list = ers_erd.ers_erd_sensor(1).time_axis;
%     s = {'Choose latency'};
%     for m = 1:length(lat_list)
%         s = [s; lat_list(m)];
%     end
%     set(handles.select_topoplot,'String',s);
%     clear ers_erd ers_erd_filename
    
    options = handles.parameters;
    load(options.ers_erd.triggers);
    
    handles.triggers_time_window = triggers(1).time_range{1,1};
    handles.triggers_cond = [];
    s = {'Choose condition/freq'};
    for idx_cond = 1:size(triggers,2)
        for idx_freq = 1:length(triggers(idx_cond).frequency)
            new_s = [char(triggers(idx_cond).condition_name) ': ' num2str(triggers(idx_cond).frequency{idx_freq}(1)) '-' ...
                num2str(triggers(idx_cond).frequency{idx_freq}(2)) ' Hz'];
            s = [s; new_s];
            handles.triggers_cond = [handles.triggers_cond; idx_cond triggers(idx_cond).frequency{idx_freq}(1) triggers(idx_cond).frequency{idx_freq}(2)];
        end
    end
    set(handles.select_topoplot,'String',s);
end

if ~exist([ers_erd_source_dir filesep 'ers_erd_roi.mat'],'file')
    set(handles.select_tfmap,'Enable','off')
else
    ers_erd_filename = [ers_erd_source_dir filesep 'ers_erd_roi.mat'];
    ers_erd = load(ers_erd_filename);
    roi_list = {ers_erd.seed_info.label};
    s = {'Choose ROI'};
    for m = 1:length(roi_list)
        s = [s; roi_list(m)];
    end
    set(handles.select_tfmap,'String',s);
    clear ers_erd ers_ers_filename
end

if ~isdir([ers_erd_source_dir filesep 'ind']) && ~isdir([ers_erd_source_dir filesep 'mni'])
    set(handles.select_map,'Enable','Off')
else
    search_dir = [ers_erd_source_dir filesep '*/*.nii'];
    handles.map_list = dir(search_dir);
    s = {'Choose map'};
    for m = 1:length(handles.map_list)
        s = [s; {handles.map_list(m).name}];
    end
    set(handles.select_map,'String',s);
end

guidata(fig_output,handles)
end

%% GUI callback functions

                    % --- start function
function template_function(hObject, eventdata, handles)
handles = guidata(gcbo);

guidata(gcbo,handles)
end                 % --- end function

                    % --- start show_erp_signal
function show_erp_signal(hObject, eventdata, handles)
handles = guidata(gcbo);
    
    if strcmpi(hObject.Tag,'erpchan')
        selection = handles.select_erpchan;
        idx = get(selection,'Value');
        str_selection = 'Channel';
    else
        selection = handles.select_erproi;
        idx = get(selection,'Value');
        str_selection = 'ROI';
    end
    
    if idx > 1
        %raweeg_filename = handles.raweeg_filename;
        %processedeeg_filename = handles.processedeeg_filename;

        idx_dataset = get(handles.menu_visual_dataset,'String');
        idx_dataset = idx_dataset(get(handles.menu_visual_dataset,'Value'));

        label = get(selection,'String');
        label = label(get(selection,'Value'));

        fig_img = figure('Units','Normalized','Position',[0.34 0.6 0.5 0.5],...
            'NumberTitle','Off','Name',[char(idx_dataset) ' - ERP time-courses - ' str_selection ': ' char(label)]);
        fig_img.set('Menubar','figure');
        fig_img.set('Pointer','watch');
        drawnow

        if strcmpi(hObject.Tag,'erpchan')
            erp = load([handles.outdir filesep 'dataset' idx_dataset{1}(9:end) filesep 'eeg_signal' filesep 'erp_results' filesep 'erp_timecourses_sensor.mat']);
            erp_data = erp.erp_sensor;
        else
            erp = load([handles.outdir filesep 'dataset' idx_dataset{1}(9:end) filesep 'eeg_source' filesep 'erp_results' filesep 'erp_timecourses_roi.mat']);
            erp_data = erp.erp_roi;
        end
        
        chan_idx = find(strcmpi(erp_data(1).label,label));
        chan_label = label;
        
        erp_time = erp_data(1).time_axis;
        
        %% adapted to the nr of triggers, JS 02.2023
        nstim = numel(erp_data);
        cond_name = {};
        for cname = 1:nstim
            str_name = char(strrep(erp_data(cname).condition_name,'_',' '));
            cond_name{cname} = str_name;
        end
        
        for s = 1:nstim
            erp_tmp = erp_data(s).erp_tc;
            erp_stimulus(:,s) = erp_tmp(chan_idx,:)';
        end
        
        p1 = plot(erp_time,erp_stimulus','LineWidth',0.75);
        if nstim == 1
            cmp = [0.2824, 0.5843, 0.9373];
        elseif nstim == 2
            cmp = [0.5020, 0.7255, 0.0941
                   0.2824, 0.5843, 0.9373];
        elseif nstim == 3
            cmp = [0.5020, 0.7255, 0.0941
                   0.9843, 0.5216, 0
                   0.2824, 0.5843, 0.9373];
        else
            cmp = [linspace(0.0941,0.8510,nstim)', linspace(0.3059,0.9294,nstim)', linspace(0.4667,0.5725,nstim)'];
        end
        for i = 1:nstim
            p1(i).Color = cmp(i,:); 
        end
        hold off
        legend(cond_name,'Location','best','FontSize',handles.fontsize), legend('boxoff')                        
        ylim([min(erp_stimulus(:)) max(erp_stimulus(:))])
        axis tight; set(gca,'FontSize',0.8*handles.fontsize)
        xlabel('Time (ms)','FontSize',handles.fontsize)
        ylabel('ERP signal (uV)','FontSize',handles.fontsize)

        %%
        drawnow
        
        dcm = datacursormode(fig_img);
        datacursormode on
        set(dcm,'updatefcn',@update_datacursor)
        
        clear erp
        fig_img.set('Pointer','arrow');

    end

guidata(gcbo,handles)
end                 % --- end show_erp_signal

                    % --- start update_datacursor
function output_txt = update_datacursor(obj,event_obj)
% Display the position of the data cursor
% obj          Currently not used (empty)
% event_obj    Handle to event object
% output_txt   Data cursor text string (string or cell array of strings).

    pos = get(event_obj,'Position');
    xlab = event_obj.Target.Parent.XLabel.String;
    ylab = event_obj.Target.Parent.YLabel.String;
    output_txt = {['Channel: ',get((get(event_obj,'Target')),'DisplayName')], ...
        [xlab ': ',num2str(pos(1),4)],[ylab ': ',num2str(pos(2),4)]};

    % If there is a Z-coordinate in the position, display it as well
    if length(pos) > 2
        zlab = event_obj.Target.Parent.ZLabel.String;
        output_txt{end+1} = [zlab ': ',num2str(pos(3),4)];
    end
end
                    % --- start update_datacursor

                     % --- start show_erp_topoplot
function show_erp_topoplot(hObject, eventdata, handles)
handles = guidata(gcbo);

    idx_dataset = get(handles.menu_visual_dataset,'String');
    idx_dataset = idx_dataset(get(handles.menu_visual_dataset,'Value'));

    select_topoplot = handles.select_erptopoplot;
    erp_filename = [handles.outdir filesep 'dataset' idx_dataset{1}(9:end) filesep 'eeg_signal' filesep 'erp_results' filesep 'erp_timecourses_sensor.mat'];
    topoplot_file = load(erp_filename);
    topoplot_data = topoplot_file.erp_sensor;

    latency = get(select_topoplot,'Value')-1;
    if latency > 0
%         setappdata(groot,'erp',erp)
        
        lat_val = get(select_topoplot,'String');
        lat_val = lat_val(latency+1);
        
        fig_img = figure('Units','Normalized','Position',[0.34 0.6 0.5 0.25],...
            'NumberTitle','Off','Name',[char(idx_dataset) ' - ERP topoplots - Latency: ' char(lat_val)]);
        fig_img.set('Menubar','figure');

        maxval = 0; minval = 0;
        for idx = 1:size(topoplot_data,2)
            [~,topoval] = topoplot(topoplot_data(idx).erp_tc(:,latency)',topoplot_file.elecpos);
            maxval = max(maxval,max(topoval(:)));
            minval = min(minval,min(topoval(:)));
        end
        topo_plot_erp_range = [minval maxval];
        %% adapted to the nr of triggers, JS 02.2023
        maxcval = 0; mincval = 0;
        ntopo = numel(topoplot_data);
        if ntopo > 3
            r = ceil(ntopo/3);
            for idx = 1:ntopo
                subplot(r,3,idx);
                topoplot(topoplot_data(idx).erp_tc(:,latency)',topoplot_file.elecpos,'WhiteBk','on','MapLimits',topo_plot_erp_range);
                condition = topoplot_data(idx).condition_name;
                condition = strrep(condition,'_',' ');
                condition = [upper(condition(1)) condition(2:end)];
                title(condition,'FontSize',handles.fontsize);
                cax = caxis;
                caxis([minval maxval])
                maxcval = max(maxcval,cax(2));
                mincval = min(mincval,cax(1));
            end
        else
            for idx = 1:ntopo
                subplot(1,ntopo,idx);
                topoplot(topoplot_data(idx).erp_tc(:,latency)',topoplot_file.elecpos,'WhiteBk','on','MapLimits',topo_plot_erp_range);
                condition = topoplot_data(idx).condition_name;
                condition = strrep(condition,'_',' ');
                condition = [upper(condition(1)) condition(2:end)];
                title(condition,'FontSize',handles.fontsize);
                cax = caxis;
                caxis([minval maxval])
                maxcval = max(maxcval,cax(2));
                mincval = min(mincval,cax(1));
            end
        end
        colormap(bipolar(256, mincval, maxcval))
        h = axes(fig_img,'Visible','Off');
        cb = colorbar(h,'Position',[0.92 0.168 0.022 0.7]); cb.FontSize = 0.9*handles.fontsize;
        caxis(h,topo_plot_erp_range);
        ylabel(cb, 'ERP signal (uV)','FontSize',handles.fontsize)
        %%
        
        clear topoplot_file
    end

guidata(gcbo,handles)
end                 % --- end show_erp_topoplot

                     % --- start show_ers_erd_topoplot
function show_ers_erd_topoplot(hObject, eventdata, handles)
handles = guidata(gcbo);

    idx_dataset = get(handles.menu_visual_dataset,'String');
    idx_dataset = idx_dataset(get(handles.menu_visual_dataset,'Value'));

    select_topoplot = handles.select_topoplot;
    ers_erd_filename = [handles.outdir filesep 'dataset' idx_dataset{1}(9:end) filesep 'eeg_signal' filesep 'ers_erd_results' filesep 'ers_erd_sensor.mat'];
    topoplot_file = load(ers_erd_filename);
    topoplot_data = topoplot_file.ers_erd_sensor;

    condition = get(select_topoplot,'Value')-1;
    if condition > 0
        condition_idx = handles.triggers_cond(condition,1);
        str_condition = char(topoplot_data(condition_idx).condition_name);
        str_frequency = [num2str(handles.triggers_cond(condition,2)) '-' num2str(handles.triggers_cond(condition,3))];
        
        fig_img = figure('Units','Normalized',...
            'NumberTitle','Off','Name',[char(idx_dataset) ' - ERS/ERD topoplots - ' str_condition ' - Frequency: ' str_frequency ' Hz']);
        fig_img.set('Menubar','figure');
        
%         for idx = 1:size(topoplot_data,2)
%             subplot(1,3,idx);
%             topoplot(topoplot_data(idx).erp_tc(:,latency)', topoplot_file.elecpos);
%             condition = topoplot_data(idx).condition_name;
%             condition = strrep(condition,'_',' ');
%             title(condition);
%         end

        time_window = handles.triggers_time_window;
        frequency_window = [handles.triggers_cond(condition,2),handles.triggers_cond(condition,3)]; %% beta, you should plot also for other frequency windows

        time_vect = find(topoplot_data(1).time_axis >= time_window(1) & topoplot_data(1).time_axis <= time_window(2));
        frequency_vect = find(topoplot_data(1).frequency_axis >= frequency_window(1) & topoplot_data(1).frequency_axis <= frequency_window(2));

        topomap = topoplot_data(condition_idx).tf_map(:, frequency_vect, time_vect);
        topomap = mean(topomap, 3);
        topomap = mean(topomap, 2);

        maplimit = [min(topomap) max(topomap)];
        topoplot(topomap, topoplot_file.elecpos, 'whitebk', 'on', 'maplimits',maplimit); %[-1*maplimit, maplimit]);
        
        %load('cm_blue_white_red.mat');
        %colormap(gca, blue_white_red);
        colormap(bipolar(256,maplimit(1),maplimit(2)))
        bar = colorbar('Position',[0.88 0.168 0.032 0.7]);
        ylabel(bar, 'ERD/ERS (%)','FontSize',10)
        %bar.Label.String = 'ERD/ERS (%)';
        
        %fig_img.set('Color',[0.95 0.95 0.95]);
        
        clear topoplot_file
    end

guidata(gcbo,handles)
end                 % --- end show_ers_erd_topoplot

                    % --- start show_tfmap
function show_tfmap(hObject, eventdata, handles)
handles = guidata(gcbo);
    
    idx_dataset = get(handles.menu_visual_dataset,'String');
    idx_dataset = idx_dataset(get(handles.menu_visual_dataset,'Value'));
        
    if strcmpi(hObject.Tag,'tfchan')
        select_tf = handles.select_tfchan;
        ers_erd_filename = [handles.outdir filesep 'dataset' char(idx_dataset{1}(9:end)) filesep 'eeg_signal' filesep 'ers_erd_results' filesep 'ers_erd_sensor.mat'];
        ers_erd = load(ers_erd_filename);
        ers_erd_data = ers_erd.ers_erd_sensor;
        str_title = 'Channel';
    else
        select_tf = handles.select_tfmap;
        ers_erd_filename = [handles.outdir filesep 'dataset' char(idx_dataset{1}(9:end)) filesep 'eeg_source' filesep 'ers_erd_results' filesep 'ers_erd_roi.mat'];
        ers_erd = load(ers_erd_filename);
        ers_erd_data = ers_erd.ers_erd_roi;
        str_title = 'ROI';
    end
    idx_tfmap = get(select_tf,'Value');
    
    if idx_tfmap > 1
        roi_name = char(hObject.String(hObject.Value));
        roi_idx = hObject.Value - 1;
        
        fig_img = figure('Units','Normalized','Position',[0.34 0.6 0.7 0.77],...
            'NumberTitle','Off','Name',[char(idx_dataset) ' - ERS/ERD time-frequency maps - ' str_title ': ' roi_name]);
        fig_img.set('Menubar','figure');

        num_conditions = length({ers_erd_data.condition_name});
        maxval = 0; minval = 0;
        for i = 1:num_conditions
            tfmap_condition = ers_erd_data(i).tf_map;
            matrixval = squeeze(tfmap_condition(roi_idx,:,:));
            maxval = max(maxval,max(matrixval(:)));
            minval = min(minval,min(matrixval(:)));
        end
        
        gridplot = numSubplots(num_conditions);
        maxcval = 0; mincval = 0;
            for i = 1:num_conditions
                subplot(gridplot(1),gridplot(2),i)
                tfmap_condition = ers_erd_data(i).tf_map;
                imagesc(ers_erd_data(i).time_axis/1000,ers_erd_data(i).frequency_axis,squeeze(tfmap_condition(roi_idx,:,:)))
                
                cax = caxis;
                caxis([minval maxval])
                maxcval = max(maxcval,cax(2));
                mincval = min(mincval,cax(1));
                
                set(gca, 'YDir', 'normal')
                xlabel('Time (s)')
                ylabel('Frequency (Hz)')
                name_condition = ers_erd_data(i).condition_name;
                name_condition = strrep(name_condition,'_',' ');
                title(name_condition)
            end
        colormap(bipolar(256, mincval, maxcval))    
        cbar_pos = get(subplot(gridplot(1),gridplot(2),num_conditions),'Position');
        c = colorbar('Location','southoutside','Position', [cbar_pos(1) cbar_pos(2)-0.068 cbar_pos(3) 0.02]);
        c.Label.String = 'ERD/ERS (%)';
        clear ers_erd ers_erd_filename
    end
    
guidata(gcbo,handles)
end                 % --- end show_tfmap

                    % --- start show_img
function show_img(hObject, eventdata, handles)
handles = guidata(gcbo);
    
    idx_dataset = get(handles.menu_visual_dataset,'String');
    idx_dataset = idx_dataset(get(handles.menu_visual_dataset,'Value'));
    
    if strcmpi(hObject.Tag,'erpmap')
        select_map = handles.select_erpmap;
        map_list = handles.erp_map_list;
        str_title = 'ERP';
    else
        select_map = handles.select_map;
        map_list = handles.map_list;
        str_title = 'ERS/ERD';
    end
    
    idx_map = get(select_map,'Value');
    if idx_map > 1
        seedimg_list = get(select_map,'String');
        seedimg_filename = seedimg_list(idx_map);
        seedimg_info = upper(split(seedimg_filename,'_'));
        if strcmpi(seedimg_info(end),'mni.nii')
            title = [char(idx_dataset) ' - ' str_title ' map: ' char(seedimg_filename{1}(1:end-4)) ' - Template MRI'];
            background_img = handles.anat_filename;
            % Resample map (temporary)
            [bb,vox] = net_world_bb(background_img);
            net_resize_img([map_list(idx_map-1).folder filesep map_list(idx_map-1).name],vox,bb);
        else
            title = [char(idx_dataset) ' - ' str_title ' map: ' char(seedimg_filename{1}(1:end-4)) ' - Individual MRI'];
            background_img = handles.img_filename;
            % Resample map (temporary)
            [bb,vox] = net_world_bb(background_img);
            net_resize_img([map_list(idx_map-1).folder filesep map_list(idx_map-1).name],vox,bb);
        end
        fig_img = figure('Units','Normalized','Position',[0.33 0.0 0.64 1],...
            'NumberTitle','Off','Name',title);
        nii = load_nii(background_img);
        res_seedimg_filename = [map_list(idx_map-1).folder filesep 'r' map_list(idx_map-1).name];
        seed = load_nii(res_seedimg_filename);
        % Delete resampled map
        delete(res_seedimg_filename);
%{     
        % Adjust values for visualization
        seed_minval = 0.01;
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
        opt.setcolorindex = 2;
        %opt.setcolormap = load('cmap_blue_white_red.txt'); %%%% missing high values
        opt.command = 'update';
        view_nii(fig_img,nii,opt);
        set(gcf, 'Pointer', 'arrow');
    end
        
guidata(gcbo,handles);
end                 % --- end show_img
