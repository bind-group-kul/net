function [ EEGOUT, command ] = pop_cwregression( EEG ,varargin)
%  UNTITLED1 Summary of this function goes here
%  Detailed explanation goes here

command='';

% keyboard;

if numel(varargin)==0
    
    % probably can be removed..
    % cfg.cwregression.srate = EEG.srate;         %srate=1000;
    % cfg.cwregression.windowduration = 4;        %windowduration=4.0;
    % cfg.cwregression.delay = 0.021;             %delay=0.021;
    % cfg.cwregression.taperingfactor = 1;        %taperingfactor=1;
    % cfg.cwregression.taperingfunction = @hann;  %taperingfunction=@hann;
    % cfg.cwregression.regressorinds = [33:40];   %regressorinds=1:30;
    % cfg.cwregression.channelinds = 1:31;        %channelinds=33:40;
    % cfg.cwregression.method='taperedhann';
    % cfg.doui=1;                                 % present the GUI!
    
    srate=EEG.srate;
    windowduration = 4;
    delay = 0.021;
    taperingfactor = 1;
    taperingfunction = @hann;
    
    mark=[];for i=1:numel({EEG.chanlocs.labels});if numel(regexp(EEG.chanlocs(i).labels,'CW.*'));mark=[mark i];end;end
    regressorinds=mark;
    mark=[];mark=[];for i=1:numel({EEG.chanlocs.labels});if numel(regexp(EEG.chanlocs(i).labels,'ECG.*'))==0&&numel(regexp(EEG.chanlocs(i).labels,'CW.*'))==0;mark=[mark i];end;end
    channelinds = mark;
    method='taperedhann';
    doui=1;
    
    
    [data cfg] = run_cwregression(EEG.data,EEG.srate,windowduration,delay,taperingfactor,taperingfunction,regressorinds,channelinds,method,1);
    % this will pop up a menu... so things might've changed since then...
    % (but the changed variables are passed on in cfg to m_do_... etc etc.
    
    
    % then restore from cfg all the stuff!
    
    if numel(cfg)==0
        EEGOUT = EEG;
        return;
    end
    
    srate               = cfg.cwregression.srate;       %srate=1000;
    windowduration      = cfg.cwregression.windowduration;       %windowduration=2.0;
    delay               = cfg.cwregression.delay;         %delay=0.050;
    taperingfactor      = cfg.cwregression.taperingfactor;      %taperingfactor=1;
    taperingfunction    = cfg.cwregression.taperingfunction;  %taperingfunction=@hann;
    regressorinds       = cfg.cwregression.regressorinds;    %regressorinds=1:30;
    channelinds         = cfg.cwregression.channelinds;       %channelinds=33:40;
    method              = cfg.cwregression.method;
    
    
    
end

% without a gui, directly doing the correction is the following:
if numel(varargin)>7
    
    srate = varargin{1}; %srate=1000;
    windowduration = varargin{2}; %windowduration=2.0;
    delay = varargin{3}; %delay=0.050;
    taperingfactor = varargin{4}; %taperingfactor=1;
    taperingfunction = str2func(varargin{5}); %taperingfunction=@hann;
    regressorinds = varargin{6}; %regressorinds=1:30;
    channelinds = varargin{7}; %channelinds=33:40;
    method = varargin{8}; %channelinds=33:40;

    if numel(varargin)==9
        doui=varargin{9};
    else
        doui=1;
    end

    [data cfg] = run_cwregression(EEG.data,EEG.srate,windowduration,delay,taperingfactor,taperingfunction,regressorinds,channelinds,method,doui);
    
end

% build up the command for EEGLAB... this doesn't do anythng (yet!) U can
% 'eval' this later on by copy-pasting the command from EEG.history into a
% script or in the matlab command window.
% keyboard;
command = sprintf('EEG = pop_cwregression(%s, %d, %f, %f, %d, \''%s\'', [','EEG',EEG.srate,windowduration,delay,taperingfactor,func2str(taperingfunction));
for i_reg=1:numel(regressorinds)
    command = [command sprintf('%d ',regressorinds(i_reg))];
end
command(end)=[];
command=[command sprintf('], [')];
for i_channel=1:numel(channelinds)
    command = [command sprintf('%d ',channelinds(i_channel))];
end
command(end)=[];
command = [command sprintf('], \''%s\'', %d);',method,0)];


% this pop function will also do the subtraction.

% keyboard;
if numel(cfg)==0
    EEGOUT=EEG;
    command=[];
    return
end
% do the subtraction... can also be incorporated deeper into this function!
EEG.data(channelinds,:) = EEG.data(channelinds,:) - data.subtracted_data;

% give the diagnostical data, too.
EEG.cwregression.cfg=cfg;

EEG=pop_editset(EEG, 'setname', ['cwcor_' EEG.setname]);

EEG.cwregression.cfg = cfg;

% set output parameters!
EEGOUT=EEG;


