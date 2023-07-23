function handles = net_gui_view_prepro_parameters(hObject, eventdata, handles)

% k=[1,1];
% fontsize = 13*k(2);
% fontname = 'Helvetica';
 
k = handles.k;
fontsize = handles.fontsize;
fontname = handles.fontname;

gui_data = figure('Units','Normalized','NumberTitle','Off','Name','View pre-processing parameters',...
    'Menubar','none','WindowStyle','modal','CloseRequestFcn',''); %'PaperUnits',handles.gui.PaperUnits %'PaperSize',handles.gui.PaperSize
set(gui_data, 'Pointer', 'watch'); drawnow
handles.gui_data = gui_data;
% handles.input_filename = handles.parameters_filename;
%handles.input_filename = '/Users/u0114283/Documents/NET_v2.24/gui/parameters.xlsx';

box = uiextras.VBox('Parent',gui_data,'Spacing',2*min(k),'Padding',5*min(k)); % originally 10&5

tabs = uiextras.TabPanel('Parent',box,'Padding',0,'TabSize', -1, ... %170*k(1), ... % originally 110*k(1)
    'FontName',fontname,'FontSize',floor(8*k(2)),'FontWeight','bold');

handles.tabs = tabs;
tabnames = {'CONVERSION';'HEAD MODEL';'SIGNAL PROCESSING';'SOURCE LOCALIZATION'}; %;'ACTIVITY ANALYSIS';'CONNECTIVITY ANALYSIS';'STATISTICS'};
% Show data from dataset excel file
sheets_list = {'conversion';'head_modelling';'signal_processing';'source_localization';'activity_analysis';'connectivity_analysis';'statistical_analysis'};
for s = 1:4
    sheet_name = char(sheets_list(s));
    %handles.(sheet_name) = [];'
    [~,~,xlsdata] = xlsread(handles.input_filename,s);
    find_nan = cellfun(@isnan,xlsdata(:,1),'UniformOutput',false);
    find_nan = cellfun(@(x) x(1),find_nan);
    xlsdata(find_nan,:) = [];
    handles.(sheet_name).xls_names = xlsdata(2:end,1);
    handles.(sheet_name).xls_data = xlsdata(2:end,2:end);
    
%     for ncol = 1:size(handles.(sheet_name).xls_data,2)
%         % format data to left alignment
%         dat = handles.(sheet_name).xls_data(2:end,ncol);
%         dat=cellfun(@string,dat,'UniformOutput',false);
%         miss = cell2mat(cellfun(@ismissing,dat,'UniformOutput',false));
%         dat(miss) = {''};
%         dat = cellfun(@char,cellfun(@string,dat,'UniformOutput',false),'UniformOutput',false);
%         handles.(sheet_name).xls_data(2:end,ncol) = cellfun(@(s) sprintf('%*s',-max(cellfun(@length,dat)),s),dat,'UniformOutput',false);
%     end
    
%     tabData = uix.Panel('Parent',tabs,'Padding',5*min(k),'Tag',sheet_name);
%     handles.datatable = uitable('Parent',tabData, 'ColumnName',{char(tabnames(s)),''},...
%     'ColumnFormat',{'char',[]}, ...
%     'FontName',fontname,'FontSize',fontsize,'Data',[handles.(sheet_name).xls_names(2:end,:) handles.(sheet_name).xls_data(2:end,:)],'Enable','On', ...
%     'CellSelectionCallback',@select_data);

    tabData=uix.ScrollingPanel('Parent',tabs,'Padding',5*min(k)); % originally 5*min(k))
    tabData.Tag = sheet_name;

    box_param = uiextras.HBox('Parent',tabData,'Spacing',min(k),'Padding',5*min(k)); % originally 10*min(k) & 5*min(k))

    box_param_names = uiextras.VBox('Parent',box_param,'Spacing',5*min(k)); %,'Padding',5*min(k));
    box_param_values = uiextras.VBox('Parent',box_param,'Spacing',5*min(k)); %,'Padding',5*min(k));
    box_param_select = uiextras.VBox('Parent',box_param,'Spacing',5*min(k)); %,'Padding',5*min(k));
    box_param_help = uiextras.VBox('Parent',box_param,'Spacing',5*min(k)); %,'Padding',5*min(k));
    for idx_name = 1:size(handles.(sheet_name).xls_names,1)
        uicontrol('Parent',box_param_names,'Style','text','String',handles.(sheet_name).xls_names(idx_name),...
            'FontName',fontname,'FontSize',fontsize,'HorizontalAlignment','left');
        uicontrol('Parent',box_param_values,'Style','edit','String',handles.(sheet_name).xls_data(idx_name,1),'Enable','Off',...
            'FontName',fontname,'FontSize',fontsize,'HorizontalAlignment','left','Tag',char(handles.(sheet_name).xls_names(idx_name)));  
        uicontrol('Parent',box_param_select,'Style','pushbutton','String','Edit','Tag',char(handles.(sheet_name).xls_names(idx_name)),...
            'FontName',fontname,'FontSize',fontsize,'HorizontalAlignment','center','Callback',@edit_parameter);
        uicontrol('Parent',box_param_help,'Style','text','String','?','Tooltip',char(handles.(sheet_name).xls_data{idx_name,2}),...
            'FontName',fontname,'FontSize',fontsize,'HorizontalAlignment','center');
    end
    set(box_param_names,'Sizes',repmat(20*k(2),1,size(handles.(sheet_name).xls_names,1)))
    set(box_param_values,'Sizes',repmat(20*k(2),1,size(handles.(sheet_name).xls_names,1)))
    set(box_param_select,'Sizes',repmat(20*k(2),1,size(handles.(sheet_name).xls_names,1)))
    set(box_param_help,'Sizes',repmat(20*k(2),1,size(handles.(sheet_name).xls_names,1)))
    set(box_param,'Sizes',[200*k(2) 140*k(2) 55*k(2) 10*k(2)]) % originally [235*k(2) 135*k(2) 70*k(2) 20*k(2)]
    
    % René: makes the column widts fixed
    %set(box_param,'Sizes',[200*k(2) 140*k(2) 55*k(2) 10*k(2)]) % originally [235*k(2) 135*k(2) 70*k(2) 20*k(2)]
    
    % René: widths of the columns
    set(box_param, 'Sizes', [-1 -1 80 30])

    set(tabData,'Units','Normalized',...
    'Heights',10+25*k(2)*size(handles.(sheet_name).xls_names,1),... % heights of contents, in pixels and/or weights
        'MinimumHeights',50,... % minimum heights of contents, in pixels
        'VerticalOffsets',0,... % vertical offsets of contents, in pixels
        'VerticalSteps',30,... % vertical slider steps, in pixels
        'HorizontalOffsets',0,... % horizontal offsets of contents, in pixels
        'HorizontalSteps',30,... % horizontal slider steps, in pixels
        'MouseWheelEnabled','on');
        
        % René: makes columns fixed width
        %'Widths',490,... % widths of contents, in pixels and/or weights
        %'MinimumWidths',30,... % minimum widths of contents, in pixels

end
tabs.TabNames = tabnames;

uiextras.Empty('Parent',box);

box_lower = uiextras.HBox('Parent',box,'Spacing',20*min(k),'Padding',5*min(k));

uiextras.Empty('Parent',box_lower);

box_buttons = uiextras.VBox('Parent',box_lower);

uicontrol('Parent',box_buttons,'Style','pushbutton','String','Save',...
    'FontName',fontname,'FontSize',fontsize,'Callback',@save_file);
uicontrol('Parent',box_buttons,'Style','pushbutton','String','Cancel',...
    'FontName',fontname,'FontSize',fontsize,'Callback',@cancel_edit);
set(box_buttons,'Sizes',[30*k(2) 30*k(2)])

uiextras.Empty('Parent',box_lower);

set(box_lower,'Sizes',[-1 170*k(2) -1]) %[-1 170*k(2) -1]
% set(box,'Sizes',[300*k(2) -1 90*k(2)])
% René: make columns vertical adjustable and interspace fixed
set(box,'Sizes',[-1 50 90*k(2)])

set(gui_data, 'Pointer', 'arrow');

guidata(gui_data,handles)
guidata(handles.gui,handles)
end


%% GUI callback functions

                    % --- start function
function template_function(hObject, eventdata, handles)
    handles = guidata(gcbo);
    
    guidata(gcbo,handles)
end                 % --- end function

                    % --- start edit_parameter
function edit_parameter(hObject, eventdata, handles)
    handles = guidata(gcbo);
    
    edit_obj = findobj(allchild(handles.tabs),'Tag',hObject.Tag,'-and','Style','edit');
    if strcmpi(hObject.String,'Edit')
        set(edit_obj,'Enable','On')
        set(hObject,'String','Cancel')
        setappdata(hObject,'oldvalue',edit_obj.String)
    elseif strcmpi(hObject.String,'Cancel')
        set(edit_obj,'String',getappdata(hObject,'oldvalue'))
        set(edit_obj,'Enable','Off')
        rmappdata(hObject,'oldvalue')
        set(hObject,'String','Edit')
    end
    guidata(gcbo,handles)
end                 % --- end edit_parameter

                    % --- start save_file
function save_file(hObject, eventdata, handles)
handles = guidata(gcbo);

% if ~isempty(findobj(allchild(handles.tabs),'String','OK'))
%     msg = {'Warning: Edit(s) not saved.';'Do you want to save them all?'};
%     choice = questdlg(msg,'Save edits?','Save all','Cancel','Save all');
%     if strcmp(choice,'Cancel')
%         return
%     end
% end

sheets_list = {'conversion';'head_modelling';'signal_processing';'source_localization'};
for s = 1:4
    sheet_name = char(sheets_list(s));
    panel = findobj(allchild(handles.tabs),'Tag',sheet_name);
    new_param = flip(get(findobj(allchild(panel),'Style','Edit'),'String'));
    new_param = cellfun(@char,new_param,'UniformOutput',0);
    new_data = table(new_param);
    writetable(new_data,handles.parameters_filename,'Sheet',s,'Range','B2','WriteVariableNames',false);
%     new_data = table([handles.(sheet_name).xls_names, new_param, handles.(sheet_name).xls_data(:,2)]);
%     writetable(new_data,handles.input_filename,'Sheet',sheet_name,'Range','A2','WriteVariableNames',false);
end
% handles.parameters_data = new_data;
% setappdata(handles.gui,'parameters_data',handles.parameters_data);

guidata(gcbo,handles)
uiresume;
end                 % --- end save_file

                    % --- start cancel_edit
function cancel_edit(hObject, eventdata, handles)
uiresume;
end                 % --- end cancel_edit

%{
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
%}


%%
%{
f=figure;

p=uix.ScrollingPanel('Parent',f);
    
    filename = '/Users/u0114283/Documents/NET_v2.24/gui/Book1.xlsx';
    [~,~,xlsdata] = xlsread(filename);
   uitable('Parent',p,'Data',xlsdata); 
   
   set(p,'Units','Normalized',...
    'Heights',500,... % heights of contents, in pixels and/or weights
        'MinimumHeights',50,... % minimum heights of contents, in pixels
        'VerticalOffsets',10,... % vertical offsets of contents, in pixels
        'VerticalSteps',30,... % vertical slider steps, in pixels
        'Widths',300,... % widths of contents, in pixels and/or weights
        'MinimumWidths',30,... % minimum widths of contents, in pixels
        'HorizontalOffsets',10,... % horizontal offsets of contents, in pixels
        'HorizontalSteps',30,... % horizontal slider steps, in pixels
        'MouseWheelEnabled','on');
%}