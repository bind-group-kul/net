function varargout = process_stdrow( varargin )
% PROCESS_STDROW: Uniformize the list of rows for a set of time-frequency files.

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
% Authors: Francois Tadel, 2013

macro_methodcall;
end


%% ===== GET DESCRIPTION =====
function sProcess = GetDescription() %#ok<DEFNU>
    % Description the process
    sProcess.Comment     = 'Uniform row names';
    sProcess.FileTag     = '| stdrow';
    sProcess.Category    = 'Custom';
    sProcess.SubGroup    = 'Standardize';
    sProcess.Index       = 301;
    % Definition of the input accepted by this process
    sProcess.InputTypes  = {'timefreq', 'matrix'};
    sProcess.OutputTypes = {'timefreq', 'matrix'};
    sProcess.nInputs     = 1;
    sProcess.nMinFiles   = 2;
    % Definition of the options
    % === TARGET LIST OF ROW NAMES
    sProcess.options.method.Comment = {'<HTML>Keep only the common row names<BR>=> Remove all the others', ...
                                       '<HTML>Keep all the row names<BR>=> Fill the missing rows with zeros', ...
                                       '<HTML>Use the first file in the list as a template'};
    sProcess.options.method.Type    = 'radio';
    sProcess.options.method.Value   = 1;
    % === OVERWRITE
    sProcess.options.overwrite.Comment = 'Overwrite input files';
    sProcess.options.overwrite.Type    = 'checkbox';
    sProcess.options.overwrite.Value   = 1;
end


%% ===== FORMAT COMMENT =====
function Comment = FormatComment(sProcess) %#ok<DEFNU>
    switch (sProcess.options.method.Value) 
        case 1,    Comment = [sProcess.Comment, ' (remove extra)'];
        case 2,    Comment = [sProcess.Comment, ' (add missing)'];
        case 3,    Comment = [sProcess.Comment, ' (use first)'];
    end
end


%% ===== RUN =====
function OutputFiles = Run(sProcess, sInputs) %#ok<DEFNU>
    % Options
    Method = sProcess.options.method.Value;
    isOverwrite = sProcess.options.overwrite.Value;
    OutputFiles = {};
    
    % ===== ANALYZE DATABASE =====
    AllRowNames   = cell(1,length(sInputs));
    nRows         = zeros(1,length(sInputs));
    isEqualRows   = zeros(1,length(sInputs));
    unionRowNames = {};
    interRowNames = {};
    % Check all the input files
    for iInput = 1:length(sInputs)
        % Cannot process connectivity files
        if ~isempty(strfind(sInputs(iInput).FileName, '_connectn'))
            bst_report('Error', sProcess, sInputs(iInput), 'Cannot process connectivity results.');
            return;
        end
        % Load row names
        switch lower(sInputs(iInput).FileType)
            case 'timefreq'
                fileMat = in_bst_timefreq(sInputs(iInput).FileName, 0, 'RowNames', 'DataType');
                % Check file type: Cannot process source files
                if strcmpi(fileMat.DataType, 'results') || ~iscell(fileMat.RowNames)
                    bst_report('Error', sProcess, sInputs(iInput), 'Cannot process source maps, or any file that does not have explicit row names.');
                    return;
                end
                % Add row names to the list
                AllRowNames{iInput} = fileMat.RowNames;
            case 'matrix'
                fileMat = in_bst_matrix(sInputs(iInput).FileName, 'Description');
                % Check file type
                if (size(fileMat.Description,2) > 1)
                    bst_report('Error', sProcess, sInputs(iInput), 'Cannot process a matrix file in which the "Description" fields has more than one column.');
                    return;
                end
                % Add row names to the list
                AllRowNames{iInput} = fileMat.Description;
        end
        % Keep track of row numbers
        nRows(iInput) = length(AllRowNames{iInput});
        % If list is the same as previous
        if isempty(isEqualRows)
            isEqualRows = 1;
        else
            isEqualRows(iInput) = isequal(AllRowNames{iInput}, AllRowNames{1});
        end
        % Union of all the row names
        unionRowNames = union(unionRowNames, AllRowNames{iInput});
        % Intersection of all the row names
        if isempty(interRowNames)
            interRowNames = AllRowNames{iInput};
        else
            interRowNames = intersect(interRowNames, AllRowNames{iInput});
        end
    end
    % Check if there any difference in the row names
    if all(isEqualRows)
        bst_report('Error', sProcess, sInputs, 'All the input files have identical row names.');
        return;
    end
    % Check if there are rowns left
    if isempty(interRowNames) && (Method == 1)
        bst_report('Error', sProcess, sInputs, 'No common row names in those data sets.');
        return;
    end
    

    %% ===== COMMON ROW LIST =====
    % Get the row list that has the more/less rows
    switch (Method)
        % Only common rows
        case 1   
            % Get the minimum number of rows
            [tmp, iRef] = min(nRows);
            % Get rows
            DestRowNames = AllRowNames{iRef};
            % Remove unecessary rows
            iRemove = find(~ismember(DestRowNames, interRowNames));
            if ~isempty(iRemove)
                DestRowNames(iRemove) = [];
            end
        % All rows
        case 2   
            % Get the maximum number of rows
            [tmp, iRef] = max(nRows);
            % Get rows
            DestRowNames = AllRowNames{iRef};
            % Add all the other rows
            iAdd = find(~ismember(unionRowNames, DestRowNames));
            if ~isempty(iAdd)
                DestRowNames = [DestRowNames; unionRowNames{iAdd}];
            end
        % First file
        case 3   
            DestRowNames = AllRowNames{1};
    end

    
    %% ===== PROCESS FILES =====
    % Process each input file
    for iInput = 1:length(sInputs)
        % If it's a file that was not changed: skip to next file
        if isequal(DestRowNames, AllRowNames{iInput})
            OutputFiles{iInput} = file_fullpath(sInputs(iInput).FileName);
            continue;
        end
        % Create list of orders for rows
        iRowSrc = [];
        iRowDest = [];
        for iChan = 1:length(DestRowNames)
            iTmp = find(strcmpi(DestRowNames{iChan}, AllRowNames{iInput}));
            iTmp = setdiff(iTmp, iRowSrc);
            if (length(iTmp) > 1)
                if (length(iTmp) > 1)
                    bst_report('Warning', sProcess, sInputs, 'Several rows with the same name, re-ordering might be inaccurate.');
                    iTmp = iTmp(1);
                end
            end
            if ~isempty(iTmp)
                iRowDest(end+1) = iChan;
                iRowSrc(end+1)  = iTmp;
            end
        end
        
        % List of added rows
        iAddedChan = setdiff(1:length(DestRowNames), iRowDest);
        iRemChan   = setdiff(1:length(AllRowNames{iInput}), iRowSrc);
        % Add a history entry
        strHistory = 'Uniform list of rows:';
        if ~isempty(iAddedChan)
            strTmp = '';
            for i = 1:length(iAddedChan)
                strTmp = [strTmp, DestRowNames{iAddedChan(i)}, ','];
            end
            strHistory = [strHistory, sprintf(' %d added (%s)', length(iAddedChan), strTmp(1:end-1))];
        end
        if ~isempty(iRemChan)
            strTmp = '';
            for i = 1:length(iRemChan)
                strTmp = [strTmp, AllRowNames{iInput}{iRemChan(i)}, ','];
            end
            strHistory = [strHistory, sprintf(' %d removed (%s)', length(iRemChan), strTmp(1:end-1))];
        end
        
        % Load the data file
        fileMat = load(file_fullpath(sInputs(iInput).FileName));
        newFileMat = fileMat;
        % Saved structure depends on the file type
        switch lower(sInputs(iInput).FileType)
            case 'timefreq'
                newFileMat.TF = zeros(length(DestRowNames), size(fileMat.TF,2), size(fileMat.TF,3));
                newFileMat.TF(iRowDest,:) = fileMat.TF(iRowSrc,:);
                newFileMat.RowNames = DestRowNames;
            case 'matrix'
                newFileMat.Value = zeros(length(DestRowNames), size(fileMat.Value,2));
                newFileMat.Value(iRowDest,:) = fileMat.Value(iRowSrc,:);
                newFileMat.Description = DestRowNames;
        end
        % Add comment
        newFileMat.Comment = [newFileMat.Comment ' ' sProcess.FileTag];
        % Add a history entry
        newFileMat = bst_history('add', newFileMat, 'stdrow', strHistory);
        
        % Overwrite the input file
        if isOverwrite
            OutputFiles{iInput} = file_fullpath(sInputs(iInput).FileName);
            bst_save(OutputFiles{iInput}, newFileMat, 'v6');
        % Create a new file
        else
            % Output filename: add file tag
            FileTag = strtrim(strrep(sProcess.FileTag, '|', ''));
            OutputFiles{iInput} = strrep(file_fullpath(sInputs(iInput).FileName), '.mat', ['_' FileTag '.mat']);
            OutputFiles{iInput} = file_unique(OutputFiles{iInput});
            % Save file
            bst_save(OutputFiles{iInput}, newFileMat, 'v6');
            % Add file to database structure
            db_add_data(sInputs(iInput).iStudy, OutputFiles{iInput}, newFileMat);
        end
    end
end



