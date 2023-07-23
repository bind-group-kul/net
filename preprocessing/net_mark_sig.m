function [u,count]=net_mark_sig(s,fs,p)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%mark_EOG?? Mark the EOG contaminated EEG zones based on amplitude of EOG.
% s-> input singal with EOG
% fs->the samples
% p-> it can choose weather to draw the picture or not??p??[0,1];0 presents
% not draw??1 presents to draw the raw EEG and the contaminated EEG zones.
% u-> output of the mark of contaminated EEG data.
% count->output of the number of marks.
%% @(#)$Id: mark_EOG.m 2010.6,18 Yanbing Qi Exp $
%% @(#)$Id: mark_EOG.m 2010.7,16 Yanbing Qi Exp $
%% @(#)$Id: mark_EOG.m 2011.06.09 Yanbing Qi Exp $
%$%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Check inputs
  if nargin < 3
    p=0;
      if nargin < 2
        error('MATLAB:mark_EOG:NotEnoughInputs',...
              'Not enough input arguments.  See mark_EOG.');
      end  
  end


% check input signal
[a_1,b_1]=size(s);
updown=0;
count=0;
if b_1==1 && b_1<a_1
    s=s';
    updown=1;
end
if a_1~=1 && b_1~=1
    error('MATLAB:mark_EOG:Inputmatrixisnotreliable',...
              'Input matrix is not a one - dimensional array.  See mark_EOG.');
end
% Decide the EOG eliminate zone.
forward_cut=floor(0.5*fs)-100;
backward_cut=floor(0.5*fs)+100;
u=zeros(size(s));
% According to the high amplitude characteristic  of the EOG contaminated
% zone to mark the raw EEG signal.
for i=1:length(s)
    if s(i)>45 || s(i)<-45
        u(i)=1;
    end
end
for i=1:length(u)-1
    if u(i)==0 && u(i+1)==1
        count=count+1;
        if i>forward_cut
            u(i-forward_cut:i)=1;
        else
            u(1:i)=1;
        end
    end

    if u(i)==1 && u(i+1)==0
        if length(u)-i>backward_cut
            u(i:i+backward_cut)=3;
        else
            u(i:end)=3;
        end
    end
end
for i=1:length(u)
    if u(i)>0
        u(i)=1;
    end
end
% plot function
if p==1
    figure;hold on;plot(u*50,'r');plot(s)
    legend('Mark','Raw EEG data');
    title('The mark of contaminated EEG data');
    hold off;
end

if updown==1
    s=s';
end


