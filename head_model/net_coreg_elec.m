function elec_coreg = net_coreg_elec(elec, headshape)
%% co-register electrode positions with the sMRI headshape

pos = elec.chanpos;

pos_coreg = pos;
for j = 1:size(pos,1);
    coord = pos(j,:);
    dist = sum((headshape-ones(size(headshape,1),1)*coord).^2,2);%Compute the distance from each vertices to the sensor position
    [~,pos_n] = min(dist);%Find the vertice that is close to the sensor position
    pos_coreg(j,:)=headshape(pos_n,:);%Now use that vertices as the sensor position
end

elec_coreg = elec;
elec_coreg.chanpos = pos_coreg;
elec_coreg.elecpos = pos_coreg;