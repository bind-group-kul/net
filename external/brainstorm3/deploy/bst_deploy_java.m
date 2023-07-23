function bst_deploy_java(IS_BIN)
% BST_DEPLOY_JAVA - Brainstorm deployment script.
%
% USAGE:  bst_deploy_java(IS_BIN=0)
%
% INPUTS:
%    - IS_BIN : Flag to compile Brainstorm using the MCC compiler
%
% STEPS:
%    - Update doc/version.txt
%    - Update doc/license.html (update block: "Version: ...")
%    - Update *.m inital comments (replace block "@=== ... ===@" with deploy/autocomment.txt)
%    - Remove *.asv files
%    - Zip brainstorm3 directory (output file: <bstMakeDir>/brainstorm_yymmdd.zip)
%    - Restore defaults/* directories
%    (optional)
%    - Build stand-alone application
%    - Zip stand-alone directory  (output file: <bstMakeDir>/bst_bin_os_yymmdd.zip)
%    - Zip <bstDefDir> directory (output file: <bstMakeDir>/bst_defaults_yymmdd.zip)

% @=============================================================================
% This software is part of the Brainstorm software:
% http://neuroimage.usc.edu/brainstorm
% 
% Copyright (c)2000-2012 Brainstorm by the University of Southern California
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
% Authors: Francois Tadel, 2011-2013


%% ===== PARSE INPUTS =====
if (nargin < 1) || isempty(IS_BIN)
    IS_BIN = 0;
elseif ischar(IS_BIN)
    switch(IS_BIN)
        case '0',   IS_BIN = 0;
        case '1',   IS_BIN = 1;
        otherwise,  error('Invalid value for IS_BIN.');
    end
end
% Check if compiler is available
if IS_BIN && ~exist('deploytool', 'file')
    disp('DEPLOY> No compiler available: cannot produce standalone application.');
    IS_BIN = 0;
end


%% ===== CONFIGURATION =====
bstVersion    = '3.1';
% Root brainstorm directory
bstDir        = bst_get('BrainstormHomeDir');
bstToolboxDir = fullfile(bstDir, 'toolbox');
% Deploy folder
deployDir = fullfile(fileparts(bstDir), 'brainstorm3_deploy');
% Get file names
versionFile     = fullfile(bstDir, 'doc', 'version.txt');
licenseFile     = fullfile(bstDir, 'doc', 'license.html');
autoCommentFile = fullfile(bstDir, 'deploy', 'autocomment.txt');

% Compiler configuration   
if IS_BIN
    % Clear command window
    clc
    % JDK folder
    jdkDir = 'C:\Program Files (x86)\Java\jdk1.6.0_27';
    % Set JAVA_HOME environment variable
    setenv('JAVA_HOME', jdkDir);
    % Get Matlab version
    VER = bst_get('MatlabVersion');
    % Javabuilder output
    compilerFile = fullfile(bstDir, 'deploy', 'bst_javabuilder.prj');
    compilerDir = fullfile(deployDir, 'bst_javabuilder');
    compilerOutputDir = fullfile(compilerDir, 'distrib');
    compilerSrcDir    = fullfile(compilerDir, 'src');
    % Packaging folders
    packageDir = fullfile(deployDir, 'package');
    % Create the folders for the packaging
    binDir = fullfile(bstDir, 'bin', VER.Release);
    jarDir = fullfile(packageDir, 'jar');
    % Delete existing folders
    try
        rmdir(compilerDir, 's');
        rmdir(packageDir, 's');
    catch
        disp(['DEPLOY> Error: Could not delete folders: "' compilerDir '" or "' packageDir '"']);
    end
end


%% ===== MAKE DIRECTORIES =====
if IS_BIN
    dirToCreate = {deployDir, compilerOutputDir, compilerSrcDir, jarDir, binDir};
else
    dirToCreate = {deployDir};
end
% For each directory
for i=1:length(dirToCreate)
    % Create directory if it does not exist yet
    if ~exist(dirToCreate{i}, 'file')
        isCreated = mkdir(dirToCreate{i});
        if ~isCreated
            error(['Cannot create output directory:' dirToCreate{i}]);
        end
    end
end


%% ===== GET ALL DIRECTORIES =====
% Get all the Brainstorm subdirectories
bstPath = [bstDir, ';', getPath(bstDir)];
% Split string
jPath = java.lang.String(bstPath);
jSplitPath = jPath.split(';');


%% ===== UPDATE VERSION.TXT =====
disp([10 'DEPLOY> Updating: ', strrep(versionFile, bstDir, '')]);
% Get date string
c = clock;
strDate = sprintf('%02d%02d%02d', c(1)-2000, c(2), c(3));
% Version.txt contents
strVersion = ['% Brainstorm' 10 ...
              '% v. ' bstVersion ' ' strDate ' (' date ')'];
% Write version.txt
writeAsciiFile(versionFile, strVersion);


%% ===== UPDATE LICENSE.HTML =====
disp(['DEPLOY> Updating: ', strrep(licenseFile, bstDir, '')]);
% Read previous file
strLicense = readAsciiFile(licenseFile);
% Find block to replace
blockToFind = 'Version: ';
iStart = strfind(strLicense, blockToFind);
% If block was found
if ~isempty(iStart)
    % Start replacing after the block
    iStart = iStart(1) + length(blockToFind) - 1;
    % Stops replacing at the first HTML tag after the block
    iStop = iStart;
    while (strLicense(iStop) ~= '<')
        iStop = iStop + 1;
    end
    % Replace block
    strLicense = [strLicense(1:iStart), ...
                  bstVersion ' (' date ')', ...
                  strLicense(iStop:end)];
    % Save file
    writeAsciiFile(licenseFile, strLicense);
end


%% ===== PROCESS DIRECTORIES =====
disp(['DEPLOY> Reading: ', strrep(autoCommentFile, bstDir, '')]);
% Read file
autoComment = readAsciiFile(autoCommentFile);
if isempty(autoComment)
    error('Auto-comment file not found.');
end
% Convert to Unix-like string
autoComment = strrep(autoComment, char([13 10]), char(10));
% Updating the M-files
disp('DEPLOY> Updating: Comments in all *.m files...');
for iPath = 1:length(jSplitPath)
    curPath = char(jSplitPath(iPath));
    % Remove ASV files
    delete(fullfile(curPath, '*.asv'));
    
    % === EDIT .M COMMENTS (TOOLBOX ONLY) ===
    % Is it a toolbox directory
    if ~isempty(strfind(curPath, bstToolboxDir)) || strcmpi(curPath, bstDir)
        % List all .m files in current directory
        mFiles = dir(fullfile(curPath, '*.m'));
        % Process each m-file
        for iFile = 1:length(mFiles)
            % Build full file name
            fName = fullfile(curPath, mFiles(iFile).name);
            % Replace comment block in file
            replaceBlock(fName, '% @===', '===@', autoComment);
        end
    end
end


%% ===== MATLAB COMPILER =====
if IS_BIN
    % === COMPILING ===
    disp('DEPLOY> Starting Matlab Compiler...');
    % Starting compiler
    deploytool('-build', compilerFile);
    % This stupid call is asynchronous: have to wait manually until it's done
    % Get the text in the command window, until there is that "Build finished" text in it
    while(1)
        pause(2);
        cmdWinDoc = com.mathworks.mde.cmdwin.CmdWinDocument.getInstance;
        jString   = cmdWinDoc.getText(cmdWinDoc.getStartPosition.getOffset, cmdWinDoc.getLength);
        if ~isempty(strfind(char(jString), 'Build finished'))
            break;
        end
        fprintf(1, '.');
    end
    
    % === MOVE DEPLOYED FILES ===
    disp('DEPLOY> Packaging binary distribution...');
    % Newer versions of the compiler do not respect the destination folder: need to move it
    if (VER.Version >= 800)
        % Delete brainstorm3_deploy/javabuilder
        try
            rmdir(compilerDir, 's');
        catch
            disp(['DEPLOY> Error: Could not delete folder: "' compilerDir '"']);
        end
        % Copy "brainstorm3\deploy\bst_javabuilder" to "brainstorm3_deploy/bst_javabuilder"
        movefile(fullfile(bstDir, 'deploy', 'bst_javabuilder'), compilerDir);
    end
    
    % === PACKAGING ===
    % Compiled jar
    compiledJar = fullfile(compilerOutputDir, 'bst_javabuilder.jar');
    % Find the JAR created by the compiler
    if ~file_exist(compiledJar)
        error('Compilation is incomplete: cannot package the binary distribution.');
    end
    % JavaBuilder .jar file
    javabuilderJar = fullfile(matlabroot, 'toolbox', 'javabuilder', 'jar', 'javabuilder.jar');
    % Unjar everything in package dir
    unzip(javabuilderJar, jarDir);
    unzip(compiledJar, jarDir);

    % Write manifest
    manifestFile = fullfile(jarDir, 'manifest.txt');
    fid = fopen(manifestFile, 'w');
    fwrite(fid, ['Manifest-Version: 1.0' 13 10 ...
                 'Main-Class: bst_javabuilder.Run' 13 10 ...
                 'Created-By: Brainstorm 3.1 (' date ')' 13 10]);
    fclose(fid);
    
    % Brainstorm application .jar file
    appJar = fullfile(bstDir, 'java', 'brainstorm.jar');
    % Unjar in "javabuilder" folder, just to get the SelectMcr class
    unzip(appJar, compilerDir);
    classFile = fullfile('org', 'brainstorm', 'file', 'SelectMcr.class');
    destFolder = fullfile(jarDir, fileparts(classFile));
    mkdir(destFolder);
    copyfile(fullfile(compilerDir, classFile), destFolder);
    % Re-jar files together
    bstJar = fullfile(binDir, 'brainstorm3.jar');
    delete(bstJar);
    system(['cd "' jarDir '" & "' jdkDir '\bin\jar.exe" cmf manifest.txt "' bstJar '" bst_javabuilder org com']);
end


%% ===== CREATE ZIP ===== 
% Output files 
zipFileBst = fullfile(deployDir, ['brainstorm_' strDate '.zip']);
disp(['DEPLOY> Creating final zip file: ' zipFileBst]);
% Create zip file
zip(zipFileBst, bstDir, fileparts(bstDir));
% Done
disp(['DEPLOY> Done.' 10]);



end




%% =================================================================================================
%  ===== HELPER FUNCTIONS ==========================================================================
%  =================================================================================================

%% ===== READ ASCII FILE =====
function fContents = readAsciiFile(filename)
    fContents = '';
    % Open ascii file
    fid = fopen(filename, 'r');
    if (fid < 0)
        return;
    end
    % Read file
    fContents = char(fread(fid, Inf, 'char')');
    % Close file
    fclose(fid);
end

%% ===== WRITE ASCII FILE =====
function writeAsciiFile(filename, fContents)
    % Open ascii file
    fid = fopen(filename, 'w');
    if (fid < 0)
        return;
    end
    % Write file
    fwrite(fid, fContents, 'char');
    % Close file
    fclose(fid);
end

%% ===== GET PATH =====
function p = getPath(d)
    % Generate path based on given root directory
    files = dir(d);
    if isempty(files)
        return
    end
    % Base path: input dir
    p = [d pathsep];
    % Set logical vector for subdirectory entries in d
    isdir = logical(cat(1,files.isdir));
    % Recursively descend through directories
    dirs = files(isdir); % select only directory entries from the current listing
    for i=1:length(dirs)
       dirname = dirs(i).name;
       % Ignore directories starting with '.' and 'defaults' folder
       if (dirname(1) ~= '.') && ~strcmpi(dirname, 'defaults')
           p = [p getPath(fullfile(d, dirname))]; % recursive calling of this function.
       end
    end
end

%% ===== REPLACE BLOCK IN FILE =====
function replaceBlock(fName, strStart, strStop, strNew)
    % Read file
    fContents = readAsciiFile(fName);
    % Detect block markers (strStart, strStop)
    % => Start
    iStart = strfind(fContents, strStart);
    if isempty(iStart)
        disp(['*** Block not found in file: "', fName, '"']);
        return;
    end
    iStart = iStart(1);
    % => Stop
    iStop = strfind(fContents(iStart:end), strStop) + length(strStop) + iStart - 1;
    if isempty(iStop)
        disp(['*** Block not found in file: "', strrep(fName,'\','\\'), '"']);
        return;
    end
    iStop = iStop(1);

    % Replace file block with new one
    fContents = [fContents(1:iStart - 1), ...
        strNew, ...
        fContents(iStop:end)];
    % Re-write file
    writeAsciiFile(fName, fContents);
end


