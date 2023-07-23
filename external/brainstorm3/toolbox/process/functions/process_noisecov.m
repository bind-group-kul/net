function varargout = process_noisecov( varargin )
% PROCESS_NOISECOV: Compute a noise covariance matrix

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
% Authors: Francois Tadel, 2012

macro_methodcall;
end


%% ===== GET DESCRIPTION =====
function sProcess = GetDescription() %#ok<DEFNU>
    % ===== PROCESS =====
    % Description the process
    sProcess.Comment     = 'Compute noise covariance';
    sProcess.FileTag     = '';
    sProcess.Category    = 'Custom';
    sProcess.SubGroup    = 'Sources';
    sProcess.Index       = 321;
    % Definition of the input accepted by this process
    sProcess.InputTypes  = {'data', 'raw'};
    sProcess.OutputTypes = {'data', 'raw'};
    sProcess.nInputs     = 1;
    sProcess.nMinFiles   = 1;
    % Option: Baseline
    sProcess.options.baseline.Comment = 'Baseline:';
    sProcess.options.baseline.Type    = 'baseline';
    sProcess.options.baseline.Value   = [];
    % Options: Remove DC offset
    sProcess.options.label1.Comment = '<HTML><BR>Remove DC offset:';
    sProcess.options.label1.Type    = 'label';
    sProcess.options.dcoffset.Comment = {'Block by block, to avoid effects of slow shifts in data', 'Compute global average and remove it to from all the blocks'};
    sProcess.options.dcoffset.Type    = 'radio';
    sProcess.options.dcoffset.Value   = 1;
    % Option: Full/Diagonal
    sProcess.options.label2.Comment = '<HTML><BR>Output:';
    sProcess.options.label2.Type    = 'label';
    sProcess.options.method.Comment = {'Full noise covariance matrix', 'Diagonal matrix (better if: nTime < nChannel*(nChannel+1)/2)'};
    sProcess.options.method.Type    = 'radio';
    sProcess.options.method.Value   = 1;
    % Option: Copy to other conditions
    sProcess.options.copycond.Comment = 'Copy to other conditions';
    sProcess.options.copycond.Type    = 'checkbox';
    sProcess.options.copycond.Value   = 0;
    % Option: Copy to other subjects
    sProcess.options.copysubj.Comment = 'Copy to other subjects';
    sProcess.options.copysubj.Type    = 'checkbox';
    sProcess.options.copysubj.Value   = 0;
end


%% ===== FORMAT COMMENT =====
function Comment = FormatComment(sProcess) %#ok<DEFNU>
    Comment = sProcess.Comment;
end


%% ===== RUN =====
function OutputFiles = Run(sProcess, sInputs) %#ok<DEFNU>
    OutputFiles = {};
    
    % ===== GET OPTIONS =====
    % Get default options
    OPTIONS = bst_noisecov();
    % Get options
    OPTIONS.Baseline = sProcess.options.baseline.Value{1};
    switch (sProcess.options.dcoffset.Value)
        case 1,  OPTIONS.RemoveDcOffset = 'file';
        case 2,  OPTIONS.RemoveDcOffset = 'all';
    end
    switch (sProcess.options.method.Value)
        case 1,  OPTIONS.NoiseCovMethod = 'full';
        case 2,  OPTIONS.NoiseCovMethod = 'diag';
    end
    OPTIONS.AutoReplace = 1;
    % Copy to other studies
    isCopyCond = sProcess.options.copycond.Value;
    isCopySubj = sProcess.options.copysubj.Value;
    
    % ===== GET OUTPUT STUDY =====
    % Only the input studies
    if ~isCopyCond && ~isCopySubj
        iTarget = [sInputs.iStudy];
    % All the conditions of the selected subjects
    elseif isCopyCond && ~isCopySubj
        iTarget = [];
        AllSubjFile = unique({sInputs.SubjectFile});
        for iSubj = 1:length(AllSubjFile)
            [tmp, iNew] = bst_get('StudyWithSubject', AllSubjFile{iSubj});
            iTarget = [iTarget, iNew];
        end
    % The selected conditions for all the subjects
    elseif ~isCopyCond && isCopySubj
        iTarget = [];
        ProtocolSubjects = bst_get('ProtocolSubjects');
        AllCond = unique({sInputs.Condition});
        AllSubj = {ProtocolSubjects.Subject.Name};
        for iSubj = 1:length(AllSubj)
            for iCond = 1:length(AllCond)
                [tmp, iNew] = bst_get('StudyWithCondition', [AllSubj{iSubj}, '/', AllCond{iCond}]);
                iTarget = [iTarget, iNew];
            end
        end
    % All the studies
    elseif isCopyCond && isCopySubj
        ProtocolStudies = bst_get('ProtocolStudies');
        iTarget = 1:length(ProtocolStudies.Study);
    end
    iTarget = unique(iTarget);
    
    % ===== GET DATA =====
    % Get all the input data files
    iStudies = [sInputs.iStudy];
    iDatas   = [sInputs.iItem];
    % Get channel studies
    [sChannels, iChanStudies] = bst_get('ChannelForStudy', iTarget);
%     % Check values
%     if (length(sChannels) ~= length(iChanStudies))
%         bst_report('Error', sProcess, sInputs, ['Some of the input files are not associated with a channel file.' 10 'Please import the channel files first.']);
%         return;
%     end
    % Keep only once each channel file
    iChanStudies = unique(iChanStudies);
    
    % ===== COMPUTE =====
    % Compute NoiseCov matrix
    NoiseCovFiles = bst_noisecov(iChanStudies, iStudies, iDatas, OPTIONS);
    if isempty(NoiseCovFiles)
        bst_report('Error', sProcess, sInputs, 'Unknown error.');
        return;
    end
    % Return the data files in input
    OutputFiles = {sInputs.FileName};
end



