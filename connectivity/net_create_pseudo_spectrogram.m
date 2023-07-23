function [] = net_create_pseudo_spectrogram(source,path)
% transform sst components into power spectral density (PSD) matrix

%% load channel decompositions
[nchan, nf, ntp] = size(source.sft_data_tensor);
nvox = length( find(source.inside == 1) );
freq = 1:nf;
Fs = 200;
win.length = 2;
win.samples = round(win.length*Fs);
win.step = 1;
win.overlaptp = round(Fs*(win.length-win.step));
win.nwin = fix((ntp-win.overlaptp)/(win.samples-win.overlaptp));
colind = 1 + (0:(win.nwin-1))*(win.samples-win.overlaptp);
rowind = (1:win.samples)';
var = {win.samples,win.overlaptp,freq,Fs};

%% reconstruct source activity
spec_sst = zeros(nf,win.nwin,nvox);
[~,~,~,~,~,ww] = net_welchparse(zeros(1,ntp),'psd',var{:});
for v = 1:nvox
    display( [ 'Voxel nr. ' num2str(v) ] )
    temp_spec = zeros(win.samples,win.nwin,nf);

for f = 1:nf
    temp_brain = source.pca_projection(v,(3*v-2):(3*v))*source.imagingkernel((3*v-2):(3*v),:)*squeeze(source.sft_data_tensor(:,f,:));
    % power before windowing
    Xf = (temp_brain.*conj(temp_brain))';
    %% reshape as spectrogram
    temp_spec(:,:,f) = ww.*Xf(rowind(:,ones(1,win.nwin))+colind(ones(win.samples,1),:)-1);
end
    temp = mean(temp_spec,1);
    temp = squeeze(temp)';
    % save each pseudo-spectrogram in the corresponding slice of the matrix
    spec_sst(:,:,v) = temp;
end
save([ path filesep 'pseudo_spectrogram_psd.mat' ],'spec_sst','-v7.3')

end
