function handles = net_gui_view_data(hObject, eventdata, handles)

% k=[1,1];
% fontsize = 13*k(2);
% fontname = 'Helvetica';
 
k = handles.k;
fontsize = handles.fontsize;
fontname = handles.fontname;

gui_data = figure('Units','Normalized','Position',[0.45 0.35 0.45 0.5],'NumberTitle','Off','Name','View datasets',...
    'Menubar','none','WindowStyle','modal','CloseRequestFcn','');

handles.gui_data = gui_data;
%handles.input_filename = handles.dataset_filename;

box = uiextras.VBox('Parent',gui_data,'Padding',15*min(k)); % 'Spacing',10*min(k)    

    box_menu_dataset = uiextras.HBox('Parent',box);
        uiextras.Empty('Parent',box_menu_dataset);

        % Show data from dataset excel file
        [~,xlsdata] = xlsread(handles.input_filename,1,'A1:D1000'); %JS 08.2023
        handles.xls_names = xlsdata(1,:);
        handles.xls_data = xlsdata(2:end,:);

        s = {'Choose dataset'};
        for idx = 1:size(handles.xls_data,1)
            s = [s; {['Dataset ' num2str(idx)]}];
        end

        handles.select_dataset = uicontrol('Parent',box_menu_dataset,'Style','popupmenu','String',s,...
            'FontName',fontname,'FontSize',fontsize,'Callback',@update_datasets);

        % uicontrol('Parent',box,'Style','text','String','MEEG Data Folder/Filename',...
        %             'FontName',fontname,'FontSize',fontsize,'HorizontalAlignment','left');

        uiextras.Empty('Parent',box_menu_dataset);
        
        set(box_menu_dataset,'Sizes',[-1 150*k(2) -1])

uiextras.Empty('Parent',box);        
        
box_data = uiextras.HBox('Parent',box,'Spacing',10*min(k),'Padding',5*min(k));

    box_data_names = uiextras.VBox('Parent',box_data,'Spacing',20*min(k),'Padding',5*min(k));
        uicontrol('Parent',box_data_names,'Style','text','String','EEG Filename',...
            'FontName',fontname,'FontSize',fontsize,'HorizontalAlignment','left');    
        uicontrol('Parent',box_data_names,'Style','text','String','Experiment Filename (optional)',...
            'FontName',fontname,'FontSize',fontsize,'HorizontalAlignment','left');
        uicontrol('Parent',box_data_names,'Style','text','String','Sensors Position Filename',...
            'FontName',fontname,'FontSize',fontsize,'HorizontalAlignment','left');
        uicontrol('Parent',box_data_names,'Style','text','String','Structural MRI Filename',...
            'FontName',fontname,'FontSize',fontsize,'HorizontalAlignment','left');
        %{
        uicontrol('Parent',box_data_names,'Style','text','String','DWI Filename',...
            'FontName',fontname,'FontSize',fontsize,'HorizontalAlignment','left');
        uicontrol('Parent',box_data_names,'Style','text','String','CTI Filename',...
            'FontName',fontname,'FontSize',fontsize,'HorizontalAlignment','left');
        %}
    set(box_data_names,'Sizes',repmat(20*k(2),1,4))
        
    box_data_paths = uiextras.VBox('Parent',box_data,'Spacing',20*min(k),'Padding',5*min(k));
        uicontrol('Parent',box_data_paths,'Style','edit','String',' ','Enable','Off','Tag','meeg',...
            'FontName',fontname,'FontSize',fontsize,'HorizontalAlignment','left');    
        uicontrol('Parent',box_data_paths,'Style','edit','String',' ','Enable','Off','Tag','experiment',...
            'FontName',fontname,'FontSize',fontsize,'HorizontalAlignment','left');
        uicontrol('Parent',box_data_paths,'Style','edit','String',' ','Enable','Off','Tag','markers',...
            'FontName',fontname,'FontSize',fontsize,'HorizontalAlignment','left');
        uicontrol('Parent',box_data_paths,'Style','edit','String',' ','Enable','Off','Tag','mri',...
            'FontName',fontname,'FontSize',fontsize,'HorizontalAlignment','left');
        %{
        uicontrol('Parent',box_data_paths,'Style','edit','String',' ','Enable','Off','Tag','dwi',...
            'FontName',fontname,'FontSize',fontsize,'HorizontalAlignment','left');
        uicontrol('Parent',box_data_paths,'Style','edit','String',' ','Enable','Off','Tag','cti',...
            'FontName',fontname,'FontSize',fontsize,'HorizontalAlignment','left');
        %}
    set(box_data_paths,'Sizes',repmat(20*k(2),1,4))    
    handles.box_data_paths = box_data_paths;
    
    box_data_select = uiextras.VBox('Parent',box_data,'Spacing',20*min(k),'Padding',5*min(k));
        uicontrol('Parent',box_data_select,'Style','pushbutton','String','...','Enable','Off','Tag','meeg','Callback',@select_data);
        uicontrol('Parent',box_data_select,'Style','pushbutton','String','...','Enable','Off','Tag','experiment','Callback',@select_data);
        uicontrol('Parent',box_data_select,'Style','pushbutton','String','...','Enable','Off','Tag','markers','Callback',@select_data);
        uicontrol('Parent',box_data_select,'Style','pushbutton','String','...','Enable','Off','Tag','mri','Callback',@select_data);
        %uicontrol('Parent',box_data_select,'Style','pushbutton','String','...','Enable','Off','Tag','dwi','Callback',@select_data);
        %uicontrol('Parent',box_data_select,'Style','pushbutton','String','...','Enable','Off','Tag','cti','Callback',@select_data);
    set(box_data_select,'Sizes',repmat(20*k(2),1,4))
    handles.box_data_select = box_data_select;
    
%     [~,xlsdescription] = xlsread(handles.input_filename,2);
%     xlsdescription = xlsdescription(:,2);
    xlsdescription = {'EEG recordings (accepted formats: *.eeg, *.mff, *.vhdr, *.set, *.dat, *.raw)'; ...
        'Trigger parameters (accepted format: *.csv)'; ...
        'List of recording sensors positions (accepted formats: *.sfp, *.elc)'; ...
        'T1-weighted structural MR image (accepted format: *.nii)'};
    box_data_info = uiextras.VBox('Parent',box_data,'Spacing',20*min(k),'Padding',5*min(k));
        uicontrol('Parent',box_data_info,'Style','text','String','?','Tooltip',xlsdescription{1});
        uicontrol('Parent',box_data_info,'Style','text','String','?','Tooltip',xlsdescription{2});
        uicontrol('Parent',box_data_info,'Style','text','String','?','Tooltip',xlsdescription{3});
        uicontrol('Parent',box_data_info,'Style','text','String','?','Tooltip',xlsdescription{4});
    set(box_data_info,'Sizes',repmat(20*k(2),1,4))
        
set(box_data,'Sizes',[200*k(2) -1 30*k(2) 15*k(2)])
% handles.datatable = uitable('Parent',box, ...
%     'ColumnName',handles.xls_names, ... %'ColumnWidth',{75*k(1) 50*k(1) 50*k(1) 50*k(1)}, ...
%     'ColumnFormat',{'char','numeric','numeric','numeric'}, ...  % 'RawName',[]
%     'FontName',fontname,'FontSize',fontsize,'Data',handles.xls_data,'Enable','On');

box_lower = uiextras.HBox('Parent',box);

uiextras.Empty('Parent',box_lower);

box_buttons = uiextras.VBox('Parent',box_lower);

uicontrol('Parent',box_buttons,'Style','pushbutton','String','Add Dataset',...
    'FontName',fontname,'FontSize',fontsize,'Callback',@add_dataset);
handles.button_remove_dataset = uicontrol('Parent',box_buttons,'Style','pushbutton','String','Remove Selected Dataset',...
    'FontName',fontname,'FontSize',fontsize,'Enable','Off','Callback',@remove_dataset);

uiextras.Empty('Parent',box_buttons);

uicontrol('Parent',box_buttons,'Style','pushbutton','String','Save',...
    'FontName',fontname,'FontSize',fontsize,'Callback',@save_file);
uicontrol('Parent',box_buttons,'Style','pushbutton','String','Cancel',...
    'FontName',fontname,'FontSize',fontsize,'Callback',@cancel_edit);
set(box_buttons,'Sizes',[30*k(2) 30*k(2) 20*k(2) 30*k(2) 30*k(2)])

uiextras.Empty('Parent',box_lower);

set(box_lower,'Sizes',[-1 170*k(2) -1])
set(box,'Sizes',[30*k(2) 30*k(2) 200*k(2) -1]) %30*k(2) 30*k(2) 20*k(2) 30*k(2) 30*k(2)])

guidata(gui_data,handles)
guidata(handles.gui,handles)
end


%% GUI callback functions

                    % --- start function
function template_function(hObject, eventdata, handles)
    handles = guidata(gcbo);
    
    guidata(gcbo,handles)
end                 % --- end function

                    % --- start update_datasets
function update_datasets(hObject, eventdata, handles)
    handles = guidata(gcbo);
    
    idx_dataset = get(handles.select_dataset,'Value');
    if idx_dataset > 1
        set(allchild(handles.box_data_select),'Enable','On')
        set(handles.button_remove_dataset,'Enable','On')
        path = allchild(handles.box_data_paths);
        select = allchild(handles.box_data_select);
        for i = 1:length(path)
            set(path(i),'String',handles.xls_data{idx_dataset-1,(length(path)-i+1)})
            set(select(i),'Tooltip',handles.xls_data{idx_dataset-1,(length(path)-i+1)})
        end
    else
        set(allchild(handles.box_data_paths),'String','')
        set(allchild(handles.box_data_select),'Enable','Off')
        set(handles.button_remove_dataset,'Enable','Off')
    end
    
    guidata(gcbo,handles)
end                 % --- end update_datasets

                    % --- start select_data
function select_data(hObject, eventdata, handles)
handles = guidata(gcbo);
    
    switch hObject.Tag
        case 'meeg'
            ext = {'*.eeg; *.vhdr; *.mff; *.cnt; *.dat; *.raw; *.set'}; % added some formats, JS 03.2023
        case 'experiment'
            ext = {'*.csv'};
        case 'markers'
            ext = {'*.sfp; *.elc'};
        case {'mri','dwi','cti'}
            ext = {'*.nii'};
    end
    [file, path, filterindex] = uigetfile(ext,'Select file');
    
    if filterindex ~= 0
        editobj = findobj('Style','Edit','-and','Tag',hObject.Tag);
        set(editobj,'String',fullfile(path,file))
        set(hObject,'Tooltip',fullfile(path,file))
    end
    new_paths = flip(get(allchild(handles.box_data_paths),'String'));
    idx_dataset = get(handles.select_dataset,'Value') - 1;
    handles.xls_data(idx_dataset,:) = new_paths;
    
guidata(gcbo,handles)
end                  % --- end select_data

                    % --- start add_dataset
function add_dataset(hObject, eventdata, handles)
    handles = guidata(gcbo);
    
    handles.xls_data = [handles.xls_data; repmat({' '},1,length(handles.xls_names))];
    s = {'Choose dataset'};
    for idx = 1:size(handles.xls_data,1)
        s = [s; {['Dataset ' num2str(idx)]}];
    end
    set(handles.select_dataset,'String',s)
    set(handles.select_dataset,'Value',length(s))
    set(allchild(handles.box_data_paths),'String','')
    set(allchild(handles.box_data_select),'Enable','On')
    set(handles.button_remove_dataset,'Enable','On')

    guidata(gcbo,handles)
end                 % --- end add_dataset

                    % --- start remove_dataset
function remove_dataset(hObject, eventdata, handles)
    handles = guidata(gcbo);
    
    handles.flag_remove = 0;
    idx_dataset = get(handles.select_dataset,'Value') - 1;
    
    if ~isempty(dir([handles.outdir filesep 'dataset' num2str(idx_dataset) filesep '**/*.nii'])) || ~isempty(dir([handles.outdir filesep 'dataset' num2str(idx_dataset) filesep '**/*.mat']))
        msg = {'This dataset has already been (partially) processed. Please remove the input data and the related folder manually.'};
        warndlg(msg,'Dataset already processed!');
    else
        if isdir([handles.outdir filesep 'dataset' num2str(idx_dataset)])
            handles.flag_remove = idx_dataset;
        else
            handles.flag_remove = 0;
        end
        
        handles.xls_data(idx_dataset,:) = [];
        
        set(handles.select_dataset,'Value',1)
        s = {'Choose dataset'};
        for idx = 1:size(handles.xls_data,1)
            s = [s; {['Dataset ' num2str(idx)]}];
        end
        set(handles.select_dataset,'String',s)
        guidata(gcbo,handles)
        update_datasets()
    end
    
    guidata(gcbo,handles)
end                 % --- end remove_dataset

                    % --- start save_file
function save_file(hObject, eventdata, handles)
handles = guidata(gcbo);

if any(cellfun(@nodata,handles.xls_data(:,1))) || any(cellfun(@nodata,handles.xls_data(:,3))) || any(cellfun(@nodata,handles.xls_data(:,4))) % missing some input
    if any(cellfun(@nodata,handles.xls_data(:,1))) || any(cellfun(@nodata,handles.xls_data(:,3))) % no EEG or sensor pos > do not continue
        msg = msgbox('Changes NOT saved! MISSING REQUIRED DATA: EEG, Sensors position or Structural MRI filename');
    else % no MRI > do not continue if individual sensor pos is used, JS 02.2024
        indx = cellfun(@nodata,handles.xls_data(:,4));
        nomri = find(indx>0);
        for i = 1:sum(indx) %numel(handles.xls_data(:,4))
            sps = strsplit(handles.xls_data{nomri(i),3},'_');
            if ~strcmpi(sps{end},'corr.sfp') % electrode position file is not in the template list
                msg = msgbox('Changes NOT saved! MISSING MRI filename while SENSOR POSITION is not a template file. Please indicate the individual MRI filename or use a template Sensors position filename');
            else % copy the template MRI when template electrodes are used (and no MRI is specified)
                if isfield(handles,'flag_remove') && handles.flag_remove > 0
                rmdir([handles.outdir filesep 'dataset' num2str(handles.flag_remove)],'s')
                end
                [~,xlsonoffdata] = xlsread(handles.input_filename,1,'E1:J1000'); % write 'on' to all steps to have the file ready for run_no_gui, JS 08.2023
                xls_onoff = xlsonoffdata(1,:);
                if size(xlsonoffdata,1)-1~=size(handles.xls_data,1) 
                    tmp = cell(size(handles.xls_data,1),size(xlsonoffdata,2)); tmp(:) = {'on'};
                    xlsonoffdata = tmp; 
                else
                    xlsonoffdata = xlsonoffdata(2:end,:);
                end
                handles.xls_data{nomri(i),4} = [handles.net_path filesep 'template' filesep 'tissues_MNI' filesep 'mni_template.nii'];
                new_data = table([handles.xls_names xls_onoff; handles.xls_data, xlsonoffdata]);
                if exist(handles.dataset_filename,'file')
                    delete(handles.dataset_filename)
                end
                writetable(new_data,handles.dataset_filename,'WriteVariableNames',false,'Sheet',1);
                handles.dataset_data = new_data;
                
                if ~any(cellfun(@nodata,handles.xls_data(:,4)))
                setappdata(handles.gui,'dataset_data',handles.xls_data);

                guidata(gcbo,handles)
                uiresume;
                end
            end
        end
    end
else % all inputs have been correctly specified
    if isfield(handles,'flag_remove') && handles.flag_remove > 0
        rmdir([handles.outdir filesep 'dataset' num2str(handles.flag_remove)],'s')
    end
    [~,xlsonoffdata] = xlsread(handles.input_filename,1,'E1:J1000'); %JS 08.2023: write 'on' to all steps to have the file ready for run_no_gui
    xls_onoff = xlsonoffdata(1,:);
    if size(xlsonoffdata,1)-1~=size(handles.xls_data,1) 
        tmp = cell(size(handles.xls_data,1),size(xlsonoffdata,2)); tmp(:) = {'on'};
        xlsonoffdata = tmp; 
    else
        xlsonoffdata = xlsonoffdata(2:end,:);
    end    
    new_data = table([handles.xls_names xls_onoff; handles.xls_data, xlsonoffdata]);
    if exist(handles.dataset_filename,'file')
        delete(handles.dataset_filename)
    end
    writetable(new_data,handles.dataset_filename,'WriteVariableNames',false,'Sheet',1);
    handles.dataset_data = new_data;
    %setappdata(handles.gui,'dataset_data',handles.dataset_data);
        
    setappdata(handles.gui,'dataset_data',handles.xls_data);
    %     num_dataset = size(handles.xls_data,1);
    %     menu_str = {'Select sample dataset'};
    %     for n=1:num_dataset
    %         menu_str = [menu_str; ['Dataset ' num2str(n)]];
    %     end
    %     set(handles.menu_sample_dataset,'Value',1)
    %     set(handles.menu_sample_dataset,'String',menu_str)
        
    guidata(gcbo,handles)
    uiresume;
end
end                 % --- end save_file

                    % --- start nodata
function flag = nodata(c)
    flag = isempty(c) || strcmpi(c,' ');
end                 % --- end nodata

                    % --- start cancel_edit
function cancel_edit(hObject, eventdata, handles)
uiresume;
end                 % --- end cancel_edit

