function tree_set_channelflag(bstNodes, action)
% TREE_SET_CHANNELFLAG: Updates ChannelFlag for all the data files.
%
% USAGE:  tree_set_channelflag(bstNodes, 'AddBad')      : Add bad channels for all the data files
%         tree_set_channelflag(bstNodes, 'DetectFlat')  : Detect bad channels (values are all zeros)
%         tree_set_channelflag(bstNodes, 'ClearBad')    : Set some the channels as good for all the data files
%         tree_set_channelflag(bstNodes, 'ClearAllBad') : Set all the channels as good for all the data files
%         tree_set_channelflag(bstNodes, 'ShowBad')     : Display all the bad channels (as text)

% @=============================================================================
% This software is part of the Brainstorm software:
% http://neuroimage.usc.edu/brainstorm
% 
% Copyright (c)2000-2014 University of Southern California & McGill University
% This software is distributed under the terms of the GNU General Public License
% as published by the Free Software Foundation. Further details on the GPL
% license can be found at http://www.gnu.org/copyleft/gpl.html.
% 
% FOR RESEARCH PURPOSES ONLY. THE SOFTWARE IS PROVIDED "AS IS," AND THE
% UNIVERSITY OF SOUTHERN CALIFORNIA AND ITS COLLABORATORS DO NOT MAKE ANY
% WARRANTY, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO WARRANTIES OF
% MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE, NOR DO THEY ASSUME ANY
% LIABILITY OR RESPONSIBILITY FOR THE USE OF THIS SOFTWARE.
%
% For more information type "brainstorm license" at command prompt.
% =============================================================================@
%
% Authors: Francois Tadel, 2008-2012

% Parse inputs
if (nargin < 2)
    error('Usage:  tree_set_channelflag(bstNodes, action);');
end

% If processing results
nodeType = char(bstNodes(1).getType());
isResults = ismember(nodeType, {'results', 'link'});
isStat    = ismember(nodeType, {'pdata'});
if isResults
    iStudies = [];
    iResults = [];
    for i = 1:length(bstNodes)
        % Get results filename
        ResultsFile = file_resolve_link(char(bstNodes(i).getFileName()));
        ResultsFile = file_short(ResultsFile);
        % Get results file study and indice
        [sStudy, iStudy, iRes] = bst_get('ResultsFile', ResultsFile);
        if ~isempty(iRes)
            iStudies = [iStudies, iStudy];
            iResults = [iResults, iRes];
        end
    end
elseif isStat
    [iStudies, iStats] = tree_dependencies(bstNodes, 'pdata');
else
    % Get selected data files
    [iStudies, iDatas] = tree_dependencies(bstNodes, 'data');
end

% No files found : return
if isempty(iStudies)
    return;
elseif isequal(iStudies, -10)
    disp('BST> Error in tree_dependencies.');
    return;
end


%% ===== CONFIRMATIONS =====
isDetectFlat = 0;
switch (lower(action))
    case 'clearallbad'
        % Clearing bad channels: need a confirmation
        isConfirmed = java_dialog('confirm', ['WARNING: If you clear all the bad channels flags, all the channels will ' 10 ...
                                              'be considered as GOOD. You will not be able to undo the modifications.' 10 10 ...
                                              'Are you sure you want to mark all the channels as GOOD?'], 'Clear bad channels');
        if ~isConfirmed
            return
        end
    case 'addbad'
        % Setting channels to bad: ask which channels
        strBadChan = java_dialog('input', ['Please enter the channel indices to mark as BAD in ALL the selected ' 10, ...
                                        'recordings files, separated by spaces (example: "15 26 34") :' 10 10], ...
                                        'Set bad channels');
        % User canceled
        if isempty(strBadChan)
            return
        end
        % Try to convert to indices
        iAddBad = str2num(strBadChan);
        if isempty(iAddBad)
            return
        end
        if (any(iAddBad <= 0) || any(round(iAddBad) ~= iAddBad))
            error('Invalid channel indices.');
        end
    case 'clearbad'
        % Setting channels to bad: ask which channels
        strGoodChan = java_dialog('input', ['Please enter the channel indices to mark as GOOD in ALL the selected ' 10, ...
                                        'recordings files, separated by spaces (example: "15 26 34") :' 10 10], ...
                                        'Set good channels');
        % User canceled
        if isempty(strGoodChan)
            return
        end
        % Try to convert to indices
        iAddGood = str2num(strGoodChan);
        if isempty(iAddGood)
            return
        end
        if (any(iAddGood <= 0) || any(round(iAddGood) ~= iAddGood))
            error('Invalid channel indices.');
        end
    case 'detectflat'
        isDetectFlat = 1;
end


%% ===== LOOP ON FILES =====
% Progress bar
bst_progress('start', 'Update ChannelFlag', 'Initialization...', 0, length(iStudies));
strReportTitle = '';
strReport = '';
isFirstError = 1;
% Process all the data files
for i = 1:length(iStudies)
    % Get data file
    iStudy = iStudies(i);
    sStudy = bst_get('Study', iStudy);
    if isStat
        sData = sStudy.Stat(iStats(i));
        isRaw = 0;
    elseif isResults
        sData = sStudy.Result(iResults(i));
        isRaw = 0;
    else
        sData = sStudy.Data(iDatas(i));
        isRaw = strcmpi(sData.DataType, 'raw');
        if isRaw && isDetectFlat
            if isFirstError
                bst_error('This process can only be applied on imported recordings.', ...
                          'Detect flat channels', 0);
                isFirstError = 0;              
            end
            continue;
        end
    end
    DataFile = sData.FileName;
    DataFileFull = file_fullpath(DataFile);
    
    % Progress bar
    bst_progress('inc', 1);
    bst_progress('text', ['Processing: ', DataFile]);
    % Get subject
    sSubject = bst_get('Subject', sStudy.BrainStormSubject);
    % Load data from file (ChannelFlag and/or data)
    if isDetectFlat
        DataMat = in_bst_data(DataFile, 'ChannelFlag', 'F', 'History');
        % Detect bad channels
        iAddBad = find(sum(abs(DataMat.F),2) < 1e-20);
        % Remove F field
        DataMat = rmfield(DataMat, 'F');
    elseif isRaw
        DataMat = in_bst_data(DataFile, 'ChannelFlag', 'F', 'History');
    else
        DataMat = in_bst_data(DataFile, 'ChannelFlag', 'History');
    end
    warning on MATLAB:load:variableNotFound
    
    % Build information string
    strCond = [' - ' sSubject.Name];
    if ~isempty(sStudy.Condition)
        strCond = [strCond '/' sStudy.Condition{1}];
    end
    strCond = [strCond '/' sData.Comment ': '];

    % Find bad channels
    iBad = find(DataMat.ChannelFlag == -1);
    % Add bad channels to string
    if ~isempty(iBad)
        strBad = [strCond sprintf('%d ', iBad)];
    else
        strBad = '';
    end
    
    % Switch
    switch lower(action)
        case {'addbad', 'detectflat'}
            % Check indices
            if (max(iAddBad) > length(DataMat.ChannelFlag))
                bst_error('Invalid channel indices.', 'Set good/bad channels', 0);
                return;
            end
            % Message: first file
            if (i == 1)
                if isDetectFlat
                    strReportTitle = 'Detected bad channels (Subject/Condition/File):';
                else
                    strMsg = ['Added bad channels: ' sprintf('%d ', iAddBad)];
                end
            end
            % If all new bad channels are already marked as bad: nothing to do
            if isempty(iAddBad) || all(ismember(iAddBad, iBad))
                continue;
            end
            % Message: Detected bad channels
            if isDetectFlat
                strReport = [strReport 10 strCond ': ' sprintf('%d ', iAddBad)];
                strMsg = ['Detected bad channels: ' sprintf('%d ', iAddBad)];
            end
            % History: bad channels
            DataMat = bst_history('add', DataMat, 'bad_channels', strMsg);
            % Update ChannelFlag
            DataMat.ChannelFlag(iAddBad) = -1;
            % Update the RAW header
            if isRaw
                DataMat.F.channelflag = DataMat.ChannelFlag;
            end
            % Save file
            bst_save(DataFileFull, DataMat, 'v6', 1);
           
        case 'clearbad'
            % Check indices
            if (max(iAddGood) > length(DataMat.ChannelFlag))
                bst_error('Invalid channel indices.', 'Set good/bad channels', 0);
                return;
            end
            % Message
            if (i == 1)
                strMsg = ['Add good channels: ' sprintf('%d ', iAddGood)];
            end
            % Check all new good channels were already marked as good
            if isempty(iAddGood) || all(~ismember(iAddGood, iBad))
                continue;
            end
            % History: bad channels
            DataMat = bst_history('add', DataMat, 'bad_channels', strMsg);
            % Update ChannelFlag
            DataMat.ChannelFlag(iAddGood) = 1;
            % Update the RAW header
            if isRaw
                DataMat.F.channelflag = DataMat.ChannelFlag;
            end
            % Save file
            bst_save(DataFileFull, DataMat, 'v6', 1);
            
        case 'clearallbad'
            if (i == 1)
                strReportTitle = 'Cleared bad channels (Subject/Condition/File):';
            end
            % Bad channels cleared
            if ~isempty(iBad)
                % Display in message window
                %strReport = [strReport 10 strBad];
                % History: bad channels
                DataMat = bst_history('add', DataMat, 'bad_channels', 'Marked all channels as good');
                % Reset ChannelFlag
                DataMat.ChannelFlag = ones(size(DataMat.ChannelFlag));
                % Update the RAW header
                if isRaw
                    DataMat.F.channelflag = DataMat.ChannelFlag;
                end
                % Save file
                bst_save(DataFileFull, DataMat, 'v6', 1);
            end
            
        case 'showbad'
            if (i == 1)
                strReportTitle = 'List of bad channels (Subject/Condition/File):';
            end
            % Display in message window
            if ~isempty(iBad)
                strReport = [strReport 10 strBad];
            end
    end
    
    % Unload DataSets linked to this this DataFile
    iDSUnload = bst_memory('GetDataSetData', DataFile);
    if ~isempty(iDSUnload)
        bst_memory('UnloadDataSets', iDSUnload);
    end
end
% Hide progress bar
bst_progress('stop');
% Show report
if ~isempty(strReport)
    view_text( [strReportTitle 10 strReport], 'Report' );
end








