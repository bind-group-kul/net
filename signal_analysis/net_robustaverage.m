function ave_data = net_robustaverage(epoched_data,n_range)
               
dims=size(epoched_data);

epoched_data=reshape(epoched_data,dims(1),prod(dims(2:end)));

int=max(abs(epoched_data),[],2);

[~,normal]=net_tukey(int,n_range);

ave_data=mean(epoched_data(normal,:,:),1);

ave_data=reshape(ave_data,dims(2:end));