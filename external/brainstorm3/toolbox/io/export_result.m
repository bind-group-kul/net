function export_result( varargin )
% EXPORT_RESULT: Exports a sources file to one of the supported file formats.
%
% USAGE:  export_result( BstFile )
%         export_result( ResultsMat )
%         export_result( ..., OutputFile ) 
%         export_result( ..., OutputDir ) 
%         
% INPUT: 
%     - BstFile    : Full path to a Brainstorm data file to be exported
%     - ResultsMat : Brainstorm results structure to be exported
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
% Authors: Francois Tadel, 2009-2010

% ===== PASRSE INPUTS =====
if (nargin < 1)
    error('Brainstorm:InvalidCall', 'Invalid use of export_result()');
end
% CALL: export_result( BstFile, OutputFile )
if ischar(varargin{1}) 
    % Load initial file
    BstFile = varargin{1};
    ResultsMat = load(BstFile);

% CALL: export_result( ResultsMat, OutputFile ) 
else 
    ResultsMat = varargin{1};
    BstFile = [];
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
    switch (DefaultFormats.ResultsOut)
        case 'BST'
            DefaultExt = '_sources.mat';
        case 'ASCII'
            DefaultExt = '.txt';
        otherwise
            DefaultExt = '_sources.mat';
    end
    % Build default output filename
    if ~isempty(BstFile)
        [BstPath, BstBase, BstExt] = bst_fileparts(BstFile);
    else
        BstBase = file_standardize(ResultsMat.Comment);
    end
    DefaultOutputFile = bst_fullfile(LastUsedDirs.ExportData, [BstBase, DefaultExt]);
    DefaultOutputFile = strrep(DefaultOutputFile, '_results', '');
    DefaultOutputFile = strrep(DefaultOutputFile, 'results_', '');

    % === Ask user filename ===
    % Put file
    [OutputFile, FileFormat, FileFilter] = java_getfile( 'save', ...
        'Export sources...', ...   % Window title
        DefaultOutputFile, ...     % Default directory
        'single', 'files', ...     % Selection mode
        {{'_sources'}, 'Brainstorm sources (*sources*.mat)', 'BST'; ...
         {'.txt'},     'ASCII (*.txt)',                      'ASCII'; ...
        }, DefaultFormats.ResultsOut);
    % If no file was selected: exit
    if isempty(OutputFile)
        return
    end    
    % Save new default export path
    LastUsedDirs.ExportData = bst_fileparts(OutputFile);
    bst_set('LastUsedDirs', LastUsedDirs);
    % Save default export format
    DefaultFormats.ResultsOut = FileFormat;
    bst_set('DefaultFormats',  DefaultFormats);
end


% ===== SAVE RESULTS FILE =====
[OutputPath, OutputBase, OutputExt] = bst_fileparts(OutputFile);
% Show progress bar
bst_progress('start', 'Export sources', ['Export sources to file "' [OutputBase, OutputExt] '"...']);
% Switch between file formats
switch lower(OutputExt)
    case '.mat'
        bst_save(OutputFile, ResultsMat, 'v6');
    case '.txt'
        dlmwrite(OutputFile, ResultsMat.ImageGridAmp, 'newline', 'unix', 'precision', '%17.9e', 'delimiter', ' ');
    otherwise
        error(['Unsupported file extension : "' OutputExt '"']);
end

% ===== SAVE DESC FIELDS AS ASCII =====
if ~strcmpi(OutputExt, '.mat') && isfield(ResultsMat, 'DescFileName') && isfield(ResultsMat, 'DescCluster')
    % Build filenames
    [OutPath, OutBase, OutExt] = bst_fileparts(OutputFile);
    DescFileName_file = bst_fullfile(OutPath, [OutBase, '_DescFileName.txt']);
    DescCluster_file  = bst_fullfile(OutPath, [OutBase, '_DescCluster.txt']);
    % Save files
    if (length(ResultsMat.DescFileName) > 1)
        SaveCellString(DescFileName_file, ResultsMat.DescFileName);
    end
    if (length(ResultsMat.DescCluster) > 1)
        SaveCellString(DescCluster_file, ResultsMat.DescCluster);
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

