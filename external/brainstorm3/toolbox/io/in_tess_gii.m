function TessMat = in_tess_gii(TessFile)
% IN_TESS_GII: Import GIfTI/BrainVisa .gii tessellation files.
%
% USAGE:  TessMat = in_tess_gii(TessFile);
%
% INPUT: 
%     - TessFile : full path to a tesselation file
% OUTPUT:
%     - TessMat:  Brainstorm tesselation structure
%
% SEE ALSO: in_tess

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

import sun.misc.BASE64Decoder;

% Initialize returned value
TessMat = struct('Vertices', [], 'Faces', []);
% Read XML file
sXml = in_xml(TessFile);
% For each data entry
for iArray = 1:length(sXml.GIFTI.DataArray)
    % Read the file
    switch sXml.GIFTI.DataArray(iArray).Encoding
        case 'ASCII'
            value = str2num(sXml.GIFTI.DataArray(iArray).Data.text);
        case {'Base64Binary', 'GZipBase64Binary'}
            % Base64 decoding
            decoder = BASE64Decoder();
            value = decoder.decodeBuffer(sXml.GIFTI.DataArray(iArray).Data.text);
            % Unpack gzipped stream
            if strcmpi(sXml.GIFTI.DataArray(iArray).Encoding, 'GZipBase64Binary')
                value = dunzip(value);
            end
            % Cast to the required type of data
            switch (sXml.GIFTI.DataArray(iArray).DataType)
                case 'NIFTI_TYPE_UINT8',   DataType = 'uint8';
                case 'NIFTI_TYPE_INT16',   DataType = 'int16';   
                case 'NIFTI_TYPE_INT32',   DataType = 'int32';
                case 'NIFTI_TYPE_FLOAT32', DataType = 'single';
                case 'NIFTI_TYPE_FLOAT64', DataType = 'double';
            end
            value = typecast(value, DataType);
    end
    % Reshape to target dimensions
    sizeValue = [str2double(sXml.GIFTI.DataArray(iArray).Dim1), str2double(sXml.GIFTI.DataArray(iArray).Dim0)];
    value = reshape(value, sizeValue)';
    % Identify type
    switch (sXml.GIFTI.DataArray(iArray).Intent)
        case 'NIFTI_INTENT_POINTSET'
            TessMat.Vertices = value ./ 1000;
        case 'NIFTI_INTENT_TRIANGLE'
            TessMat.Faces = value + 1;
    end
end





