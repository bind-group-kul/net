function isAligned = channel_align_fiducials( ChannelFile, Modality, useGUI )
% CHANNEL_ALIGN_FIDUCIALS: Align a electrodes net in Brainstorm coordinates system (useful only for EEG).
% 
% USAGE:  channel_align_fiducials( ChannelFile, Modality, useGUI )
%         channel_align_fiducials( ChannelFile, Modality )         : useGUI=1
%
% DESCRIPTION:
%     Alignment is based on three fiducials :
%     Nasion (NAS), left pre-auricular (LPA), and right pre-auricular (RPA).
%     A simple interface ask the user to click on these three referencial points.
%
% INPUT:
%     - ChannelFile : full path to channel file
%     - Modality    : modality to display and to align
%     - useGUI      : {0,1} If set, compute channels alignment automatically 
% OUTPUT:
%     - isAligned   : 1 if the channels were aligned, else 0.

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


% ===== LOAD INPUTS =====
if (nargin < 3)
    useGUI = 1;
end
% Return default
isAligned = 0;
% Load channel
ChannelMat = in_bst_channel(ChannelFile);

%% ===== NO GUI =====
if ~useGUI
    if isfield(ChannelMat, 'SCS') && ~isempty(ChannelMat.SCS) && ~isempty(ChannelMat.SCS.NAS) && ~isempty(ChannelMat.SCS.RPA) && ~isempty(ChannelMat.SCS.LPA)
        ComputeAlignment();
        isAligned = 1;
    else
        isAligned = 0;
    end
    return;
end

%% ===== GUI =====
if useGUI
    % ===== VIEW CHANNEL FILE =====
    hFig = view_channels(ChannelFile, Modality);
    %movegui(hFig);
    set(hFig, 'Name', 'Align channels');
    % Get sensor patch handle
    hPatch = findobj(hFig, 'Tag', 'SensorsPatch');
    if isempty(hPatch) || ~ishandle(hPatch)
        bst_error('Cannot display sensors patch', 'Align electrodes', 0);
        return
    end
    % Get axes handles
    hAxes = get(hPatch, 'Parent');


    % ===== CUSTOMIZE FIGURE =====
    % Save figure callback functions
    FigureButtonDown_Bak = get(hFig, 'WindowButtonDownFcn');
    % Read toolbar icons
    iconNas   = java_geticon( 'ICON_FID_NAS' );
    iconNasOk = java_geticon( 'ICON_FID_NAS_OK' );
    iconLpa   = java_geticon( 'ICON_FID_LPA' );
    iconLpaOk = java_geticon( 'ICON_FID_LPA_OK' );
    iconRpa   = java_geticon( 'ICON_FID_RPA' );
    iconRpaOk = java_geticon( 'ICON_FID_RPA_OK' );
    iconOk    = java_geticon( 'ICON_OK' );
    % Add toolbar to window
    hToolbar = uitoolbar(hFig, 'Tag', 'AlignToolbar');
    % Fiducials buttons
    hButtonNAS = uitoggletool(hToolbar, 'CData', iconNas, 'ClickedCallback', @buttonFiducial_Callback);
    hButtonLPA = uitoggletool(hToolbar, 'CData', iconLpa, 'ClickedCallback', @buttonFiducial_Callback);
    hButtonRPA = uitoggletool(hToolbar, 'CData', iconRpa, 'ClickedCallback', @buttonFiducial_Callback);
    % Validation button
    hButtonOk = uipushtool(hToolbar, 'CData', iconOk, 'separator', 'on', 'Enable', 'off', 'ClickedCallback', @buttonOk_Callback);
    % Update figure localization
    gui_layout('Update');


    % ===== DISPLAY PREVIOUS FIDUCIALS =====
    % Initialize other variables
    hPointNas = [];
    hPointRpa = [];
    hPointLpa = [];
    hTextNas  = [];
    hTextRpa  = [];
    hTextLpa  = [];
    % Load fiducials already saved in the channel file
    if ~isfield(ChannelMat, 'SCS')
        ChannelMat.SCS = [];
    end
    if isfield(ChannelMat.SCS, 'NAS') && ~isempty(ChannelMat.SCS.NAS)
        selectFiducial(hButtonNAS, ChannelMat.SCS.NAS);    
    else
        ChannelMat.SCS.NAS = [];
    end
    if isfield(ChannelMat.SCS, 'LPA') && ~isempty(ChannelMat.SCS.LPA)
        selectFiducial(hButtonLPA, ChannelMat.SCS.LPA);   
    else
        ChannelMat.SCS.LPA = [];
    end
    if isfield(ChannelMat.SCS, 'RPA') && ~isempty(ChannelMat.SCS.RPA)
        selectFiducial(hButtonRPA, ChannelMat.SCS.RPA);   
    else
        ChannelMat.SCS.RPA = [];
    end
    % Wait until the figure is closed
    waitfor(hFig);
    isAligned = 1;
end
% END
return


%% ===== FIDUCIALS SELECTION =====
    % User click on a toolbar button
    function buttonFiducial_Callback(hObject, varargin)
        % Handles of other buttons
        hOtherButtons = setdiff([hButtonNAS, hButtonLPA, hButtonRPA], hObject);
        % If button was selected
        if strcmpi(get(hObject,'State'), 'on')
            % Unselect other buttons
            set(hOtherButtons, 'State', 'off');
            % Update figure callback to select a point
            set(hFig, 'WindowButtonDownFcn', @(h,ev)selectFiducial(hObject));
        % Else, button was unselected
        else
            disp OFF
            set(hFig, 'WindowButtonDownFcn', FigureButtonDown_Bak);
        end
    end

    % Click on the axes : fiducial localization
    function selectFiducial(hObject, pout)
        % Find surface vertex that was clicked
        if (nargin < 2)
            pout  = select3d(hPatch);
        end
        if isempty(pout)
            return
        end
        % According to fiducials that is being localized
        switch (hObject)
            case hButtonNAS
                % Save Nasion position in tesselation file
                ChannelMat.SCS.NAS = pout';
                set(hButtonNAS, 'CData', iconNasOk);
                % Plot new Nasion point (delete old)
                if ~isempty(hPointNas) && ishandle(hPointNas) && ishandle(hTextNas) 
                    delete([hPointNas hTextNas]);
                end
                [hPointNas hTextNas] = plotFiducials(pout, 'NAS');
                
            case hButtonLPA 
                ChannelMat.SCS.LPA = pout';
                set(hButtonLPA, 'CData', iconLpaOk);
                % Plot new RPA point (delete old)
                if ~isempty(hPointLpa) && ishandle(hPointLpa) && ishandle(hTextLpa) 
                    delete([hPointLpa hTextLpa]);
                end
                [hPointLpa hTextLpa] = plotFiducials(pout, 'LPA');
                
            case hButtonRPA
                ChannelMat.SCS.RPA = pout';
                set(hButtonRPA, 'CData', iconRpaOk);
                % Plot new LPA point (delete old)
                if ~isempty(hPointRpa) && ishandle(hPointRpa) && ishandle(hTextRpa) 
                    delete([hPointRpa hTextRpa]);
                end
                [hPointRpa hTextRpa] = plotFiducials(pout, 'RPA');
        end
        % Unselect button
        set(hObject, 'State', 'off');
        % Restore figure callback
        set(hFig, 'WindowButtonDownFcn', FigureButtonDown_Bak);
        % If all the fiducials are selected : enables "OK" button
        if ~isempty(ChannelMat.SCS.NAS) && ~isempty(ChannelMat.SCS.RPA) && ~isempty(ChannelMat.SCS.LPA)
            set(hButtonOk, 'Enable', 'on');
        else
            set(hButtonOk, 'Enable', 'off');
        end
    end

    % Plot fiducial marker
    function [hPoint, hText] = plotFiducials(ptLoc, ptName)
        % Plot fiducial marker
        hPoint = line(1.015*ptLoc(1), 1.015*ptLoc(2), 1.015*ptLoc(3), ...
                      'Marker',          'o', ...
                      'MarkerFaceColor', [0 0.5 0], ...
                      'MarkerEdgeColor', [.8 .8 .8], ...
                      'MarkerSize',      9, ...
                      'Tag',             'FiducialMarker');
        % Plot fiducial legend
        hText = text(1.17*ptLoc(1), 1.17*ptLoc(2), 1.17*ptLoc(3), ...
                     ptName, ...
                     'Fontname',   'helvetica', ...
                     'FontUnits',  'Point', ...
                     'FontSize',   11, ...
                     'FontWeight', 'bold', ...
                     'Color',      [0 1 0], ...
                     'Tag',        'FiducialLabel', ...
                     'Interpreter','none');
    end


%% ===== VALIDATION BUTTONS =====
    function buttonOk_Callback(varargin)
        % Close 3DViz figure
        close(hFig);
        % Compute alignement
        ComputeAlignment();
    end

    function ComputeAlignment()
        % Get sensors of the target modality
        modChannels = good_channel(ChannelMat.Channel, [], Modality);
        if isempty(modChannels)
            bst_error(['No "' Modality '" channel in file.']);
            return
        end
        % Update surface name (add a '_SCS' tag, to know that they are already realigned)
        ChannelMat.Comment = strrep(ChannelMat.Comment, ' SCS', '');
        ChannelMat.Comment = strrep(ChannelMat.Comment, 'SCS', '');
        ChannelMat.Comment = [ChannelMat.Comment, ' SCS'];
        
        bst_progress('start', 'Align electrodes', 'Aligning electrodes...');
        % Compute one transformation for all the surfaces
        if ~isfield(ChannelMat.SCS, 'R') || ~isfield(ChannelMat.SCS, 'T') || isempty(ChannelMat.SCS.R) || isempty(ChannelMat.SCS.R)
            transfSCS = cs_mri2scs(ChannelMat);
            ChannelMat.SCS.R      = transfSCS.R;
            ChannelMat.SCS.T      = transfSCS.T;
            ChannelMat.SCS.Origin = transfSCS.Origin;
        end 
        % Convert the fiducials positions
        ChannelMat.SCS.NAS = cs_mri2scs(ChannelMat, ChannelMat.SCS.NAS')';
        ChannelMat.SCS.LPA = cs_mri2scs(ChannelMat, ChannelMat.SCS.LPA')';
        ChannelMat.SCS.RPA = cs_mri2scs(ChannelMat, ChannelMat.SCS.RPA')';
        % Process each sensor
        for i = modChannels
            % Converts the sensor location to SCS (subject coordinates system)
            %ChannelMat.Channel(i).Loc = [transf, transf.T] * [ChannelMat.Channel(i).Loc; ones(1,size(ChannelMat.Channel(i).Loc, 2))];
            ChannelMat.Channel(i).Loc = cs_mri2scs(ChannelMat, ChannelMat.Channel(i).Loc);
        end
        % Process head points
        if isfield(ChannelMat, 'HeadPoints') && ~isempty(ChannelMat.HeadPoints)
            ChannelMat.HeadPoints.Loc = cs_mri2scs(ChannelMat, ChannelMat.HeadPoints.Loc);
        end
        % Remove Transformation fields from channel file
        ChannelMat.SCS = rmfield(ChannelMat.SCS, {'R', 'T'});
        
        % Save channel file
        bst_save(ChannelFile, ChannelMat, 'v7');
        bst_progress('stop');
    end
end
        
        
        
        
