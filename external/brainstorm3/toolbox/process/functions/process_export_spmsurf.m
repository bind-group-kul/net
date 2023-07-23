function varargout = process_export_spmvol( varargin )
% PROCESS_EXPORT_SPMVOL: Export source files to NIFTI files readable by SPM.
%
% USAGE:     sProcess = process_export_spmvol('GetDescription')
%                       process_export_spmvol('Run', sProcess, sInputs)

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
    sProcess.Comment     = 'Export to SPM12 (surface)';
    sProcess.FileTag     = '';
    sProcess.Category    = 'Custom';
    sProcess.SubGroup    = 'File';
    sProcess.Index       = 981;
    % Definition of the input accepted by this process
    sProcess.InputTypes  = {'results'};
    sProcess.OutputTypes = {'results'};
    sProcess.nInputs     = 1;
    sProcess.nMinFiles   = 1;
    % Definition of the options
    % === OUTPUT FOLDER
    % File selection options
    SelectOptions = {...
        '', ...                            % Filename
        '', ...                            % FileFormat
        'save', ...                        % Dialog type: {open,save}
        'Select output folder...', ...     % Window title
        'ExportData', ...                  % LastUsedDir: {ImportData,ImportChannel,ImportAnat,ExportChannel,ExportData,ExportAnat,ExportProtocol,ExportImage,ExportScript}
        'single', ...                      % Selection mode: {single,multiple}
        'dirs', ...                        % Selection mode: {files,dirs,files_and_dirs}
        {{'.folder'}, 'GIfTI (*.gii)', 'GIFTI'}, ... % Available file formats
        'SpmOut'};                         % DefaultFormats: {ChannelIn,DataIn,DipolesIn,EventsIn,AnatIn,MriIn,NoiseCovIn,ResultsIn,SspIn,SurfaceIn,TimefreqIn}
    % Option definition
    sProcess.options.outputdir.Comment = 'Output folder:';
    sProcess.options.outputdir.Type    = 'filename';
    sProcess.options.outputdir.Value   = SelectOptions;
    % === OUTPUT FILE TAG
    sProcess.options.filetag.Comment = 'Output file tag (default=Subj_Cond):';
    sProcess.options.filetag.Type    = 'text';
    sProcess.options.filetag.Value   = '';
%     % === ALL OUTPUT IN ONE FILE
%     sProcess.options.isconcat.Comment = 'Save all the trials in one file (time average only)';
%     sProcess.options.isconcat.Type    = 'checkbox';
%     sProcess.options.isconcat.Value   = 0;
    % === TIME WINDOW
%     sProcess.options.label1.Comment = '<HTML><BR><B>Time options</B>:';
%     sProcess.options.label1.Type    = 'label';
    sProcess.options.timewindow.Comment = 'Average over time window:';
    sProcess.options.timewindow.Type    = 'timewindow';
    sProcess.options.timewindow.Value   = [];
%     % === TIME DOWNSAMPLE
%     sProcess.options.timedownsample.Comment = 'Time downsample factor: ';
%     sProcess.options.timedownsample.Type    = 'value';
%     sProcess.options.timedownsample.Value   = {3,'(integer)',0};
%     % === AVERAGE OVER TIME
%     sProcess.options.timemethod.Comment = {'Average time (3D volume)', 'Keep time dimension (4D volume)'};
%     sProcess.options.timemethod.Type    = 'radio';
%     sProcess.options.timemethod.Value   = 1;
    % === ABSOLUTE VALUES
    sProcess.options.isabs.Comment = 'Use absolute values of the sources';
    sProcess.options.isabs.Type    = 'checkbox';
    sProcess.options.isabs.Value   = 1;
end


%% ===== FORMAT COMMENT =====
function Comment = FormatComment(sProcess) %#ok<DEFNU>
    Comment = sProcess.Comment;
end


%% ===== RUN =====
function OutputFiles = Run(sProcess, sInputs) %#ok<DEFNU>
    % Default options
    sProcess.options.timedownsample.Value = {1,'(integer)',0};
    sProcess.options.timemethod.Value = 1;
    sProcess.options.voldownsample.Value = {1,'(integer)',0};
    sProcess.options.iscut.Value = 1;
    sProcess.options.isconcat.Value = 0;
    % Call SPM export
    OutputFiles = process_export_spmvol('Run', sProcess, sInputs);
end



