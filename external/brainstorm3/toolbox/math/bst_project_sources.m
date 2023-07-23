function OutputFiles = bst_project_sources( ResultsFile, destSurfFile, isAbsoluteValues, isInteractive )
% BST_PROJECT_SOURCES: Project source files on a different surface (currents or timefreq).
%
% USAGE:  OutputFiles = bst_project_sources( ResultsFile, DestSurfFile, isAbsoluteValues, isInteractive )
% 
% INPUT:
%    - ResultsFile      : Relative path to sources file to reproject
%    - destSurfFile     : Relative path to destination surface file
%    - isAbsoluteValues : If 1, interpolate absolute values of the sources instead of relative values
%                         => Usually: Set to 1 to project full results, and to 0 to project kernels
%    - isInteractive    : If 1, displays questions and dialog boxes
%                         If 0, consider that it is running from the process interface

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

%% ===== PARSE INPUTS ======
if (nargin < 4) || isempty(isInteractive)
    isInteractive = 1;
end
if (nargin < 3) || isempty(isAbsoluteValues)
    isAbsoluteValues = [];
end

%% ===== GROUP BY SURFACES =====
% Group the results files to process by the surface on which they were computed
% Objective: Computing only once the transformation for all the files in the same group
ResultsGroups = {};
SurfaceGroups = {};
nGroup = 0;
OutputFiles = {};
errMsg = [];
% Display progress bar
if isInteractive
    bst_progress('start', 'Project sources', 'Initialization...');
end
isKernelOnly = 1;
% Get file type: results or timefreq
isTimefreq = strcmpi(file_gettype(ResultsFile{1}), 'timefreq');
% For each sources file: get surface
for iRes = 1:length(ResultsFile)
    % Read surface file
    if isTimefreq
        ResMat = in_bst_timefreq(ResultsFile{iRes}, 0, 'SurfaceFile', 'DataType', 'DataFile');
        % Check the data type: timefreq must be source/surface based, and no kernel-based file
        if ~strcmpi(ResMat.DataType, 'results')
            errMsg = 'Only cortical maps can be projected.';
            bst_report('Error', 'process_project_sources', ResultsFile{iRes}, errMsg);
            continue;
        elseif ~isempty(strfind(ResultsFile{iRes}, '_KERNEL_'))
            errMsg = 'Cannot re-project kernel-based time-frequency cortical maps.';
            bst_report('Error', 'process_project_sources', ResultsFile{iRes}, errMsg);
            continue;
        elseif isempty(ResMat.SurfaceFile) && ~isempty(ResMat.DataFile)
            ResAssocMat = in_bst_results(ResMat.DataFile, 0, 'SurfaceFile');
            ResMat.SurfaceFile = ResAssocMat.SurfaceFile;
        end
    else
        ResMat = in_bst_results(ResultsFile{iRes}, 0, 'SurfaceFile');
    end
    % Associated surface not defined: error
    if isempty(ResMat.SurfaceFile)
        errMsg = 'Associated surface file is not defined.';
        bst_report('Error', 'process_project_sources', ResultsFile{iRes}, errMsg);
        continue;
    end
    % Check that it is not the destination surface
    if file_compare(ResMat.SurfaceFile, destSurfFile)
        if isInteractive
            disp(['BST> WARNING: Source and destination surfaces are the same for file: ' ResultsFile{iRes}]);
        else
            errMsg = 'Source and destination surfaces are the same for file';
            bst_report('Error', 'process_project_sources', ResultsFile{iRes}, errMsg);
        end
        continue;
    end
    % Look for surface filename in SurfaceGroups
    iGroup = find(file_compare(ResMat.SurfaceFile, SurfaceGroups));
    % If does not exist yet: create it
    if isempty(iGroup)
        nGroup = nGroup + 1;
        SurfaceGroups{nGroup} = ResMat.SurfaceFile;
        ResultsGroups{nGroup} = ResultsFile(iRes);
    % Group exist: add file to the group
    else
        ResultsGroups{nGroup}{end+1} = ResultsFile{iRes};
    end
    % Check if it is a kernel-only file
    if isempty(strfind(ResultsFile{iRes}, '_KERNEL_'))
        isKernelOnly = 0;
    end
end
% If destination surface = source surface for all files
if (nGroup == 0)
    if isempty(errMsg)
        errMsg = ['Source and destination surfaces are the same for all the selected files.' 10 'Nothing to project...'];
    end   
    if isInteractive
        bst_error(errMsg, 'Project sources', 0);
        bst_progress('stop');
    else
        bst_report('Error', 'process_project_sources', ResultsFile, errMsg);
    end
    return;
end
% Get protocol folders
ProtocolInfo = bst_get('ProtocolInfo');


%% ===== ABSOLUTE VALUES =====
% Absolute values
if isKernelOnly || isTimefreq
    isAbsoluteValues = 0;
elseif isempty(isAbsoluteValues)
    % Ask user if the interpolation is supposed to be done in absolute values
    res = java_dialog('question', ['Use absolute or relative values for the interpolation ?' 10 10 ...
                      'Unless you know exactly what you are doing, click on "Absolute".' 10 10], ...
                      'Project on default anatomy', [], {'Absolute', 'Relative', 'Cancel'}, 'Absolute');
    if isempty(res) || strcmpi(res, 'Cancel')
        bst_progress('stop');
        return
    elseif strcmpi(res, 'Absolute')
        isAbsoluteValues = 1;
    else
        isAbsoluteValues = 0;
    end
end


%% ===== PROJECT SOURCES =====
isFirstWrnAbsVal = 1;
isStopWarped = [];
iUpdatedStudies = [];
% Process each surface group
for iGroup = 1:nGroup
    % ===== GET SURFACES =====
    if isInteractive
        bst_progress('start', 'Project sources', 'Loading surfaces...');
    end
    % Load source surface file
    srcSurfFile = SurfaceGroups{iGroup};
    srcSurfMat  = in_tess_bst(srcSurfFile);
    % Load destination surface file
    destSurfMat = in_tess_bst(destSurfFile);
    % Get source and destination subjects
    sSrcSubj  = bst_get('SurfaceFile', srcSurfFile);
    sDestSubj = bst_get('SurfaceFile', destSurfFile);
    % Number of vertices
    nSrc  = size(srcSurfMat.Vertices, 1);
    nDest = size(destSurfMat.Vertices, 1);
    % Source subject and destination subject are the same
    isSameSubject = file_compare(sSrcSubj.FileName, sDestSubj.FileName);
    % Check if source or destination are the default anatomy
    isSrcDefaultSubj  = strcmp(bst_fileparts(sSrcSubj.FileName), bst_get('DirDefaultSubject'));
    isDestDefaultSubj = strcmp(bst_fileparts(sDestSubj.FileName), bst_get('DirDefaultSubject'));
    % Signature string for the current transformation
    Signature = sprintf('%s%d=>%s%d', srcSurfFile, length(srcSurfMat.Vertices), destSurfFile, length(destSurfMat.Vertices));
    % Initialize interpolation matrix
    Wmat = [];
    isSaveInterp = 1;
    
    % ===== RE-USE PREVIOUS INTERPOLATION =====
    % Try to get an existing valid interpolation matrix
    if isempty(Wmat) && isfield(srcSurfMat, 'tess2tess_interp') && all(isfield(srcSurfMat.tess2tess_interp, {'Signature', 'Wmat'})) && ...
            strcmpi(srcSurfMat.tess2tess_interp.Signature, Signature) && ~isempty(srcSurfMat.tess2tess_interp.Wmat)
        Wmat = srcSurfMat.tess2tess_interp.Wmat;
        % Do not save this interpolation matrix, it's already saved
        isSaveInterp = 0;
    end
    
    % ===== CHECK IF WARPED =====
    % If projecting a warped subject back on the original brain: NOT necessary
    if isempty(Wmat) && ~isempty(strfind(srcSurfFile, '_warped')) && ~isSrcDefaultSubj && isDestDefaultSubj && (nSrc == nDest)
        % Warning message
        warnMsg = ['The source files were computed on a warped anatomy, there is' 10 ...
                   'no need to re-project them on the default anatomy, you can directly' 10 ...
                   'calculate average or differences across subjects.'];
        % Ask user to cancel the process
        if isempty(isStopWarped)
            if isInteractive
                isStopWarped = ~java_dialog('confirm', [warnMsg 10 10 'Project sources anyways?'], 'Project sources');
                if isStopWarped
                    bst_progress('stop');
                    return;
                end
            elseif ~isInteractive
                isStopWarped = 0;
                bst_report('Warning', 'process_project_sources', ResultsFile, warnMsg);
            end
        end
        % Interpolation matrix: Use an identity matrix
        Wmat = speye(nDest,nSrc);
        % Do not save this interpolation matrix, it's really not necessary
        isSaveInterp = 0;
    end

    % ===== USE FREESURFER SPHERES =====
    % If the registered spheres are available in both surfaces
    if isempty(Wmat) && isfield(srcSurfMat, 'Reg') && isfield(srcSurfMat.Reg, 'Sphere') && isfield(srcSurfMat.Reg.Sphere, 'Vertices') && ~isempty(srcSurfMat.Reg.Sphere.Vertices) && ...
       isfield(destSurfMat, 'Reg') && isfield(destSurfMat.Reg, 'Sphere') && isfield(destSurfMat.Reg.Sphere, 'Vertices') && ~isempty(destSurfMat.Reg.Sphere.Vertices)
        % Evaluate number of vertices to use
        nbNeighbors = 8;
        % Allocate interpolation matrix
        Wmat = spalloc(nDest, nSrc, nbNeighbors * nDest);
        % Split hemispheres
        [rHsrc, lHsrc, isConnected(1)]  = tess_hemisplit(srcSurfMat);
        [rHdest,lHdest, isConnected(2)] = tess_hemisplit(destSurfMat);
        % Get vertices
        srcVert  = double(srcSurfMat.Reg.Sphere.Vertices);
        destVert = double(destSurfMat.Reg.Sphere.Vertices);
        % If hemispheres are connected: process all at once
        if any(isConnected)
            rHsrc  = 1:nSrc;
            rHdest = 1:nDest;
            lHsrc  = [];
            lHdest = [];
        end
        % Re-interpolate using the sphere and the shepards algorithm
        WmatTmp = bst_shepards(destVert(rHdest,:), srcVert(rHsrc,:), nbNeighbors, 0);
        Wmat(rHdest,rHsrc) = WmatTmp;
        if ~isempty(lHdest)
            WmatTmp = bst_shepards(destVert(lHdest,:), srcVert(lHsrc,:), nbNeighbors, 0);
            Wmat(lHdest,lHsrc) = WmatTmp;
        end
    end
    
    % ===== DEFAULT METHOD: BAD =====
    % Else: Compute interpolation matrix
    if isempty(Wmat)
        % Close all figures
        bst_memory('UnloadAll', 'Forced');
        % === GET FIDUCIALS ===
        % Fiducials 3D positions are saved in the subject's MRI structure
        if ~isempty(sSrcSubj.Anatomy) && ~isempty(sDestSubj.Anatomy)
            % Get MRI filenames
            srcMriFile  = bst_fullfile(ProtocolInfo.SUBJECTS,  sSrcSubj.Anatomy(sSrcSubj.iAnatomy).FileName);
            destMriFile = bst_fullfile(ProtocolInfo.SUBJECTS, sDestSubj.Anatomy(sDestSubj.iAnatomy).FileName);
            % Load NCS structures from MRIs (contains the fiducials AC,PC,IH)
            srcMri  = load(srcMriFile,  'NCS', 'SCS');
            destMri = load(destMriFile, 'NCS', 'SCS');
            % Check NCS and SCS fields
            isMissingSrc = ~isfield(srcMri,  'NCS') || ~all(isfield(srcMri.NCS,  {'AC','PC','IH'}))    || isempty(srcMri.NCS.AC)   || isempty(srcMri.NCS.PC)  || isempty(srcMri.NCS.IH) || ...
                           ~isfield(srcMri,  'SCS') || ~all(isfield(srcMri.SCS,  {'NAS','LPA','RPA'})) || isempty(srcMri.SCS.NAS)  || isempty(srcMri.SCS.LPA) || isempty(srcMri.SCS.RPA);
            isMissingDest = ~isfield(destMri,  'NCS') || ~all(isfield(destMri.NCS,  {'AC','PC','IH'}))    || isempty(destMri.NCS.AC)   || isempty(destMri.NCS.PC)  || isempty(destMri.NCS.IH) || ...
                            ~isfield(destMri,  'SCS') || ~all(isfield(destMri.SCS,  {'NAS','LPA','RPA'})) || isempty(destMri.SCS.NAS)  || isempty(destMri.SCS.LPA) || isempty(destMri.SCS.RPA);
            % If missing SOURCE fiducials
            if isMissingSrc && ~file_compare(srcMriFile, destMriFile)
                if isInteractive
                    isStop = java_dialog('confirm', ['Warning: some fiducial points have not been marked on the source MRI.' 10 ... 
                                                     'Without those fiducials, the projection will be much less accurate.' 10 10 ...
                                                     'Start MRI Viewer and define those points now ?'], 'Project sources');
                    % Stop and start MRI Viewer
                    if isStop
                        view_mri(srcMriFile, 'EditMri');
                        return
                    end
                else
                    bst_report('Error', 'process_project_sources', ResultsFile, 'Some fiducial points have not been marked on the source MRI.');
                    return
                end
            end
            % If missing DESTINATION fiducials
            if isMissingDest && ~file_compare(srcMriFile, destMriFile)
                if isInteractive
                    isStop = java_dialog('confirm', ['Warning: some fiducial points have not been marked on the destination MRI.' 10 ... 
                                                     'Without those fiducials, the projection will be much less accurate.' 10 10 ...
                                                     'Start MRI Viewer and define those points now ?'], 'Project sources');
                    % Stop and start MRI Viewer
                    if isStop
                        view_mri(destMriFile, 'EditMri');
                        return
                    end
                else
                    bst_report('Error', 'process_project_sources', ResultsFile, 'Some fiducial points have not been marked on the destination MRI.');
                    return
                end
            end
            % If everything is set correctly
            if ~isMissingSrc && ~isMissingDest
                srcSurfMat.NCS  = srcMri.NCS;
                srcSurfMat.SCS  = srcMri.SCS;
                destSurfMat.NCS = destMri.NCS;
                destSurfMat.SCS = destMri.SCS;
            end
        else
            errMsg = 'No available MRI for source or destination subject.';
            if isInteractive
                bst_error(errMsg, 'Project sources', 0);
            else
                bst_report('Error', 'process_project_sources', ResultsFile, errMsg);
            end
            return
        end
    
        % === COMPUTE INTERPOLATION ===
        if isInteractive
            bst_progress('start', 'Project sources', 'Computing transformation...');
        end
        % Set the number of nearest neighbors to find
        %nbNeigh = 8 * ceil(length(destSurfMat.Vertices) / length(srcSurfMat.Vertices));
        nbNeigh = 8;
        % Interpolation cortex => cortex
        Wmat = tess_interp_cortex(destSurfMat, srcSurfMat, isSameSubject, nbNeigh);
    end
    
    % ===== SAVE INTERPOLATION =====
    % Save interpolation in surface file, for future use
    if isSaveInterp
        s.tess2tess_interp.Wmat      = Wmat;
        s.tess2tess_interp.Signature = Signature;
        bst_save(bst_fullfile(ProtocolInfo.SUBJECTS, srcSurfFile), s, 'v7', 1);
    end
    
    % ===== CREATE GROUP ANALYSIS SUBJECT =====
    % If src and dest subjects are not the same: create a "group analysis" subject
    if ~isSameSubject
        % Get normalized subject name
        normSubjName = bst_get('NormalizedSubjectName');
        % Try to get normalized subject
        [sNormSubj, iNormSubj] = bst_get('Subject', normSubjName, 1);
        % If normalized subject does not exist: create it
        if isempty(sNormSubj)
            % Create subject (uses default anatomy)
            [sNormSubj, iNormSubj] = db_add_subject(normSubjName, [], 1, 1);
        end
    end
    
    % ===== PROCESS EACH FILE =====
    nFile = length(ResultsGroups{iGroup});
    if isInteractive
        bst_progress('start', 'Project sources', 'Projecting sources...', 0, nFile);
    end
    % Process each results file in group
    for iFile = 1:nFile
        % Progress bar
        ResultsFile = ResultsGroups{iGroup}{iFile};
        if isInteractive
            bst_progress('text', ['Processing file: "' ResultsFile '"']);
            bst_progress('inc', 1);
        end
        
        % ===== OUTPUT STUDY =====
        % Get source study
        [sSrcStudy, iSrcStudy] = bst_get('AnyFile', ResultsFile);
        % If result has to be save in "group analysis" subject
        if ~isSameSubject
            % Get condition
            [sDestStudy, iDestStudy] = bst_get('StudyWithCondition', [sNormSubj.Name '/' sSrcStudy.Condition{1}]);
            % Create condition if doesnt exist
            if isempty(iDestStudy)
                iDestStudy = db_add_condition(sNormSubj.Name, sSrcStudy.Condition{1}, 0);
                if isempty(iDestStudy)
                    error(['Cannot create condition: "' normSubjName '/' sSrcStudy.Condition{1} '".']);
                end
                sDestStudy = bst_get('Study', iDestStudy);
            end
        % Else: use the source study as output study
        else
            sDestStudy = sSrcStudy;
            iDestStudy = iSrcStudy;
        end

        % ===== PROCESS SOURCES =====
        if isTimefreq
            ResultsMat = in_bst_timefreq(ResultsFile, 0);
            ResFile = ResultsFile;
            % Load related source file
            if ~isempty(ResultsMat.DataFile)
                [AssociateMat,AssociateFile] = in_bst_results(ResultsMat.DataFile, 0, 'HeadModelType');
                ResultsMat.HeadModelType = AssociateMat.HeadModelType;
            end
        % Z-scored files: force to read full file
        elseif ~isempty(strfind(ResultsFile, '_zscore'))
            [ResultsMat,ResFile] = in_bst_results(ResultsFile, 1);
        % Other files: read kernel only
        else 
            [ResultsMat,ResFile] = in_bst_results(ResultsFile, 0);
        end
        % Translate DataFile to a relative path
        if ~isempty(ResultsMat.DataFile)
            ResultsMat.DataFile = file_short(ResultsMat.DataFile);
        end
        % Add the HeadModelType if it is not present
        if ~isfield(ResultsMat, 'HeadModelType') || isempty(ResultsMat.HeadModelType)
            ResultsMat.HeadModelType = 'surface';
        % Else : Check the type of grid (skip volume head models)
        elseif ismember(ResultsMat.HeadModelType, {'volume', 'dba'})
            wrnMsg = ['Volumic head model: Skipping file "' ResultsFile '"...'];
            if isInteractive
                disp(wrnMsg);
            else
                bst_report('Error', 'process_project_sources', ResultsFile, wrnMsg);
            end
            continue;
        % Else : Check if the file was reprojected on an atlas
        elseif isfield(ResultsMat, 'Atlas') && ~isempty(ResultsMat.Atlas)
            wrnMsg = ['Cannot process atlas-based source files: Skipping file "' ResultsFile '"...'];
            if isInteractive
                disp(wrnMsg);
            else
                bst_report('Error', 'process_project_sources', ResultsFile, wrnMsg);
            end
            continue;
        end

        % Time-freq files
        if isTimefreq
            % APPLY INTERPOPLATION MATRIX
            tmpTF = zeros(size(Wmat,1), size(ResultsMat.TF,2), size(ResultsMat.TF,3));
            for iFreq = 1:size(ResultsMat.TF,3)
                tmpTF(:,:,iFreq) = Wmat * ResultsMat.TF(:,:,iFreq);
            end
            ResultsMat.TF = tmpTF;
            % PAC: Apply interpolation to all measures
            if isfield(ResultsMat, 'sPAC') && ~isempty(ResultsMat.sPAC)
                if isfield(ResultsMat.sPAC, 'NestingFreq') && ~isempty(ResultsMat.sPAC.NestingFreq)
                    ResultsMat.sPAC.NestingFreq = Wmat * ResultsMat.sPAC.NestingFreq;
                end
                if isfield(ResultsMat.sPAC, 'NestedFreq') && ~isempty(ResultsMat.sPAC.NestedFreq)
                    ResultsMat.sPAC.NestedFreq = Wmat * ResultsMat.sPAC.NestedFreq;
                end
                if isfield(ResultsMat.sPAC, 'PhasePAC') && ~isempty(ResultsMat.sPAC.PhasePAC)
                    ResultsMat.sPAC.PhasePAC = Wmat * ResultsMat.sPAC.PhasePAC;
                end
                if isfield(ResultsMat.sPAC, 'DirectPAC') && ~isempty(ResultsMat.sPAC.DirectPAC)
                    tmpTF = zeros(size(Wmat,1), size(ResultsMat.sPAC.DirectPAC,2), size(ResultsMat.sPAC.DirectPAC,3), size(ResultsMat.sPAC.DirectPAC,4));
                    for iLow = 1:size(ResultsMat.sPAC.DirectPAC,3)
                        for iHigh = 1:size(ResultsMat.sPAC.DirectPAC,4)
                            tmpTF(:,:,iLow,iHigh) = Wmat * ResultsMat.sPAC.DirectPAC(:,:,iLow,iHigh);
                        end
                    end
                    ResultsMat.sPAC.DirectPAC = tmpTF;
                end
            end
            % Remove link with original file
            ResultsMat.DataFile = [];
            % Change number of sources
            ResultsMat.RowNames = 1:size(ResultsMat.TF,1);
            
        % Data matrix : FULL RESULTS
        elseif isfield(ResultsMat, 'ImageGridAmp') && ~isempty(ResultsMat.ImageGridAmp)
            % Absolute values ?
            if isAbsoluteValues
                resMat = double(abs(ResultsMat.ImageGridAmp));
            else
                resMat = double(ResultsMat.ImageGridAmp);
            end
            % APPLY INTERPOPLATION MATRIX
            ResultsMat.ImageGridAmp = muliplyInterp(Wmat, resMat, ResultsMat.nComponents);
            ResultsMat.ImagingKernel = [];
            % Remove link with original file
            ResultsMat.DataFile = [];
            
        % KERNEL ONLY
        elseif isfield(ResultsMat, 'ImagingKernel') && ~isempty(ResultsMat.ImagingKernel)
            % Absolute values ?
            if isAbsoluteValues && isFirstWrnAbsVal 
                java_dialog('warning', ['Cannot project inversion kernel in absolute values.' 10 10 '"Absolute" directive ignored.'], 'Project sources');
                isFirstWrnAbsVal = 0;
            end
            % APPLY INTERPOPLATION MATRIX
            ResultsMat.ImageGridAmp = [];
            ResultsMat.ImagingKernel = muliplyInterp(Wmat, double(ResultsMat.ImagingKernel), ResultsMat.nComponents);
        else
            error(['Invalid recordings file: "' strrep(ResultsFile, '\', '\\') '".']);
        end
        
        % === SAVE NEW RESULTS ===
        % Get source filename
        [tmp__, oldBaseName] = bst_fileparts(ResFile);
        % Prepare structure to be saved
        ResultsMat.SurfaceFile = destSurfFile;
        if ~isSameSubject
            ResultsMat.Comment = [sSrcSubj.Name '/' ResultsMat.Comment];
            newResultsFile = sprintf('%s_%s.mat', oldBaseName, file_standardize(sSrcSubj.Name));
        else
            ResultsMat.Comment = [ResultsMat.Comment ' | ' destSurfMat.Comment];
            newResultsFile = sprintf('%s_%dV.mat', oldBaseName, length(destSurfMat.Vertices));
        end
        % Surface file
        ResultsMat.SurfaceFile = file_win2unix(destSurfFile);
        % History: project source
        ResultsMat = bst_history('add', ResultsMat, 'project', ['Project sources: ' srcSurfFile ' => ' ResultsMat.SurfaceFile]);
        % Build full filename
        newResultsFileFull = bst_fullfile(ProtocolInfo.STUDIES, bst_fileparts(sDestStudy.FileName), newResultsFile);    
        newResultsFileFull = file_unique(newResultsFileFull);
        newResultsFile = file_short(newResultsFileFull);
        % Save new results file
        bst_save(newResultsFileFull, ResultsMat, 'v6');

        % === ADD FILE IN DATABASE ===
        % Create Results/Timefreq structure for database
        if isTimefreq
            sNewResults = db_template('Timefreq');
            sNewResults.FileName = newResultsFile;
            sNewResults.Comment  = ResultsMat.Comment;
            sNewResults.DataFile = ResultsMat.DataFile;
            sNewResults.DataType = ResultsMat.DataType;
            % If filename already exists in this study
            iExistingRes = find(file_compare({sDestStudy.Timefreq.FileName}, newResultsFile));
            if ~isempty(iExistingRes)
                % Replace previous Results
                sDestStudy.Timefreq(iExistingRes) = sNewResults;
            else
                % Add new result
                sDestStudy.Timefreq(end + 1) = sNewResults;
            end
        else
            sNewResults = db_template('Results');
            sNewResults.FileName = newResultsFile;
            sNewResults.Comment  = ResultsMat.Comment;
            sNewResults.DataFile = ResultsMat.DataFile;
            sNewResults.isLink   = 0;
            sNewResults.HeadModelType = ResultsMat.HeadModelType;
            % If filename already exists in this study
            iExistingRes = find(file_compare({sDestStudy.Result.FileName}, newResultsFile));
            if ~isempty(iExistingRes)
                % Replace previous Results
                sDestStudy.Result(iExistingRes) = sNewResults;
            else
                % Add new result
                sDestStudy.Result(end + 1) = sNewResults;
            end
        end
        % Update study in database
        bst_set('Study', iDestStudy, sDestStudy);
        iUpdatedStudies = [iUpdatedStudies, iDestStudy];
        % Add to list of returned files
        OutputFiles{end+1} = newResultsFile;
    end
end


%% ===== UDPATE DISPLAY =====
if isInteractive
    bst_progress('stop');
end
if isempty(OutputFiles)
    return;
end
% Update tree display
panel_protocols('UpdateTree');

% Update node
panel_protocols('UpdateNode', 'Study', unique(iUpdatedStudies));
% Select first output study
panel_protocols('SelectStudyNode', iUpdatedStudies(1));
% Save database
db_save();


end



%% ===== APPLY INTERPOLATION MATRIX =====
function B = muliplyInterp(W, A, nComp)
    switch (nComp)
        case 1
            B = double(W * A);
        case 2
            B = zeros(2 * size(W,1), size(A,2));
            B(1:2:end,:) = double(W * A(1:2:end,:));
            B(2:2:end,:) = double(W * A(2:2:end,:));
        case 3
            B = zeros(3 * size(W,1), size(A,2));
            B(1:3:end,:) = double(W * A(1:3:end,:));
            B(2:3:end,:) = double(W * A(2:3:end,:));
            B(3:3:end,:) = double(W * A(3:3:end,:));
    end
    B = double(B);
end




