function [sMatrix, matName] = in_bst(FileName, TimeBounds,  isLoadFull, isIgnoreBad, RemoveBaseline)
% IN_BST: Read a data matrix in a Brainstorm file of any type.
%
% USAGE: [sMatrix, matName] = in_bst(FileName, TimeBounds, isLoadFull=1, RemoveBaseline='all')  : read only the specified time indices
%        [sMatrix, matName] = in_bst(FileName)         : Read the entire file
%                TimeVector = in_bst(FileName, 'Time') : Read time vector in the file
%
% INPUT:
%    - FileName   : Full path to file to read. Possible input file types are: 
%                    - recordings file (.F field),
%                    - results file (.ImageGridAmp field),
%                    - results file in kernel-only format (.ImagingKernel field)
%    - TimeBounds : [Start,Stop] values of the time segment to read (in seconds)
%    - isLoadFull : If 0, read the kernel-based results separately as Kernel+Recordings
%    - isIgnoreBad: If 1, do not return the bad segments in the file
%    - RemoveBaseline: {'all','no'}, only usefull when reading RAW files
%
% OUTPUT:
%    - sMatrix     : Full content of the file
%    - matName     : name of the field that was read: {'F', 'ImageGridAmp', 'TF'}
%    - TimeVector  : time values of all samples that were read in the file

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
% Authors: Francois Tadel, 2008-2013

%% ===== PARSE INPUTS =====
% Parse inputs
if (nargin < 5) || isempty(RemoveBaseline)
    RemoveBaseline = 'all';
end
if (nargin < 4) || isempty(isIgnoreBad)
    isIgnoreBad = 0;
end
if (nargin < 3) || isempty(isLoadFull)
    isLoadFull = 1;
end
if (nargin < 2) || isempty(TimeBounds)
    TimeBounds = [];
end
% Get file type
fileType = file_gettype( FileName );


%% ===== READ ONLY TIME =====
if ischar(TimeBounds) && strcmpi(TimeBounds, 'Time')
    % Load time range from this file
    switch (fileType)
        case {'data', 'raw', 'pdata'}
            FileMat = in_bst_data(FileName, 'Time');
        case {'results', 'link', 'presults'}
            FileMat = in_bst_results(FileName, isLoadFull, 'Time');
        case {'timefreq', 'ptimefreq'}
            FileMat = in_bst_timefreq(FileName, 0, 'Time');
        case 'matrix'
            FileMat = in_bst_matrix(FileName, 'Time');
    end
    sMatrix = FileMat.Time;
    return;
end


%% ===== READ ALL FILE =====
switch(fileType)
    %% ===== RESULTS =====
    case {'results', 'link'}
        % Read results file
        sMatrix = in_bst_results(FileName, 0, 'ImageGridAmp', 'ImagingKernel', 'Whitener', 'nComponents', 'Component', 'Comment', ...
                                              'Function', 'Time', 'ChannelFlag', 'GoodChannel', 'HeadModelFile', 'HeadModelType', ...
                                              'SurfaceFile', 'GridLoc', 'DataFile', 'Options', 'nAvg', 'History', 'Atlas', 'ZScore', 'ColormapType');
        % FULL RESULTS
        if isfield(sMatrix, 'ImageGridAmp') && ~isempty(sMatrix.ImageGridAmp)
            iTime = GetTimeIndices(TimeBounds, sMatrix.Time);
            sMatrix.ImageGridAmp  = sMatrix.ImageGridAmp(:,iTime);
            sMatrix.Time          = sMatrix.Time(iTime);
            sMatrix.ImagingKernel = [];
            matName = 'ImageGridAmp';
        % KERNEL ONLY
        elseif isfield(sMatrix, 'ImagingKernel') && ~isempty(sMatrix.ImagingKernel)
            % Get good channels
            iGoodChannels = sMatrix.GoodChannel;
            % For DataFile in relative
            sMatrix.DataFile = file_short(sMatrix.DataFile);
            % Load the recordings file
            if ~isempty(sMatrix.ZScore)
                DataMat = in_bst(sMatrix.DataFile, [], 1, isIgnoreBad, RemoveBaseline);
            else
                DataMat = in_bst(sMatrix.DataFile, TimeBounds, 1, isIgnoreBad, RemoveBaseline);
            end
            % Rebuild full results
            if isLoadFull
                sMatrix.ImageGridAmp = sMatrix.ImagingKernel * DataMat.F(iGoodChannels, :);
            else
                sMatrix.F = DataMat.F(iGoodChannels, :);
            end
            sMatrix.Time = DataMat.Time;
            
            % Apply dynamic zscore
            if ~isempty(sMatrix.ZScore)
                if isLoadFull
                    [sMatrix.ImageGridAmp, sMatrix.ZScore] = process_zscore_dynamic('Compute', sMatrix.ImageGridAmp, sMatrix.ZScore, DataMat.Time, sMatrix.ImagingKernel, DataMat.F(iGoodChannels,:));
                    sMatrix = rmfield(sMatrix, 'ZScore');
                else
                    [tmp, sMatrix.ZScore] = process_zscore_dynamic('Compute', [], sMatrix.ZScore, DataMat.Time, sMatrix.ImagingKernel, DataMat.F(iGoodChannels,:));
                end
                % Select requested time window
                if ~isempty(TimeBounds)
                    iTime = GetTimeIndices(TimeBounds, sMatrix.Time);
                    sMatrix.Time = sMatrix.Time(iTime);
                    if isLoadFull
                        sMatrix.ImageGridAmp = sMatrix.ImageGridAmp(:,iTime);
                    else
                        sMatrix.F = sMatrix.F(:,iTime);
                    end
                end
            end
            % Remove "Kernel" indications in the Comment field
            if isLoadFull
                sMatrix.Comment = strrep(sMatrix.Comment, '(Kernel)', '');
                sMatrix.Comment = strrep(sMatrix.Comment, 'Kernel', '');
                sMatrix.ImagingKernel = [];
                matName = 'ImageGridAmp';
            else
                matName = 'ImagingKernel';
            end
        end
    
    %% ===== DATA =====
    case 'data'
        % Read recordings file
        dataFields = fieldnames(db_template('datamat'));
        sMatrix = in_bst_data( FileName, dataFields{:});
        % Get time indices we want to read
        iTime = GetTimeIndices(TimeBounds, sMatrix.Time);
        % Fix input time bounds
        TimeBounds = sMatrix.Time([iTime(1), iTime(end)]);
        % Read RAW recordings: read first epoch only
        if isstruct(sMatrix.F)
            if isLoadFull
                % Read from the raw file
                sFile = sMatrix.F;
                [sMatrix.F, sMatrix.Time] = panel_record('ReadRawBlock', sFile, 1, TimeBounds, 0, 1, 'all');
                % Reject bad segments
                if isIgnoreBad
                    % Get list of bad segments in file
                    badSeg = panel_record('GetBadSegments', sFile);
                    % Adjust with beginning of file
                    badSeg = badSeg - sFile.prop.samples(1) + 1;
                    % Remove all the bad time indices
                    if ~isempty(badSeg)
                        iBadAll = [];
                        for iSeg = 1:size(badSeg, 2)
                            iBadAll = [iBadAll, badSeg(1,iSeg):badSeg(2,iSeg)];
                        end
                        iBadAll = intersect(iTime, iBadAll);
                        % Remove bad segments from read block
                        sMatrix.F(:,iBadAll) = [];
                        sMatrix.Time(iBadAll) = [];
                    end
                end
            elseif ~isempty(TimeBounds)
                sMatrix.Time = sMatrix.Time(iTime);
            end
        % Normal imported file
        elseif ~isempty(TimeBounds)
            sMatrix.F = sMatrix.F(:,iTime);
            sMatrix.Time = sMatrix.Time(iTime);
        end
        matName = 'F';
    
    %% ===== TIME-FREQ =====
    case 'timefreq'
        dataFields = fieldnames(db_template('timefreqmat'));
        sMatrix = in_bst_timefreq( FileName, 0, dataFields{:});
        isKernel = ~isempty(strfind(FileName, '_KERNEL_'));
        % Keep required values
        if ~isempty(TimeBounds)
            if isfield(sMatrix, 'TimeBands') && ~isempty(sMatrix.TimeBands)
                error('Cannot process values averaged by time bands.');
            end
            iTime = GetTimeIndices(TimeBounds, sMatrix.Time);
            sMatrix.TF = sMatrix.TF(:,iTime,:);
            sMatrix.Time = sMatrix.Time(iTime);
        end
        % Rebuild full source matrix
        if isLoadFull && isKernel && ismember(file_gettype(sMatrix.DataFile), {'link', 'results'})
            % Get imaging kernel
            ResultsMat = in_bst_results(sMatrix.DataFile, 0, 'ImagingKernel');
            % Initialize full matrix
            TFfull = zeros(size(ResultsMat.ImagingKernel,1), size(sMatrix.TF,2), size(sMatrix.TF,3));
            % Multiply the TF values
            for i = 1:size(sMatrix.TF,3)
                TFfull(:,:,i) = ResultsMat.ImagingKernel * sMatrix.TF(:,:,i);
            end
            sMatrix.TF = TFfull;
        end
        matName = 'TF';
        
        
    %% ===== MATRIX =====
    case 'matrix'
        dataFields = fieldnames(db_template('matrixmat'));
        sMatrix = in_bst_matrix( FileName, dataFields{:});
        % Keep required values
        if isfield(sMatrix, 'Time') && ~isempty(sMatrix.Time) && ~isempty(TimeBounds)
            iTime = GetTimeIndices(TimeBounds, sMatrix.Time);
            sMatrix.Value = sMatrix.Value(:,iTime);
            sMatrix.Time  = sMatrix.Time(iTime);
        end
        matName = 'Value';
end
end


%% ===== HELPER FUNCTIONS =====
function iTime = GetTimeIndices(TimeBounds, TimeVector)
    % Get file time indices
    if isempty(TimeBounds)
        iTime = 1:length(TimeVector);
    elseif (TimeBounds(1) > TimeVector(end)) || (TimeBounds(2) < TimeVector(1))
        iTime = [];
    else
        iTimeBounds = bst_closest(TimeBounds, TimeVector);
        iTime = iTimeBounds(1):iTimeBounds(2);       
    end
end

