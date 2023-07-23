function handles = net_gui_view_parameters_orig(hObject, eventdata, handles)

k=[1,1];
fontsize = 13*k(2);
fontname = 'Helvetica';
 
% k = handles.k;
% fontsize = handles.fontsize;
% fontname = handles.fontname;

gui_data = figure('Units','Normalized','NumberTitle','Off','Name','View parameters',...
    'Menubar','none','WindowStyle','modal'); %'CloseRequestFcn','');
handles.gui_data = gui_data;
handles.input_filename = handles.parameters_filename;
%handles.input_filename = '/Users/u0114283/Documents/NET_v2.24/gui/parameters.xlsx';
box = uiextras.VBox('Parent',gui_data,'Spacing',10*min(k),'Padding',5*min(k));    


tabs = uiextras.TabPanel('Parent',box,'Padding',0,'TabSize',65*k(1), ...
    'FontName','Tahoma','FontSize',8*k(2),'FontWeight','bold');
tabnames = {'CONVERSION';'HEAD MODEL';'SIGNAL PROCESSING';'SOURCE LOCALIZATION';'ACTIVITY ANALYSIS';'CONNECTIVITY ANALYSIS';'STATISTICS'};
% Show data from dataset excel file
[~,sheets] = xlsfinfo(handles.input_filename);

for s = 1:length(sheets)
    sheet_name = char(sheets(s));
    %handles.(sheet_name) = [];'
    [~,~,xlsdata] = xlsread(handles.input_filename,s);
    handles.(sheet_name).xls_names = xlsdata(:,1);
    handles.(sheet_name).xls_data = xlsdata(:,2:end);
    
    for ncol = 1:size(handles.(sheet_name).xls_data,2)
        % format data to left alignment
        dat = handles.(sheet_name).xls_data(2:end,ncol);
        dat=cellfun(@string,dat,'UniformOutput',false);
        miss = cell2mat(cellfun(@ismissing,dat,'UniformOutput',false));
        dat(miss) = {''};
        dat = cellfun(@char,cellfun(@string,dat,'UniformOutput',false),'UniformOutput',false);
        handles.(sheet_name).xls_data(2:end,ncol) = cellfun(@(s) sprintf('%*s',-max(cellfun(@length,dat)),s),dat,'UniformOutput',false);
    end
    
    tabData = uix.Panel('Parent',tabs,'Padding',5*min(k),'Tag',sheet_name);
    handles.datatable = uitable('Parent',tabData, 'ColumnName',{char(tabnames(s)),''},...
    'ColumnFormat',{'char',[]}, ...
    'FontName',fontname,'FontSize',fontsize,'Data',[handles.(sheet_name).xls_names(2:end,:) handles.(sheet_name).xls_data(2:end,:)],'Enable','On', ...
    'CellSelectionCallback',@select_data);
end
tabs.TabNames = tabnames;


    
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
writetable(new_data,handles.input_filename,'WriteVariableNames',false);
handles.parameters_data = new_data;
setappdata(handles.gui,'parameters_data',handles.parameters_data);

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

