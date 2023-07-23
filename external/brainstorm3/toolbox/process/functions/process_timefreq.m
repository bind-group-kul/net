function varargout = process_timefreq( varargin )
% PROCESS_TIMEFREQ: Computes the time frequency decomposition of all the trials, and average them.

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
% Authors: Francois Tadel, 2010-2013

macro_methodcall;
end


%% ===== GET DESCRIPTION =====
function sProcess = GetDescription() %#ok<DEFNU>
    % Description the process
    sProcess.Comment     = 'Time-frequency (Morlet wavelets)';
    sProcess.FileTag     = 'morlet';
    sProcess.Category    = 'Custom';
    sProcess.SubGroup    = 'Frequency';
    sProcess.Index       = 505;
    % Definition of the input accepted by this process
    sProcess.InputTypes  = {'data', 'results', 'matrix'};
    sProcess.OutputTypes = {'timefreq', 'timefreq', 'timefreq'};
    sProcess.nInputs     = 1;
    sProcess.nMinFiles   = 1;
    % Options: CLUSTERS
    sProcess.options.clusters.Comment = '';
    sProcess.options.clusters.Type    = 'cluster_confirm';
    sProcess.options.clusters.Value   = {};
    % Options: Sensor types
    sProcess.options.sensortypes.Comment = 'Sensor types or names (empty=all): ';
    sProcess.options.sensortypes.Type    = 'text';
    sProcess.options.sensortypes.Value   = 'MEG, EEG';
    sProcess.options.sensortypes.InputTypes = {'data'};
%     % Separator
%     sProcess.options.sep.Comment = '  ';
%     sProcess.options.sep.Type    = 'label';
    % Options: Time-freq
    sProcess.options.edit.Comment = {'panel_timefreq_options', 'Morlet wavelet options: '};
    sProcess.options.edit.Type    = 'editpref';
    sProcess.options.edit.Value   = [];
end


%% ===== FORMAT COMMENT =====
function Comment = FormatComment(sProcess) %#ok<DEFNU>
    Comment = sProcess.Comment;
end


%% ===== RUN =====
function OutputFiles = Run(sProcess, sInputs) %#ok<DEFNU>
    % Initialize returned values
    OutputFiles = {};
    % Get editable options (Edit... button)
    if isfield(sProcess.options, 'edit')
        tfOPTIONS = sProcess.options.edit.Value;
        % If user did not edit values: get default values
        if isempty(tfOPTIONS)
            [bstPanelNew, panelName] = panel_timefreq_options('CreatePanel', sProcess, sInputs);
            jPanel = gui_show(bstPanelNew, 'JavaWindow', panelName, 0, 0, 0); 
            drawnow;
            tfOPTIONS = panel_timefreq_options('GetPanelContents');
            gui_hide(panelName);
        end
    % Else: get default options
    else
        tfOPTIONS = bst_timefreq();
        tfOPTIONS.Method = sProcess.FileTag;
        switch tfOPTIONS.Method
            case 'fft',     tfOPTIONS.Comment = 'FFT';
            case 'psd',     tfOPTIONS.Comment = 'PSD';
            case 'morlet',  tfOPTIONS.Comment = 'Wavelet';
            case 'hilbert', tfOPTIONS.Comment = 'Hilbert';
        end
    end
    
    % Add other options
    tfOPTIONS.Method = sProcess.FileTag;
    if isfield(sProcess.options, 'sensortypes')
        tfOPTIONS.SensorTypes = sProcess.options.sensortypes.Value;
    else
        tfOPTIONS.SensorTypes = [];
    end
    if isfield(sProcess.options, 'mirror') && ~isempty(sProcess.options.mirror) && ~isempty(sProcess.options.mirror.Value)
        tfOPTIONS.isMirror = sProcess.options.mirror.Value;
    else
        tfOPTIONS.isMirror = 0;
    end
    tfOPTIONS.Clusters   = sProcess.options.clusters.Value;
    % If a time window was specified
    if isfield(sProcess.options, 'timewindow') && ~isempty(sProcess.options.timewindow) && ~isempty(sProcess.options.timewindow.Value) && iscell(sProcess.options.timewindow.Value)
        tfOPTIONS.TimeWindow = sProcess.options.timewindow.Value{1};
    elseif ~isfield(tfOPTIONS, 'TimeWindow')
        tfOPTIONS.TimeWindow = [];
    end
    % If a window length was specified (PSD)
    if isfield(sProcess.options, 'win_length') && ~isempty(sProcess.options.win_length) && ~isempty(sProcess.options.win_length.Value) && iscell(sProcess.options.win_length.Value)
        tfOPTIONS.WinLength  = sProcess.options.win_length.Value{1};
        tfOPTIONS.WinOverlap = sProcess.options.win_overlap.Value{1};
    end
%     % Frequency bands
%     if isfield(sProcess.options, 'isfreqbands') && ~isempty(sProcess.options.isfreqbands) && ~isempty(sProcess.options.isfreqbands.Value) && sProcess.options.isfreqbands.Value
%         tfOPTIONS.Freqs = sProcess.options.freqbands.Value;
%     end
%     % Measure
%     if isfield(sProcess.options, 'measure') && ~isempty(sProcess.options.measure) && ~isempty(sProcess.options.measure.Value) && sProcess.options.measure.Value
% 
%     end
    % Output
    if isfield(sProcess.options, 'avgoutput') && ~isempty(sProcess.options.avgoutput) && ~isempty(sProcess.options.avgoutput.Value)
        if sProcess.options.avgoutput.Value
            tfOPTIONS.Output = 'average';
        else
            tfOPTIONS.Output = 'all';
        end
    end
    
    
    % === EXTRACT CLUSTER/SCOUTS ===
    if ~isempty(tfOPTIONS.Clusters)
        % If cluster function should be applied AFTER time-freq: get all time series
        sClustersExtract = tfOPTIONS.Clusters;
        [sClustersExtract.isAbsolute] = deal(0);
        if strcmpi(tfOPTIONS.ClusterFuncTime, 'after')
            [sClustersExtract.Function] = deal('All');
        end
        % Call process
        ClustMat = bst_process('CallProcess', 'process_extract_cluster', sInputs, [], ...
                               'clusters',    sClustersExtract, ...
                               'isnorm',      0, ...
                               'save',        0, ...
                               'userowname',  cellfun(@(c)strcmpi(c,'All'), {tfOPTIONS.Clusters.Function}), ...
                               'concatenate', 0, ...
                               'timewindow',  tfOPTIONS.TimeWindow);
        if isempty(ClustMat)
            bst_report('Error', sProcess, sInputs, 'Cannot access clusters/scouts time series.');
            return;
        end
        % Get data to process
        DataToProcess = {ClustMat.Value};
        tfOPTIONS.TimeVector  = ClustMat(1).Time;
        tfOPTIONS.ListFiles   = {sInputs.FileName};
        tfOPTIONS.nComponents = [ClustMat.nComponents];
        tfOPTIONS.RowNames    = {};
        for iFile = 1:length(ClustMat)
            for iRow = 1:length(ClustMat(iFile).Description)
                splitStr = str_split(ClustMat(iFile).Description{iRow}, '@');
                tfOPTIONS.RowNames{iFile}{iRow,1} = deblank(splitStr{1});
            end
        end
        clear ClustMat;
    % === DATA FILES ===
    else
        DataToProcess = {sInputs.FileName};
        tfOPTIONS.TimeVector = in_bst(sInputs(1).FileName, 'Time');
    end

    % === OUTPUT STUDY ===
    if strcmpi(tfOPTIONS.Output, 'average')
        % Get output study
        [sStudy, iStudy, Comment] = bst_process('GetOutputStudy', sProcess, sInputs);
        % If no valid output study can be found
        if isempty(iStudy)
            return;
        end
        % Save all outputs from bst_timefreq in target Study
        tfOPTIONS.iTargetStudy = iStudy;
    else
        tfOPTIONS.iTargetStudy = [];
    end
    
    % === START COMPUTATION ===
    [OutputFiles, Messages] = bst_timefreq(DataToProcess, tfOPTIONS);
    if ~isempty(Messages)
        if isempty(OutputFiles)
            bst_report('Error', sProcess, sInputs, Messages);
        else
            bst_report('Info', sProcess, sInputs, Messages);
            disp(['BST> process_timefreq: ' Messages]);
        end
    end
end




