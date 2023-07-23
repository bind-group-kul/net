% make this a function that outputs all the desired metrics, also.
% x, the data(n-chan by m-pointsintime)
% regs, the regressors
% window, the window that should be used (m timepoints long!)
% delay_in_samples (if this is set, expand all the regressors to all time
% points for each channel).
% fix_delay, a matrix of nchannels-by-mregressors (if this is set, expand
% regressor m for channel n by matrix(n,m) time points.
% if fix_delay is set, delay_in_samples should be [].
% if delay_in_samples is set, fix_delay should be [].

function [fittedregs logging] = fit_regmat_to_signalmat(x,regs,window,delay_in_samples,fix_delay,do_logging)

% if fix_delay == []
% set the delay to that delay value (i.e., do not expand things so fastly!)
% if fix_delay == N, with N either neg or positive integer
% expand to entire pre-and post delayed matrix.
%
% why I added this? I think that the delay between the CW loops and the EEG
% signals should remain (fairly) constant throughout measurement time. But,
% I don't know exactly what that delay is; if I can measure that delay
% first, I will know how far I need to move the regressors forward or
% backwards and then I won't need to expand so far. Another advantage is
% that when windowing, in each window the cw loop regressors then also will
% have the same delay.
%
% if fix_delay is not [], then this will OVERRIDE the delay_in_samples
% thingy!
%

% this is hard-coded... maybe things'll speed up if I set this to 0.



import misc.delay_embed;


nx=size(x,1);
nregs = size(regs,1); % number of regressors.

% init here...
logging.bparams = {};
logging.corrs = {};

% time-expand regressors (only if the delays are not given explicitly in a
% matrix).
if numel(fix_delay)==0
    % full expansion for every channel.
    expregs=flipud(delay_embed(regs,(1+2*delay_in_samples)));
    
    
    % window that...
    % keyboard;
    if numel(window)~=0
        expregs = (window*ones(1,size(expregs,1)).*expregs')';
    end
end

% calculate the inverse (i.e., time-consuming process, so I take it outside
% of the loop for a 30-fold speedup.
% disp('calculating inverse...');
% tic
inv_expregs = pinv(expregs);
% disp('Done calculating inverse!');
% toc




% initialize what you return...
% keyboard;
fittedregs=zeros(size(x),class(x));

logging=struct('fitscale',[],'fitdelay',[],'fitmetric_scale',[],'fitmetric_delay',[]);

% fill that up!
% this calculation goes for each channel, separately!
for i_x=1:nx
    
    % determine this PER channel again & again (saves memory I guess)?
    % window the datavec, too.
    %keyboard;
    if numel(window)~=0
        datavec = x(i_x,:) .* window';
    else
        datavec = x(i_x,:);
    end
    % window datavec...
    % keyboard;
    
    
    % this'll shift the regressors in time for each channel to be corrected
    % individually.
    % this (deparately) needs to be updated.. or fixed! or put in another
    % loop. it is way too confusing as it is. now it is not used however.
    
    if numel(fix_delay)~=0
        if size(fix_delay,1)~=size(x,1) || size(fix_delay,2)~=size(regs,1)
            error('fix_delay should be specified as a matrix of nchan-by-nreg integer values!');
        end
        % read out the matrix (for every channel and regressor pair there
        % should be 1 delay value)
        
        % here since you are in channel i_x, you need to read out one vec
        % of these...
        % then, shift the different regressors in the right way.
        % maybe use a separate easy sub-function(again). Put that into
        % tools.
        expregs=zeros(size(regs));
        delay_values = fix_delay(i_x,:);
        
        for i_reg=1:nregs
            expregs(i_reg,:) = tools.my_vector_shifter(regs(i_reg,:),delay_values(i_reg));
        end
        
        
        % window this...
        if numel(window)~=0
            expregs = (window*ones(1,size(expregs,1)).*expregs')';
        end
        
        % and... also, of course, calculate the pinv!
        inv_expregs = pinv(expregs);
        
        % keyboard;
        
    end
    
    % keyboard;
    fitted=datavec*inv_expregs*expregs;
    fittedregs(i_x,:)=fitted;
    
    % log here...
    % dologging = 1;
    % let's do that another(i.e., better) way...
    if do_logging==1
        
        % do it another way...all_beta_params = datavec*inv_expregs;
        % invert only a part (of 1 regressor) this time; not everything!
        
        
        % keyboard;
        for i_reg = 1:nregs
            % t_expregs = expregs(i_reg:nregs:end,:);
            % inv_t_expregs = pinv(t_expregs);
            % disp(i_x);
            % disp(i_reg);
            % tmp2 = datavec*inv_t_expregs;
            % keyboard; % must think this over... again!
            tmp = datavec*inv_expregs;
            logging.bparams{i_x,i_reg} = tmp(i_reg:nregs:end);
        end
        
        
            %         keyboard;

        for i_reg = 1:nregs
            % correlations!!
            % expregs;
            tmp = expregs(i_reg:nregs:end,:);
            tcorrs = corr(datavec',tmp');
            logging.corrs{i_x,i_reg} = tcorrs;
            
            
        end
        
        
        
    end
    
    
    %     if dologging==1
    %
    %         % then determine some metrics; one for each reg. and each channel.
    %         for i_reg=1:nregs
    %             % now determine my fit parameters... per regressor!
    %
    %             %  if i_x==1 && i_reg==2
    %             %     keyboard;
    %             %  end
    %
    %             reg_sep = expregs(i_reg:nregs:end,:);
    %
    %
    %
    %             fitscales=[];for i=1:size(reg_sep,1);fitscales(i)=fitted/reg_sep(i,:);end
    %             fitcorrs=[];for i=1:size(reg_sep,1);fitcorrs(i)=corr2(fitted',reg_sep(i,:)');end
    %
    %             fitscale = mean(fitscales);
    %
    %
    %             % func_handle = @(pars) 1 - prod(fitcorrs./my_poly(1:numel(fitcorrs),pars./pars_begin,pars_begin));
    %
    %
    %             % maybe troubleshoot this another time!!
    %             % pars0delay = max(delay_in_this_window,1+2*delay_in_samples-delay_in_this_window);
    %             % pars0 = [-1*(max(fitcorrs)-min(fitcorrs))/pars0delay^2 pars0delay max(fitcorrs)];
    %             % options.MaxFunEvals = 1000;
    %             % pars = fminsearch(@(x) function_to_optimize(fitcorrs,x,pars0),[1 1 1],options);
    %             % pars.*pars0;
    %
    %
    %
    %
    %             % v=lscov(reg_sep',fitted');
    %
    %             % does it fit well with a 1/x^2 function???
    %             % sum([sign(diff(fitcorrs(1:delay_in_this_window))) -1*sign(diff(fitcorrs(delay_in_this_window:end)))]
    %
    %             % delay the regressor (separately!!)...
    %
    %             % fitmetric_scale = abs(corr(fitted',datavec'));
    %
    %             if numel(fix_delay)==0
    %                 delay_in_this_window = find(fitcorrs==max(fitcorrs));
    %                 fitdelay = delay_in_this_window - delay_in_samples - 1;
    %
    %                 fitmetric_scale = abs(corr(reg_sep(delay_in_this_window,:)',datavec'));
    %
    %                 check_vec = sign(diff(sign(diff(fitcorrs))));
    %                 fitmetric_delay = sum(check_vec==0)/numel(check_vec);
    %
    %                 % weight it by the fitmetric_scale, too...
    %                 fitmetric_delay = fitmetric_delay * fitmetric_scale;
    %
    %                 % there is no change in direction at all?
    %                 if fitmetric_delay==1;
    %                     fitmetric_delay = 0;
    %                 end
    %
    %                % if i_reg==2&&i_x==1
    %                 %    disp(fitmetric_delay);
    %                   %  keyboard;
    %                % end
    %
    %             else
    %                 fitdelay = fix_delay;
    %                 fitmetric_delay = [];
    %
    %                 fitmetric_scale = abs(corr(fitted',datavec'));
    %             end
    %
    %
    %
    %
    %             logging.fitscale(i_x,i_reg) = fitscale;
    %             logging.fitdelay(i_x,i_reg) = fitdelay;
    %             logging.fitmetric_scale(i_x,i_reg) = fitmetric_scale;
    %             logging.fitmetric_delay(i_x,i_reg) = fitmetric_delay;
    %
    %         end
    %     end
    
end


