function [sAllAtlas, Messages] = import_label(SurfaceFile, LabelFiles, isNewAtlas)
% IMPORT_LABEL: Import an atlas segmentation for a given surface
% 
% USAGE: import_label(SurfaceFile, LabelFiles, isNewAtlas=1) : Add label information to SurfaceFile
%        import_label(SurfaceFile)                           : Ask the user for the label file to import

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
% Authors: Francois Tadel, 2012-2013

import sun.misc.BASE64Decoder;


%% ===== GET FILES =====
sAllAtlas = repmat(db_template('Atlas'), 0);
Messages = [];
% Parse inputs
if (nargin < 3) || isempty(isNewAtlas)
    isNewAtlas = 1;
end
if (nargin < 2) || isempty(LabelFiles)
    LabelFiles = [];
end

% CALL: import_label(SurfaceFile)
if isempty(LabelFiles)
    % Get last used folder
    LastUsedDirs = bst_get('LastUsedDirs');
    DefaultFormats = bst_get('DefaultFormats');
    % Get label files
    [LabelFiles, FileFormat] = java_getfile( 'open', ...
       'Import labels...', ...        % Window title
       LastUsedDirs.ImportAnat, ...   % Default directory
       'multiple', 'files', ...       % Selection mode
       bst_get('FileFilters', 'labelin'), ...
       DefaultFormats.LabelIn);
    % If no file was selected: exit
    if isempty(LabelFiles)
        return
    end
	% Save last used dir
    LastUsedDirs.ImportAnat = bst_fileparts(LabelFiles{1});
    bst_set('LastUsedDirs',  LastUsedDirs);
    % Save default export format
    DefaultFormats.LabelIn = FileFormat;
    bst_set('DefaultFormats',  DefaultFormats);
% CALL: import_label(SurfaceFile, LabelFiles)
else
    % Force cell input
    if ~iscell(LabelFiles)
        LabelFiles = {LabelFiles};
    end
    % Detect file format based on file extension
    [fPath, fBase, fExt] = bst_fileparts(LabelFiles{1});
    switch (fExt)
        case '.annot',  FileFormat = 'FS-ANNOT';
        case '.label',  FileFormat = 'FS-LABEL';
        case '.gii',    FileFormat = 'GII-TEX';
        case '.mat',    FileFormat = 'BST';
        case '.dfs',    FileFormat = 'DFS';
        otherwise,      Messages = 'Unknown file extension.'; return;
    end
end


%% ===== READ FILES =====
% Read destination surface
sSurf = bst_memory('GetSurface', file_short(SurfaceFile));
if isempty(sSurf)
    isLoadedHere = 1;
    sSurf = bst_memory('LoadSurface', file_short(SurfaceFile));
    panel_scout('SetCurrentSurface', sSurf.FileName);
else
    isLoadedHere = 0;
end
% Process one after the other
for iFile = 1:length(LabelFiles)
    % Get filename
    [fPath, fBase, fExt] = bst_fileparts(LabelFiles{iFile});
    % New atlas structure: use filename as the atlas name
    if isNewAtlas || isempty(sSurf.Atlas) || isempty(sSurf.iAtlas)
        sAtlas = db_template('Atlas');
        iAtlas = 'Add';
        % FreeSurfer Atlas names
        switch (fBase)
            case {'lh.aparc.a2009s', 'rh.aparc.a2009s'}
                sAtlas.Name = 'Destrieux';
            case {'lh.aparc', 'rh.aparc'}
                sAtlas.Name = 'Desikan-Killiany';
            case {'lh.BA', 'rh.BA'}
                sAtlas.Name = 'Brodmann';
            case {'lh.BA.thresh', 'rh.BA.thresh'}
                sAtlas.Name = 'Brodmann-thresh';
            case {'lh.aparc.DKTatlas40', 'rh.aparc.DKTatlas40'}
                sAtlas.Name = 'Mindboggle';
            case {'lh.PALS_B12_Brodmann', 'rh.PALS_B12_Brodmann'}
                sAtlas.Name = 'PALS-B12 Brodmann';
            case {'lh.PALS_B12_Lobes', 'rh.PALS_B12_Lobes'}
                sAtlas.Name = 'PALS-B12 Lobes';
            case {'lh.PALS_B12_OrbitoFrontal', 'rh.PALS_B12_OrbitoFrontal'}
                sAtlas.Name = 'PALS-B12 Orbito-frontal';
            case {'lh.PALS_B12_Visuotopic', 'rh.PALS_B12_Visuotopic'}
                sAtlas.Name = 'PALS-B12 Visuotopic';
            case {'lh.Yeo2011_7Networks_N1000', 'rh.Yeo2011_7Networks_N1000'}
                sAtlas.Name = 'Yeo 7 Networks';
            case {'lh.Yeo2011_17Networks_N1000', 'rh.Yeo2011_17Networks_N1000'}
                sAtlas.Name = 'Yeo 17 Networks';
            otherwise
                sAtlas.Name = fBase;
        end
    % Existing atlas structure
    else
        iAtlas = sSurf.iAtlas;
        sAtlas = sSurf.Atlas(iAtlas);
    end
    % Check that atlas have the correct structure
    if isempty(sAtlas.Scouts)
        sAtlas.Scouts = repmat(db_template('ScoutMat'), 0);
    end
    % Switch based on file format
    switch (FileFormat)
        % ===== FREESURFER ANNOT =====
        case 'FS-ANNOT'
            % === READ FILE ===
            % Read label file
            [vertices, labels, colortable] = read_annotation(LabelFiles{iFile});
            % Check sizes
            if (length(labels) ~= length(sSurf.Vertices))
                Messages = [Messages, sprintf('%s:\nNumbers of vertices in the surface (%d) and the label file (%d) do not match\n', fBase, length(sSurf.Vertices), length(labels))];
                continue
            end

            % === CONVERT TO SCOUTS ===
            % Convert to scouts structures
            lablist = unique(labels);
            % Loop on each label
            for i = 1:length(lablist)
                % Find entry in the colortable
                iTable = find(colortable.table(:,5) == lablist(i));
                % If correspondence not defined: ignore label
                if (length(iTable) ~= 1)
                    continue;
                end
                % New scout index
                iScout = length(sAtlas.Scouts) + 1;
                sAtlas.Scouts(iScout).Vertices = find(labels == lablist(i));
                sAtlas.Scouts(iScout).Label    = colortable.struct_names{iTable};
                sAtlas.Scouts(iScout).Color    = colortable.table(iTable,1:3) ./ 255;
                sAtlas.Scouts(iScout).Function = 'Mean';
                sAtlas.Scouts(iScout).Region   = 'UU';
            end
            if isempty(sAtlas.Scouts)
                Messages = [Messages, fBase, ':' 10 'Could not match labels and color table.' 10];
                continue;
            end

        % ==== FREESURFER LABEL ====
        case 'FS-LABEL'
            % === READ FILE ===
            % Read label file
            LabelMat = mne_read_label_file(LabelFiles{iFile});
            % Convert indices from 0-based to 1-based
            LabelMat.vertices = LabelMat.vertices + 1;
            % Check sizes
            if (max(LabelMat.vertices) > length(sSurf.Vertices))
                Messages = [Messages, sprintf('%s:\nNumbers of vertices in the label file (%d) exceeds the number of vertices in the surface (%d)\n', fBase, max(LabelMat.vertices), length(sSurf.Vertices))];
                continue
            end
            % === CONVERT TO SCOUTS ===
            % Convert to scouts structures
            uniqueValues = unique(LabelMat.values);
            minmax = [min(uniqueValues), max(uniqueValues)];
            % Loop on each label
            for i = 1:length(uniqueValues)
                % New scout index
                iScout = length(sAtlas.Scouts) + 1;
                % Calculate intensity [0,1]
                if (minmax(1) == minmax(2))
                    c = 0;
                else
                    c = (uniqueValues(i) - minmax(1)) ./ (minmax(2) - minmax(1));
                end
                % Create structure
                sAtlas.Scouts(iScout).Vertices = double(LabelMat.vertices(LabelMat.values == uniqueValues(i)));
                sAtlas.Scouts(iScout).Seed     = [];
                sAtlas.Scouts(iScout).Label    = num2str(uniqueValues(i));
                sAtlas.Scouts(iScout).Color    = [1 c 0];
                sAtlas.Scouts(iScout).Function = 'Mean';
                sAtlas.Scouts(iScout).Region   = 'UU';
            end
            if isempty(sAtlas.Scouts)
                Messages = [Messages, fBase, ':' 10 'Could not match labels and color table.' 10];
                continue;
            end
            
        % ==== BRAINVISA GIFTI =====
        case 'GII-TEX'
            % Remove the "L" and "R" strings from the name
            AtlasName = sAtlas.Name;
            AtlasName = strrep(AtlasName, 'R', '');
            AtlasName = strrep(AtlasName, 'L', '');
            % Read XML file
            sXml = in_xml(LabelFiles{iFile});
            % If there is more than one entry: force adding
            if (length(sXml.GIFTI.DataArray) > 1)
                iAtlas = 'Add';
            end
            % Process all the entries
            for ia = 1:length(sXml.GIFTI.DataArray)
                % Atlas name
                sAtlas(ia).Name = sprintf('%s #%d', AtlasName, ia);
                % Get data field
                switch sXml.GIFTI.DataArray(ia).Encoding
                    case 'ASCII'
                        labels = str2num(sXml.GIFTI.DataArray(ia).Data.text);
                    case {'Base64Binary', 'GZipBase64Binary'}
                        % Base64 decoding
                        decoder = BASE64Decoder();
                        labels = decoder.decodeBuffer(sXml.GIFTI.DataArray(ia).Data.text);
                        % Unpack gzipped stream
                        if strcmpi(sXml.GIFTI.DataArray(ia).Encoding, 'GZipBase64Binary')
                            labels = dunzip(labels);
                        end
                        % Cast to the required type of data
                        switch (sXml.GIFTI.DataArray(ia).DataType)
                            case 'NIFTI_TYPE_UINT8',   DataType = 'uint8';
                            case 'NIFTI_TYPE_INT16',   DataType = 'int16';   
                            case 'NIFTI_TYPE_INT32',   DataType = 'int32';
                            case 'NIFTI_TYPE_FLOAT32', DataType = 'single';
                            case 'NIFTI_TYPE_FLOAT64', DataType = 'double';
                        end
                        labels = typecast(labels, DataType);
                end
                % Check sizes
                if (length(labels) ~= length(sSurf.Vertices))
                    Messages = [Messages, sprintf('%s:\nNumbers of vertices in the surface (%d) and the label file (%d) do not match\n', fBase, length(sSurf.Vertices), length(labels))];
                    continue;
                end
                % Convert to scouts structures
                lablist = unique(labels);
                ColorTable = panel_scout('GetScoutsColorTable');
                % Loop on each label
                for i = 1:length(lablist)
                    % New scout index
                    iScout = length(sAtlas(ia).Scouts) + 1;
                    % New color
                    iColor = mod(iScout-1, length(ColorTable)) + 1;
                    % Get the vertices for this annotation
                    sAtlas(ia).Scouts(iScout).Vertices = find(labels == lablist(i));
                    sAtlas(ia).Scouts(iScout).Seed     = [];
                    sAtlas(ia).Scouts(iScout).Label    = num2str(lablist(i));
                    sAtlas(ia).Scouts(iScout).Color    = ColorTable(iColor,:);
                    sAtlas(ia).Scouts(iScout).Function = 'Mean';
                    sAtlas(ia).Scouts(iScout).Region   = 'UU';
                end
            end
            
        % ===== MRI VOLUMES =====
        case 'MRI-MASK'
            % Read MRI volume
            sMriMask = in_mri(LabelFiles{iFile});
            sMriMask.Cube = double(sMriMask.Cube);
            % Get al the values in the MRI
            allValues = unique(sMriMask.Cube);
            % If values are not integers, it is not a mask or an atlas: it has to be binarized first
            if any(allValues ~= round(allValues))
                % Warning: not a binary mask
                isConfirm = java_dialog('confirm', ['Warning: This is not a binary mask.' 10 'Try to import this MRI as a surface anyway?'], 'Import binary mask');
                if ~isConfirm
                    TessMat = [];
                    return;
                end
                % Analyze MRI histogram
                Histogram = mri_histogram(sMriMask.Cube);
                % Binarize based on background level
                sMriMask.Cube = (sMriMask.Cube > Histogram.bgLevel);
                allValues = [0,1];
            end
            % Skip the first value (background)
            allValues(1) = [];
            % Load the subject SCS coordinates
            sSubject = bst_get('SurfaceFile', SurfaceFile);
            sMriSubj = in_mri_bst(sSubject.Anatomy(sSubject.iAnatomy).FileName);
            % Check the compatibility of MRI sizes
            if ~isequal(size(sMriSubj.Cube), size(sMriMask.Cube))
                Messages = [Messages, 'Error: The selected MRI file does not match the size of the subject''s MRI.'];
                return;
            end
            % Converting the sSurf vertices to MRI
            vertMri = cs_scs2mri(sMriSubj, sSurf.Vertices' * 1000)';
            vertMri = round(bst_bsxfun(@rdivide, vertMri, sMriSubj.Voxsize));
            indMri = sub2ind(size(sMriSubj.Cube), ...
                        bst_saturate(vertMri(:,1), [1, size(sMriSubj.Cube,1)]), ...
                        bst_saturate(vertMri(:,2), [1, size(sMriSubj.Cube,2)]), ...
                        bst_saturate(vertMri(:,3), [1, size(sMriSubj.Cube,3)]));
            % Get scouts colortable
            ColorTable = panel_scout('GetScoutsColorTable');
            % Generate a tesselation for all the others
            for i = 1:length(allValues)
                % Get the binary mask of the current region
                mask = (sMriMask.Cube == allValues(i));
                % Dilate mask
                mask = mri_dilate(mask);
                mask = mri_dilate(mask);
                % Get the vertices in this mask
                scoutVertices = find(mask(indMri));
                if isempty(scoutVertices)
                    continue;
                end
                % New scout index
                iScout = length(sAtlas.Scouts) + 1;
                % New color
                iColor = mod(iScout-1, length(ColorTable)) + 1;
                % Get the vertices for this annotation
                sAtlas.Scouts(iScout).Vertices = scoutVertices;
                sAtlas.Scouts(iScout).Seed     = [];
                sAtlas.Scouts(iScout).Label    = num2str(allValues(i));
                sAtlas.Scouts(iScout).Color    = ColorTable(iColor,:);
                sAtlas.Scouts(iScout).Function = 'Mean';
                sAtlas.Scouts(iScout).Region   = 'UU';
            end

        % ===== BRAINSTORM SCOUTS =====
        case 'BST'
            % Load file
            ScoutMat = load(LabelFiles{iFile});
            % Convert old scouts structure to new one
            if isfield(ScoutMat, 'Scout')
                ScoutMat.Scouts = ScoutMat.Scout;
            elseif isfield(ScoutMat, 'Scouts')
                % Ok
            else
                Messages = [Messages, fBase, ':' 10 'Invalid scouts file.' 10];
                continue;
            end
            % Check the number of vertices
            if (length(sSurf.Vertices) ~= ScoutMat.TessNbVertices)
                Messages = [Messages, sprintf('%s:\nNumbers of vertices in the surface (%d) and the scout file (%d) do not match\n', fBase, length(sSurf.Vertices), ScoutMat.TessNbVertices)];
                continue;
            end
            % If name is not defined: use the filename
            if isNewAtlas
                if isfield(ScoutMat, 'Name') && ~isempty(ScoutMat.Name)
                    sAtlas.Name = ScoutMat.Name;
                else
                    [fPath,fBase] = bst_fileparts(LabelFiles{iFile});
                    sAtlas.Name = strrep(fBase, 'scout_', '');
                end
            end
            % Copy the new scouts
            for i = 1:length(ScoutMat.Scouts)
                iScout = length(sAtlas.Scouts) + 1;
                sAtlas.Scouts(iScout).Vertices = ScoutMat.Scouts(i).Vertices;
                sAtlas.Scouts(iScout).Seed     = ScoutMat.Scouts(i).Seed;
                sAtlas.Scouts(iScout).Color    = ScoutMat.Scouts(i).Color;
                sAtlas.Scouts(iScout).Label    = ScoutMat.Scouts(i).Label;
                sAtlas.Scouts(iScout).Function = ScoutMat.Scouts(i).Function;
                if isfield(ScoutMat.Scouts(i), 'Region')
                    sAtlas.Scouts(iScout).Region = ScoutMat.Scouts(i).Region; 
                else
                    sAtlas.Scouts(iScout).Region = 'UU';
                end
            end

        % ===== BrainSuite/SVReg surface file =====
        case 'DFS'
            % === READ FILE ===
            [VertexLabelIds, labelMap] = in_label_bs(LabelFiles{iFile});

            % === CONVERT TO SCOUTS ===
            % Convert to scouts structures
            lablist = unique(VertexLabelIds);
            sAtlas.Name = 'SVReg';

            % Loop on each label
            for i = 1:length(lablist)
                % Find label ID
                id = lablist(i);
                % Skip if label id is not in labelMap
                if ~labelMap.containsKey(num2str(id))
                    continue;
                end
                entry = labelMap.get(num2str(id));
                labelInfo.Name = entry(1);
                labelInfo.Color = entry(2);
                % Skip the "background" scout
                if strcmpi(labelInfo.Name, 'background')
                    continue;
                end
                % New scout index
                iScout = length(sAtlas.Scouts) + 1;
                sAtlas.Scouts(iScout).Vertices = find(VertexLabelIds == id);
                sAtlas.Scouts(iScout).Label    = labelInfo.Name;
                sAtlas.Scouts(iScout).Color    = labelInfo.Color;
                sAtlas.Scouts(iScout).Function = 'Mean';
                sAtlas.Scouts(iScout).Region   = 'UU';
            end
            if isempty(sAtlas.Scouts)
                Messages = [Messages, fBase, ':' 10 'Could not match vertex labels and label description file.' 10];
                continue;
            end

        % ===== Unknown file =====
        otherwise
            Messages = [Messages, fBase, ':' 10 'Unknown file extension.' 10];
            continue;
    end
    
    % Loop on all the loaded atlases
    for ia = 1:length(sAtlas)
        % Brodmann atlas: remove the "Unknown" scout
        iUnknown = find(strcmpi({sAtlas(ia).Scouts.Label}, 'unknown') | strcmpi({sAtlas(ia).Scouts.Label}, 'medial.wall') | strcmpi({sAtlas(ia).Scouts.Label}, 'freesurfer_defined_medial_wall'));
        if ~isempty(iUnknown)
            sAtlas(ia).Scouts(iUnknown) = [];
        end
        % Fix all the scouts seeds and identify regions
        for i = 1:length(sAtlas(ia).Scouts)
            if isempty(sAtlas(ia).Scouts(i).Seed) || ~ismember(sAtlas(ia).Scouts(i).Seed, sAtlas(ia).Scouts(i).Vertices)
                sAtlas(ia).Scouts(i) = panel_scout('SetScoutsSeed', sAtlas(ia).Scouts(i), sSurf.Vertices);
            end
            if isempty(sAtlas(ia).Scouts(i).Region) || strcmpi(sAtlas(ia).Scouts(i).Region, 'UU')
                sAtlas(ia).Scouts(i) = tess_detect_region(sAtlas(ia).Scouts(i));
            end
        end
        % Sort scouts by alphabetical order
        [tmp,I] = sort(lower({sAtlas(ia).Scouts.Label}));
        sAtlas(ia).Scouts = sAtlas(ia).Scouts(I);
        % Return new atlas
        sAllAtlas(end+1) = sAtlas(ia);
        % Add atlas to the surface
        panel_scout('SetAtlas', SurfaceFile, iAtlas, sAtlas(ia));
    end
end


%% ===== SAVE IN SURFACE =====
% Unload surface to save it
if isLoadedHere
    bst_memory('UnloadSurface', SurfaceFile);
end



