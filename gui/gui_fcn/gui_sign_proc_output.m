function gui_sign_proc_output(handles)

k = handles.k;
fontsize = handles.fontsize;
fontname = handles.fontname;

fig_name = 'Signal processing sample outputs';

findwindow = findobj('Tag','fig_visual','-and','Name',fig_name);
if ~isempty(findwindow)
    close(findwindow);
end

fig_output = figure('Units','Normalized','Position',[0.01 0.37 0.25 0.25],...
        'NumberTitle','Off','Name',fig_name,'Tag','fig_visual');
fig_output.set('Menubar','none');

mainbox = uiextras.VBox('Parent',fig_output,'Padding',10*min(k));

    uicontrol('Parent',mainbox,'Style','Text','String','Choose output(s) to visualize:',...
        'FontName',fontname,'FontSize',fontsize);    

    hbox = uiextras.HBox('Parent',mainbox,'Spacing',10*min(k),'Padding',5*min(k));
    
        uiextras.Empty('Parent',hbox);

        box_buttons = uiextras.VBox('Parent',hbox,'Padding',5*min(k));
            uicontrol('Parent',box_buttons,'Style','text','String','Signal time-course + power spectral density (PSD)',...
                'FontName',fontname,'FontSize',fontsize);
            
            D    = spm_eeg_load(handles.processedeeg_filename);
            handles.fs_proc   = fsample(D);
            chanlist = D.chanlabels;
            s = [{'Choose channel';'All EEG'}];
            for m = 1:length(chanlist)
                s = [s; chanlist(m)];
            end
            handles.select_chan = uicontrol('Parent',box_buttons,'Style','popupmenu','String',s,...
                'FontName',fontname,'FontSize',fontsize,'Callback',@show_signal);
            
%             uicontrol('Parent',box_buttons,'Style','text','String','Signal power spectral density (PSD)',...
%                 'FontName',fontname,'FontSize',fontsize);
%             
%             uicontrol('Parent',box_buttons,'Style','pushbutton','String','Plot',...
%                 'FontName',fontname,'FontSize',fontsize,'Callback',@show_psd);
            
        set(box_buttons,'Sizes',[45*k(2) 50*k(2)]) % 40*k(2) 30*k(2)])

        uiextras.Empty('Parent',hbox);
    
    set(hbox,'Sizes',[-1 200*k(2) -1])
set(mainbox,'Sizes',[-1 170*k(2)])
    
guidata(fig_output,handles)
end

%% GUI callback functions

                    % --- start function
function template_function(hObject, eventdata, handles)
handles = guidata(gcbo);

guidata(gcbo,handles)
end                 % --- end function

                    % --- start show_signal
function show_signal(hObject, eventdata, handles)
handles = guidata(gcbo);

    idx_chan = get(handles.select_chan,'Value');
    if idx_chan > 1
        raweeg_filename = handles.raweeg_filename;
        processedeeg_filename = handles.processedeeg_filename;

        idx_dataset = get(handles.menu_visual_dataset,'String');
        idx_dataset = idx_dataset(get(handles.menu_visual_dataset,'Value'));

        label = get(handles.select_chan,'String');
        label = label(get(handles.select_chan,'Value'));
        if strcmpi(label,'All EEG')
            chan_label = 'EEG';
        else
            chan_label = label;
        end

        fig_img = figure('Units','Normalized','Position',[0.34 0.0 0.64 1],...
            'NumberTitle','Off','Name',[char(idx_dataset) ' - Time-courses + PSD - Channel: ' char(label)]);
        fig_img.set('Menubar','figure');
        fig_img.set('Pointer','watch');
        drawnow

        % Raw data
        D    = spm_eeg_load(raweeg_filename);
        list_eeg = selectchannels(D,chan_label);
        fs_raw   = fsample(D);
        
        if not(handles.fs_proc == fs_raw)
            S =[];
            S.D = D;
            S.fsample_new = handles.fs_proc;
            D_ds = spm_eeg_downsample(S);
            data = D_ds(list_eeg,:,:);
            [fpth,fnm] = fileparts(raweeg_filename);
            delete([fpth filesep 'd' fnm '.*'])
        else
            data = D(list_eeg,:,:);
            D_ds = D; % added for compatibility, JS 12.2022
        end
        
        if strcmpi(label,'All EEG')
            chan_idx = D.chanlabels(list_eeg);
        else
            chan_idx = label;
        end

        subplot(2,2,1)
        p = plot((1:length(data))/fsample(D_ds), detrend(data')');
        title('Time-course - Raw data','FontSize',handles.fontsize)
        axis tight, set(gca,'FontSize',0.8*handles.fontsize)
        xlabel('Time (s)','FontSize',handles.fontsize), %xlim([0 80])
        ylabel('EEG signal (uV)','FontSize',handles.fontsize), ylim([min(data(:)) max(data(:))])
        legend(chan_idx);
        legend('hide');
        drawnow

        % NET cleaning
        D    = spm_eeg_load(processedeeg_filename);
        data2 = D(list_eeg,:,:);

        subplot(2,2,2)
        plot((1:length(data))/fsample(D_ds), data2)
        title('Time-course - Cleaned data','FontSize',handles.fontsize)
        axis tight, set(gca,'FontSize',0.8*handles.fontsize)
        xlabel('Time (s)','FontSize',handles.fontsize), %xlim([0 80])
        ylabel('EEG signal (uV)','FontSize',handles.fontsize), ylim([min(data2(:)) max(data2(:))])
        legend(chan_idx);
        legend('hide');
        drawnow

        %% net_plotPSD
        % Raw data
%         D    = spm_eeg_load( raweeg_filename );
%         list_eeg = selectchannels(D,'EEG');
%         data = D(list_eeg,:,:);
%         Fs   = fsample(D);
        ntp  = size(data,2);
        nfft = 1024;
        df   = [1 100];
        Fs = handles.fs_proc;

        subplot(2,2,3)
        performPSD1(detrend(data')',nfft,Fs,@hanning,60,1,df);
        title('PSD - Raw data','FontSize',handles.fontsize)
        set(gca,'FontSize',0.8*handles.fontsize)
        xlim([0 80]), xlabel('Frequency (Hz)','FontSize',handles.fontsize)
        ylim([0 100]), ylabel('PSD (uV^2/Hz)','FontSize',handles.fontsize)
        legend(chan_idx); legend('hide');
        drawnow

        % NET cleaning
%         D    = spm_eeg_load( processedeeg_filename );
%         data2 = D(list_eeg,:,:);

        subplot(2,2,4)
        performPSD1(data2,nfft,Fs,@hanning,60,1,df);
        title('PSD - Cleaned data','FontSize',handles.fontsize)
        set(gca,'FontSize',0.8*handles.fontsize)
        xlim([0 80]), xlabel('Frequency (Hz)','FontSize',handles.fontsize)
        ylim([0 100]), ylabel('PSD (uV^2/Hz)','FontSize',handles.fontsize)
        legend(chan_idx); legend('hide');
        drawnow
        
        dcm = datacursormode(fig_img);
        datacursormode on
        set(dcm,'updatefcn',@update_datacursor)
        
        fig_img.set('Pointer','arrow');

    end

guidata(gcbo,handles)
end                 % --- end show_signal

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
                    

%%                    
%{
                    % --- start show_signal
function show_signal(hObject, eventdata, handles)
handles = guidata(gcbo);

    idx_chan = get(handles.select_chan,'Value');
        if idx_chan > 1
            raweeg_filename = handles.raweeg_filename;
            processedeeg_filename = handles.processedeeg_filename;
            
            idx_dataset = get(handles.menu_visual_dataset,'String');
            idx_dataset = idx_dataset(get(handles.menu_visual_dataset,'Value'));
            
            chan_label = get(handles.select_chan,'String');
            chan_label = chan_label(get(handles.select_chan,'Value'));
            
            fig_img = figure('Units','Normalized',... %'Position',[0.34 0.0 0.64 1],...
                'NumberTitle','Off','Name',['Time-courses - ' char(idx_dataset) ' - Channel ' char(chan_label)]);
            fig_img.set('Menubar','figure');
            fig_img.set('Pointer','watch');
            drawnow
            
            % Raw data
            D    = spm_eeg_load(raweeg_filename);
            list_eeg = selectchannels(D,chan_label);
            data = D(list_eeg,:,:);
            Fs   = fsample(D);
            
            subplot(2,1,1)
            plot(1:length(data),data)
            title('Raw EEG data')
            xlabel('Time'), %xlim([0 80])
            ylabel('EEG signal'), ylim([min(data) max(data)])
            axis tight
            
            % NET cleaning
            D    = spm_eeg_load(processedeeg_filename);
            data2 = D(list_eeg,:,:);
            
            subplot(2,1,2)
            plot(1:length(data2),data2)
            title('Cleaned EEG data')
            xlabel('Time'), %xlim([0 80])
            ylabel('EEG signal'), ylim([min(data2) max(data2)])
            axis tight
            
            fig_img.set('Pointer','arrow');
        end
end                 % --- end show_signal

                    % --- start show_psd
function show_psd(hObject, eventdata, handles)
handles = guidata(gcbo);

raweeg_filename = handles.raweeg_filename;
processedeeg_filename = handles.processedeeg_filename;

idx_dataset = get(handles.menu_visual_dataset,'String');
idx_dataset = idx_dataset(get(handles.menu_visual_dataset,'Value'));

fig_img = figure('Units','Normalized',... %'Position',[0.34 0.0 0.64 1],...
    'NumberTitle','Off','Name',['Power spectral densities - ' char(idx_dataset)]);
fig_img.set('Menubar','figure');
fig_img.set('Pointer','watch');
drawnow

%% net_plotPSD
% Raw data
D    = spm_eeg_load( raweeg_filename );
list_eeg = selectchannels(D,'EEG');
data = D(list_eeg,:,:);
Fs   = fsample(D);
ntp  = size(data,2);
nfft = 1024;
df   = [1 100];

subplot(1,2,1)
performPSD1(data,nfft,Fs,@hanning,60,1,df);
title('Raw EEG data')
xlim([0 80]), xlabel('Frequency')
ylim([0 100]), ylabel('PSD')

% NET cleaning
D    = spm_eeg_load( processedeeg_filename );
data2 = D(list_eeg,:,:);

subplot(1,2,2)
performPSD1(data2,nfft,Fs,@hanning,60,1,df);
title('Cleaned EEG data')
xlim([0 80]), xlabel('Frequency')
ylim([0 100]), ylabel('PSD')

fig_img.set('Pointer','arrow');
end                 % --- end show_psd
%}