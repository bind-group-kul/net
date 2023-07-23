function varargout = process_extract_cluster( varargin )
% PROCESS_EXTRACT_CLUSTER: Extract scouts/clusters values.

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
% Authors: Francois Tadel, 2010-2014

macro_methodcall;
end


%% ===== GET DESCRIPTION =====
function sProcess = GetDescription() %#ok<DEFNU>
    % Description the process
    sProcess.Comment     = 'Clusters time series';
    sProcess.FileTag     = '| cluster';
    sProcess.Category    = 'Custom';
    sProcess.SubGroup    = 'Extract';
    sProcess.Index       = 351;
    % Definition of the input accepted by this process
    sProcess.InputTypes  = {'data', 'results',  'timefreq'};
    sProcess.OutputTypes = {'matrix', 'matrix', 'matrix'};
    sProcess.nInputs     = 1;
    sProcess.nMinFiles   = 1;
    
    % === TIME WINDOW
    sProcess.options.timewindow.Comment = 'Time window:';
    sProcess.options.timewindow.Type    = 'timewindow';
    sProcess.options.timewindow.Value   = [];
    % === CLUSTERS
    sProcess.options.clusters.Comment = '';
    sProcess.options.clusters.Type    = 'cluster';
    sProcess.options.clusters.Value   = [];
    % === NORM XYZ
    sProcess.options.isnorm.Comment = 'Unconstrained sources: Norm of the three orientations (x,y,z)';
    sProcess.options.isnorm.Type    = 'checkbox';
    sProcess.options.isnorm.Value   = 0;
    % === CONCATENATE
    sProcess.options.concatenate.Comment = 'Concatenate output in one unique matrix';
    sProcess.options.concatenate.Type    = 'checkbox';
    sProcess.options.concatenate.Value   = 1;
    % === SAVE OUTPUT
    sProcess.options.save.Comment = '';
    sProcess.options.save.Type    = 'ignore';
    sProcess.options.save.Value   = 1;
    % === USE ROW NAME
    sProcess.options.userowname.Comment = '';
    sProcess.options.userowname.Type    = 'ignore';
    sProcess.options.userowname.Value   = [];
end


%% ===== FORMAT COMMENT =====
function Comment = FormatComment(sProcess)
    % Get type of data
    DataType = gui_brainstorm('GetProcessFileType', 'Process1');
    % Get name of the cluster (cluster or scout)
    switch (DataType)
        case 'data',      clusterType = 'clusters';
    	case 'results',   clusterType = 'scouts';
        case 'timefreq',  clusterType = 'scouts';
    end
    Comment = ['Extract ' clusterType ' time series:'];
    % Get selected clusters
    sClusters = sProcess.options.clusters.Value;
    % Format comment
    if isempty(sClusters)
        Comment = [Comment, '[no selection]'];
    elseif (length(sClusters) > 15)
        Comment = [Comment, sprintf('[%d %s]', length(sClusters), clusterType)];
    else
        for i = 1:length(sClusters)
            Comment = [Comment, ' ', sClusters(i).Label];
        end
    end
end


%% ===== RUN =====
function OutputFiles = Run(sProcess, sInputs) %#ok<DEFNU>
    % Concatenate values ?
    isConcatenate = sProcess.options.concatenate.Value && (length(sInputs) > 1);
    isSave = sProcess.options.save.Value;
    isNorm = sProcess.options.isnorm.Value;
    % If a time window was specified
    if isfield(sProcess.options, 'timewindow') && ~isempty(sProcess.options.timewindow) && ~isempty(sProcess.options.timewindow.Value) && iscell(sProcess.options.timewindow.Value)
        TimeWindow = sProcess.options.timewindow.Value{1};
    else
        TimeWindow = [];
    end
    OutputFiles = {};
    % Get clusters
    sClusters = sProcess.options.clusters.Value;
    if isempty(sClusters)
        bst_report('Error', sProcess, [], 'No cluster/scout selected.');
        return;
    end
    ProtocolInfo = bst_get('ProtocolInfo');
    % Use rown names by default
    if isfield(sProcess.options, 'userowname') && ~isempty(sProcess.options.userowname) && (length(sProcess.options.userowname.Value) == length(sClusters))
        UseRowName = sProcess.options.userowname.Value;
    else
        UseRowName = ones(size(sClusters));
    end
    % Unconstrained function
    if isNorm
        XyzFunction = 'norm';
    else
        XyzFunction = 'none';
    end
    
    % ===== LOOP ON THE FILES =====
    for iInput = 1:length(sInputs)
        ScoutOrient = [];
        SurfOrient = [];
        ZScore = [];
        % === READ FILES ===
        switch (sInputs(iInput).FileType)
            case 'data'
                clustType = 'clusters';
                % Load recordings
                sMat = in_bst_data(sInputs(iInput).FileName);
                matValues = sMat.F;
                % Input filename
                condComment = sInputs(iInput).FileName;
                % Check for channel file
                if isempty(sInputs(iInput).ChannelFile)
                    bst_report('Error', sProcess, sInputs(iInput), 'This process requires a channel file.');
                    continue;
                end
                % Get channel file
                ChannelMat = in_bst_channel(sInputs(iInput).ChannelFile);
                nComponents = 1;
                
            case 'results'
                clustType = 'scouts';
                % Load results
                sMat = in_bst_results(sInputs(iInput).FileName, 0);
                nComponents = sMat.nComponents;
                % Error: cannot process atlas-based files
                if isfield(sMat, 'Atlas') && ~isempty(sMat.Atlas)
                    bst_report('Error', sProcess, sInputs(iInput), 'File is already based on an atlas.');
                    continue;
                end
                % Get surface vertex normals
                if ~isempty(sMat.SurfaceFile)
                    sSurf = in_tess_bst(sMat.SurfaceFile);
                    SurfOrient = sSurf.VertNormals;
                end
                % FULL RESULTS
                if isfield(sMat, 'ImageGridAmp') && ~isempty(sMat.ImageGridAmp)
                    sResults = sMat;
                    matValues = sMat.ImageGridAmp;
                % KERNEL ONLY
                elseif isfield(sMat, 'ImagingKernel') && ~isempty(sMat.ImagingKernel)
                    sResults = sMat;
                    sMat = in_bst_data(sResults.DataFile);
                    matValues = [];
                end
                % Get ZScore parameter
                if isfield(sResults, 'ZScore') && ~isempty(sResults.ZScore)
                    ZScore = sResults.ZScore;
                end
                % Input filename
                if isequal(sInputs(iInput).FileName(1:4), 'link')
                    % Get data filename
                    [KernelFile, DataFile] = file_resolve_link(sInputs(iInput).FileName);
                    DataFile = strrep(DataFile, ProtocolInfo.STUDIES, '');
                    DataFile = file_win2unix(DataFile(2:end));
                    condComment = [DataFile '/' sInputs(iInput).Comment];
                else
                    condComment = sInputs(iInput).FileName;
                end
            case 'timefreq'
                clustType = 'scouts';
                % Load file
                sMat = in_bst_timefreq(sInputs(iInput).FileName, 0);
                if ~strcmpi(sMat.DataType, 'results')
                    bst_report('Error', sProcess, sInputs(iInput), 'This file does not contain any valid cortical maps.');
                    continue;
                end
                matValues = sMat.TF;
                nComponents = 1;
                % Error: cannot process atlas-based files
                if isfield(sMat, 'Atlas') && ~isempty(sMat.Atlas)
                    bst_report('Error', sProcess, sInputs(iInput), 'File is already based on an atlas.');
                    continue;
                end
                % Get ZScore parameter
                if isfield(sMat, 'ZScore') && ~isempty(sMat.ZScore)
                    ZScore = sMat.ZScore;
                end
                % Input filename
                condComment = sInputs(iInput).FileName;
               
            otherwise
                bst_report('Error', sProcess, sInputs(iInput), 'Unsupported file type.');
                continue;
        end
        % Add possibly missing fields
        if ~isfield(sMat, 'ChannelFlag')
            sMat.ChannelFlag = [];
        end
        if ~isfield(sMat, 'History')
            sMat.History = {};
        end
        % Replicate if no time
        if (size(matValues,2) == 1)
            matValues = cat(2, matValues, matValues);
        end
        if (length(sMat.Time) == 1)
            sMat.Time = [0,1];
        end
        
        % === TIME ===
        % Check time vectors
        if (iInput == 1)
            initTimeVector = sMat.Time;
        elseif (length(initTimeVector) ~= length(sMat.Time)) && isConcatenate
            bst_report('Error', sProcess, sInputs(iInput), 'Time definition should be the same for all the files.');
            continue;
        end
        % Option: Time window
        if ~isempty(TimeWindow)
            % Get time indices
            if (length(sMat.Time) <= 2)
                iTime = 1:length(sMat.Time);
            else
                iTime = panel_time('GetTimeIndices', sMat.Time, TimeWindow);
                if isempty(iTime)
                    bst_report('Error', sProcess, sInputs(iInput), 'Invalid time window option.');
                    continue;
                end
            end
            % Keep only the requested time window
            if ~isempty(matValues)
                matValues = matValues(:,iTime,:);
            else
                sMat.F = sMat.F(:,iTime);
            end
            sMat.Time = sMat.Time(iTime);
        end
        
        % === LOOP ON CLUSTERS ===
        scoutValues  = [];
        Description  = {};
        clustComment = [];
        for iClust = 1:length(sClusters)
            % === GET ROWS INDICES ===
            switch (sInputs(iInput).FileType)
                case 'data'
                    iRows = panel_cluster('GetChannelsInCluster', sClusters(iClust), ChannelMat.Channel, sMat.ChannelFlag);
                case {'results', 'timefreq'}
                    % Get the scout vertices
                    iRows = sClusters(iClust).Vertices;
                    % Get the scout orientation
                    if ~isempty(SurfOrient)
                        ScoutOrient = SurfOrient(iRows,:);
                    end
                    % Indices to read: depend on the number of components at each vertex
                    switch (nComponents)
                        case 2
                            iRows = sort([2*iRows-1, 2*iRows-1]);
                        case 3
                            iRows = sort([3*iRows-2, 3*iRows-1, 3*iRows]);
                    end
            end
            % Get row names
            if strcmpi(sClusters(iClust).Function, 'All') && UseRowName(iClust) 
                if isfield(sClusters(iClust), 'Sensors')
                    RowNames = sClusters(iClust).Sensors;
                else
                    RowNames = cellfun(@num2str, num2cell(sClusters(iClust).Vertices), 'UniformOutput', 0);
                end
            else
                RowNames = [];
            end
            
            % === GET SOURCES ===
            % Get all the sources values
            if ~isempty(matValues)
                sourceValues = matValues(iRows,:,:);
            else
                sourceValues = sResults.ImagingKernel(iRows,:) * sMat.F(sResults.GoodChannel,:);
            end
            
            % === APPLY DYNAMIC ZSCORE ===
            if ~isempty(ZScore)
                ZScoreScout = ZScore;
                % Keep only the selected vertices
                if ~isempty(iRows) && ~isempty(ZScoreScout.mean)
                    ZScoreScout.mean = ZScoreScout.mean(iRows,:);
                    ZScoreScout.std  = ZScoreScout.std(iRows,:);
                end
                % Calculate mean/std
                if isempty(ZScoreScout.mean)
                    sourceValues = process_zscore_dynamic('Compute', sourceValues, ZScoreScout, sMat.Time, sResults.ImagingKernel(iRows,:), sMat.F(sResults.GoodChannel,:));
                % Apply existing mean/std
                else
                    sourceValues = process_zscore_dynamic('Compute', sourceValues, ZScoreScout);
                end
            end
            
            % === COMPUTE CLUSTER VALUES ===
            % Are we supposed to flip the sign of the vertices with different orientations
            isFlipSign = (nComponents == 1) && ...
                         strcmpi(sInputs(iInput).FileType, 'results') && ...
                         isempty(strfind(sInputs(iInput).FileName, '_abs_zscore'));
            % Save the name of the scout/cluster
            clustComment = [clustComment, ' ', sClusters(iClust).Label];
            % Loop on frequencies
            nFreq = size(sourceValues,3);
            for iFreq = 1:nFreq
                % Apply scout function
                tmpScout = bst_scout_value(sourceValues(:,:,iFreq), sClusters(iClust).Function, ScoutOrient, nComponents, XyzFunction, isFlipSign);
                % Add frequency
                if (nFreq > 1)
                % Get frequency comments
                    if iscell(sMat.Freqs)
                        freqComment = [' ' sMat.Freqs{iFreq,1}];
                    else
                        freqComment = [' ' num2str(sMat.Freqs(iFreq)), 'Hz'];
                    end
                else
                    freqComment = '';
                end
                % If there is only one component
                if (nComponents == 1) || strcmpi(XyzFunction, 'norm')
                    scoutValues = cat(1, scoutValues, tmpScout);
                    % Multiple rows for the same cluster (Function 'All')
                    if ~isempty(RowNames)
                        for iRow = 1:size(tmpScout,1)
                            Description = cat(1, Description, [sClusters(iClust).Label '.' RowNames{iRow} ' @ ' condComment freqComment]);
                        end
                    % One ouput row per cluster
                    else
                        scoutDesc   = repmat({[sClusters(iClust).Label, ' @ ', condComment freqComment]}, size(tmpScout,1), 1);
                        Description = cat(1, Description, scoutDesc{:});
                    end        
                else
                    scoutValues = cat(1, scoutValues, tmpScout);
                    for iRow = 1:(size(tmpScout,1) / nComponents) 
                        for iComp = 1:nComponents
                            if ~isempty(RowNames)
                                Description = cat(1, Description, [sClusters(iClust).Label '.' RowNames{iRow} '.' num2str(iComp) ' @ ' condComment freqComment]);
                            else
                                Description = cat(1, Description, [sClusters(iClust).Label '.' num2str(iComp) ' @ ' condComment freqComment]);
                            end
                        end
                    end
                end
            end
        end
        
        % === OUTPUT STRUCTURE ===
        if (iInput == 1)
            % Create structure
            newMat = db_template('matrixmat');
            newMat.Value       = [];
            newMat.ChannelFlag = ones(size(sMat.ChannelFlag));
        end
        newMat.Time = sMat.Time;
        newMat.nAvg = 1;
        % Concatenate new values to existing ones
        if isConcatenate
            newMat.Value       = cat(1, newMat.Value,       scoutValues);
            newMat.Description = cat(1, newMat.Description, Description);
            newMat.ChannelFlag(sMat.ChannelFlag == -1) = -1;
        else
            newMat.Value       = scoutValues;
            newMat.Description = Description;
            newMat.ChannelFlag = sMat.ChannelFlag;
        end

        % === HISTORY ===
        if ~isConcatenate || (iInput == 1)
            % Re-use the history of the initial file
            newMat.History = sMat.History;
            % History: process name
            newMat = bst_history('add', newMat, 'process', FormatComment(sProcess));
        end
        % History: File name
        newMat = bst_history('add', newMat, 'process', [' - File: ' sInputs(iInput).FileName]);

        % === SAVE FILE ===
        % One file per input: save one matrix file per input file
        if ~isConcatenate
            % Comment: forced in the options
            if isfield(sProcess.options, 'Comment') && isfield(sProcess.options.Comment, 'Value') && ~isempty(sProcess.options.Comment.Value)
                newMat.Comment = sProcess.options.Comment.Value;
            % Comment: Process default (limit size of cluster comment)
            elseif (length(sClusters) > 1) && (length(clustComment) > 20)
                newMat.Comment = [sMat.Comment, ' | ' num2str(length(sClusters)) ' ' clustType];
            else
                newMat.Comment = [sMat.Comment, ' | ' clustType ' (' clustComment(2:end) ')'];
            end
            % Save new file in database
            if isSave
                % Output study = input study
                [sStudy, iStudy] = bst_get('Study', sInputs(iInput).iStudy);
                % Output filename
                OutFile = bst_process('GetNewFilename', bst_fileparts(sStudy.FileName), ['matrix_' clustType(1:end-1)]);
                % Save on disk
                bst_save(OutFile, newMat, 'v6');
                % Register in database
                db_add_data(iStudy, OutFile, newMat);
                % Out to list of output files
                OutputFiles{end+1} = OutFile;
            % Just return scout values
            else
                % Add nComponents to indicate how many components per vertex
                if (nComponents == 1) || strcmpi(XyzFunction, 'norm')
                    newMat.nComponents = 1;
                else
                    newMat.nComponents = nComponents;
                end
                % Return structure
                if isempty(OutputFiles)
                    OutputFiles = newMat;
                else
                    OutputFiles(end+1) = newMat;
                end
            end
        end
    end
    
    % === SAVE FILE ===
    % Only one concatenated output matrix
    if isConcatenate
        % Get output study
        [sStudy, iStudy, Comment] = bst_process('GetOutputStudy', sProcess, sInputs);
        % Comment: forced in the options
        if isfield(sProcess.options, 'Comment') && isfield(sProcess.options.Comment, 'Value') && ~isempty(sProcess.options.Comment.Value)
            newMat.Comment = sProcess.options.Comment.Value;
        % Comment: Process default
        else
            newMat.Comment = [strrep(FormatComment(sProcess), ' time series', ''), ' (' Comment ')'];
        end
        % Save new file in database
        if isSave
            % Output filename
            OutputFiles{1} = bst_process('GetNewFilename', bst_fileparts(sStudy.FileName), ['matrix_' clustType(1:end-1)]);
            % Save on disk
            bst_save(OutputFiles{1}, newMat, 'v6');
            % Register in database
            db_add_data(iStudy, OutputFiles{1}, newMat);
        % Just return scout values
        else
            OutputFiles = newMat;
        end
    end
end




