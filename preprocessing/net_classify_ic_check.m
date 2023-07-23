function [comp_checked] = net_classify_ic_check(comp)

warning off;

comp_checked = comp;

stats=comp.stats;
names = fieldnames(stats);


IC = comp.trial{1};
A = comp.topo;
time_ica = comp.time{1};
Nc = size(IC,1);

Fs = comp.fs_ica;

clas = zeros(1,Nc);

if isfield(comp, 'good_ics')
    good_ics = comp.good_ics;
    clas(good_ics)=1;   % vector with 1 if the IC is good, and zith 0 is the IC is artifact
end

window=10;          %expressed in seconds

window_base=find(time_ica >= time_ica(1) & time_ica < window+time_ica(1));     % expressed in number of points


% win=1024*ceil(4/(dec+1));
win = 2.^ceil(log2(Fs)); %1024;
mspettro=zeros(Nc,win/2+1,1);
for ix=1:Nc
    sig=IC(ix,:);
    nave=fix(length(sig)/win);
    Pfin=zeros(win/2+1,1);
    for jx=1:nave
        interv=[1+(jx-1)*win:jx*win];
        buffer=detrend(sig(interv));
        [P, F] = spectrum(buffer, win, 0, hamming(win), Fs);
        P=P(:,1);
        Pfin=Pfin+P;
    end
    Prms=sqrt(2*Pfin/(nave*win));
    mspettro(ix,:)=Prms';
end


chanlocs=comp.chanlocs;


% rmdir([comp.fname(1:end-4) filesep], 's');
% mkdir(comp.fname(1:end-4));

flag=0;

while flag==0
    
    b_ic=[];
    g_ic=[];
    
    
    figure('Position', [100 100 1200 1200]);
    
   for i=1:Nc

   %   i=66;  
        
        if clas(i) > 0
            disp(['component no. ' num2str(i) ' - automatic classification : brain signal']);
        else
            disp(['component no. ' num2str(i) ' - automatic classification : artifact']);
        end

        for zz=1:length(names)
            val=getfield(stats,names{zz});
            disp([names{zz} ' : ' num2str(max(val(:,i)))]);
        end

        disp(' ');

        sig=IC(i,:);
        subplot(2,5,1:3);
        plot(time_ica,sig);
        axis tight;
        title('time course');
        ylabel('microVolt');
        xlabel('minute');
        
        subplot(2,5,4:5); 
        plot(time_ica(window_base),sig(window_base));
        axis tight;
        title('time course');
        ylabel('microVolt');
        xlabel('second');
        
        subplot(2,2,3); 
        topoplot((A(:,i))-mean(A(:,i))',chanlocs,'electrodes' ,'off', 'style', 'map');
        title(['IC no. ' num2str(i)],'FontSize',12);
        
        
        subplot(2,2,4); 
        plot(F,mspettro(i,:),'r');
        axis([0 min(100,Fs/2) 0 1.1*max(mspettro(i,:))]);
        title('power spectrum');
        ylabel('microVolt^2/Hz');
        xlabel('Hz');
        
        
        %print([comp.fname(1:end-4) filesep 'IC_' num2str(i) '.tif'], '-dtiff', '-r100');   % save the figure, 05.03.2015
        
        if clas(i) > 0
            ButtonName=questdlg( 'How do you classify this component: Brain signal?', ...
                'Independent Components classification','Brain signal','Artifact','Brain signal');
        else
            ButtonName=questdlg('How do you classify this component: Artifact?', ...
                'Independent Components classification','Brain signal','Artifact','Artifact');
        end
        
        if strcmp(ButtonName,'Brain signal')
            g_ic=[g_ic i];
        else
            b_ic=[b_ic i];
        end % if
        
    end
    close all;
    
    clear sig;
    clear mat;
    
    ButtonName=questdlg('Are you sure that the classification is correct?', ...
        'Independent Components classification','Yes','No','Yes');
    
    if strcmp(ButtonName,'Yes')
        flag=1;
    end % if
end

comp_checked.good_ics = g_ic;
comp_checked.bad_ics = b_ic;
% 'g_ic' is the final list of good ICs

% 'b_ic' is the final list of bad ICs