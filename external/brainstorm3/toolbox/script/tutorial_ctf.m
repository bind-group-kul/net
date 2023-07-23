% TUTORIAL_CTF: Run all the scripts related to tutorial CTF.
% Use this script to validate a Brainstorm installation

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
% Authors: Francois Tadel, 2010-2012

disp([10 '===== BRAINSTORM SELF-VALIDATION: TUTORIAL CTF =====' 10]);

try
    disp([10 '===== TUTORIAL 3/10 =====']);
    tutorial_03_anatomy
    bst_memory('UnloadAll', 'Forced');
    
    disp([10 '===== TUTORIAL 4/10 =====']);
    tutorial_04_recordings
    bst_memory('UnloadAll', 'Forced');
    
    disp([10 '===== TUTORIAL 5/10 =====']);
    tutorial_05_exploration
    bst_memory('UnloadAll', 'Forced');

    disp([10 '===== TUTORIAL 6/10 =====']);
    tutorial_06_headmodel
    bst_memory('UnloadAll', 'Forced');
    
    disp([10 '===== TUTORIAL 7/10 =====']);
    tutorial_07_noisecov
    bst_memory('UnloadAll', 'Forced');
    
    disp([10 '===== TUTORIAL 8/10 =====']);
    tutorial_08_sources
    bst_memory('UnloadAll', 'Forced');
    
    disp([10 'Brainstorm validation: ok.' 10]);
catch
    bst_error();
    disp([10 'Brainstorm validation: failed.' 10]);
end





