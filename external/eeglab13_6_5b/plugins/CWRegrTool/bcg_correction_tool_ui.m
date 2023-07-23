function varargout = bcg_correction_tool_ui(varargin)
% BCG_CORRECTION_TOOL_UI MATLAB code for bcg_correction_tool_ui.fig
%      BCG_CORRECTION_TOOL_UI, by itself, creates a new BCG_CORRECTION_TOOL_UI or raises the existing
%      singleton*.
%
%      H = BCG_CORRECTION_TOOL_UI returns the handle to a new BCG_CORRECTION_TOOL_UI or the handle to
%      the existing singleton*.
%
%      BCG_CORRECTION_TOOL_UI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in BCG_CORRECTION_TOOL_UI.M with the given input arguments.
%
%      BCG_CORRECTION_TOOL_UI('Property','Value',...) creates a new BCG_CORRECTION_TOOL_UI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before bcg_correction_tool_ui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to bcg_correction_tool_ui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help bcg_correction_tool_ui

% Last Modified by GUIDE v2.5 19-Sep-2013 13:29:00

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @bcg_correction_tool_ui_OpeningFcn, ...
                   'gui_OutputFcn',  @bcg_correction_tool_ui_OutputFcn, ...
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



% --- Executes just before bcg_correction_tool_ui is made visible.
function bcg_correction_tool_ui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to bcg_correction_tool_ui (see VARARGIN)

% Choose default command line output for bcg_correction_tool_ui
handles.output = hObject;

% Update handles structure




if numel(varargin)==1
    cfg = varargin{1};
elseif numel(varargin)==0
    cfg.cwregression.srate=[];
    cfg.cwregression.windowduration=[];
    cfg.cwregression.delay=[];
    cfg.cwregression.taperingfactor=[];
    cfg.cwregression.taperingfunction=@()nofunc;
    cfg.cwregression.regressorinds=[];
    cfg.cwregression.channelinds=[];
    cfg.cwregression.method='none';
else
    error('too many input arguments!!');
end
handles.userdata.cfg=cfg;

% set all the fields properly.
% deze moet ik gewoon hard-coden!!
% fields=fieldnames(cfg.cwregression);
% keyboard;
fields={'srate','delay','channelinds','regressorinds','windowduration','taperingfunction','taperingfactor'};
for i=1:numel(fields)
    if strcmp(fields{i},'taperingfunction')
        set(handles.(['edit_' fields{i}]),'String',func2str(handles.userdata.cfg.cwregression.(fields{i})));
    else
        set(handles.(['edit_' fields{i}]),'String',num2str(handles.userdata.cfg.cwregression.(fields{i})));
    end
end



if strcmp(cfg.cwregression.method,'everything')
    
    % Hint: get(hObject,'Value') returns toggle state of radiobutton_everything
    set(handles.radiobutton_everything,'Value',1);
    set(handles.radiobutton_slidingwindow,'Value',0);
    set(handles.radiobutton_taperedhann,'Value',0);
    
    % prepare the parameters!!!
    % invisible...
    for param={'windowduration','taperingfunction','taperingfactor'} 
        set(handles.(['edit_' param{1}]),'visible','off');
        set(handles.(['text_' param{1}]),'visible','off');
    end
    % visible...
    for param={'srate','delay','channelinds','regressorinds'} 
        set(handles.(['edit_' param{1}]),'visible','on');
        set(handles.(['text_' param{1}]),'visible','on');
        set(handles.text10,'visible','on');
    end
    
    
elseif strcmp(cfg.cwregression.method,'slidingwindow')
    
    % Hint: get(hObject,'Value') returns toggle state of radiobutton_slidingwindow
    set(handles.radiobutton_everything,'Value',0);
    set(handles.radiobutton_slidingwindow,'Value',1);
    set(handles.radiobutton_taperedhann,'Value',0);
    
    
    % prepare the parameters!!!
    % invisible...
    for param={'taperingfunction','taperingfactor'} 
        set(handles.(['edit_' param{1}]),'visible','off');
        set(handles.(['text_' param{1}]),'visible','off');
    end
    % visible...
    for param={'srate','delay','channelinds','regressorinds','windowduration'}
        set(handles.(['edit_' param{1}]),'visible','on');
        set(handles.(['text_' param{1}]),'visible','on');
        set(handles.text10,'visible','on');
    end
    
    
elseif strcmp(cfg.cwregression.method,'taperedhann')
    
    set(handles.radiobutton_everything,'Value',0);
    set(handles.radiobutton_slidingwindow,'Value',0);
    set(handles.radiobutton_taperedhann,'Value',1);
    
    
    % prepare the parameters!!!
    % invisible...
    for param={} 
        set(handles.(['edit_' param{1}]),'visible','off');
        set(handles.(['text_' param{1}]),'visible','off');
    end
    % visible...
    for param={'srate','delay','channelinds','regressorinds','windowduration','taperingfunction','taperingfactor'}
        set(handles.(['edit_' param{1}]),'visible','on');
        set(handles.(['text_' param{1}]),'visible','on');
        set(handles.text10,'visible','on');
    end
      
    
elseif strcmp(cfg.cwregression.method,'none')
    
    set(handles.radiobutton_everything,'Value',0);
    set(handles.radiobutton_slidingwindow,'Value',0);
    set(handles.radiobutton_taperedhann,'Value',0);
    
    for param={'srate','delay','channelinds','regressorinds','windowduration','taperingfunction','taperingfactor'}
        set(handles.(['edit_' param{1}]),'visible','off');
        set(handles.(['text_' param{1}]),'visible','off');
    end
    set(handles.text10,'visible','off');
    
    
end

% keyboard;

% % more tricks to arrange for the visibility.
% for param={'srate','delay','channelinds','regressorinds','windowduration','taperingfunction','taperingfactor'}
%     set(handles.(['edit_' param{1}]),'visible','off');
%     set(handles.(['text_' param{1}]),'visible','off');
% end
% set(handles.text10,'visible','off');
% 



handles.userdata.buttonpressed=0;
guidata(hObject, handles);
% UIWAIT makes bcg_correction_tool_ui wait for user response (see UIRESUME)
uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = bcg_correction_tool_ui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure

% keyboard;

if handles.userdata.buttonpressed==0
    handles.userdata.cfg=[];
    disp('closed figure with the button! -- aborting cw regression.');
end
varargout{1} =  handles.userdata.cfg;

close(handles.figure1);

% put the variable in the calling namespace.
% keyboard;
% close(hObject);




function edit_srate_Callback(hObject, eventdata, handles)
% hObject    handle to edit_srate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_srate as text
%        str2double(get(hObject,'String')) returns contents of edit_srate as a double

handles.userdata.cfg.srate=str2num(get(hObject,'String'));
% set(hObject,'handles',handles);


% --- Executes during object creation, after setting all properties.
function edit_srate_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_srate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end




function edit_windowduration_Callback(hObject, eventdata, handles)
% hObject    handle to edit_windowduration (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_windowduration as text
%        str2double(get(hObject,'String')) returns contents of edit_windowduration as a double


% --- Executes during object creation, after setting all properties.
function edit_windowduration_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_windowduration (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_delay_Callback(hObject, eventdata, handles)
% hObject    handle to edit_delay (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_delay as text
%        str2double(get(hObject,'String')) returns contents of edit_delay as a double


% --- Executes during object creation, after setting all properties.
function edit_delay_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_delay (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_channelinds_Callback(hObject, eventdata, handles)
% hObject    handle to edit_channelinds (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_channelinds as text
%        str2double(get(hObject,'String')) returns contents of edit_channelinds as a double


% --- Executes during object creation, after setting all properties.
function edit_channelinds_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_channelinds (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_regressorinds_Callback(hObject, eventdata, handles)
% hObject    handle to edit_regressorinds (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_regressorinds as text
%        str2double(get(hObject,'String')) returns contents of edit_regressorinds as a double


% --- Executes during object creation, after setting all properties.
function edit_regressorinds_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_regressorinds (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_taperingfunction_Callback(hObject, eventdata, handles)
% hObject    handle to edit_taperingfunction (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_taperingfunction as text
%        str2double(get(hObject,'String')) returns contents of edit_taperingfunction as a double


% --- Executes during object creation, after setting all properties.
function edit_taperingfunction_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_taperingfunction (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_taperingfactor_Callback(hObject, eventdata, handles)
% hObject    handle to edit_taperingfactor (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_taperingfactor as text
%        str2double(get(hObject,'String')) returns contents of edit_taperingfactor as a double


% --- Executes during object creation, after setting all properties.
function edit_taperingfactor_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_taperingfactor (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton1.
function pushbutton1_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% set all the fields properly.



fields={'srate','delay','channelinds','regressorinds','windowduration','taperingfunction','taperingfactor'};
% keyboard;
for i=1:numel(fields)
    if strcmp(fields{i},'taperingfunction')
        handles.userdata.cfg.cwregression.(fields{i}) = str2func(get(handles.(['edit_' fields{i}]),'String'));
    else
        handles.userdata.cfg.cwregression.(fields{i}) = str2num(get(handles.(['edit_' fields{i}]),'String'));
    end
end


if get(handles.radiobutton_everything,'value');
    handles.userdata.cfg.cwregression.method = 'everything';
elseif get(handles.radiobutton_slidingwindow,'value');
    handles.userdata.cfg.cwregression.method = 'slidingwindow';
elseif get(handles.radiobutton_taperedhann,'value');
    handles.userdata.cfg.cwregression.method = 'taperedhann';
else
    handles.userdata.cfg.cwregression.method = 'none';
end


handles.userdata.buttonpressed=1;
guidata(hObject,handles);

% keyboard;
% bcg_correction_tool_ui_OutputFcn(hObject, eventdata, handles);
% put cfg into the calling namespace.
% keyboard;
% this will evaluate figure1_CloseRequestFcn.

close(handles.figure1);


% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure

% set output...
% keyboard;
% cfg=bcg_correction_tool_ui_OutputFcn(hObject, eventdata, handles);
% then close (finally!)
% keyboard;
% assignin('caller','cfg',handles.userdata.cfg)

    

if isequal(get(hObject, 'waitstatus'), 'waiting')
    % 
    % The GUI is still in UIWAIT, us UIRESUME
    % keyboard;
    uiresume(hObject);
else
    % bcg_correction_tool_ui_OutputFcn(hObject, eventdata, handles)
    % The GUI is no longer waiting, just close it
    delete(hObject);
end


% delete(hObject);


% --- Executes on button press in radiobutton_everything.
function radiobutton_everything_Callback(hObject, eventdata, handles)
% hObject    handle to radiobutton_everything (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of radiobutton_everything
if get(hObject,'Value')==1
    set(handles.radiobutton_slidingwindow,'Value',0);
    set(handles.radiobutton_taperedhann,'Value',0);
    
    % prepare the parameters!!!
    % invisible...
    for param={'windowduration','taperingfunction','taperingfactor'} 
        set(handles.(['edit_' param{1}]),'visible','off');
        set(handles.(['text_' param{1}]),'visible','off');
    end
    % visible...
    for param={'srate','delay','channelinds','regressorinds'} 
        set(handles.(['edit_' param{1}]),'visible','on');
        set(handles.(['text_' param{1}]),'visible','on');
        set(handles.text10,'visible','on');
    end
    
else
    for param={'srate','delay','channelinds','regressorinds','windowduration','taperingfunction','taperingfactor'}
        set(handles.(['edit_' param{1}]),'visible','off');
        set(handles.(['text_' param{1}]),'visible','off');
    end
    set(handles.text10,'visible','off');
    
end


% --- Executes on button press in radiobutton_slidingwindow.
function radiobutton_slidingwindow_Callback(hObject, eventdata, handles)
% hObject    handle to radiobutton_slidingwindow (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of radiobutton_slidingwindow
if get(hObject,'Value')==1
    set(handles.radiobutton_taperedhann,'Value',0);
    set(handles.radiobutton_everything,'Value',0);
    
    
    % prepare the parameters!!!
    % invisible...
    for param={'taperingfunction','taperingfactor'} 
        set(handles.(['edit_' param{1}]),'visible','off');
        set(handles.(['text_' param{1}]),'visible','off');
    end
    % visible...
    for param={'srate','delay','channelinds','regressorinds','windowduration'}
        set(handles.(['edit_' param{1}]),'visible','on');
        set(handles.(['text_' param{1}]),'visible','on');
        set(handles.text10,'visible','on');
    end
    
else
    for param={'srate','delay','channelinds','regressorinds','windowduration','taperingfunction','taperingfactor'}
        set(handles.(['edit_' param{1}]),'visible','off');
        set(handles.(['text_' param{1}]),'visible','off');
    end
    set(handles.text10,'visible','off');
    
end



% --- Executes on button press in radiobutton_taperedhann.
function radiobutton_taperedhann_Callback(hObject, eventdata, handles)
% hObject    handle to radiobutton_taperedhann (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of radiobutton_taperedhann
if get(hObject,'Value')==1
    set(handles.radiobutton_slidingwindow,'Value',0);
    set(handles.radiobutton_everything,'Value',0);
    
    
    % prepare the parameters!!!
    % invisible...
    for param={} 
        set(handles.(['edit_' param{1}]),'visible','off');
        set(handles.(['text_' param{1}]),'visible','off');
    end
    % visible...
    for param={'srate','delay','channelinds','regressorinds','windowduration','taperingfunction','taperingfactor'}
        set(handles.(['edit_' param{1}]),'visible','on');
        set(handles.(['text_' param{1}]),'visible','on');
        set(handles.text10,'visible','on');
    end
    
    
else
    for param={'srate','delay','channelinds','regressorinds','windowduration','taperingfunction','taperingfactor'}
        set(handles.(['edit_' param{1}]),'visible','off');
        set(handles.(['text_' param{1}]),'visible','off');
    end
    set(handles.text10,'visible','off');
end
    
