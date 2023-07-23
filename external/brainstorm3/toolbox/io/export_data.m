function OutputFile = export_data( varargin )
% EXPORT_DATA: Exports a recordings file to one of the supported file formats.
%
% USAGE:  OutputFile = export_data( BstFile, OutputFile=[ask] )
%         OutputFile = export_data( DataMat, OutputFile=[ask] )
%                      export_data( BstFiles ) : Batch process over multiple files
%         
% INPUT: 
%     - BstFile    : Full path to a Brainstorm data file to be exported
%     - DataMat    : Brainstorm data structure to be exported
%     - OutputFile : Full path to target file (extension will determine the format)
%                    If not specified: asked to the user

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
% Authors: Francois Tadel, 2008-2010

% ===== PASRSE INPUTS =====
if (nargin < 1)
    error('Brainstorm:InvalidCall', 'Invalid use of export_data()');
end
% CALL: export_data( BstFile, OutputFile )
if ischar(varargin{1}) 
    % Load initial file
    BstFile = varargin{1};
    DataMat = load(BstFile);
% CALL: export_data( DataMat, OutputFile ) 
elseif isstruct(varargin{1})
    DataMat = varargin{1};
    BstFile = [];
% CALL: export_data( BstFiles, OutputFile )
elseif iscell(varargin{1}) 
    % Single file
    if (length(varargin{1}) == 1)
        BstFile = varargin{1}{1};
        DataMat = load(BstFile);
    % Multiple files
    else
        BstFiles = varargin{1};
        AllOutputs = cell(1,length(BstFiles));
        % Call function once to get the output filename
        AllOutputs{1} = export_data(BstFiles{1});
        if isempty(AllOutputs{1})
            OutputFile = [];
            return;
        end
        % Loop on the other files
        for i = 2:length(BstFiles)
            AllOutputs{i} = file_unique(AllOutputs{i-1});
            export_data(BstFiles{i}, AllOutputs{i});
        end
        OutputFile = AllOutputs;
        return;
    end
end
% Get output filename
if (nargin >= 2)
    OutputFile = varargin{2};
else
    OutputFile = [];
end
    
% ===== SELECT OUTPUT FILE =====
if isempty(OutputFile)
    % === Build a default filename ===
    % Get default directories and formats
    LastUsedDirs = bst_get('LastUsedDirs');
    DefaultFormats = bst_get('DefaultFormats');
    % Get default extension
    switch (DefaultFormats.DataOut)
        case 'BST'
            DefaultExt = '_timeseries.mat';
        case 'EEG-EGI-RAW'
            DefaultExt = '.raw';
        case 'EEG-CARTOOL-EPH'
            DefaultExt = '.eph';
        case 'EXCEL'
            DefaultExt = '.xls';
        case 'ASCII'
            DefaultExt = '.txt';
        otherwise
            DefaultExt = '_timeseries.mat';
    end
    % Build default output filename
    if ~isempty(BstFile)
        [BstPath, BstBase, BstExt] = bst_fileparts(BstFile);
    else
        BstBase = file_standardize(DataMat.Comment);
    end
    DefaultOutputFile = bst_fullfile(LastUsedDirs.ExportData, [BstBase, DefaultExt]);
    DefaultOutputFile = strrep(DefaultOutputFile, '_data', '');
    DefaultOutputFile = strrep(DefaultOutputFile, 'data_', '');

    % === Ask user filename ===
    % Put file
    [OutputFile, FileFormat, FileFilter] = java_getfile( 'save', ...
        'Export MEG/EEG recordings...', ... % Window title
        DefaultOutputFile, ...              % Default directory
        'single', 'files', ...              % Selection mode
        {{'_timeseries'}, 'Brainstorm time series (*timeseries*.mat)', 'BST'; ...
         {'.raw'},  'EEG: EGI NetStation RAW (*.raw)',  'EEG-EGI-RAW'; ...
         {'.eph'},  'EEG: Cartool EPH (*.eph)',         'EEG-CARTOOL-EPH'; ...
         {'.xls'},  'Microsoft Excel (*.xls)',          'EXCEL'; ...
         {'.txt'},  'ASCII (*.txt)',                    'ASCII'; ...
        }, DefaultFormats.DataOut);
    % If no file was selected: exit
    if isempty(OutputFile)
        return
    end    
    % Save new default export path
    LastUsedDirs.ExportData = bst_fileparts(OutputFile);
    bst_set('LastUsedDirs', LastUsedDirs);
    % Save default export format
    DefaultFormats.DataOut = FileFormat;
    bst_set('DefaultFormats',  DefaultFormats);
end


% ===== DATA TO SAVE =====
if isfield(DataMat, 'F') && ~isempty(DataMat.F)
    DataToSave = DataMat.F;
elseif isfield(DataMat, 'ImageGridAmp') && ~isempty(DataMat.ImageGridAmp)
    DataToSave = DataMat.ImageGridAmp;
else
    error('No relevant data to save found in structure.');
end
    
% ===== SAVE DATA FILE =====
[OutputPath, OutputBase, OutputExt] = bst_fileparts(OutputFile);
% Show progress bar
bst_progress('start', 'Export EEG/MEG recordings', ['Export recordings to file "' [OutputBase, OutputExt] '"...']);    
% Switch between file formats
switch lower(OutputExt)
    case '.mat'
        bst_save(OutputFile, DataMat, 'v6');
    case '.raw'
        out_data_egi_raw(DataMat, OutputFile);
    case '.eph'
        % Get sampling rate
        samplingFreq = round(1/(DataMat.Time(2) - DataMat.Time(1)));
        % Write header : nb_electrodes, nb_time, sampling_freq
        dlmwrite(OutputFile, [size(DataToSave,1), size(DataToSave,2), samplingFreq], 'newline', 'unix', 'precision', '%d', 'delimiter', ' ');
        % Write data
        dlmwrite(OutputFile, DataToSave' * 1000, 'newline', 'unix', 'precision', '%0.7f', 'delimiter', '\t', '-append');
    case '.xls'
        res = xlswrite(OutputFile, DataToSave);
        if ~res
            error('Unable to save MS Excel file. Check that Excel is installed on this computer.');
        end
    case '.txt'
        dlmwrite(OutputFile, DataToSave, 'newline', 'unix', 'precision', '%17.9e', 'delimiter', ' ');
    otherwise
        error(['Unsupported file extension : "' OutputExt '"']);
end

% ===== SAVE DESC FIELDS AS ASCII =====
if ~strcmpi(OutputExt, '.mat') && isfield(DataMat, 'DescFileName') && isfield(DataMat, 'DescCluster')
    % Build filenames
    [OutPath, OutBase, OutExt] = bst_fileparts(OutputFile);
    DescFileName_file = bst_fullfile(OutPath, [OutBase, '_DescFileName.txt']);
    DescCluster_file  = bst_fullfile(OutPath, [OutBase, '_DescCluster.txt']);
    % Save files
    if (length(DataMat.DescFileName) > 1)
        SaveCellString(DescFileName_file, DataMat.DescFileName);
    end
    if (length(DataMat.DescCluster) > 1)
        SaveCellString(DescCluster_file, DataMat.DescCluster);
    end
end

% Hide progress bar
bst_progress('stop');

end


%% ===== SAVE CELL ARRAY OF STRINGS AS ASCII =====
function SaveCellString(filename, cellArray)
    % Open file
    fid = fopen(filename,'wt');
    % Loop on rows
    for i = 1:size(cellArray, 1)
        % Loop on columns
        for j = 1:size(cellArray, 2)
            fprintf(fid, ['"' strrep(cellArray{i,j},'\','\\') '"     ']);
        end
        % New line
        fprintf(fid, '\n');
    end
    % Close file
    fclose(fid);
end

