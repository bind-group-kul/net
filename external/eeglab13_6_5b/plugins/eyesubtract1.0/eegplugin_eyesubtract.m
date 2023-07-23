% eegplugin_eyesubtract() - Eye movement subtraction plugin
%
% Usage:
%   >> eegplugin_eyesubtract(fig, trystrs, catchstrs);
%
% Inputs:
%   fig        - [integer] eeglab figure.
%   trystrs    - [struct] "try" strings for menu callbacks.
%   catchstrs  - [struct] "catch" strings for menu callbacks.
%
% @article{parra2005,
%       author = {Lucas C. Parra and Clay D. Spence and Adam Gerson 
%                 and Paul Sajda},
%       title = {Recipes for the Linear Analysis of {EEG}},
%       journal = {{NeuroImage}},
%       year = {in revision}}
%
% Authors: Xiang Zhou (zhxapple@hotmail.com, 2005)
%	   with Adam Gerson (adg71@columbia.edu, 2005),	   
%      and Lucas Parra (parra@ccny.cuny.edu, 2005),
%	   and Paul Sajda (ps629@columbia,edu 2005)

%123456789012345678901234567890123456789012345678901234567890123456789012

% Copyright (C) 2005 Xiang Zhou, Adam Gerson, Lucas Parra and Paul Sajda
%
% This program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 2 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program; if not, write to the Free Software
% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

function vers = eegplugin_eyesubtract(fig, try_strings, catch_strings); 

vers='eyesubtract1.0';
if nargin < 3
    error('eegplugin_eyesubtract requires 3 arguments');
end;

% add lr folder to path
% -----------------------
if ~exist('pop_eyesubtract')
    p = which('eegplugin_eyesubtract');
    p = p(1:findstr(p,'eegplugin_eyesubtract.m')-1);
    addpath([ p vers ] );
end;


% create menu
menu = findobj(fig, 'tag', 'tools');

% menu callback commands
% ----------------------

cmd=  [  '[ALLEEG LASTCOM]=pop_eyesubtract(ALLEEG, CURRENTSET); EEG=ALLEEG(CURRENTSET); eeglab(''redraw'');'  ];

% add new submenu
uimenu( menu, 'label', 'Subtract Eye Movement Components', 'callback', cmd);
