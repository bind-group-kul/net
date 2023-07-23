function varargout = process_dipole_scanning( varargin )
% PROCESS_CREATE_DIPOLE_FILE: Generates a brainstorm dipole file from the GLS and GLS-P inverse solutions.

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
% Authors: Elizabeth Bock, John C. Mosher, Francois Tadel, 2013

macro_methodcall;
end


%% ===== GET DESCRIPTION =====
function sProcess = GetDescription() %#ok<DEFNU>
    % Description the process
    sProcess.Comment     = 'Dipole scanning';
    sProcess.FileTag     = '';
    sProcess.Category    = 'Custom';
    sProcess.SubGroup    = 'Sources';
    sProcess.Index       = 326;
    % Definition of the input accepted by this process
    sProcess.InputTypes  = {'results'};
    sProcess.OutputTypes = {'results'};
    sProcess.nInputs     = 1;
    sProcess.nMinFiles   = 1;
    sProcess.isSeparator = 1;
    % Definition of the options
     % === Time window
    sProcess.options.timewindow.Comment = 'Time window:';
    sProcess.options.timewindow.Type    = 'timewindow';
    sProcess.options.timewindow.Value   = [];
    % === fit frequency
    sProcess.options.downsample.Comment = 'Time between dipoles: ';
    sProcess.options.downsample.Type    = 'value';
    sProcess.options.downsample.Value   = {2, 'ms', []};
    % === Separator
    sProcess.options.sep2.Type = 'separator';
    sProcess.options.sep2.Comment = ' ';
    % === CLUSTERS
    sProcess.options.clusters.Comment = 'Limit scanning to selected scouts';
    sProcess.options.clusters.Type    = 'cluster_confirm';
    sProcess.options.clusters.Value   = [];    
end


%% ===== FORMAT COMMENT =====
function Comment = FormatComment(sProcess)
    Comment = sProcess.Comment;
end


%% ===== RUN =====
function OutputFiles = Run(sProcess, sInputs) %#ok<DEFNU>
    OutputFiles = {};
    % === Get options
     % Time window to process
    TimeWindow = sProcess.options.timewindow.Value{1};
    if (TimeWindow(1) >= TimeWindow(2)) 
        bst_report('Error', sProcess, [], 'Invalid time definition.');
        return;
    end

    FitPeriod = sProcess.options.downsample.Value{1} / 1000;
    sScouts = sProcess.options.clusters.Value;
    hasFixedOrient = 1;
    
    % === Get the results
    if ~isempty(strfind(sInputs.FileName, 'GLSP'))
       ScanType = 'GLSP';    % works for all three cases of Mosher
    elseif ~isempty(strfind(sInputs.FileName, 'MNEJP'))
       ScanType = 'MNEJP';
    elseif ~isempty(strfind(sInputs.FileName, 'GLSRP'))
       ScanType = 'GLSRP';
    elseif strfind(sInputs.FileName, 'dSPM')
       ScanType = 'dSPM';
    elseif strfind(sInputs.FileName, 'sLORETA')
       ScanType = 'sLORETA';
    elseif strfind(sInputs.FileName, 'zscore')
       ScanType = 'zscore';
    else
       bst_report('Error', sProcess, [], sprintf('%s\n%s', 'Dipole scanning is only available on a performance image matrix', 'i.e.  GLSP, dSPM, sLORETA and MN zscore'));
       return;
    end
    
    % === Get the sources
    sResultP = in_bst_results(sInputs.FileName, 0);
    DataMatP = in_bst_data(sResultP.DataFile);
    sResultP.ImageGridAmp = sResultP.ImagingKernel * DataMatP.F(sResultP.GoodChannel,:); 
    SamplesBounds = bst_closest(TimeWindow, DataMatP.Time);
    
    % The "performance" image matrix
    P = sResultP.ImageGridAmp(:,SamplesBounds(1):SamplesBounds(2));
    
    if strcmp('free',[sResultP.Options.SourceOrient])
        hasFixedOrient = 0;
        % use the norm
        Pscan = sqrt(P(1:3:end,:).^2 + P(2:3:end,:).^2 + P(3:3:end,:).^2);
    else
        Pscan = P;
    end
    
    % === Find the index of 'best fit' at every time point
    % Get the selected scouts
    if ~isempty(sScouts)
        scoutVerts = [];
        for iScout = 1:length(sScouts)
            scoutVerts = [scoutVerts sScouts(iScout).Vertices];
        end
        [mag,ind] = max(Pscan(scoutVerts,:));
        maxInd = scoutVerts(ind);
    else
        % don't use scouts, use all vertices
        [mag,maxInd] = max(Pscan,[],1);
    end
    
   
    % === Get the time
    timeVector = DataMatP.Time(SamplesBounds(1):SamplesBounds(2));
    
    % === Prepare a mask for downsampling the number of dipoles to save
    NumDipoles = size(P,2);
    if FitPeriod > 0
        tTotal = timeVector(end) - timeVector(1);
        nNewDipoles = tTotal/FitPeriod;
        dsFactor = round(NumDipoles/nNewDipoles);
    else
        dsFactor = 1;
    end
    temp = zeros(1,dsFactor);
    temp(1) = 1;
    dsMask = repmat(temp, 1, floor(NumDipoles/dsFactor));
    dsMask = logical([dsMask zeros(1,NumDipoles-length(dsMask))]);
    % downsample 
    dsTimeVector = timeVector(dsMask);
    dsMaxInd = maxInd(dsMask);

    % === Get the surface
    SurfaceMat = in_tess_bst(sResultP.SurfaceFile, 0);

    % === Get the locations on the cortex
    loc = SurfaceMat.Vertices';
    
    % === find the orientations
    if hasFixedOrient
        % use the headmodel orientations
        sHeadModel = bst_get('HeadModelForStudy', sInputs.iStudy);
        if isempty(sHeadModel)
            error('No headmodel available for this study.');
        end
        HeadModelFile = sHeadModel.FileName;
        HeadModelMat = in_headmodel_bst(HeadModelFile, 0, 'Gain', 'GridLoc', 'GridOrient');
        fullOrient = HeadModelMat.GridOrient';
        for jj = 1:length(dsMaxInd)
            orient(:,jj) = fullOrient(:,dsMaxInd(jj));
        end
    else
        fullOrient = reshape(P,sResultP.nComponents,[],size(P,2));
        dsOrient = fullOrient(:,:,dsMask);
        for jj = 1:length(dsMaxInd)
            orient(:,jj) = fullOrient(:,dsMaxInd(jj),jj);
        end
    end

    % === Performace measures for GLSP
    if ~isempty(strcmp(ScanType, 'GLSP')) || ...
          ~isempty(strcmp(ScanType,'MNEJP')) || ...
          ~isempty(strcmp(ScanType,'GLSRP')),
        % === Goodness of fit
        % square the performance at every source, there for resulting in a
        % scalar squared performance value at every dipolar source
        P2 = sum(reshape(abs(P).^2,sResultP.nComponents,[]),1);
        P2 = reshape(P2,[],size(P,2));

        % get the squared norm of the whitened data
        wd2 = sum(abs(sResultP.Whitener * DataMatP.F(sResultP.GoodChannel,SamplesBounds(1):SamplesBounds(2))).^2,1);

        % the goodness of fit is now calculated by dividing the norm into each
        % performance value
        gof = P2 * diag(1./wd2);

        % === Chi-square
        % the chi square is the difference of the norm and the performance
        % resulting in the error for every source at every time point
        ChiSquare = repmat(wd2,size(P2,1),1) - P2;

        % The reduced chi-square is found by dividing by the degrees of freedom in
        % the error, which (for now) is simply a scalar, since we assume all
        % sources have the same degrees of freedom. Thus ROI modeling will require
        % that all ROIs have the same DOF. 
        DOF = size(sResultP.ImagingKernel,2) - sResultP.nComponents;
        RChiSquare = ChiSquare / DOF;
        
        % downsample
        dsChiSquare = ChiSquare(:,dsMask);
        dsRChiSquare = RChiSquare(:,dsMask);
        dsGOF = gof(:,dsMask);
    
    else
       dsChiSquare = [];
       dsRChiSquare = [];
       dsGOF = [];
    end
    
    dsP = P(:,dsMask);

    
    % === Error mask
%     ERR_THRESH = 3; 
%     Error_Mask = RChiSquare < ERR_THRESH;
% 
%     P2mask = zeros(size(P2));
%     P2mask(Error_Mask) = P2(Error_Mask);
% 
%     GOFmask = zeros(size(GOF));
%     GOFmask(Error_Mask) = GOF(Error_Mask);
    
    NumDipoles = length(dsMaxInd);
    
    %% === CREATE OUTPUT STRUCTURE ===
    bst_progress('start', 'Dipole File', 'Saving result...');
    % Get output study
    [sStudy, iStudy] = bst_get('Study', sInputs.iStudy);
    % Comment: forced in the options
    if isfield(sProcess.options, 'Comment') && isfield(sProcess.options.Comment, 'Value') && ~isempty(sProcess.options.Comment.Value)
        Comment = sProcess.options.Comment.Value;
    % Comment: process default
    else
        Comment = [DataMatP.Comment ' | ' ScanType '-dipole-scan'];
    end
    % Get base filename
    [fPath, fBase, fExt] = bst_fileparts(sInputs.FileName);
    % Create base structure
    DipolesMat = struct('Comment',     Comment, ...
                        'Time',        unique(dsTimeVector), ...
                        'DipoleNames', [], ...
                        'Subset', [], ...
                        'Dipole',      repmat(struct(...
                             'Index',           0, ...
                             'Time',            0, ...
                             'Origin',          [0 0 0], ...
                             'Loc',             [0 0 0], ...
                             'Amplitude',       [0 0 0], ...
                             'Goodness',        [], ...
                             'Errors',          0, ...
                             'Noise',           0, ...
                             'SingleError',     [0 0 0 0 0], ...
                             'ErrorMatrix',     zeros(1,25), ...
                             'ConfVol',         [], ...
                             'Khi2',            [], ...
                             'DOF',            [], ...
                             'Probability',     0, ...
                             'NoiseEstimate',   0, ...
                             'Perform',         0), 1, NumDipoles));

    % Fill structure    
    for i = 1:NumDipoles
        DipolesMat.Dipole(i).Index          = 1;
        DipolesMat.Dipole(i).Time           = dsTimeVector(i);
        DipolesMat.Dipole(i).Origin         = [0 0 0];
        DipolesMat.Dipole(i).Loc            = loc(:,dsMaxInd(i));
        DipolesMat.Dipole(i).Amplitude      = orient(:,i);
        DipolesMat.Dipole(i).Errors         = 0;
        DipolesMat.Dipole(i).Noise          = [];
        DipolesMat.Dipole(i).SingleError    = [];
        DipolesMat.Dipole(i).ErrorMatrix    = [];
        DipolesMat.Dipole(i).ConfVol        = [];
        DipolesMat.Dipole(i).Probability    = [];
        DipolesMat.Dipole(i).NoiseEstimate  = [];
        
        DipolesMat.Dipole(i).Perform        = dsP(dsMaxInd(i),i);
        
        if ~isempty(strcmp(ScanType, 'GLSP')) || ...
              ~isempty(strcmp(ScanType,'MNEJP')) || ...
              ~isempty(strcmp(ScanType,'GLSRP')),
           DipolesMat.Dipole(i).Goodness       = dsGOF(dsMaxInd(i),i);
           DipolesMat.Dipole(i).Khi2           = dsChiSquare(dsMaxInd(i),i);
           DipolesMat.Dipole(i).DOF            = DOF;
        end
    end

    % Create the dipoles names list
    dipolesList = unique([DipolesMat.Dipole.Index]); %unique group names
    DipolesMat.DipoleNames = cell(1,length(dipolesList));
    k = 1; %index of names for groups with subsets
    nChanSet = 1;
    for i = 1:(length(dipolesList)/nChanSet)
        % If more than one channel subset, name the groups according to index
        % and subset number
        if nChanSet > 1
            for j = 1:nChanSet
                DipolesMat.DipoleNames{k} = sprintf('Group #%d (%d)', dipolesList(i), j);
                DipolesMat.Subset(k) = j;
                k=k+1;
            end
        % if only one subsets, name the groups according to index
        else
            DipolesMat.DipoleNames{i} = sprintf('Group #%d', dipolesList(i));
            DipolesMat.Subset(i) = 1;
        end

    end
    DipolesMat.Subset = unique(DipolesMat.Subset);


    % Add data file
    DipolesMat.DataFile = '';
    % Add History field
    DipolesMat = bst_history('add', DipolesMat, 'generate', ['Generated from: ' sInputs.FileName]);
   
    %% ===== SAVE NEW FILE =====
    % Get imported base name
    [tmp__, importedBaseName, importedExt] = bst_fileparts(sInputs.FileName);
    importedBaseName = strrep(importedBaseName, 'dipoles_', '');
    importedBaseName = strrep(importedBaseName, '_dipoles', '');
    importedBaseName = strrep(importedBaseName, 'dipoles', '');
    % Limit number of chars
    if (length(importedBaseName) > 15)
        importedBaseName = importedBaseName(1:15);
    end
    % Create output filename
    ProtocolInfo = bst_get('ProtocolInfo');
    OutputFile = bst_fullfile(ProtocolInfo.STUDIES, bst_fileparts(sStudy.FileName), 'dipoles_fit.mat');
    OutputFile = file_unique(OutputFile);
    % Save new file in Brainstorm format
    save(OutputFile, '-struct', 'DipolesMat');
    
    
    %% ===== UPDATE DATABASE =====
    % Create structure
    BstDipolesMat = db_template('Dipoles');
    BstDipolesMat.FileName = file_short(OutputFile);
    BstDipolesMat.Comment  = Comment;
    BstDipolesMat.DataFile = '';
    % Add to study
    iDipole = length(sStudy.Dipoles) + 1;
    sStudy.Dipoles(iDipole) = BstDipolesMat;
    
    % Save study
    bst_set('Study', iStudy, sStudy);
    % Update tree
    panel_protocols('UpdateNode', 'Study', iStudy);
    % Save database
    db_save();

end





