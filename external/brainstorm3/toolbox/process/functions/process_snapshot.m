function varargout = process_snapshot( varargin )
% PROCESS_SNAPSHOT: Delete files, subject, or condition.
%
% USAGE:     sProcess = process_snapshot('GetDescription')
%                       process_snapshot('Run', sProcess, sInputs)

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
    % Description the process
    sProcess.Comment     = 'Save snapshot';
    sProcess.FileTag     = '';
    sProcess.Category    = 'Custom';
    sProcess.SubGroup    = 'File';
    sProcess.Index       = 982;
    % Definition of the input accepted by this process
    sProcess.InputTypes  = {'data', 'results'};
    sProcess.OutputTypes = {'data', 'results'};
    sProcess.nInputs     = 1;
    sProcess.nMinFiles   = 1;
    sProcess.isSeparator = 1;
    % Definition of the options
    % === TARGET
    sProcess.options.target.Comment = 'Snapshot: ';
    sProcess.options.target.Type    = 'combobox';
    sProcess.options.target.Value   = {1, {'Sensors/MRI registration', 'SSP projectors', 'Noise covariance', 'Headmodel spheres', 'Recordings time series', 'Recordings topography (one time)', 'Recordings topography (contact sheet)', 'Sources (one time)', 'Sources (contact sheet)'}};
    % === SENSORS 
    sProcess.options.modality.Comment = 'Sensor type: ';
    sProcess.options.modality.Type    = 'combobox';
    sProcess.options.modality.Value   = {1, {'MEG (All)', 'MEG (Gradiometers)', 'MEG (Magnetometers)', 'EEG', 'ECOG', 'SEEG'}};
    % === Orientation 
    sProcess.options.orient.Comment = 'Orientation: ';
    sProcess.options.orient.Type    = 'combobox';
    sProcess.options.orient.Value   = {1, {'left', 'right', 'top', 'bottom', 'front', 'back'}};
    % === TIME: Single view
    sProcess.options.time.Comment = 'Time (in seconds):';
    sProcess.options.time.Type    = 'value';
    sProcess.options.time.Value   = {0, 's', 4};
    % === TIME: Contact sheet
    sProcess.options.contact_time.Comment = 'Contact sheet (start time, stop time):';
    sProcess.options.contact_time.Type    = 'value';
    sProcess.options.contact_time.Value   = {[0,.1], 'list', 4};
    sProcess.options.contact_nimage.Comment = 'Contact sheet (number of images):';
    sProcess.options.contact_nimage.Type    = 'value';
    sProcess.options.contact_nimage.Value   = {12, '', 0};
    % === COMMENT
    sProcess.options.comment.Comment = 'Comment: ';
    sProcess.options.comment.Type    = 'text';
    sProcess.options.comment.Value   = '';
end


%% ===== FORMAT COMMENT =====
function Comment = FormatComment(sProcess) %#ok<DEFNU>
    Comment = ['Snapshot: ' sProcess.options.target.Value{2}{sProcess.options.target.Value{1}}];
end


%% ===== RUN =====
function OutputFiles = Run(sProcess, sInputs) %#ok<DEFNU>
    % Returned files: same as input
    OutputFiles = {sInputs.FileName};
    % Get options
    SnapTarget = sProcess.options.target.Value{1};
    switch (sProcess.options.modality.Value{1})
        case 1,  Modality = 'MEG';
        case 2,  Modality = 'MEG GRAD';
        case 3,  Modality = 'MEG MAG';
        case 4,  Modality = 'EEG';
        case 5,  Modality = 'ECOG';
        case 6,  Modality = 'SEEG';
    end
    Orient         = sProcess.options.orient.Value{2}{sProcess.options.orient.Value{1}};
    Time           = sProcess.options.time.Value{1};
    contact_time   = sProcess.options.contact_time.Value{1};
    contact_nimage = sProcess.options.contact_nimage.Value{1};
    Comment        = sProcess.options.comment.Value;
    % Contact sheet
    Contact = [contact_time, contact_nimage];
    % Select only one input file per channel file
    if any(SnapTarget == [1 2 3 4])
        [AllChannelFile, iAllChan] = unique({sInputs.ChannelFile});
        sInputs = sInputs(iAllChan);
    end
    
    % For each file, capture view for each file
    for iFile = 1:length(sInputs)
        FileName = sInputs(iFile).FileName;
        switch (SnapTarget)
            case 1
                bst_report('Snapshot', 'registration', FileName, Comment, Modality, Orient);
            case 2
                bst_report('Snapshot', 'ssp', FileName, Comment);
            case 3
                bst_report('Snapshot', 'noisecov', FileName, Comment);
            case 4
                bst_report('Snapshot', 'headmodel', FileName, Comment);
            case 5
                bst_report('Snapshot', 'data', FileName, Comment, Modality);
            case 6
                bst_report('Snapshot', 'topo', FileName, Comment, Modality, Time);
            case 7
                if (length(Contact) ~= 3)
                    bst_report('Error', sProcess, [], 'Invalid contact sheet time values');
                    return;
                end
                bst_report('Snapshot', 'topo', FileName, Comment, Modality, Contact);
            case 8
                bst_report('Snapshot', 'sources', FileName, Comment, Time, .30, Orient);
            case 9
                if (length(Contact) ~= 3)
                    bst_report('Error', sProcess, [], 'Invalid contact sheet time values');
                    return;
                end
                bst_report('Snapshot', 'sources', FileName, Comment, Contact, .30, Orient);
        end
    end
end



