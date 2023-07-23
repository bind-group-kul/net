%
% 'overseer' function for performing & logging subtraction with sliding
% windows.
%
%
% [data,cfg]=m_do_slidingwindow(data,cfg)

function [data,cfg]=m_do_slidingwindow(data,cfg)



cwregression=cfg.cwregression;

if isfield(cwregression,'do_logging');
    do_logging = cwregression.do_logging;
else
    do_logging = 0;
end



% as input we have the data matrix, and the regressor matrix.
% we have sampling rate
% we have the length of the window in sec
% we have the amount of temporal delay in sec

% function_to_calculate_nwindows=@(x) 2*(2^x-1)+1;
% nwindows=function_to_calculate_nwindows(cwregression.taperingfactor);
% do some complicated arithmatics to make sure that the boundaries of the
% tapering windows always falls on a sample (and not between samples, as
% then the sum would no longer hold...
% iteratively add (length) in samples to obtain this result.
% taper_factor = cwregression.taperingfactor;

number_of_samples_in_window = floor(cwregression.srate*cwregression.windowduration + 1);
step_in_samples = number_of_samples_in_window - 1;


delay_in_samples = floor(cwregression.srate*cwregression.delay);
window=[];

x=data.matrix(cwregression.channelinds,:);
regs=data.matrix(cfg.cwregression.regressorinds,:);

% for now... just store the subtracted data, so I can view it...
subtracted_signals = zeros(size(x),class(x));

% stores logging (fitparameters, etc).
store_logging={};


% if you later decide to skip certain bad fits/windows, the division needs
% to be accounted for separately. Since this is a bit more complicated, we
% now divide (see later on) by 2^(taper_factor-1) and leave it at that.
% for this purpose, matrix_weights_fits would exist (see commented code).

% keyboard;
% jcheck=1;
current_sample = 1;
count=0;
try
while current_sample < size(x,2) - number_of_samples_in_window;
    
    count=count+1;
%     if count==3
%         keyboard;
%     end
    % what does this select??
    range = current_sample:(current_sample+number_of_samples_in_window-1);
 
    % do a new window;
    xpart = x(:,range);
    regspart = regs(:,range);
    
    [fittedregs logging]=tools.fit_regmat_to_signalmat(xpart,regspart,[],delay_in_samples,[],do_logging);
    
    subtracted_signals(:,range(1:end-1)) = fittedregs(:,1:end-1);
    
    % disp([range(1) range(end-1)]);
        
    store_logging{end+1} = logging;
    
    current_sample = current_sample+step_in_samples;
    
end
catch
    keyboard;
end


cfg.cwregression.logging = store_logging;
data.subtracted_data = subtracted_signals;