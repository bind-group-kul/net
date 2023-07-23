function varargout = net_ics_viewer(varargin)
% NET_ICS_VIEWER MATLAB code for net_ics_viewer.fig
%      NET_ICS_VIEWER, by itself, creates a new NET_ICS_VIEWER or raises the existing
%      singleton*.
%
%      H = NET_ICS_VIEWER returns the handle to a new NET_ICS_VIEWER or the handle to
%      the existing singleton*.
%
%      NET_ICS_VIEWER('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in NET_ICS_VIEWER.M with the given input arguments.
%
%      NET_ICS_VIEWER('Property','Value',...) creates a new NET_ICS_VIEWER or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before net_ics_viewer_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to net_ics_viewer_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help net_ics_viewer

% Last Modified by GUIDE v2.5 25-Sep-2022 12:59:57

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @net_ics_viewer_OpeningFcn, ...
                   'gui_OutputFcn',  @net_ics_viewer_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT

%% Global variables
global layoutConfig;
global icFile;
global icData;
global eventTemplate;

% --- Executes just before net_ics_viewer is made visible.
function net_ics_viewer_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to net_ics_viewer (see VARARGIN)

% Choose default command line output for net_ics_viewer
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes net_ics_viewer wait for user response (see UIRESUME)
 %uiwait(handles.mainWindow);
warning off
initiations(hObject, handles);


% --- Outputs from this function are returned to the command line.
function varargout = net_ics_viewer_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

%% UI callbacks
% --- Executes when mainWindow is resized.
function mainWindow_SizeChangedFcn(hObject, eventdata, handles)
% hObject    handle to mainWindow (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    rescaleMainWindow(hObject, handles);

% --- Executes on button press in pushbutton_loadFile.
function pushbutton_loadFile_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_loadFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    global icFile;
    global icData;
    [icFile.name, icFile.path, icFile.filterIndex] = uigetfile( ...
           {'*.mat','Matlab data file (*.mat)'; ...
            }, ...
            'Pick a file', ...
            'MultiSelect', 'off');
    
    file = [icFile.path, icFile.name];
    if(icFile.name)
        if (exist(file, 'file'))
            load(file);
            %here load processed data, extract events, put it into icData
            spmD = spm_eeg_load([icFile.path, 'processed_eeg.mat']);
            icData.events = spmD.triggers;
            clear spmD;
            if(exist('IC', 'var') && exist('mixing_matrix', 'var') && exist('bad_ics', 'var') && exist('Fs', 'var'))
                %copy to global variable
                set(handles.edit_filepath, 'Enable', 'on');
                set(handles.edit_filepath, 'String', file);
                set(handles.edit_currentIcIndex, 'Enable', 'on');
                set(handles.pushbutton_previous, 'Enable', 'on');
                set(handles.pushbutton_next, 'Enable', 'on');
                set(handles.pushbutton_gotoIc, 'Enable', 'on');
                
                icData.ic = IC;
                icData.mixingMatrix = mixing_matrix;
                icData.badIcs = bad_ics;
                icData.fs = Fs;
                icData.icNum = size(IC, 1);
                icData.badIcNum = length(bad_ics);
                icData.currentIcIndex = 1;
                icData.isFileLoaded = 1;

                clear IC bad_ics mixing_matrix Fs

                process_triggers();
                
                refresh_chart(hObject, handles); %% here refresh, add event-related in refresh
            else
                %deal with ilegal loadings
                set(handles.edit_filepath, 'String', 'data file is invalid, please choose again.');
            end
        else
            set(handles.edit_filepath, 'String', 'data file does not exist, please choose again.');
        end
    end

function edit_filepath_Callback(hObject, eventdata, handles)
% hObject    handle to edit_filepath (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_filepath as text
%        str2double(get(hObject,'String')) returns contents of edit_filepath as a double
    


% --- Executes during object creation, after setting all properties.
function edit_filepath_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_filepath (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end




% --- Executes on button press in pushbutton_previous.
function pushbutton_previous_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_previous (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    global icData;
    if(icData.currentIcIndex > 1)
        icData.currentIcIndex = icData.currentIcIndex - 1;
        refresh_chart(handles.mainWindow, handles);
    end
        

% --- Executes on button press in pushbutton_next.
function pushbutton_next_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_next (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    global icData;
    if(icData.currentIcIndex < icData.icNum)
        icData.currentIcIndex = icData.currentIcIndex + 1;
        refresh_chart(handles.mainWindow, handles);
    end


function edit_currentIcIndex_Callback(hObject, eventdata, handles)
% hObject    handle to edit_currentIcIndex (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_currentIcIndex as text
%        str2double(get(hObject,'String')) returns contents of edit_currentIcIndex as a double


% --- Executes during object creation, after setting all properties.
function edit_currentIcIndex_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_currentIcIndex (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton_gotoIc.
function pushbutton_gotoIc_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_gotoIc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    global icData;
    tempIndex = round(str2num(handles.edit_currentIcIndex.String));
    if(tempIndex >0 && tempIndex < icData.icNum)
        icData.currentIcIndex = tempIndex;
        refresh_chart(handles.mainWindow, handles);
    end
    
% --- Executes on selection change in popupmenu_frequency.
function popupmenu_frequency_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_frequency (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu_frequency contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu_frequency

    global icData;
    icData.currentStopFreq = get(hObject,'Value');
    refresh_chart(hObject, handles);
    


% --- Executes during object creation, after setting all properties.
function popupmenu_frequency_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_frequency (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

    % --- Executes on selection change in popupmenu_event_template.
function popupmenu_event_template_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_event_template (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu_event_template contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu_event_template
    global icData;
    icData.currentEventTemplate = get(hObject,'Value');
    load([icData.eventTemplateStruct(icData.currentEventTemplate).folder, filesep, icData.eventTemplateStruct(icData.currentEventTemplate).name]);
    icData.triggers = triggers;
    disp(['triggers loaded: ', icData.eventTemplateStruct(icData.currentEventTemplate).folder, filesep, icData.eventTemplateStruct(icData.currentEventTemplate).name]);
    trig_name = {triggers(:).condition_name};
    set(handles.popupmenu_event_name, 'Enable', 'on');
    set(handles.popupmenu_event_name, 'String', trig_name);
    set(handles.popupmenu_event_name, 'Value', icData.currentEvent);
    

% --- Executes during object creation, after setting all properties.
function popupmenu_event_template_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_event_template (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

 % --- Executes on selection change in popupmenu_event_name.
function popupmenu_event_name_Callback(hObject, eventdata, handles)
    global icData;
    icData.currentEvent = get(hObject,'Value');
    refresh_chart(hObject, handles);

function popupmenu_event_name_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_event_name (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
    
% --- Executes on selection change in popupmenu_template.
function popupmenu_template_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_template (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu_template contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu_template
    global icData;
    icData.currentTemplate = get(hObject,'Value');
    icData.locs = readlocs([icData.templateStruct(icData.currentTemplate).folder, filesep, icData.templateStruct(icData.currentTemplate).name]);
    disp(['electrode locations loaded: ', icData.templateStruct(icData.currentTemplate).folder, filesep, icData.templateStruct(icData.currentTemplate).name]);
        

% --- Executes during object creation, after setting all properties.
function popupmenu_template_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_template (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on key press with focus on mainWindow and none of its controls.
function mainWindow_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to mainWindow (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.FIGURE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
    global icData;
    if(strcmp(eventdata.Key,'leftarrow') && icData.isFileLoaded == 1)
        pushbutton_previous_Callback(hObject, eventdata, handles);
    elseif(strcmp(eventdata.Key, 'rightarrow') && icData.isFileLoaded == 1)
        pushbutton_next_Callback(hObject, eventdata, handles)
    end

%% private functions
function refresh_chart(hMainWindow, handles)
    warning off;
    global icData;
    global icFile;
    ic = icData.ic(icData.currentIcIndex,:);
    mixing_matrix = icData.mixingMatrix(:,icData.currentIcIndex);
    icLen = length(ic);
    timeAxis = 0:1/icData.fs:(icLen-1)/icData.fs;
    
    %update title
    status = ' good';
    if(sum(icData.badIcs == icData.currentIcIndex))
        status = ' bad';
    end
    set(handles.text_title, 'String', [icFile.name, ': IC ', num2str(icData.currentIcIndex), '/',num2str(icData.icNum),status]);
    
    %update index box
    set(handles.edit_currentIcIndex, 'String', num2str(icData.currentIcIndex));
    
    %plot axes icInTime
    axes(handles.axes_ic_in_time);
    plot(timeAxis, ic);
    %xlabel('Time (s)');
    title(['IC ', num2str(icData.currentIcIndex), ' in time, and in power spectrum'], 'FontSize', 14);
    set(handles.axes_time_frequency_1, 'xGrid', 'on');
    set(handles.axes_time_frequency_1, 'yGrid', 'on');
    
    %topoplot
    axes(handles.axes_topoplot);
    plot(0);
    topoplot(mixing_matrix, icData.locs, 'conv', 'on', 'whitebk', 'on');
    colorbar;
    title(['IC ', num2str(icData.currentIcIndex), ' mixing matrix in topoplot'], 'FontSize', 14);
    
    %plot axes psd
    [pxx,f] = pwelch(ic, icData.fs);
    f=f*icData.fs;
    [~, idx_f] = min(abs(f-80));
    axes(handles.axes_psd);
    area(f(1:idx_f),pxx(1:idx_f));
    xlabel(' Time (ms) /  Frequency (Hz)');
    %title(['IC ', num2str(icData.currentIcIndex), ': power spectrum'], 'FontSize', 14);
    set(handles.axes_time_frequency_2, 'xGrid', 'on');
    set(handles.axes_time_frequency_2, 'yGrid', 'on');
    
    %plot time-frequency 1
    axes(handles.axes_time_frequency_1);
    plot(0); %clear axes
    % tf-decompose ic according to icData.events
    if(icData.conditions_num >=1)
        large_window = 2; % window length in sec
        step_window  = 0.1; % step length in sec, smaller will make calculation take longer time
        frequencies  = 1:icData.currentStopFreq; % in Hz, resolution 1 Hz
        % window2 = hann( round(Fs*large_window) ); % in points/samples
        window2 = round(icData.fs*large_window); % in points/samples
        overlap = round(icData.fs*(large_window-step_window));
        [~, F, T, Ptot] = spectrogram(ic, window2, overlap, frequencies, icData.fs);
        imagesc(T,F,10*log(Ptot));
        xlabel('Time (s)');
        ylabel('Frequency (Hz)');
        set(gca, 'YDir', 'normal');
        title(['IC ', num2str(icData.currentIcIndex),' in power spectrum'], 'FontSize', 14);
        bar = colorbar;
        bar.Label.String = 'Power (dB)';
        set(handles.axes_ic_in_time, 'xGrid', 'off');
        set(handles.axes_ic_in_time, 'yGrid', 'off');
        set(handles.axes_ic_in_time, 'yDir', 'normal');
    end
    
    %plot time-frequency of events
    axes(handles.axes_time_frequency_2);
    if(icData.conditions_num >=2)
        large_window = 2; % window length in sec
        step_window  = 0.1; % step length in sec, smaller will make calculation take longer time
        frequencies  = 1:icData.currentStopFreq; % in Hz, resolution 1 Hz
        % window2 = hann( round(Fs*large_window) ); % in points/samples
        window2 = round(icData.fs*large_window); % in points/samples
        overlap = round(icData.fs*(large_window-step_window));
        [~, F, T, Ptot] = spectrogram(ic, window2, overlap, frequencies, icData.fs);
        options_ers_erd.pretrig = icData.triggers(icData.currentEvent).pretrig;
        options_ers_erd.posttrig = icData.triggers(icData.currentEvent).posttrig;
        options_ers_erd.baseline = icData.triggers(icData.currentEvent).baseline;
        [tf_map_1, times] = net_ers_erd(Ptot,T,icData.events{icData.currentEvent},options_ers_erd);
        
        imagesc(times,F,tf_map_1);
        xlabel('Time(ms)');
        ylabel('Frequency (Hz)');
        set(gca, 'YDir', 'normal');
        title(['IC ', num2str(icData.currentIcIndex),' in time-frequency domain for ', strrep(icData.triggers(icData.currentEvent).condition_name, '_', ' ')], 'FontSize', 14);
        bar = colorbar;
        bar.Label.String = 'Intensity (%)';
        set(handles.axes_psd, 'xGrid', 'off');
        set(handles.axes_psd, 'yGrid', 'off');
        set(handles.axes_psd, 'yDir', 'normal');
    end
    
    

function rescaleMainWindow(hMainWindow, handles)
    global layoutConfig;
    
    %calculate size of edit_filepath
    h=handles.edit_filepath;
    width = hMainWindow.Position(3) - 14*layoutConfig.edgeMargin - handles.pushbutton_loadFile.Position(3) - handles.popupmenu_frequency.Position(3) - handles.popupmenu_event_template.Position(3) - handles.popupmenu_event_name.Position(3) - handles.popupmenu_template.Position(3) - 3*handles.pushbutton_previous.Position(3) - handles.edit_currentIcIndex.Position(3); 
    set(h, 'Position', [h.Position(1), h.Position(2), width, h.Position(4)]);
    
    %calculate position of pupupmenu_frequency
    h=handles.popupmenu_frequency;
    xPosition = handles.edit_filepath.Position(1) + handles.edit_filepath.Position(3) + layoutConfig.edgeMargin;
    set(h, 'Position', [xPosition, h.Position(2), h.Position(3), h.Position(4)]);
    
    
    %calculate position of pupupmenu_event_template
    h=handles.popupmenu_event_template;
    xPosition = handles.popupmenu_frequency.Position(1) + handles.popupmenu_frequency.Position(3) + layoutConfig.edgeMargin;
    set(h, 'Position', [xPosition, h.Position(2), h.Position(3), h.Position(4)]);
    
    %calculate position of pupupmenu_event_name
    h=handles.popupmenu_event_name;
    xPosition = handles.popupmenu_event_template.Position(1) + handles.popupmenu_event_template.Position(3) + layoutConfig.edgeMargin;
    set(h, 'Position', [xPosition, h.Position(2), h.Position(3), h.Position(4)]);
    
    %calculate position of popupmenu_template
    h=handles.popupmenu_template;
    xPosition = handles.popupmenu_event_name.Position(1)+handles.popupmenu_event_name.Position(3) + layoutConfig.edgeMargin;
    set(h, 'Position', [xPosition, h.Position(2), h.Position(3), h.Position(4)]);
    
    %calculate position of pushbutton_previous
    h=handles.pushbutton_previous;
    xPosition = handles.popupmenu_template.Position(1) + handles.popupmenu_template.Position(3) + layoutConfig.edgeMargin;
    set(h, 'Position', [xPosition, h.Position(2), h.Position(3), h.Position(4)]);
    %calculate position of edit_currentIcIndex
    h=handles.edit_currentIcIndex;
    xPosition = handles.pushbutton_previous.Position(1) + handles.pushbutton_previous.Position(3) + layoutConfig.edgeMargin;
    set(h, 'Position', [xPosition, h.Position(2), h.Position(3), h.Position(4)]);
    %calculate position of pushbutton_next
    h=handles.pushbutton_next;
    xPosition = handles.edit_currentIcIndex.Position(1) + handles.edit_currentIcIndex.Position(3) + layoutConfig.edgeMargin;
    set(h, 'Position', [xPosition, h.Position(2), h.Position(3), h.Position(4)]);
    %calculate position of pushbutton_gotoIc
    h=handles.pushbutton_gotoIc;
    xPosition = handles.pushbutton_next.Position(1) + handles.pushbutton_next.Position(3) + layoutConfig.edgeMargin;
    set(h, 'Position', [xPosition, h.Position(2), h.Position(3), h.Position(4)]);
    
    %calculate size of panel_charts
    h=handles.uipanel_charts;
    width = hMainWindow.Position(3) - 2*layoutConfig.edgeMargin;
    height = hMainWindow.Position(4) - 4*layoutConfig.edgeMargin - handles.text_title.Position(4) - handles.pushbutton_loadFile.Position(4);
    set(h, 'Position', [h.Position(1), h.Position(2), width, height]);
    
    %calculate position and size of text_title
    h=handles.text_title;
    width = hMainWindow.Position(3) - 2*layoutConfig.edgeMargin;
    yPosition = handles.uipanel_charts.Position(2) + handles.uipanel_charts.Position(4) + layoutConfig.edgeMargin;
    set(h, 'Position', [h.Position(1), yPosition, width, h.Position(4)]);
    
    %calculate size of axis_psd
    h=handles.axes_time_frequency_2;
    xPosition = layoutConfig.axisMargin;
    width = (handles.uipanel_charts.Position(3) - 4*layoutConfig.axisMargin)/2;
    height = (handles.uipanel_charts.Position(4) - 4*layoutConfig.axisMargin)/2+layoutConfig.edgeMargin;
    set(h, 'Position', [xPosition, h.Position(2), width, height]);
    
    %calculate size and position of axes_psd
    h=handles.axes_psd;
    height2 = (height - layoutConfig.axisMargin2)/2;
    xPosition = handles.axes_time_frequency_2.Position(3) + 3*layoutConfig.axisMargin;
    set(h, 'Position', [xPosition, h.Position(2), width, height2]);
     
    %calculate size and position of axes_ic_in_time
    h=handles.axes_ic_in_time;
    yPosition = handles.axes_psd.Position(2)+ handles.axes_psd.Position(4) + layoutConfig.axisMargin2;
    set(h, 'Position', [xPosition, yPosition, width, height2]);
    
    
    %calculate size and position of axes_topoplot
    h=handles.axes_topoplot;
    yPosition = handles.axes_ic_in_time.Position(2)+handles.axes_ic_in_time.Position(4) + layoutConfig.axisMargin;
    set(h, 'Position', [xPosition, yPosition, width, height]);
    %calculate size and position of axes_time_frequency_1
    h=handles.axes_time_frequency_1;
    xPosition = layoutConfig.axisMargin;
    set(h, 'Position', [xPosition, yPosition, width, height]);
    
    

function initiations(hMainWindow, handles)
    global layoutConfig;
    global icFile;
    global icData;
    global eventTemplate;
    
    layoutConfig.edgeMargin = 10;
    layoutConfig.axisMargin = 50;
    layoutConfig.axisMargin2 = 20;
    
    icFile.name = [];
    icFile.path = [];
    icFile.FilterIndex = [];
    
    icData.ic = [];
    icData.mixingMatrix = [];
    icData.bad_ics = [];
    icData.currentTemplate = 1;
    icData.currentEvent = 1;
    icData.currentEventTemplate = 1;
    icData.currentStopFreq = 80;
    
    icData.isFileLoaded = 0;
    
    warning off;
    try
        netPath = net();
        
        templatefiles = [netPath, filesep, 'template', filesep, 'electrode_position', filesep, '*.sfp'];
        [templatefileNameCell, templatesNameStruct] = getfilelist(templatefiles);
        %[~, icData.currentTemplate] = ismember('bp128_corr.sfp', templatefileNameCell);
        icData.templateStruct = templatesNameStruct;
        icData.locs = readlocs([icData.templateStruct(icData.currentTemplate).folder, filesep, icData.templateStruct(icData.currentTemplate).name]);
        disp(['electrode locations loaded: ', icData.templateStruct(icData.currentTemplate).folder, filesep, icData.templateStruct(icData.currentTemplate).name]);
        set(handles.popupmenu_template, 'Enable', 'on');
        set(handles.popupmenu_template, 'String', templatefileNameCell);
        set(handles.popupmenu_template, 'Value', icData.currentTemplate);
        
        eventTemplatefiles = [netPath, filesep, 'template', filesep, 'triggers', filesep, '*.mat'];
        [eventTemplatefileNameCell, eventTemplatesNameStruct] = getfilelist(eventTemplatefiles);
        %[~, icData.currentEventTemplate] = ismember('hand_foot_lips_10_July.mat', eventTemplatefileNameCell);
        icData.eventTemplateStruct = eventTemplatesNameStruct;
        load([icData.eventTemplateStruct(icData.currentEventTemplate).folder, filesep, icData.eventTemplateStruct(icData.currentEventTemplate).name]);
        icData.triggers = triggers;
        disp(['triggers loaded: ', icData.eventTemplateStruct(icData.currentEventTemplate).folder, filesep, icData.eventTemplateStruct(icData.currentEventTemplate).name])
        set(handles.popupmenu_event_template, 'Enable', 'on');
        set(handles.popupmenu_event_template, 'String', eventTemplatefileNameCell);
        set(handles.popupmenu_event_template, 'Value', icData.currentEventTemplate);
        
        trig_name = {triggers(:).condition_name};
        set(handles.popupmenu_event_name, 'Enable', 'on');
        set(handles.popupmenu_event_name, 'String', trig_name);
        set(handles.popupmenu_event_name, 'Value', icData.currentEvent);
        
         frequencies = 1:120;
         set(handles.popupmenu_frequency, 'Enable', 'on');
         set(handles.popupmenu_frequency, 'String', num2cell(frequencies));
         set(handles.popupmenu_frequency, 'Value', icData.currentStopFreq);
        
        
    catch
        set(handles.text_title, 'String', 'Check NET path!');
    end
        
    
function [fileNameCell, fileStruct] = getfilelist(templatefiles)
    fileStruct = dir(templatefiles);
    fileNum = length(fileStruct);
    fileNameCell = cell(1, fileNum);
    for iterFile = 1:fileNum
        fileNameCell{iterFile} = fileStruct(iterFile).name;
    end
    
function [] = process_triggers()
    global icData;
    conditions_num = length(icData.triggers);
    events_num = length(icData.events);
    events = cell(1, conditions_num);
    
    for iter_events = 1:1:events_num
        for iter_conditions = 1:1:conditions_num
            sub_conditions_num = length(icData.triggers(iter_conditions).trig_labels);
            for iter_sub_conditions = 1:1:sub_conditions_num
                if(strcmp(icData.events(iter_events).value, icData.triggers(iter_conditions).trig_labels{iter_sub_conditions}))
                    events{iter_conditions} = [events{iter_conditions}, icData.events(iter_events)];
                    continue;
                end
            end
        end
    end
    
    empty_condition_index=[];
    for iter_conditions = 1:1:conditions_num
        if (isempty(events{iter_conditions}))
            empty_condition_index = [empty_condition_index iter_conditions];
            fprintf(['NET ERS/ERD: condition ''', icData.triggers(iter_conditions).condition_name, ''' cannot be found across all the events, please check your triggers template or your experiment!\n']);
        end
    end
    %delete empty conditions, and update conditions infomation
    events(empty_condition_index) = [];
    icData.triggers(empty_condition_index) = [];
    icData.conditions_num = length(events);
    icData.events = events;
    disp('events updated!');
       
