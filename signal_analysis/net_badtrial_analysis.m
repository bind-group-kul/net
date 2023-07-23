% function Der = net_badtrial_repair(De)
% Description: to find the bad trials and repair them
% De: the epoched data in SPM format
%
% last version: 03.04.2014

function Der = net_badtrial_analysis(epoched_data,options)



[nch,~,nev]=size(epoched_data);


%-Artefact detection
%--------------------------------------------------------------------------


var_val=ones(nch,nev);
for i=1:nch
    for j=1:nev
        var_val(i,j)=var(squeeze(data(i,:,j)));
    end
end

meanvar_val=mean(var_val,1);

meanvar_val_sel=meanvar_val(meanvar_val>=prctile(meanvar_val,options.prctile_sel) & meanvar_val<=prctile(meanvar_val,100-options.prctile_sel));
bad_events= find(meanvar_val>mean(meanvar_val_sel)+options.nstd*std(meanvar_val_sel));



Der = clone(De, ['r' fname(De)], [De.nchannels De.nfrequencies De.nsamples De.ntrials-length(bad_events)]);

cl   = De.condlist;
goodtrials = [];
for i = 1:numel(cl)
    goodtrials  = [goodtrials indtrial(De, cl{i}, 'GOOD')];
end
goodtrials(bad_events) = [];

Der(:,:,:) =  De(:, :, goodtrials);
Der.save

