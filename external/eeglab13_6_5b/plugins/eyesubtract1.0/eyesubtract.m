% eyesubtract() - Remove eye movement components
%
% Usage:
%   >> [EEG LASTCOM] = eyesubtract(EEG,event_type,events);
%
% Input:
%   EEG		- EEGLAB EEG dataset structure
%   event_type  - structure of event_type
%                 event_type.blink - eye blink
%                 event_type.left  - left eye movement
%                 event_type.right - right eye movement
%                 event_type.up    - upward eye movement
%                 event_type.down  - downward eye movement
%   events      - event channel [1 x samples]
%                 equal to event_type for appropriate duration and
%                 zero elsewhere
%
% Outputs:
%   EEG		- EEGLAB EEG dataset structure with eye component removed
%   LASTCOM 	- command history for EEGLAB
%
% @article{parra2005,
%       author = {Lucas C. Parra and Clay D. Spence and Adam Gerson 
%                 and Paul Sajda},
%       title = {Recipes for the Linear Analysis of {EEG}},
%       journal = {{NeuroImage}},
%       year = {in revision}}
%
% Authors: Xiang Zhou (zhxapple@hotmail.com, 2005)
%          with Adam Gerson (adg71@columbia.edu, 2005),
%          and Lucas Parra (parra@ccny.cuny.edu, 2005),
%          and Paul Sajda (ps629@columbia,edu 2005)

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

function A=eyesubtract(EEG,event_type,events)

% First check that we have the correct eye movement events

blink=find(events==event_type.blink);
if isempty(blink) error(' The event type of blink is wrong! '); end;

left=find(events==event_type.left);
if isempty(left)   error(' The event type of moving left is wrong! ');  end;

right=find(events==event_type.right);
if isempty(right)  error(' The event type of moving right is wrong! '); end;

up=find(events==event_type.up);
if isempty(up)     error(' The event type of moving up is wrong! ');    end;

down=find(events==event_type.down);
if isempty(down)   error(' The event type of moving down is wrong! ');  end;

data_blink = EEG.data(:,blink);
data_left  = EEG.data(:,left );
data_right = EEG.data(:,right);
data_up    = EEG.data(:,up   );
data_down  = EEG.data(:,down );

% Forward model

a_H  =  difference(data_left,  data_right);     clear data_left data_right;
a_V  =  difference(data_up,    data_down );     clear data_up   data_down;
a_B  =  Maximumpower(data_blink);               clear data_blink;

A=[a_H a_V a_B];

return

function Difvec=difference(EEG_1,EEG_2)

%Difvec   = mean(EEG_1-EEG_2,2);
% Should this be?
Difvec = mean(EEG_1,2)-mean(EEG_2,2);

Difvec   = Difvec./norm(Difvec);

return

function Max_eigvec=Maximumpower(EEGdata);

[Channel,SRate,Epoch]=size(EEGdata);

for e=1:Epoch
    for i=1:Channel
        EEGdata(i,:,e)=EEGdata(i,:,e)-mean(EEGdata(i,:,e));
    end;
end;


% Maximum Power method

a=EEGdata(:,:);

pow_a=a*a';

[vb,tmp] = eig(pow_a);
Max_eigvec=vb(:,end)./norm(vb(:,end));


return
