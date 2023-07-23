function [peaks]=net_trig_dev(trace_abs,thres)

values=(trace_abs > thres);

vett=[];
max_pos=[];
for i=1:length(trace_abs)
    if values(i)==1
        vett=[vett,i];
    else
        if ~isempty(vett)
            [val,pos]=max(trace_abs(vett));
            max_pos=[max_pos,pos+vett(1)-1];
        end
        vett=[];
    end
end
peaks=max_pos;