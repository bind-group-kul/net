function net_gui

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%                                                      %%%
%%%                        .:: NET ::.                   %%%
%%%                                                      %%%
%%%  Non-invasive Electrophysiological analysis Toolbox  %%%
%%%  --------------------------------------------------  %%%
%%%  --------------------------------------------------  %%%
%%%       Gaia Amaranta Taberna - 08.04.22 - v.1.0       %%%
%%%                                                      %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%{

Cite as:
--------


%}

%close all
%clear all
clc

welcome_str = ([ ...
'\n' ... 
'======================================================= \n' ...
'               __    __              _______  \n' ...
'              |  \\  |  |  ________  |       | \n' ...
'              |   \\ |  | |   _____| |_     _| \n' ...
'              |    \\|  | |  |___      |   |   \n' ...
'              |  |\\    | |   ___|     |   |   \n' ...
'              |  | \\   | |  |_____    |   |   \n' ...
'              |__|  \\__| |________|   |___|   \n' ...
'\n * Non-invasive Electrophysiological analysis Toolbox * \n' ...
'======================================================= \n' ...
' v.1.0 \n \n' ...
]);

fprintf(welcome_str);

% --------------- %
%   Main window   %
% --------------- %

warning off
gui_path = fileparts(mfilename('fullpath'));
net_path = fileparts(gui_path);
addpath(genpath(net_path))

gui = figure('Visible','Off');
set(gui,'NumberTitle','Off', ...
    'Name','.:: NET ::.')
win_pos = [0.025 0.01 0.5 0.86];
set(gui,'Units','Normalized','Position',win_pos)
set(gui,'Resize','Off')
set(gui,'Menubar','None','Toolbar','None')
handles = guihandles(gui);
handles.gui = gui;
%set(handles.gui, 'WindowKeyPressFcn', @(x,y)disp(get(handles.gui,'CurrentCharacter')))
ss = get(0,'screensize');
k = ss./[1 1 1440 900];
k = k(3:4);
fontsize = floor(10*k(2));
fontname = 'Verdana'; %'Arial';
handles.k = k;
handles.fontsize = fontsize;
handles.fontname = fontname;
handles.gui_path = gui_path;
handles.net_path = net_path;

main = uiextras.VBox('Parent',gui,'Spacing',10*min(k),'Padding',25*min(k)); %,'Units','Normalized','Position',[0.025 0.5 0.95 0.86]);

%%%%% LOGO %%%%%
ax_logo = axes('Parent',main);
set(ax_logo,'Visible','Off')
[logo,~,alpha] = imread([gui_path filesep 'logo/logo_full.png']);
%logo = imread([gui_path filesep 'logo/logoNET_gui.jpg']);
%alpha = 1;
l = imshow(logo,'parent',ax_logo);
set(l,'AlphaData',alpha);
z = zoom;
setAllowAxesZoom(z,ax_logo,false);
r = rotate3d;
setAllowAxesRotate(r,ax_logo,false);
logo_h = ss(4)*(win_pos(4)-win_pos(2))/7; %/10
%%%%%%%%%%%%%%%

%%%%% PANEL PROCESSING DIRECTORY %%%%%
panel_out_dir = uix.Panel('Parent',main,'Title','Processing directory', ...
    'FontName',fontname,'FontSize',fontsize,'Padding',5*min(k));%,'Background',[0.8 0.8 0.8]);

    box_out_dir = uiextras.HBox('Parent',panel_out_dir,'Spacing',10*min(k),'Padding',5*min(k));
        
        handles.outdir_button = uicontrol('Parent',box_out_dir,'Style','Edit','String','Select processing directory','Enable','Off',...
            'FontName',fontname,'FontSize',fontsize,'HorizontalAlignment','left');
        
        uicontrol('Parent',box_out_dir,'Style','pushbutton','String','...',...
            'FontName',fontname,'FontSize',fontsize,'Tag','outdir_button','Callback',@select_outdir,'Enable','On');
    
    set(box_out_dir,'Sizes',[-1 20*k(2)])
%%%%%%%%%%%%%%%


%%%%% PANEL LOAD/VIEW INPUTS %%%%%
panel_input = uix.Panel('Parent',main,'Title','Input data', ...
    'FontName',fontname,'FontSize',fontsize,'Padding',5*min(k));%,'Background',[0.8 0.8 0.8]);

    box_input = uiextras.HBox('Parent',panel_input,'Spacing',10*min(k),'Padding',5*min(k));
    
        uiextras.Empty('Parent',box_input);
        
        handles.box_input_dataset = uiextras.VBox('Parent',box_input);
        
            uicontrol('Parent',handles.box_input_dataset,'Style','pushbutton','String','Load Datasets','Tag','load_dataset_button',...
                'FontName',fontname,'FontSize',fontsize,'HorizontalAlignment','left','Callback',@load_data,'Enable','Off');
            uicontrol('Parent',handles.box_input_dataset,'Style','pushbutton','String','View Datasets','Tag','view_dataset_button',...
                'FontName',fontname,'FontSize',fontsize,'HorizontalAlignment','left','Callback',@view_data,'Enable','Off');
        set(handles.box_input_dataset,'Sizes',[40*k(2) 40*k(2)])
        
        handles.box_input_param = uiextras.VBox('Parent',box_input);
            
            uicontrol('Parent',handles.box_input_param,'Style','pushbutton','String','<html><center>Load Prepro<br>Parameters</center></html>','Tag','load_parameters_button',...
                'FontName',fontname,'FontSize',fontsize,'HorizontalAlignment','left','Callback',@load_data,'Enable','Off');
            uicontrol('Parent',handles.box_input_param,'Style','pushbutton','String','<html><center>View/Edit Prepro<br>Parameters</center></html>','Tag','view_parameters_button',...
                'FontName',fontname,'FontSize',fontsize,'HorizontalAlignment','left','Callback',@view_data,'Enable','Off');
        set(handles.box_input_param,'Sizes',[40*k(2) 40*k(2)])
        
        handles.box_input_analysis = uiextras.VBox('Parent',box_input);
            
            uicontrol('Parent',handles.box_input_analysis,'Style','pushbutton','String','<html><center>Load Analysis<br>Parameters</center></html>','Tag','load_analysis_button',...
                'FontName',fontname,'FontSize',fontsize,'HorizontalAlignment','left','Callback',@load_data,'Enable','Off');
            uicontrol('Parent',handles.box_input_analysis,'Style','pushbutton','String','<html><center>View/Edit Analysis<br>Parameters</center></html>','Tag','view_analysis_button',...
                'FontName',fontname,'FontSize',fontsize,'HorizontalAlignment','left','Callback',@view_data,'Enable','Off');
        set(handles.box_input_analysis,'Sizes',[40*k(2) 40*k(2)])
        
        uiextras.Empty('Parent',box_input);
        
    set(box_input,'Sizes',[-1 150*k(2) 150*k(2) 150*k(2) -1])
%%%%%%%%%%%%%%%


%%%%% PANEL RUN %%%%%
panel_run = uix.Panel('Parent',main,'Title','Run NET', ...
    'FontName',fontname,'FontSize',fontsize,'Padding',5*min(k));%,'Background',[0.8 0.8 0.8]);

    box_run = uiextras.VBox('Parent',panel_run,'Spacing',20*min(k)); % ,'Padding',5*min(k));
    
        box_select_run = uiextras.HBox('Parent',box_run);
                    
            handles.buttons_select_run = uibuttongroup('Parent',box_select_run,'BorderType','none','SelectionChangedFcn',@run_all_sample);
                handles.radiobutt_run_sample = uicontrol('Parent',handles.buttons_select_run,'Style','radiobutton','String','Sample Dataset',...
                    'FontName',fontname,'FontSize',fontsize,'HorizontalAlignment','left','Callback',[],'Position',[10 38 150 20]);
                uicontrol('Parent',handles.buttons_select_run,'Style','radiobutton','String','All Datasets','Tag','run_all',...
                    'FontName',fontname,'FontSize',fontsize,'HorizontalAlignment','left','Callback',[],'Position',[10 19 150 20]);
                uicontrol('Parent',handles.buttons_select_run,'Style','radiobutton','String','All Datasets & Steps','Tag','run_auto',...
                    'FontName',fontname,'FontSize',fontsize,'HorizontalAlignment','left','Callback',[],'Position',[10 0 200 20]);
            set(allchild(handles.buttons_select_run),'Enable','Off')
            
            handles.menu_sample_dataset = uicontrol('Parent',box_select_run,'Style','popupmenu','String','Select sample dataset',...
                'FontName',fontname,'FontSize',fontsize,'Callback',@select_sample_dataset,'Enable','Off');
            
        box_initialize = uiextras.HBox('Parent',box_run);
        
            uiextras.Empty('Parent',box_initialize);
            
            handles.button_init = uicontrol('Parent',box_initialize,'Style','pushbutton','String','Initialization','Tag','initialization',...
                'FontName',fontname,'FontSize',fontsize,'HorizontalAlignment','left','Callback',@initialization,'Enable','Off');
            
            uiextras.Empty('Parent',box_initialize);
        
        box_processing = uiextras.HBox('Parent',box_run);
        
            uiextras.Empty('Parent',box_processing);
        
            panel_prepro = uix.Panel('Parent',box_processing,'Title','Pre-processing','BorderType','none',...
                'FontName',fontname,'FontSize',fontsize,'Padding',5*min(k));%,'Background',[0.8 0.8 0.8]);

                box_prepro = uiextras.HBox('Parent',panel_prepro);
                
                    uiextras.Empty('Parent',box_prepro);
                
                    handles.box_buttons_prepro = uiextras.VBox('Parent',box_prepro);

                        handles.button_headmod = uicontrol('Parent',handles.box_buttons_prepro,'Style','pushbutton','String','Head Modelling',...
                            'FontName',fontname,'FontSize',fontsize,'HorizontalAlignment','left','Callback',@head_modelling,'Enable','Off');
                        handles.button_signal = uicontrol('Parent',handles.box_buttons_prepro,'Style','pushbutton','String','Signal Processing',...
                            'FontName',fontname,'FontSize',fontsize,'HorizontalAlignment','left','Callback',@signal_processing,'Enable','Off');
                        handles.button_source = uicontrol('Parent',handles.box_buttons_prepro,'Style','pushbutton','String','Source Localization',...
                            'FontName',fontname,'FontSize',fontsize,'HorizontalAlignment','left','Callback',@source_localization,'Enable','Off');
                    
                    set(handles.box_buttons_prepro,'Sizes',[30*k(2) 30*k(2) 30*k(2)])
                    
                    uiextras.Empty('Parent',box_prepro);    
                    
                set(box_prepro,'Sizes',[5*k(2) 150*k(2) -1])
                
            panel_act_conn = uix.Panel('Parent',box_processing,'Title','Analysis','BorderType','none',...
                'FontName',fontname,'FontSize',fontsize,'Padding',5*min(k));%,'Background',[0.8 0.8 0.8]);

                box_act_conn = uiextras.HBox('Parent',panel_act_conn);
                
                    uiextras.Empty('Parent',box_act_conn);
                
                    handles.buttons_act_conn = uiextras.VBox('Parent',box_act_conn);

                        uicontrol('Parent',handles.buttons_act_conn,'Style','pushbutton','String','Activity','Tag','button_activity',...
                            'FontName',fontname,'FontSize',fontsize,'HorizontalAlignment','left','Callback',@activity_analysis,'Enable','Off');
                        uicontrol('Parent',handles.buttons_act_conn,'Style','pushbutton','String','Connectivity','Tag','button_connectivity',...
                            'FontName',fontname,'FontSize',fontsize,'HorizontalAlignment','left','Callback',@connectivity_analysis,'Enable','Off');
                        handles.button_stat = uicontrol('Parent',handles.buttons_act_conn,'Style','pushbutton','String','Statistics',...
                            'FontName',fontname,'FontSize',fontsize,'HorizontalAlignment','left','Callback',@group_statistics,'Enable','Off');
                    
                    set(handles.buttons_act_conn,'Sizes',[30*k(2) 30*k(2) 30*k(2)])
                    
                    uiextras.Empty('Parent',box_act_conn);    
                    
                set(box_act_conn,'Sizes',[5*k(2) 150*k(2) -1])
                
                %{
                    box_act_conn = uiextras.VBox('Parent',panel_act_conn);

                        box_select_act_conn = uiextras.HBox('Parent',box_act_conn);
                    
                        handles.buttons_act_conn = uibuttongroup('Parent',box_select_act_conn,'BorderType','none');
                            handles.button_activity = uicontrol('Parent',handles.buttons_act_conn,'Style','radiobutton','String','Activity',...
                                'FontName',fontname,'FontSize',fontsize,'HorizontalAlignment','left','Position',[10 32 150 30]);
                            uicontrol('Parent',handles.buttons_act_conn,'Style','radiobutton','String','Connectivity',...
                                'FontName',fontname,'FontSize',fontsize,'HorizontalAlignment','left','Position',[10 9 150 30]);
                        set(allchild(handles.buttons_act_conn),'Enable','Off');
                        
                        box_act_conn_run = uiextras.VBox('Parent',box_select_act_conn);    
                        
                        uiextras.Empty('Parent',box_act_conn_run);
                        
                        handles.button_run_act_conn = uicontrol('Parent',box_act_conn_run,'Style','pushbutton','String','Run',...
                            'FontName',fontname,'FontSize',fontsize,'HorizontalAlignment','left','Callback',@run_activity_connectivity,'Enable','Off');
                            
                        uiextras.Empty('Parent',box_act_conn_run);
                        
                        set(box_act_conn_run,'Sizes',[5*k(2) 30*k(2) -1])
                    set(box_select_act_conn,'Sizes',[-1 150*k(2)])

                    box_stat = uiextras.HBox('Parent',box_act_conn);

                        uiextras.Empty('Parent',box_stat);

                        uicontrol('Parent',box_stat,'Style','pushbutton','String','Statistics',...
                            'FontName',fontname,'FontSize',fontsize,'HorizontalAlignment','left','Callback',@group_statistics,'Enable','Off');

                        uiextras.Empty('Parent',box_stat);                    

                    set(box_stat,'Sizes',[-1 150*k(2) -1])
                set(box_act_conn,'Sizes',[-1 30*k(2)])  
              %}
                set(box_processing,'Sizes',[40*k(2) 350*k(2) -1])
    set(box_run,'Sizes',[55*k(2) 30*k(2) -1])
%%%%%%%%%%%%%%%


%%%%% PANEL VISUALIZE %%%%%
panel_visual = uix.Panel('Parent',main,'Title','Visualizations', ...
    'FontName',fontname,'FontSize',fontsize,'Padding',5*min(k));%,'Background',[0.8 0.8 0.8]);

    box_visual = uiextras.VBox('Parent',panel_visual,'Spacing',10*min(k)); % ,'Padding',5*min(k));
    
        box_select_visual = uiextras.HBox('Parent',box_visual);
        
            handles.menu_visual_dataset = uicontrol('Parent',box_select_visual,'Style','popupmenu','String','Select sample dataset',...
                'FontName',fontname,'FontSize',fontsize,'Callback',@select_visual_dataset,'Enable','Off');
            
            uiextras.Empty('Parent',box_select_visual);
            
            set(box_select_visual,'Sizes',[280*k(2) -1])
            
        handles.box_buttons_visual = uiextras.HBox('Parent',box_visual);
        
            handles.visual_head_model = uicontrol('Parent',handles.box_buttons_visual,'Style','pushbutton','String','Head Modelling','Tag','visual_head_model',...
            	'FontName',fontname,'FontSize',fontsize,'HorizontalAlignment','left','Callback',@visualization,'Enable','Off');
            handles.visual_sign_proc = uicontrol('Parent',handles.box_buttons_visual,'Style','pushbutton','String','Signal Processing','Tag','visual_sign_proc',...
            	'FontName',fontname,'FontSize',fontsize,'HorizontalAlignment','left','Callback',@visualization,'Enable','Off');            
            handles.visual_activity = uicontrol('Parent',handles.box_buttons_visual,'Style','pushbutton','String','Activity','Tag','visual_activity',...
            	'FontName',fontname,'FontSize',fontsize,'HorizontalAlignment','left','Callback',@visualization,'Enable','Off');
            handles.visual_connectivity = uicontrol('Parent',handles.box_buttons_visual,'Style','pushbutton','String','Connectivity','Tag','visual_connectivity',...
            	'FontName',fontname,'FontSize',fontsize,'HorizontalAlignment','left','Callback',@visualization,'Enable','Off');

        set(handles.box_buttons_visual,'Sizes',[150*k(2) 150*k(2) 150*k(2) 150*k(2)])
        
%         box_button_stat = uiextras.HBox('Parent',box_visual);
%             
%             uiextras.Empty('Parent',box_button_stat);
%         
%             handles.visual_statistics = uicontrol('Parent',box_button_stat,'Style','pushbutton','String','Statistics','Tag','visual_statistics',...
%             	'FontName',fontname,'FontSize',fontsize,'HorizontalAlignment','left','Callback',@visualization,'Enable','Off');
% 
%             uiextras.Empty('Parent',box_button_stat);
%             
%         set(box_button_stat,'Sizes',[-1 150*k(2) -1])
        
    set(box_visual,'Sizes',[-1 30*k(2)])
%%%%%%%%%%%%%%%

%uiextras.Empty('Parent',main);

%%%%% QUIT/ABOUT %%%%%
box_quit_about = uiextras.HBox('Parent',main);

    uicontrol('Parent',box_quit_about,'Style','pushbutton','String','Quit','ForegroundColor','w','BackgroundColor',[75 95 145]/255,... %[53 37 62]/255,...
            	'FontName',fontname,'FontSize',fontsize,'HorizontalAlignment','left','Callback',@programQuit,'Enable','On');
    
    uiextras.Empty('Parent',box_quit_about);        
            
    uicontrol('Parent',box_quit_about,'Style','pushbutton','String','About','ForegroundColor','w','BackgroundColor',[75 95 145]/255,... %[53 37 62]/255,...
            	'FontName',fontname,'FontSize',fontsize,'HorizontalAlignment','left','Callback',@aboutFig,'Enable','On');

set(box_quit_about,'Sizes',[70*k(2) -1 70*k(2)])
%%%%%%%%%%%%%%%

set(main,'Sizes',[logo_h 60*k(2) 115*k(2) 266*k(2) 100*k(2) 22*k(2)]) % [logo_h 60*k(2) 120*k(2) 268*k(2) 100*k(2) -1 30*k(2)]

% Make the UI visible.
set(gui,'Visible','On')
guidata(gui,handles)
end

%% GUI callback functions

                    % --- start function
function template_function(hObject, eventdata, handles)
    handles = guidata(gcbo);
    
    guidata(gcbo,handles)
end                 % --- end function

                    % --- start select_outdir
function select_outdir(hObject, eventdata, handles)
% Select output directory
% -----------------
handles = guidata(gcbo);
    
    overwrite = 1;
    outdir = uigetdir(handles.net_path);
    if outdir ~= 0
        % Initialize load/view buttons
        set(get(handles.box_input_dataset,'Children'),'Enable','Off');
        set(get(handles.box_input_param,'Children'),'Enable','Off');
        set(get(handles.box_input_analysis,'Children'),'Enable','Off');
        
        % define pathnames
        [~,dir] = fileparts(outdir);
        dataset_filename = [outdir filesep dir '_dataset.xlsx'];
        parameters_filename = [outdir filesep dir '_parameters_prepro.xlsx'];
        analysis_filename = [outdir filesep dir '_parameters_analysis.xlsx'];
        handles.dataset_filename = dataset_filename;
        handles.parameters_filename = parameters_filename;
        handles.analysis_filename = analysis_filename;
        
        % if files already exist, ask to overwrite
        if exist(handles.dataset_filename,'file') && exist(handles.parameters_filename,'file')
            msg = {'Warning: Dataset and prepro parameters files found in this folder.';'Do you want to overwrite them with default ones or keep the current files?'};
            choice = questdlg(msg,'Overwrite dataset/prepro parameters files?', 'Overwrite','Keep','Keep');
            if strcmp(choice,'Keep')
                overwrite = 0;
            end
        end
        
        % select directory
        set(handles.(hObject.Tag),'Enable','Inactive');
        set(handles.(hObject.Tag),'String',outdir);
        handles.outdir = outdir;
        
        if overwrite == 1
            % copy template dataset and parameters files
            template_dataset_path = [handles.net_path filesep 'template_files' filesep 'template_dataset.xlsx'];
            template_parameters_path = [handles.net_path filesep 'template_files' filesep 'template_parameters_prepro.xlsx'];
            copyfile(template_dataset_path,dataset_filename);
            copyfile(template_parameters_path,parameters_filename);
        end
        handles.template_analysis_path = [handles.net_path filesep 'template_files' filesep 'template_parameters_analysis.xlsx'];
        
        % Enable load/view dataset and parameters
        set(get(handles.box_input_dataset,'Children'),'Enable','On');
        set(get(handles.box_input_param,'Children'),'Enable','On');
        set(findobj('Parent',handles.box_input_analysis,'Tag','load_analysis_button'),'Enable','On');
        if exist(analysis_filename,'file')
            set(findobj('Parent',handles.box_input_analysis,'Tag','view_analysis_button'),'Enable','On');
        end
        
        % Read number of datasets
        [~,xlsdata] = xlsread(handles.dataset_filename,1);
        if any(cellfun(@nodata,xlsdata(:,1))) || any(cellfun(@nodata,xlsdata(:,3))) || any(cellfun(@nodata,xlsdata(:,4)))
            handles.input_filename = handles.dataset_filename;
            handles = net_gui_view_data(hObject, eventdata, handles);
            msg = msgbox('MISSING REQUIRED DATA: EEG, Sensors position or Structural MRI filename');
            uiwait(handles.gui_data);
            %handles.dataset_data = getappdata(handles.gui,'dataset_data');
            delete(handles.gui_data);
        end
        num_dataset = size(xlsdata,1)-1;
        menu_str = {'Select sample dataset'};
        for n=1:num_dataset
            menu_str = [menu_str; ['Dataset ' num2str(n)]];
        end
        set(handles.menu_sample_dataset,'Value',1)
        set(handles.menu_sample_dataset,'String',menu_str)
        
        % Enable run sample dataset/all
        set(handles.buttons_select_run,'SelectedObject',handles.radiobutt_run_sample)
        set(allchild(handles.buttons_select_run),'Enable','On')
        set(handles.menu_sample_dataset,'Enable','On')
        
        % Read parameters
        flag_param = 'prepro';
        parameters_prepro = net_gui_read_options(handles.parameters_filename,flag_param);
        handles.parameters = parameters_prepro;
        if exist(analysis_filename,'file')
            flag_param = 'analysis';
            parameters_analysis = net_gui_read_options(handles.analysis_filename,flag_param);
            f = fieldnames(parameters_analysis);
            for i = 1:length(f)
                handles.parameters.(f{i}) = parameters_analysis.(f{i});
            end
        end
        
        % Initialize visualization
        set(handles.menu_visual_dataset,'Value',1)
        set(handles.menu_visual_dataset,'String','Select sample dataset')
        set(handles.menu_visual_dataset,'Enable','Off')
        set(allchild(handles.box_buttons_visual),'Enable','Off')
        %set(handles.visual_statistics,'Enable','Off');
        
        % Initialize processing
        set(allchild(handles.box_buttons_prepro),'Enable','Off')
        set(allchild(handles.buttons_act_conn),'Enable','Off')
        %set(handles.button_run_act_conn,'Enable','Off')
        
        % Check status processing per dataset
        guidata(handles.gui,handles)
        check_status_processing(hObject, eventdata, handles)
        handles.table_steps = getappdata(handles.gui,'table_steps');   
    end
    
guidata(hObject,handles)
end                 % --- end select_outdir

                    % --- start check_status_processing
function check_status_processing(hObject, eventdata, handles)
handles = guidata(gcbo);
    
    [~,xlsdata] = xlsread(handles.dataset_filename,1);
    num_dataset = size(xlsdata,1)-1;
    
    head_model = zeros(num_dataset,1);
    sign_proc = zeros(num_dataset,1);
    source_loc = zeros(num_dataset,1);
    activity = zeros(num_dataset,1);
    connectivity = zeros(num_dataset,1);
    
    table_steps = table(head_model,sign_proc,source_loc,activity,connectivity);
    
    for n=1:num_dataset
        pathy = handles.outdir;
        dd = [pathy filesep 'dataset' num2str(n)];
        
        ddsub = [dd filesep 'mr_data'];
        if exist([ddsub filesep 'anatomy_prepro_headmodel.mat'],'file')
            table_steps.head_model(n,1) = 1;
        else
            table_steps.head_model(n,1) = 0;
        end
        
        ddsub = [dd filesep 'eeg_signal'];
        if exist([ddsub filesep 'processed_eeg.mat'],'file')
            table_steps.sign_proc(n,1) = 1;
        else
            table_steps.sign_proc(n,1) = 0;
        end
        
        ddsub = [dd filesep 'eeg_source'];
        if exist([ddsub filesep 'sources_eeg.mat'],'file')
            table_steps.source_loc(n,1) = 1;
        else
            table_steps.source_loc(n,1) = 0;
        end
                
        if exist([dd filesep 'eeg_source' filesep 'ers_erd_results'],'dir') || exist([dd filesep 'eeg_signal' filesep 'ers_erd_results'],'dir') || exist([dd filesep 'eeg_signal' filesep 'erp_results'],'dir') || exist([dd filesep 'eeg_source' filesep 'erp_results'],'dir')
            table_steps.activity(n,1) = 1;
        else
            table_steps.activity(n,1) = 0;
        end
        
        ddsub_seed = [dd filesep 'eeg_source' filesep 'seed_connectivity'];
        ddsub_ica = [dd filesep 'eeg_source' filesep 'ica_results'];
        if exist([ddsub_seed filesep 'matrix_connectivity' filesep 'matrix_connectivity.mat'],'file') || exist([ddsub_ica filesep 'sica' filesep 'mni' filesep 'rsn'],'dir') || exist([ddsub_ica filesep 'tica' filesep 'mni' filesep 'rsn'],'dir')
            table_steps.connectivity(n,1) = 1;
        else
            table_steps.connectivity(n,1) = 0;
        end
    end
    setappdata(handles.gui,'table_steps',table_steps);
    
    guidata(handles.gui,handles)
    %set(allchild(handles.box_buttons_visual),'Enable','Off');
    check_status_visual(hObject, eventdata, handles)
%     visual_datasets = sum(table2array(table_steps),2);
%     visual_str = {'Select sample dataset'};
%     for n = 1:numel(visual_datasets)
%         if visual_datasets(n) > 0
%             visual_str = [visual_str; ['Dataset ' num2str(n)]];
%         end
%     end
%     set(handles.menu_visual_dataset,'String',visual_str)
%     
%     if size(visual_str,1) == 1
%         set(handles.menu_visual_dataset,'Enable','Off')
%     end
       
guidata(gcbo,handles)
end                 % --- end check_status_processing

                    % --- start load_data
function load_data(hObject, eventdata, handles)
handles = guidata(gcbo);

    % choose Excel file
    [filename, pathname] = uigetfile({'*.xlsx';'*.xls'},'',handles.net_path);
    
    if ischar(filename)
        handles.chosen_file = [pathname filename];

        guidata(gcbo,handles)
        view_data(hObject, eventdata, handles)
%{
        if strcmp(hObject.Tag,'load_dataset_button')

            %%%%%%%%%%%%%
            % CHECK CELLS (files exist/correct format)
            %%%%%%%%%%%%%

            %if ischar(filename) % if a file was selected
    %             % if it doesn't exist, save copy in output directory (with standard filename)
    %             if ~strcmp([pathname filename],handles.dataset_filename)
    %                 copyfile([pathname filename],handles.dataset_filename);
    %             end
                %handles.dataset_filename = dataset_filename;
                guidata(gcbo,handles)
                view_data(hObject, eventdata, handles)
                % handles.dataset_data = getappdata(handles.gui,'dataset_data');
            %end
        elseif strcmp(hObject.Tag,'load_parameters_button')

            %%%%%%%%%%%%%
            % CHECK CELLS (files exist/correct format)
            %%%%%%%%%%%%%

            %if ischar(filename) % if a file was selected
    %             % if it doesn't exist, save copy in output directory (with standard filename)
    %             if ~strcmp([pathname filename],handles.dataset_filename)
    %                 copyfile([pathname filename],handles.parameters_filename);
    %             end
                %handles.dataset_filename = dataset_filename;
                guidata(gcbo,handles)
                view_data(hObject, eventdata, handles)
                %handles.parameters_data = getappdata(handles.gui,'parameters_data');
            %end
        end
%}
        
    end
    
guidata(gcbo,handles)
end                 % --- end load_data
                    
                    % --- start view_data
function view_data(hObject, eventdata, handles)
    handles = guidata(gcbo);
    
    if strcmp(hObject.Tag,'view_dataset_button') || strcmp(hObject.Tag,'load_dataset_button')
        
        if strcmp(hObject.Tag,'load_dataset_button')
            handles.input_filename = handles.chosen_file;
        else
            handles.input_filename = handles.dataset_filename;
        end
        handles = net_gui_view_data(hObject, eventdata, handles);
        uiwait(handles.gui_data);
        %handles.dataset_data = getappdata(handles.gui,'dataset_data');
        delete(handles.gui_data);
        
        %dataset_data = getappdata(handles.gui,'dataset_data');
        num_dataset = size(handles.xls_data,1); % handles.dataset_data % handles.xls_data
        menu_str = {'Select sample dataset'};
        for n=1:num_dataset
            menu_str = [menu_str; ['Dataset ' num2str(n)]];
        end
        set(handles.menu_sample_dataset,'String',menu_str)
        
        % Initialize visualization
        set(handles.menu_visual_dataset,'String','Select sample dataset')
        set(handles.menu_visual_dataset,'Enable','Off')
        set(allchild(handles.box_buttons_visual),'Enable','Off')
        %set(handles.visual_statistics,'Enable','Off');
        
        % Check status processing per dataset
        guidata(handles.gui,handles)
        check_status_processing(hObject, eventdata, handles)
        handles.table_steps = getappdata(handles.gui,'table_steps');
        
    elseif strcmp(hObject.Tag,'view_parameters_button') || strcmp(hObject.Tag,'load_parameters_button')
        if strcmp(hObject.Tag,'load_parameters_button')
            handles.input_filename = handles.chosen_file;
        else
            handles.input_filename = handles.parameters_filename;
        end
        handles = net_gui_view_prepro_parameters(hObject, eventdata, handles);
        uiwait(handles.gui_data);
        %handles.parameters_data = getappdata(handles.gui,'parameters_data');
        delete(handles.gui_data);
        flag_param = 'prepro';
        parameters_prepro = net_gui_read_options(handles.parameters_filename,flag_param);
        f = fieldnames(parameters_prepro);
        for i = 1:length(f)
            handles.parameters.(f{i}) = parameters_prepro.(f{i});
        end
    elseif strcmp(hObject.Tag,'view_analysis_button') || strcmp(hObject.Tag,'load_analysis_button')
        if strcmp(hObject.Tag,'load_analysis_button')
            handles.input_filename = handles.chosen_file;
        else
            handles.input_filename = handles.analysis_filename;
        end
        handles = net_gui_view_analysis_parameters(hObject, eventdata, handles);
        uiwait(handles.gui_data);
        %handles.parameters_data = getappdata(handles.gui,'parameters_data');
        delete(handles.gui_data);
        if exist(handles.analysis_filename,'file')
            flag_param = 'analysis';
            parameters_analysis = net_gui_read_options(handles.analysis_filename,flag_param);
            f = fieldnames(parameters_analysis);
            for i = 1:length(f)
                handles.parameters.(f{i}) = parameters_analysis.(f{i});
            end
            guidata(gcbo,handles)
        end
    end

    set(handles.buttons_select_run,'SelectedObject',handles.radiobutt_run_sample)
    set(handles.menu_sample_dataset,'Value',1)
    set(handles.menu_sample_dataset,'Enable','on')
    select_sample_dataset(hObject, eventdata, handles)
    
    guidata(gcbo,handles)
end                 % --- end view_data

                    % --- start run_all_sample
function run_all_sample(hObject, eventdata, handles)
    handles = guidata(gcbo);
    
    set(handles.button_init,'Enable','On')
    if strcmp(hObject.SelectedObject.Tag,'run_all') || strcmp(hObject.SelectedObject.Tag,'run_auto')
        set(handles.menu_sample_dataset,'Enable','Off')
        %s = get(handles.button_init,'String');
        %set(handles.button_init,'String',s{1})
        set(handles.menu_sample_dataset,'Value',1)
    else
        set(handles.menu_sample_dataset,'Enable','On')
        if get(handles.menu_sample_dataset,'Value') == 1
            set(handles.button_init,'Enable','Off')
            %set(handles.menu_visual_dataset,'Enable','Off')
            %set(handles.menu_visual_dataset,'Value',1)
        end
    end
    set(allchild(handles.box_buttons_prepro),'Enable','Off')
    set(allchild(handles.buttons_act_conn),'Enable','Off')
    %set(handles.button_run_act_conn,'Enable','Off')
    %set(handles.menu_visual_dataset,'Enable','Off')
    %set(handles.menu_visual_dataset,'Value',1)
    %set(allchild(handles.box_buttons_visual),'Enable','Off');
    
    guidata(gcbo,handles)
end                 % --- end run_all_sample

                    % --- start select_sample_dataset
function select_sample_dataset(hObject, eventdata, handles)
    handles = guidata(gcbo);
    
    if get(hObject,'Value') == 1
        set(handles.button_init,'Enable','Off')
    else
        set(handles.button_init,'Enable','On')
    end
    set(allchild(handles.box_buttons_prepro),'Enable','Off')
    %set(handles.menu_visual_dataset,'Enable','Off')
    %set(handles.menu_visual_dataset,'Value',1)
    %set(allchild(handles.box_buttons_visual),'Enable','Off')
    set(allchild(handles.buttons_act_conn),'Enable','Off')
    %set(handles.button_run_act_conn,'Enable','Off')
    
    guidata(gcbo,handles)
end                 % --- end select_sample_dataset

                    % --- start check_exist_files
function check_exist_files(hObject, eventdata, handles)
handles = guidata(gcbo);
    
handles.table_steps = getappdata(handles.gui,'table_steps');
    % if files already exist, ask to overwrite
    setappdata(handles.gui,'flag_init',1);
    if sum(handles.table_steps{handles.subjects,:}(:)) > 0
        msg = {'Warning: Subfolder(s)/file(s) already present in this directory.';'Do you want to PERMANENTLY erase and re-initialize or keep and overwrite?'};
        choice = questdlg(msg,'Overwrite processing files?','Erase','Overwrite','Cancel','Overwrite');
        if strcmp(choice,'Erase')
            for s = 1:length(handles.subjects)
                rmdir([handles.outdir filesep 'dataset' num2str(handles.subjects(s))],'s')
            end
            if isdir([handles.outdir filesep 'group'])
                rmdir([handles.outdir filesep 'group'],'s')
            end
            handles.table_steps{handles.subjects,:}(:) = 0;
            setappdata(handles.gui,'table_steps',handles.table_steps);
            check_status_visual(hObject, eventdata, handles)
        elseif strcmp(choice,'Cancel') || strcmp(choice,'')
            setappdata(handles.gui,'flag_init',0);
        end
    end
    
guidata(gcbo,handles)
end                 % --- end check_exist_files

                    % --- start initialization
function initialization(hObject, eventdata, handles)
    handles = guidata(gcbo);
    
    if strcmp(handles.buttons_select_run.SelectedObject.Tag,'run_all') || strcmp(handles.buttons_select_run.SelectedObject.Tag,'run_auto')
        num_dataset = size(get(handles.menu_sample_dataset,'String'),1)-1;
        handles.subjects = 1:num_dataset;
    else
        num_dataset = 1;
        handles.subjects = get(handles.menu_sample_dataset,'Value')-1;
    end
    
    [~,xlsdata] = xlsread(handles.dataset_filename,1);
    if any(cellfun(@nodata,xlsdata(handles.subjects+1,1))) || any(cellfun(@nodata,xlsdata(handles.subjects+1,3))) || any(cellfun(@nodata,xlsdata(handles.subjects+1,4)))
        msgbox('MISSING REQUIRED DATA: EEG, Sensors position or Structural MRI filename. Check the input data to continue.');
        return
    end
    if any(any(cellfun(@nopath,xlsdata(handles.subjects+1,:))))
        msgbox('INPUT FILE(S) NOT FOUND. Check the input file paths to continue.');
        return
    end
    
    if strcmpi(hObject.Tag,'initialization')
        handles.datasets = net_read_data(handles.dataset_filename,handles.subjects);
        flag_param = 'prepro';
        handles.parameters = net_gui_read_options(handles.parameters_filename,flag_param);
        if exist(handles.analysis_filename,'file')
            flag_param = 'analysis';
            parameters_analysis = net_gui_read_options(handles.analysis_filename,flag_param);
            f = fieldnames(parameters_analysis);
            for i = 1:length(f)
                handles.parameters.(f{i}) = parameters_analysis.(f{i});
            end
        end
    end
    
    
    guidata(handles.gui,handles)
    check_status_processing(hObject, eventdata, handles) %%%%%%
    if strcmpi(hObject.Tag,'initialization')
        handles = guidata(gcbo);
        check_exist_files(hObject, eventdata, handles)
        if getappdata(handles.gui,'flag_init') == 0
            set(handles.menu_sample_dataset,'Value',1);
            set(handles.button_init,'Enable','Off');
            setappdata(handles.gui,'flag_init',1);
            return
        end
    end
    
    net_initialize_dir_filenames(handles)
    set(handles.button_headmod,'Enable','On');
    %set(handles.button_signal,'Enable','On');
    set(handles.button_init,'Enable','Off');
    
%     for n=1:num_dataset
%         field_str = ['dataset' num2str(num_dataset)];
%         flag_source = 0;
%         if handles.processing_steps.(field_str).head_model == 1 && handles.processing_steps.(field_str).sign_proc == 1
%             flag_source = flag_source + 1;
%         end
%         flag_act_conn = 0;
%         if handles.processing_steps.(field_str).source_loc == 1
%             flag_act_conn = flag_act_conn + 1;
%         end
%     end

    
    %guidata(handles.gui,handles)   % GAIA 13.05
    %check_status_processing(hObject, eventdata, handles)   % GAIA 13.05
    
    % Check status processing per dataset
    % If files already exist -> enable related processing buttons
    handles.table_steps = getappdata(handles.gui,'table_steps');
    if sum(handles.table_steps.head_model(handles.subjects)) == num_dataset
        set(handles.button_signal,'Enable','On');
    else
        set(handles.button_signal,'Enable','Off');
    end
    if sum(handles.table_steps.head_model(handles.subjects)) == num_dataset && sum(handles.table_steps.sign_proc(handles.subjects)) == num_dataset
        set(handles.button_source,'Enable','On');
    else
        set(handles.button_source,'Enable','Off');
    end
    if exist(handles.analysis_filename,'file') && sum(handles.table_steps.source_loc(handles.subjects)) == num_dataset
        set(allchild(handles.buttons_act_conn),'Enable','On');
        %set(handles.button_run_act_conn,'Enable','On');
    else
        set(allchild(handles.buttons_act_conn),'Enable','Off');
        %set(handles.button_run_act_conn,'Enable','Off');
    end
    if sum(handles.table_steps.activity(handles.subjects)) < 2 && sum(handles.table_steps.connectivity(handles.subjects)) < 2
        set(handles.button_stat,'Enable','Off')
    else
        set(handles.button_stat,'Enable','On')
    end
    
    if size(get(handles.menu_visual_dataset,'Value'),1) > 1
        set(handles.menu_visual_dataset,'Enable','On')
    end
    
    if strcmp(handles.buttons_select_run.SelectedObject.Tag,'run_auto')
        set(allchild(handles.box_buttons_prepro),'Enable','Off')
        set(allchild(handles.buttons_act_conn),'Enable','Off')
        for idx = 1:num_dataset
            handles.subjects = idx;
            guidata(gcbo,handles)
   
            head_modelling(hObject, eventdata, handles)
            signal_processing(hObject, eventdata, handles)
            source_localization(hObject, eventdata, handles)
             
            %         set(handles.buttons_select_run,'SelectedObject',findobj('Parent',handles.buttons_select_run,'-and','Tag','run_all'));
            %         set(allchild(handles.buttons_act_conn),'Enable','On');
           
            if isfield(handles.parameters,'erp') || isfield(handles.parameters,'ers_erd')
                activity_analysis(hObject, eventdata, handles)
            end
            
            if isfield(handles.parameters,'ica_conn') || isfield(handles.parameters,'seeding')
                connectivity_analysis(hObject, eventdata, handles)
            end
            
        end
        if isfield(handles.parameters,'stats')
            group_statistics(hObject, eventdata, handles)
        end
        fprintf('\n*** END OF PROCESSING. ***\n')
        check_status_visual(hObject, eventdata, handles)
        set(handles.button_init,'Enable','On')
        set(handles.menu_sample_dataset,'Enable','Off')
        set(handles.menu_sample_dataset,'Value',1)
        set(allchild(handles.box_buttons_prepro),'Enable','Off')
        set(allchild(handles.buttons_act_conn),'Enable','Off')
    end
    
    guidata(gcbo,handles)
end                 % --- end initialization

                    % --- start head_modelling
function head_modelling(hObject, eventdata, handles)
handles = guidata(gcbo);
%set(gcf, 'Pointer', 'watch');

fprintf('\n*** HEAD MODELLING: START... ***\n')
xls_data = handles.datasets;
options = handles.parameters;

for subject_i = handles.subjects
    
    % initialize filenames
    NET_folder = handles.net_path;
    folderpaths = getappdata(handles.gui,'folderpaths');
    folderpaths = folderpaths(subject_i);
    ddx = folderpaths.mr_data;
    ddy = folderpaths.eeg_signal;
    ddz = folderpaths.eeg_source;
    net_initialize_filenames;
    
    % Initialize structural MR image
    net_initialize_mri(xls_data(subject_i).anat_filename,[ddx filesep 'anatomy.nii']);

    % Convert raw EEG data to SPM format
    if ~(exist(raweeg_filename)==2)
        net_initialize_eeg(xls_data(subject_i).eeg_filename,xls_data(subject_i).experiment_filename,raweeg_filename,options.eeg_convert,options.pos_convert);
    end
    
    % HEAD MODELLING
    
    % remove image bias
    net_preprocess_sMRI(img_filename_orig,anat_filename,tpm_filename);
    
    % perform tissue segmentation
    net_segment_sMRI(img_filename,tpm_filename,options.sMRI);
    
    % creating tissue classes
    net_tissues_sMRI(img_filename,tpm_filename,options.sMRI);
    
    % coregister electrodes to MRI
    net_coregister_sensors(xls_data(subject_i).markerpos_filename,ddx,ddy,anat_filename,options.pos_convert);
    
    % calculate head model
    net_calculate_leadfield(segimg_filename,elec_filename,options.leadfield);

    handles.table_steps.head_model(subject_i,1) = 1;
    setappdata(handles.gui,'table_steps',handles.table_steps);

    fprintf(['\t** HEAD MODELLING: subject ' num2str(subject_i) ' DONE! **\n'])
end
    fprintf('\n*** HEAD MODELLING: DONE! ***\n')
    guidata(handles.gui,handles)
    if ~strcmp(handles.buttons_select_run.SelectedObject.Tag,'run_auto')
        fprintf('\n*** END OF PROCESSING. ***\n')
        initialization(hObject, eventdata, handles) % GAIA 13.05
        check_status_visual(hObject, eventdata, handles)
    end
%set(gcf, 'Pointer', 'arrow');
guidata(gcbo,handles)
end                 % --- end head_modelling

                    % --- start signal_processing
function signal_processing(hObject, eventdata, handles)
handles = guidata(gcbo);

fprintf('\n*** SIGNAL PROCESSING: START... ***\n')
xls_data = handles.datasets;
options = handles.parameters;
for subject_i = handles.subjects
    %% initialize filenames
    NET_folder = handles.net_path;
    folderpaths = getappdata(handles.gui,'folderpaths');
    folderpaths = folderpaths(subject_i);
    ddx = folderpaths.mr_data;
    ddy = folderpaths.eeg_signal;
    ddz = folderpaths.eeg_source;
    net_initialize_filenames;
    
    % Convert raw EEG data to SPM format, if using the same headmodel for
    % all participants
    if ~(exist(raweeg_filename)==2)
        net_initialize_eeg(xls_data(subject_i).eeg_filename,xls_data(subject_i).experiment_filename,raweeg_filename,options.eeg_convert,options.pos_convert);
    end
    
    %% initializing the preprocessed EEG file
    net_eegprepro_initialize(raweeg_filename, processedeeg_filename);
    
    %% SIGNAL PRE-PROCESSING
   
    %% detecting and Repairing the bad channels
    net_repair_badchannel(processedeeg_filename, options.badchannel_detection);
    %   net_plotPSD(raweeg_filename,processedeeg_filename)
    
    %% filtering EEG data
    net_filtering(processedeeg_filename,options.filtering);
    
    %% Attenuating fMRI gradient artifacts (for EEG/fMRI data only)
    net_rmMRIartifact(processedeeg_filename, options.fmri_artifacts);
    
    %% Attenuating BCG artifacts (for EEG/fMRI data only)
    net_rmBCGartifact(processedeeg_filename, options.bcg_artifacts);
    
    %% filtering EEG data
    net_filtering(processedeeg_filename,options.filtering);
    
    %% resampling EEG data for artifact removal
    net_resampling(processedeeg_filename,options.resampling_bss);
    
    %% Ocular artifact attenuation using BSS
    net_ocular_correction_wKurt(processedeeg_filename, options.ocular_correction);
    %net_plotPSD(raweeg_filename,processedeeg_filename)
    
    %% Movement artifact attenuation using BSS
    net_movement_correction_wSampEn(processedeeg_filename, options.mov_correction);
    %net_plotPSD(raweeg_filename,processedeeg_filename)
    
    %% Myogenic artifact removal using BSS
    net_muscle_correction_gamma_ratio(processedeeg_filename, options.muscle_correction);
    %net_plotPSD(raweeg_filename,processedeeg_filename)
    
    %% Cardiac artifact removal using BSS
    net_cardiac_correction_skew(processedeeg_filename, options.cardiac_correction);
    %net_plotPSD(raweeg_filename,processedeeg_filename)
    
    %% De-spiking EEG data
    net_despiking(processedeeg_filename,options.despiking);
    
    %% Re-referencing EEG data
    net_reference(processedeeg_filename,options.reference);
    
    %% resampling EEG data for source localization
    net_resampling(processedeeg_filename,options.resampling_src);
    % net_plotPSD(raweeg_filename,processedeeg_filename)
    % saveas(gcf,[dd filesep 'psd.jpg'])
    %close all

    handles.table_steps.sign_proc(subject_i,1) = 1;
    setappdata(handles.gui,'table_steps',handles.table_steps);

    fprintf('\n*** SIGNAL PROCESSING: DONE! ***\n')
end

guidata(handles.gui,handles)
if ~strcmp(handles.buttons_select_run.SelectedObject.Tag,'run_auto')
    fprintf('\n*** END OF PROCESSING. ***\n')
    initialization(hObject, eventdata, handles) % GAIA 13.05
    check_status_visual(hObject, eventdata, handles)
end

guidata(gcbo,handles)
end                 % --- end signal_processing

                    % --- start source_localization
function source_localization(hObject, eventdata, handles)
handles = guidata(gcbo);

fprintf('\n*** SOURCE LOCALIZATION: START... ***\n')
xls_data = handles.datasets;
options = handles.parameters;
for subject_i = handles.subjects
    %% initialize filenames
    NET_folder = handles.net_path;
    folderpaths = getappdata(handles.gui,'folderpaths');
    folderpaths = folderpaths(subject_i);
    ddx = folderpaths.mr_data;
    ddy = folderpaths.eeg_signal;
    ddz = folderpaths.eeg_source;
    net_initialize_filenames;
    
    %% perform source localization
    net_sourceanalysis(processedeeg_filename,headmodel_filename,source_filename,options.source);

    handles.table_steps.source_loc(subject_i,1) = 1;
    setappdata(handles.gui,'table_steps',handles.table_steps);

    fprintf('\n*** SOURCE LOCALIZATION: DONE! ***\n')
end

guidata(handles.gui,handles)
if ~strcmp(handles.buttons_select_run.SelectedObject.Tag,'run_auto')
    fprintf('\n*** END OF PROCESSING. ***\n')
    initialization(hObject, eventdata, handles) % GAIA 13.05
    check_status_visual(hObject, eventdata, handles)
end
%set(allchild(handles.buttons_act_conn),'Enable','On');

guidata(gcbo,handles)
end                 % --- end source_localization

                    % --- start activity_analysis
function activity_analysis(hObject, eventdata, handles)
handles = guidata(gcbo);

fprintf('\n*** ACTIVITY ANALYSIS: START... ***\n')
xls_data = handles.datasets;
options = handles.parameters;

if any(strcmpi(struct2cell(options.erp),'on')) || any(strcmpi(struct2cell(options.ers_erd),'on'))
    for subject_i = handles.subjects
        %% initialize filenames
        NET_folder = handles.net_path;
        folderpaths = getappdata(handles.gui,'folderpaths');
        folderpaths = folderpaths(subject_i);
        ddx = folderpaths.mr_data;
        ddy = folderpaths.eeg_signal;
        ddz = folderpaths.eeg_source;
        net_initialize_filenames;
        
        %% ERP analysis
        net_erp_analysis(source_filename,options.erp);
        
        %% ERS/ERD analysis
        net_ers_erd_analysis(source_filename,options.ers_erd);
        
        handles.table_steps.activity(subject_i,1) = 1;
        setappdata(handles.gui,'table_steps',handles.table_steps);
        
        fprintf('\n*** ACTIVITY ANALYSIS: DONE! ***\n')
    end
else
    fprintf('No activity analyses to run.\n')
end
guidata(handles.gui,handles)
if ~strcmp(handles.buttons_select_run.SelectedObject.Tag,'run_auto')
    fprintf('\n*** END OF PROCESSING. ***\n')
    initialization(hObject, eventdata, handles) % GAIA 13.05
    check_status_visual(hObject, eventdata, handles)
end

guidata(gcbo,handles)
end                 % --- end activity_analysis

                    % --- start connectivity_analysis
function connectivity_analysis(hObject, eventdata, handles)
handles = guidata(gcbo);

fprintf('\n*** CONNECTIVITY ANALYSIS: START... ***\n')
xls_data = handles.datasets;
options = handles.parameters;

if any(strcmpi(struct2cell(options.ica_conn),'on')) || any(strcmpi(struct2cell(options.seeding),'on'))
    for subject_i = handles.subjects
        %% initialize filenames
        NET_folder = handles.net_path;
        folderpaths = getappdata(handles.gui,'folderpaths');
        folderpaths = folderpaths(subject_i);
        ddx = folderpaths.mr_data;
        ddy = folderpaths.eeg_signal;
        ddz = folderpaths.eeg_source;
        net_initialize_filenames;
        
        %% ICA connectivity analysis
        net_ica_connectivity(source_filename,options.ica_conn);
        
        %% seed-based connectivity analysis
        net_seed_connectivity(source_filename,options.seeding);
        
        handles.table_steps.connectivity(subject_i,1) = 1;
        setappdata(handles.gui,'table_steps',handles.table_steps);
        
        fprintf('\n*** CONNECTIVITY ANALYSIS: DONE! ***\n')
    end
else
    fprintf('No connectivity analyses to run.\n')
end
guidata(handles.gui,handles)
if ~strcmp(handles.buttons_select_run.SelectedObject.Tag,'run_auto')
    fprintf('\n*** END OF PROCESSING. ***\n')
    initialization(hObject, eventdata, handles) % GAIA 13.05
    check_status_visual(hObject, eventdata, handles)
end

guidata(gcbo,handles)
end                 % --- end connectivity_analysis

                    % --- start group_statistics
function group_statistics(hObject, eventdata, handles)
    handles = guidata(gcbo);
    
    fprintf('\n*** STATISTICAL ANALYSIS: START... ***\n')
    options = handles.parameters;
    pathy = handles.outdir;
    
    table_steps = getappdata(handles.gui,'table_steps');
    subj_flag = ~strcmpi(options.stats.subjects,'none') && (any(table_steps.connectivity == 1) || any(table_steps.activity == 1));
    
    if subj_flag
        if strcmpi(options.stats.subjects,'all')
            options.stats.subjects = 1:size(table_steps.activity,1);
        else
            options.stats.subjects = str2num(options.stats.subjects);
        end
        if any(strcmpi(options.stats.flag,{'erp','ers_erd'}))
            subjs = intersect(find(table_steps.activity == 1),options.stats.subjects,'stable');
            options.stats.subjects = subjs;
        else
            subjs = intersect(find(table_steps.connectivity == 1),options.stats.subjects,'stable');
            options.stats.subjects = subjs;
        end
        if length(options.stats.subjects) >= 2
            net_group_analysis(pathy,options.stats);
        else
            fprintf('At least 2 SUBJECTS NEEDED to perform statistical analyses!')
        end
    else
        fprintf('No statistical analyses to run.')
    end
    if ~strcmp(handles.buttons_select_run.SelectedObject.Tag,'run_auto')
        fprintf('\n*** END OF PROCESSING. ***\n')
        check_status_visual(hObject, eventdata, handles)
    end
    
    guidata(gcbo,handles)
end                 % --- end group_statistics

                    % --- start check_status_visual
function check_status_visual(hObject, eventdata, handles)
handles = guidata(gcbo);
    
    table_steps = getappdata(handles.gui,'table_steps');
    visual_datasets = sum(table2array(table_steps),2);
    visual_str = {'Select sample dataset'};
    flag_visual = 0;
    for n = 1:numel(visual_datasets)
        if visual_datasets(n) > 0
            visual_str = [visual_str; ['Dataset ' num2str(n)]];
            flag_visual = [flag_visual; n];
        end
    end
    if exist([handles.outdir filesep 'group'],'dir')    % size(visual_str,1) > 2 &&
    	visual_str = [visual_str; 'Group'];
    end
    setappdata(handles.gui,'flag_visual',flag_visual)
    set(handles.menu_visual_dataset,'Value',1)
    set(handles.menu_visual_dataset,'String',visual_str)
    set(allchild(handles.box_buttons_visual),'Enable','Off');
    %set(handles.visual_statistics,'Enable','Off');
    
    if size(visual_str,1) == 1
        set(handles.menu_visual_dataset,'Enable','Off')
    else
        set(handles.menu_visual_dataset,'Enable','On')
    end
    
guidata(gcbo,handles)
end                 % --- end check_status_visual

                    % --- start select_visual_dataset
function select_visual_dataset(hObject, eventdata, handles)
handles = guidata(gcbo);

    set(allchild(handles.box_buttons_visual),'Enable','Off');
    %set(handles.visual_statistics,'Enable','Off');
    
    % Close previous visualization menu windows
    if ~isempty(findobj('Tag','fig_visual'))
        close(findobj('Tag','fig_visual'));
    end
    
    str_menu_visual = get(handles.menu_visual_dataset,'String');
    if strcmpi(str_menu_visual(get(handles.menu_visual_dataset,'Value')),'Group')
    	%set(handles.visual_statistics,'Enable','On');
        search_dir = [handles.outdir filesep 'group' filesep 'eeg_source'];
            stat_list = dir(search_dir);
            stat_list = stat_list([stat_list.isdir]);
            stat_list = stat_list(~ismember({stat_list.name},{'.','..'}));
        
        if any(ismember({stat_list.name},{'ers_erd_results','erp_results'}))
            set(handles.visual_activity,'Enable','On');
        end
        if any(ismember({stat_list.name},{'ica_results','seed_connectivity'}))
            set(handles.visual_connectivity,'Enable','On');
        end
    else
        table_steps = getappdata(handles.gui,'table_steps');
        flag_visual = getappdata(handles.gui,'flag_visual');
        idx_dataset = flag_visual(get(handles.menu_visual_dataset,'Value'));
        if idx_dataset > 0
            if table_steps.head_model(idx_dataset,1) == 1
                set(handles.visual_head_model,'Enable','On');
            end
            if table_steps.sign_proc(idx_dataset,1) == 1
                set(handles.visual_sign_proc,'Enable','On');
            end
            if table_steps.activity(idx_dataset,1) == 1
                set(handles.visual_activity,'Enable','On');
            end
            if table_steps.connectivity(idx_dataset,1) == 1
                set(handles.visual_connectivity,'Enable','On');
            end
        end
    end
    
guidata(gcbo,handles)
end                 % --- end select_visual_dataset

                    % --- start visualization
function visualization(hObject, eventdata, handles)
handles = guidata(gcbo);
    
    %idx_dataset = get(handles.menu_visual_dataset,'Value') - 1;
    
    NET_folder = handles.net_path;
    options = handles.parameters;
    
    isgroup = 0;
    menu_idx = get(handles.menu_visual_dataset,'Value');
    menu_str = get(handles.menu_visual_dataset,'String');
    if strcmpi(menu_str(menu_idx),'Group')
        isgroup = 1;
    end
    if ~isgroup
        flag_visual = getappdata(handles.gui,'flag_visual');
        idx_dataset = flag_visual(get(handles.menu_visual_dataset,'Value'));
        
        pathy = handles.outdir;
        dd=[pathy filesep 'dataset' num2str(idx_dataset)];
        ddx=[dd filesep 'mr_data'];
        ddy=[dd filesep 'eeg_signal'];
        ddz=[dd filesep 'eeg_source'];
        net_initialize_filenames;
    end
    
    if strcmp(hObject.Tag,'visual_head_model')
        handles.img_filename = img_filename;
        handles.segimg_filename = segimg_filename;
        handles.elec_filename = elec_filename;
        gui_head_modelling_output(handles);
    elseif strcmp(hObject.Tag,'visual_sign_proc')
        handles.raweeg_filename = raweeg_filename;
        handles.processedeeg_filename = processedeeg_filename;
        gui_sign_proc_output(handles)
    elseif strcmp(hObject.Tag,'visual_activity')
        if isgroup
            handles.anat_filename = [NET_folder filesep 'template' filesep 'tissues_MNI' filesep options.sMRI.template '.nii'];
            gui_statistics_activity_output(handles);
        else
            handles.anat_filename = anat_filename;
            handles.img_filename = img_filename;
            handles.processedeeg_filename = processedeeg_filename;
            gui_activity_output(handles);
        end
    elseif strcmp(hObject.Tag,'visual_connectivity')
        if isgroup
            handles.anat_filename = [NET_folder filesep 'template' filesep 'tissues_MNI' filesep options.sMRI.template '.nii'];
            gui_statistics_connectivity_output(handles);
        else
            handles.anat_filename = anat_filename;
            handles.img_filename = img_filename;
            gui_connectivity_output(handles);
        end
%     elseif strcmp(hObject.Tag,'visual_statistics')
%         handles.anat_filename = [NET_folder filesep 'template' filesep 'tissues_MNI' filesep options.sMRI.template '.nii'];
%         gui_statistics_output(handles);
    end
    
guidata(gcbo,handles)
end                 % --- end visualization

                    % --- start aboutFig
function aboutFig(hObject, eventdata, handles)
% Open window "About"
% -------------------
handles = guidata(gcbo);
    net_gui_about(handles)
end                 % --- end aboutFig

                    % --- start programQuit
function programQuit(hObject, eventdata, handles)
% Quit the GUI
% ------------
    choice = questdlg('Are you sure you want to quit the program?','Quit','Yes','No','No');
    if strcmp(choice,'Yes')
        close all force
        gui_path = fileparts(mfilename('fullpath')); % JS 08.2023 - remove net from the path
        net_path = fileparts(gui_path);
        rmpath(genpath(net_path))
        disp('___ Quitted NET ___')
    end
end                 % --- end programQuit