%
% 'overseer' function for performing & logging subtraction without
% any kind of windowing.
%
%
% [data,cfg]=m_do_everything(data,cfg)

function [data,cfg]=m_do_everything(data,cfg)



% % probably can be removed..
% cfg.cwregression.srate = 1000;              %srate=1000;
% cfg.cwregression.windowduration = 1.3;      %windowduration=2.0;
% cfg.cwregression.delay = 0.050;             %delay=0.050;
% cfg.cwregression.taperingfactor = 2;        %taperingfactor=1;
% cfg.cwregression.taperingfunction = @hann;  %taperingfunction=@hann;
% cfg.cwregression.regressorinds = 33:40;     %regressorinds=1:30;
% cfg.cwregression.channelinds = 1:31;        %channelinds=33:40;
% cfg.cwregression.method='taperedhann';     % What method are we using??
% % 'everything','none','slidingwindow' are the other options for method.
% 



% cwregression=cfg.cwregression;

cwregression=cfg.cwregression;

if isfield(cwregression,'do_logging');
    do_logging = cwregression.do_logging;
else
    do_logging = 0;
end




delay_in_samples = floor(cwregression.srate*cwregression.delay);

x=data.matrix(cwregression.channelinds,:);
regs=data.matrix(cfg.cwregression.regressorinds,:);


window=[];

[subtracted_signals logging]=tools.fit_regmat_to_signalmat(x,regs,window,delay_in_samples,[],do_logging);

cfg.cwregression.logging = {logging};
data.subtracted_data = subtracted_signals;



