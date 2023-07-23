function varargout = process_average_rows( varargin )
% PROCESS_AVERAGE_ROWS: For each file in input, compute the average of the different frequency bands.

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
    sProcess.Comment     = 'Average rows';
    sProcess.FileTag     = '| avgrows';
    sProcess.Category    = 'File';
    sProcess.SubGroup    = 'Average';
    sProcess.Index       = 305;
    % Definition of the input accepted by this process
    sProcess.InputTypes  = {'timefreq', 'matrix'};
    sProcess.OutputTypes = {'timefreq', 'matrix'};
    sProcess.nInputs     = 1;
    sProcess.nMinFiles   = 1;
    % === AVERAGE TYPE
    sProcess.options.avgtype.Comment = {'Average all the rows together', 'Average the rows with identical name', 'Average by scout name'};
    sProcess.options.avgtype.Type    = 'radio';
    sProcess.options.avgtype.Value   = 1;
    % === OVERWRITE
    sProcess.options.overwrite.Comment = 'Overwrite input files';
    sProcess.options.overwrite.Type    = 'checkbox';
    sProcess.options.overwrite.Value   = 1;
end


%% ===== FORMAT COMMENT =====
function Comment = FormatComment(sProcess) %#ok<DEFNU>
    Comment = sProcess.Comment;
end


%% ===== RUN =====
function OutputFile = Run(sProcess, sInput) %#ok<DEFNU>
    OutputFile = {};
    % Get options
    switch (sProcess.options.avgtype.Value)
        case 1,  AvgType = 'all';
        case 2,  AvgType = 'name';
        case 3,  AvgType = 'scout';
    end
    isOverwrite = sProcess.options.overwrite.Value;
    % File type
    switch (sInput.FileType)
        case 'timefreq'
            % Load TF file
            FileMat = in_bst_timefreq(sInput.FileName, 0);
            % Check for measure
            if strcmpi(FileMat.Measure, 'none')
                bst_report('Error', sProcess, sInput, 'Cannot average complex values. Please apply a measure to the values before calling this function.');
                return;
            end
            % Remove the rows information if averaging the rows together
            if strcmpi(AvgType, 'all')
                FileMat.RowNames = repmat({'AvgRow'}, size(FileMat.RowNames));
            elseif strcmpi(AvgType, 'scout')
                for iRow = 1:length(FileMat.RowNames)
                    % Format: "scoutname @ filename" (extracting the same scout from multiple files)
                    iAt = find(FileMat.RowNames{iRow}=='@', 1);
                    if ~isempty(iAt) && (iAt > 1)
                        FileMat.RowNames{iRow} = strtrim(FileMat.RowNames{iRow}(1:iAt-1));
                    % Format: "scoutname.ivertex" (extracting the same scout from multiple files)
                    else
                        iDot = find(FileMat.RowNames{iRow}=='.', 1, 'last');
                        if ~isempty(iDot) && (iDot > 1) && (iDot < length(FileMat.RowNames{iRow})) && ~isnan(str2double(FileMat.RowNames{iRow}(iDot+1:end)))
                            FileMat.RowNames{iRow} = strtrim(FileMat.RowNames{iRow}(1:iDot-1));
                        end
                    end
                end
            end
            % Unique row names
            uniqueRowNames = unique(FileMat.RowNames);
            newTF = zeros(length(uniqueRowNames), size(FileMat.TF,2), size(FileMat.TF,3));
            % Loop on the row names
            for iUnique = 1:length(uniqueRowNames)
                iRows = find(strcmp(FileMat.RowNames, uniqueRowNames{iUnique}));
                newTF(iUnique,:,:) = mean(FileMat.TF(iRows,:,:), 1);
            end
            % Save changes
            FileMat.TF = newTF;
            FileMat.RowNames = uniqueRowNames;

        case 'matrix'
            % Load TF file
            FileMat = in_bst_matrix(sInput.FileName);
            % Remove the rows information if averaging the rows together
            if strcmpi(AvgType, 'all')
                FileMat.Description = repmat({'AvgRow'}, size(FileMat.Description));
            elseif strcmpi(AvgType, 'scout')
                for iRow = 1:length(FileMat.Description)
                    iAt = find(FileMat.Description{iRow}=='@', 1);
                    if ~isempty(iAt) && (iAt > 1)
                        FileMat.Description{iRow} = strtrim(FileMat.Description{iRow}(1:iAt-1));
                    end
                end
            end
            % Unique row names
            uniqueRowNames = unique(FileMat.Description);
            newValue = zeros(length(uniqueRowNames), size(FileMat.Value,2), size(FileMat.Value,3));
            % Loop on the row names
            for iUnique = 1:length(uniqueRowNames)
                iRows = find(strcmp(FileMat.Description, uniqueRowNames{iUnique}));
                newValue(iUnique,:,:) = mean(FileMat.Value(iRows,:,:), 1);
            end
            % Save changes
            FileMat.Value = newValue;
            FileMat.Description = uniqueRowNames;
    end
    % Add history entry
    switch (AvgType)
        case 'all',   FileMat = bst_history('add', FileMat, 'avgfreq', 'Average all the rows.');
        case 'name',  FileMat = bst_history('add', FileMat, 'avgfreq', 'Average rows by name.');
    end
    % Add file tag
    FileMat.Comment = [FileMat.Comment, ' ', sProcess.FileTag];
    % Overwrite the input file
    if isOverwrite
        OutputFile = file_fullpath(sInput.FileName);
        bst_save(OutputFile, FileMat, 'v6');
    % Create a new file
    else
        % Output filename: add file tag
        FileTag = strtrim(strrep(sProcess.FileTag, '|', ''));
        OutputFile = strrep(file_fullpath(sInput.FileName), '.mat', ['_' FileTag '.mat']);
        OutputFile = file_unique(OutputFile);
        % Save file
        bst_save(OutputFile, FileMat, 'v6');
        % Add file to database structure
        db_add_data(sInput.iStudy, OutputFile, FileMat);
    end
end




