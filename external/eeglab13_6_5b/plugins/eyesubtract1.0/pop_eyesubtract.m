% pop_eyesubtract() - Remove eye movement components
%
% Usage:
%   >> [ALLEEG LASTCOM] = pop_eyesubtract(ALLEEG, CURRENTSET);
%
% Input:
%   ALLEEG	- EEGLAB ALLEEG dataset structure
%   CURRENTSET  - EEGLAB CURRENTSET variable
%
% Outputs:
%   ALLEEG      - EEGLAB ALLEEG dataset structure with eye component removed
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

function [ALLEEG, LASTCOM] = pop_eyesubtract(ALLEEG, CURRENTSET)
LASTCOM='';

%Initialization

if nargin < 1
    help pop_eyesubtract;
    return;
end;

if isempty(ALLEEG)
    error('pop_eyesubtract(): cannot process empty sets of data');
end;

%Plot dialog

gtmp = [1 .8 .2];
uigeom = {gtmp gtmp gtmp gtmp gtmp gtmp gtmp gtmp};

uilist = {
    { 'style' 'text' 'string' 'Data set from eye movement experiment' } ...
    { 'style' 'edit' 'string' num2str(CURRENTSET) }...
    {}...
    { 'style' 'text' 'string' 'Data set to remove eye movement from' } ...
    { 'style' 'edit' 'string' num2str(CURRENTSET) }...
    {}...  
    { 'style' 'text' 'string' 'Blink event type' } ...
    { 'style' 'edit' 'string' num2str(1) }...
    {}...
    { 'style' 'text' 'string' 'Left eye movement event type' } ...
    { 'style' 'edit' 'string' num2str(2)}...
    {}...
    { 'style' 'text' 'string' 'Right eye movement event type' } ...
    { 'style' 'edit' 'string' num2str(3) }...
    {}...
    { 'style' 'text' 'string' 'Upward eye movement event type' } ...
    { 'style' 'edit' 'string' num2str(4) }...
    {}...
    { 'style' 'text' 'string' 'Downward eye movement event type' } ...
    { 'style' 'edit' 'string' num2str(5) }...
    {}...
    { 'style' 'text' 'string' 'Offset of training events (ms)' } ...
    { 'style' 'edit' 'string' '350' }...
    {}
    };
result = inputgui(uigeom, uilist);

if length(result) == 0
    return;
end;


% Decode parameter list

event_type = struct('blink',[],'left',[],'right',[],'up',[],'down',[]);
eyeset           = eval( [ '[' result{1} ']' ]);
eyesubtractset   = eval( [ '[' result{2} ']' ]);
event_type.blink = eval( [ '[' result{3} ']' ]);
event_type.left  = eval( [ '[' result{4} ']' ]);
event_type.right = eval( [ '[' result{5} ']' ]);
event_type.up    = eval( [ '[' result{6} ']' ]);
event_type.down  = eval( [ '[' result{7} ']' ]);
offset   = eval( [ '[' result{8} ']' ]);

if isempty(event_type.blink), error('Please input the event value for blinks'); end;
if isempty(event_type.left),  error('Please input the event value for left eye movement');  end;
if isempty(event_type.right), error('Please input the event value for right eye movement'); end;
if isempty(event_type.up),    error('Please input the event value for upward eye movement');    end;
if isempty(event_type.down),  error('Please input the event value for downward eye movement');  end;

% Initialize EEGdata

events   =  zeros(1,ALLEEG(eyeset).pnts);
offset=fix((offset./1000).*ALLEEG(eyeset).srate);
for i=1:length(ALLEEG(eyeset).event),
    if ismember(ALLEEG(eyeset).event(i).type,[event_type.blink event_type.left event_type.right event_type.up event_type.down]),
        events((ALLEEG(eyeset).event(i).latency+offset):(ALLEEG(eyeset).event(i).latency ...
            +ALLEEG(eyeset).event(i).duration-1)) = ALLEEG(eyeset).event(i).type;
    end
end

% High-pass filter (2nd order Butterworth, cutoff f = 0.1 Hz).

ALLEEG(eyeset).data = ALLEEG(eyeset).data- ...
    repmat(ALLEEG(eyeset).data(:,1),[1 size(ALLEEG(eyeset).data,2)]);
[b,a]=butter(3,0.1/ALLEEG(eyeset).srate*2,'high');
ALLEEG(eyeset).data = filtfilt(b,a,ALLEEG(eyeset).data);

A    =  eyesubtract(ALLEEG(eyeset),event_type,events);
a_H  =  A(:,1);
a_V  =  A(:,2);
a_B  =  A(:,3);

V    =  inv(A'*A)*A';

ALLEEG(eyeset).icasphere=eye(ALLEEG(eyeset).nbchan);
ALLEEG(eyeset).icaweights(1:3,:)=V;
ALLEEG(eyeset).icawinv(:,1:3)=A;

eeg_options;
ALLEEG(eyeset).icaact    = (ALLEEG(eyeset).icaweights*ALLEEG(eyeset).icasphere)*reshape(ALLEEG(eyeset).data, ALLEEG(eyeset).nbchan, ALLEEG(eyeset).trials*ALLEEG(eyeset).pnts);
ALLEEG(eyeset).icaact    = reshape( ALLEEG(eyeset).icaact, size(ALLEEG(eyeset).icaact,1), ALLEEG(eyeset).pnts, ALLEEG(eyeset).trials);

setlist=[eyeset eyesubtractset];
[ALLEEG]=eeg_store(ALLEEG,ALLEEG(eyeset),eyeset);
[ALLEEG EEG neweyesubtractset]=eeg_store(ALLEEG,ALLEEG(eyesubtractset));
ALLEEG(neweyesubtractset).data = ...
    (eye(size(ALLEEG(neweyesubtractset).data,1))-A*V)*ALLEEG(neweyesubtractset).data(:,:);
ALLEEG(neweyesubtractset).setname=[ALLEEG(neweyesubtractset).setname ' - Eye Movement Artifacts Removed'];
[ALLEEG]=eeg_store(ALLEEG,ALLEEG(neweyesubtractset),neweyesubtractset);

% Display scalp maps of eye movement components
figure;
subplot(1,3,1);
topoplot(A(:,1),ALLEEG(eyeset).chanlocs);
title('Horizontal');

subplot(1,3,2);
topoplot(A(:,2),ALLEEG(eyeset).chanlocs);
title('Vertical');

subplot(1,3,3);
topoplot(A(:,3),ALLEEG(eyeset).chanlocs);
title('Blink');

% Display eye movement components and artifact-free data

figure;
timex=[0:ALLEEG(eyeset).pnts-1]./ALLEEG(eyeset).srate;
plot(timex,ALLEEG(eyeset).icaact(1,:)+10000,'r');
hold on;
plot(timex,ALLEEG(eyeset).icaact(2,:)+8000,'k');
plot(timex,ALLEEG(eyeset).icaact(3,:)+6000,'b');
plot(timex,ALLEEG(eyeset).data(1,:)+4000,'g');
plot(timex,ALLEEG(neweyesubtractset).data(1,:)+2000,'b');
plot(timex,100.*events,'r');
set(gca,'YTick',[0:2000:10000]);
set(gca,'YTickLabel',{'Events' ['Artifact-free ' ALLEEG(neweyesubtractset).chanlocs(1).labels] ['Original ' ALLEEG(eyeset).chanlocs(1).labels] 'Blink' 'Vertical' 'Horizontal'});
xlabel('Time (seconds)');
axis tight;
set(gcf,'color','w');

