function varargout = process_source_flat( varargin )
% PROCESS_SOURCE_FLAT: Convert an unconstrained source file into a flat map.

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
    % ===== PROCESS =====
    % Description the process
    sProcess.Comment     = 'Unconstrained to flat map';
    sProcess.FileTag     = '';
    sProcess.Category    = 'File';
    sProcess.SubGroup    = 'Sources';
    sProcess.Index       = 337;
    % Definition of the input accepted by this process
    sProcess.InputTypes  = {'results'};
    sProcess.OutputTypes = {'results'};
    sProcess.nInputs     = 1;
    sProcess.nMinFiles   = 1;
    sProcess.isSeparator = 0;
    % === SELECT METHOD
    sProcess.options.label1.Comment = ['<HTML>Converts unconstrained source files (3 values per vertex: x,y,z)<BR>' 10 ...
                                       'to simpler files with only one value per vertex.<BR><BR>' 10 ...
                                       'Method used to perform this conversion:'];
    sProcess.options.label1.Type    = 'label';
    sProcess.options.method.Comment = {'<HTML><B>Norm</B>: sqrt(x^2+y^2+z^2)', '<HTML><B>PCA</B>: First mode of svd(x,y,z)'};
    sProcess.options.method.Type    = 'radio';
    sProcess.options.method.Value   = 1;
end


%% ===== FORMAT COMMENT =====
function Comment = FormatComment(sProcess) %#ok<DEFNU>
    Comment = sProcess.Comment;
end


%% ===== RUN =====
function OutputFiles = Run(sProcess, sInput) %#ok<DEFNU>
    OutputFiles = {};
    % Get options
    switch(sProcess.options.method.Value)
        case 1, Method = 'norm';
        case 2, Method = 'pca';
    end

    % ===== PROCESS INPUT =====
    % Load the source file
    ResultsMat = in_bst_results(sInput.FileName, 1);
    % Error: cannot process results from volume grids
    if (ResultsMat.nComponents ~= 3)
        bst_report('Error', sProcess, sInput, 'The input file is not an unconstrained source model.');
        return;
    end
    % Calculate the values
    switch (Method)
        case 'pca'
            ResultsMat.ImageGridAmp = bst_scout_value(ResultsMat.ImageGridAmp, 'none', [], 3, 'pca', 0);
        case 'norm'
            ResultsMat.ImageGridAmp = sqrt(ResultsMat.ImageGridAmp(1:3:end,:).^2 + ResultsMat.ImageGridAmp(2:3:end,:).^2 + ResultsMat.ImageGridAmp(3:3:end,:).^2);
    end
    % Set the number components
    ResultsMat.nComponents = 1;
   
    % ===== SAVE FILE =====
    % Reset the data file initial path
    ResultsMat.DataFile = file_win2unix(file_short(ResultsMat.DataFile));
    % Add comment
    ResultsMat.Comment = [ResultsMat.Comment ' | ' Method];
    % Add history entry
    ResultsMat = bst_history('add', ResultsMat, 'flat', ['Convert unconstrained sources to a flat map with option: ' Method]);
    % File tag
    if ~isempty(strfind(sInput.FileName, '_abs_zscore'))
        fileTag = 'results_abs_zscore';
    elseif ~isempty(strfind(sInput.FileName, '_zscore'))
        fileTag = 'results_zscore';
    else
        fileTag = 'results';
    end
    % Output filename
    OutputFiles{1} = bst_process('GetNewFilename', bst_fileparts(sInput.FileName), [fileTag '_' Method]);
    % Save on disk
    bst_save(OutputFiles{1}, ResultsMat, 'v6');
    % Register in database
    db_add_data(sInput.iStudy, OutputFiles{1}, ResultsMat);
end



