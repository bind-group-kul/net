function handles = net_gui_view_data_orig(hObject, eventdata, handles)

% k=[1,1];
% fontsize = 13*k(2);
% fontname = 'Helvetica';
 
k = handles.k;
fontsize = handles.fontsize;
fontname = handles.fontname;

gui_data = figure('Units','Normalized','NumberTitle','Off','Name','View datasets',...
    'Menubar','none','CloseRequestFcn','');

handles.gui_data = gui_data;
%handles.input_filename = handles.dataset_filename;

box = uiextras.VBox('Parent',gui_data,'Spacing',10*min(k),'Padding',5*min(k));    

% Show data from dataset excel file
[~,xlsdata] = xlsread(handles.input_filename,1);
handles.xls_names = xlsdata(1,:);
handles.xls_data = xlsdata(2:end,:);

handles.datatable = uitable('Parent',box, ...
    'ColumnName',handles.xls_names, ... %'ColumnWidth',{75*k(1) 50*k(1) 50*k(1) 50*k(1)}, ...
    'ColumnFormat',{'char','numeric','numeric','numeric'}, ...  % 'RawName',[]
    'FontName',fontname,'FontSize',fontsize,'Data',handles.xls_data,'Enable','On', ...
    'CellSelectionCallback',@select_data);
    
uicontrol('Parent',box,'Style','pushbutton','String','save','callback',@save_file);
uicontrol('Parent',box,'Style','pushbutton','String','cancel','callback',@cancel_edit);

guidata(gui_data,handles)
guidata(handles.gui,handles)
end


%% GUI callback functions

                    % --- start function
function template_function(hObject, eventdata, handles)
    handles = guidata(gcbo);
    
    guidata(gcbo,handles)
end                 % --- end function

                    % --- start save_file
function save_file(hObject, eventdata, handles)
handles = guidata(gcbo);

    new_data = table([handles.xls_names; handles.datatable.Data]);
    if exist(handles.dataset_filename,'file')
        delete(handles.dataset_filename)
    end
    writetable(new_data,handles.dataset_filename,'WriteVariableNames',false);
    handles.dataset_data = new_data;
    %setappdata(handles.gui,'dataset_data',handles.dataset_data);

guidata(gcbo,handles)
uiresume;
end                 % --- end save_file

                    % --- start cancel_edit
function cancel_edit(hObject, eventdata, handles)
uiresume;
end                 % --- end cancel_edit

                    % --- start select_data
function select_data(hObject, eventdata, handles)
handles = guidata(gcbo);

if ~isempty(eventdata.Indices)
    selected_cell = handles.datatable.Data(eventdata.Indices(1),eventdata.Indices(2));
    selected_path = fileparts(selected_cell{1});
    [filename,pathname]=uigetfile([selected_path filesep '*.*']);
    if ischar(filename)
        
        %%%%%%%%%%%%%
        % CHECK CELLS (files exist/correct format)
        %%%%%%%%%%%%%
        
        handles.xls_data(eventdata.Indices(1),eventdata.Indices(2)) = {[pathname filename]};
    end
    handles.datatable.Data = handles.xls_data;
end

guidata(gcbo,handles)
end                  % --- end select_data

