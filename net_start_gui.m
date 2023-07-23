%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%                                                      %%%
%%%                        .:: NET ::.                   %%%
%%%                                                      %%%
%%%  Non-invasive Electrophysiological analysis Toolbox  %%%
%%%  --------------------------------------------------  %%%
%%%  --------------------------------------------------  %%%
%%%       Gaia Amaranta Taberna - 08.04.22 - v.1.0       %%%
%%%                                                      %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%{

Cite as:
--------


%}

close all
clear all
clc
warning off

gui_path = [fileparts(mfilename('fullpath')) filesep 'gui'];
addpath(gui_path)

fprintf('Opening the GUI...\n\n');
pause(2)

% Run the GUI
net_gui


