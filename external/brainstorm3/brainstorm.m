function varargout = brainstorm( varargin )
% BRAINSTORM: Brainstorm startup function. 
%
% USAGE: brainstorm              : Start Brainstorm
%        brainstorm start        : Start Brainstorm
%        brainstorm nogui        : Start brainstorm without interface
%        brainstorm stop         : Stop Brainstorm
%        brainstorm reset        : Re-inialize Brainstorm (delete preferences and database)
%        brainstorm kinect       : Use a Microsoft Kinect to generate a head shape
%        brainstorm digitize     : Digitize points using a Polhemus system
%        brainstorm setpath      : Add Brainstorm subdirectories to current path
%        brainstorm startjava    : Add Brainstorm Java classes to dynamic classpath
%        brainstorm info         : Open Brainstorm website
%        brainstorm license      : Displays license agreement window
%        brainstorm update       : Download and install latest Brainstorm update
%        brainstorm validate_ctf : Runs all the CTF tutorials to check that everything is working
%        brainstorm validate_fif : Runs the tutorial_neuromag script, that processes some Neuromag recordings
%        brainstorm validate_raw : Runs the tutorial_raw script, that tests the process interface
%        brainstorm deploy       : Create a zip file for distribution (see bst_deploy for options)
%        brainstorm deploy 1     : Compile the current version of Brainstorm with Matlab mcc compiler
%  res = brainstorm('status')    : Return brainstorm status (1=running, 0=stopped)

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
% Authors: Francois Tadel, 2008-2014

% Make sure that "more" is off
more off

% Compiled version
if exist('isdeployed', 'builtin') && isdeployed
    BrainstormHomeDir = fileparts(fileparts(which(mfilename)));
    %disp(['Running from: ' BrainstormHomeDir]);
else
    % Assume we are in the Brainstorm folder
    BrainstormHomeDir = fileparts(which(mfilename));
    % Add path to "core" and "io" subfolders
    corePath = fullfile(BrainstormHomeDir, 'toolbox', 'core');
    if ~exist(corePath, 'dir')
        error(['Unable to find ' corePath ' directory.']);
    end
    addpath(corePath);
    addpath(fullfile(BrainstormHomeDir, 'toolbox', 'io'));
    addpath(fullfile(BrainstormHomeDir, 'toolbox', 'misc'));
end

% Set dynamic JAVA CLASS PATH
if ~exist('org.brainstorm.tree.BstNode', 'class')
    % Add Brainstorm JARs to classpath
    javaaddpath([BrainstormHomeDir '/java/RiverLayout.jar']);
    javaaddpath([BrainstormHomeDir '/java/brainstorm.jar']);
    javaaddpath([BrainstormHomeDir '/java/vecmath.jar']);
    % Get JOGL version
    JOGLVersion = bst_get('JOGLVersion');
    switch (JOGLVersion)
        case 0
            % Nothing supported
        case 1
            javaaddpath([BrainstormHomeDir '/java/brainstorm_jogl1.jar']);
            if exist('isdeployed', 'builtin') && isdeployed
                dynamicPath = javaclasspath;
                for i = 1:length(dynamicPath)
                    if ~isempty(strfind(dynamicPath{i}, 'jogl2'))
                        dynamicPath(i) = [];
                        break;
                    end
                end
                javaclasspath(dynamicPath);
            end
        case 2
            javaaddpath([BrainstormHomeDir '/java/brainstorm_jogl2.jar']);
            if exist('isdeployed', 'builtin') && isdeployed
                dynamicPath = javaclasspath;
                for i = 1:length(dynamicPath)
                    if ~isempty(strfind(dynamicPath{i}, 'jogl1'))
                        dynamicPath(i) = [];
                        break;
                    end
                end
                javaclasspath(dynamicPath);
            end
    end
end

% Default action : start
if (nargin == 0)
    action = 'start';
else
    action = lower(varargin{1});
end

res = 1;
switch action
    case 'start'
        bst_set_path(BrainstormHomeDir);
        bst_startup(BrainstormHomeDir, 1);
    case 'nogui'
        bst_set_path(BrainstormHomeDir);
        bst_startup(BrainstormHomeDir, 0);
    case 'kinect'
        bst_set_path(BrainstormHomeDir);
        bst_kinect_record;
    case 'digitize'
        brainstorm nogui
        panel_digitize('Start');
    case {'status', 'isstarted', 'isrunning'}
        res = isappdata(0, 'BrainstormRunning');
    case {'exit', 'stop', 'quit'}
        bst_exit();
    case 'reset'
        bst_reset();
    case 'setpath'
        disp('Adding all Brainstorm directories to local path...');
        bst_set_path(BrainstormHomeDir);
    case 'startjava'
        disp('Starting Java...');
    case {'info', 'website'}
        web('http://neuroimage.usc.edu/brainstorm/');
    case 'forum'
        web('http://neuroimage.usc.edu/forums/');
    case 'license'
        bst_set_path(BrainstormHomeDir);
        bst_set('BrainstormHomeDir', BrainstormHomeDir);
        bst_license();
    case 'update'
        % Add path to java_dialog function
        addpath(fullfile(BrainstormHomeDir, 'toolbox', 'gui'));
        % Update
        bst_update(0);
    case 'validate_ctf'
        bst_set_path(BrainstormHomeDir);
        tutorial_ctf;
    case 'validate_raw'
        bst_set_path(BrainstormHomeDir);
        tutorial_raw;
    case 'validate_resting'
        bst_set_path(BrainstormHomeDir);
        tutorial_raw;
    case 'validate_fif'
        bst_set_path(BrainstormHomeDir);
        tutorial_neuromag;
    case 'deploy'
        bst_set_path(BrainstormHomeDir);
        % Add path to java_dialog function
        deployPath = fullfile(BrainstormHomeDir, 'deploy');
        addpath(deployPath);
        bst_set('BrainstormHomeDir', BrainstormHomeDir);
        % Get Matlab version
        VER = bst_get('MatlabVersion');
        bst_deploy_java = str2func(['bst_deploy_java_' VER.Release(2:end)]);
        % Update
        if (nargin > 1)
            bst_deploy_java(varargin{2:end});
        else
            bst_deploy_java();
        end
    case 'packagebin'
        bst_set_path(BrainstormHomeDir);
        deployPath = fullfile(BrainstormHomeDir, 'deploy');
        addpath(deployPath);
        bst_set('BrainstormHomeDir', BrainstormHomeDir);
        bst_package_bin(varargin{2:end});
    otherwise
        disp(' ');
        disp('Usage : brainstorm start        : Start Brainstorm');
        disp('        brainstorm nogui        : Start brainstorm without interface (for scripts)');
        disp('        brainstorm stop         : Stop Brainstorm');
        disp('        brainstorm update       : Download and install latest Brainstorm update (see bst_update)');
        disp('        brainstorm reset        : Re-initialize Brainstorm database and preferences');
        disp('        brainstorm digitize     : Digitize electrodes positions and head shape using a Polhemus system');
        disp('        brainstorm setpath      : Add Brainstorm subdirectories to current path');
        disp('        brainstorm startjava    : Add Brainstorm Java classes to dynamic classpath');
        disp('        brainstorm info         : Open Brainstorm website');
        disp('        brainstorm forum        : Open Brainstorm forum');
        disp('        brainstorm license      : Display license');
        disp('        brainstorm validate_ctf : Runs all the CTF tutorials to validate the software');
        disp('        brainstorm validate_raw : Runs the continuous file pipeline');
        disp('        brainstorm validate_fif : Runs the Neuromag recordings tutorial');
        disp('        brainstorm validate_rs  : Runs the resting state analysis pipeline');
        disp('        brainstorm deploy       : Create a zip file for distribution (see bst_deploy)');
        disp('        brainstorm deploy 1     : Deploy + compile the current version of Brainstorm with Matlab mcc compiler');
        disp('        brainstorm packagebin   : Create separate zip files for all the currently available binary distributions');
        disp(' ');
end

% Return value
if (nargout >= 1)
    varargout{1} = res;
end

end


%% ===== SET PATH =====
function bst_set_path(BrainstormHomeDir)
    % Cancel add path in case of deployed application
    if exist('isdeployed', 'builtin') && isdeployed
        return
    end
    % Brainstorm folder itself
    addpath(BrainstormHomeDir) % make sure the main brainstorm folder is in the path
    % List of folders to add
    NEXTDIR = {'external','toolbox'}; % in reverse order of priority
    for i = 1:length(NEXTDIR)
        nextdir = fullfile(BrainstormHomeDir,NEXTDIR{i});
        % Reset the last warning to blank
        lastwarn('');
        % Check that directory exist
        if ~isdir(nextdir)
            error(['Directory "' NEXTDIR{i} '" does not exist in Brainstorm path.' 10 ...
                   'Please re-install Brainstorm.']);
        end
        % Recursive search for subfolders in each main folder
        P = genpath(nextdir);
        % Add directory and subdirectories
        addpath(P);
    end
    % Adding user's mex path
    userMexDir = bst_get('UserMexDir');
    addpath(userMexDir);
    % Adding user's custom process path
    userProcessDir = bst_get('UserProcessDir');
    addpath(userProcessDir);
end





