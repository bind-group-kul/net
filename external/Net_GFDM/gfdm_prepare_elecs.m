% gfdm_prepare_elecs.m
% Ernesto Cuartas M (ECM), 24/04/2017
% Updated: 02/06/2020
% Email: ecuartasm@gmail.com

function elec_fdm = gfdm_prepare_elecs( cfg )
% gfdm_prepare_elecs.m
% Ernesto Cuartas M (ECM), 24/04/2017
% Updated: 02/06/2020
% Email: ecuartasm@gmail.com
%
% GFDM_PREPARE_ELECS ensures that the already aligned electrodes are placed 
% over the scalp surface, projecting the electrode positions across a line 
% with the center in the middle point of the GM. The electrodes must be placed 
% over scalp voxel positions, otherwise, the lead-pair source will not have a 
% valid position in the right hand side vector. 
%
% INPUT: ( cfg ) The cfg argument is a structure containing:
%   cfg.mri           a fieldtrip MRI structure holding an alrready aligned structural MRI
%   cfg.electrodes    a fieldtrip electrode structure containing the aligned electrodes
%   cfg.vol           head model structure
%
% OUTPUT: ( elec ) structure containing the FDM electrodes
%   elec_fdm.lead    array holding the lead-pair distribution
%   elec_fdm.leadp   vector holding the lead-pair distribution
%   elec_fdm.cent    midle point of the segmented GM
%   elec_fdm.OK      boolean flag indicating 
%
% EXAMPLE: example using gfdm_prepare_elecs
%   cfg               = [];
%   cfg.mri           = mri_aligned;
%   cfg.electrodes    = electrodes_aligned;
%   cfg.vol           = vol;
%   elec              = gfdm_prepare_elecs( cfg );

As     = cfg.vol.box.anatomy;
elcA   = cfg.elec;
% cent   = cfg.vol.cent_pos;
gm_idx = cfg.vol.gm_idx;
nele   = length(cfg.elec.elecpos);

box_Ti = cfg.vol.box.transform;
mri_Ti = cfg.vol.box.segTr;
Tr = mri_Ti*box_Ti;
elcps = [ elcA.elecpos' ; ones(1,length(elcA.elecpos))];
elcpsitr = (Tr^-1)*elcps;
elcA.elecpos = elcpsitr(1:3,:)';
elc = elcA.elecpos;
elecN = zeros(size(elc));

Msk = cell(size(gm_idx));
for a = 1:length(gm_idx)
    Msk{a} = (As == gm_idx(a));
end
m_gm = zeros(size(As));
for a = 1:length(gm_idx)
    m_gm = m_gm | Msk{a};
end

% maca = cfg.mri;
% maca.anatomy = gmvol;
% ft_sourceplot([], maca)

box = BoxMri(m_gm);
cent = box(3,:);

% Searching for a valid position inside the volume in the radial direction, lser is the maximun distant for the search 
lser = 0.75*max(cfg.vol.box.dim);
prc_OK = true;
ndir = [elc(:,1) - cent(1), elc(:,2) - cent(2), elc(:,3) - cent(3)];
for a = 1:nele
    nora = ndir(a,:);
    nora  = nora./norm(nora);    
    posN = [-1 -1 -1];
    psa = round(elc(a,:));
    for b = 1:lser
        psf = round(cent + (lser-b)*nora);
        if( check_surr_0(As, psf) )
            posN = psf;
            break;
        end
    end
    if(isequal(posN,[-1 -1 -1]))
        prc_OK = false;
    end
    elecN(a,:) = posN;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% scalp = zeros(size(cfg.vol.box.anatomy));
% scalp(cfg.vol.box.anatomy == 12) = 1;
% mripr = cfg.vol.box;
% mripr.scalp = scalp;
% mripr.transform = eye(4);
% 
% cfgs             = [];
% cfgs.tissue      = {'scalp'};
% cfgs.numvertices = [20000];
% bnd_seg          = ft_prepare_mesh(cfgs,mripr);
% % save('seg_mri.mat', 'seg_mri');
% figure
% ft_plot_mesh(bnd_seg(1), 'facecolor',[0.6 0.6 0.8], 'facealpha', 0.7, 'edgecolor', [1 1 1], 'edgealpha', 0.0);
% camlight
% hold on
% plot3(elecN(:,1), elecN(:,2), elecN(:,3), 'sg')
% for a = 1:length(elecN)
%     text(elecN(a,1), elecN(a,2), elecN(a,3), elcA.label{a})  
% end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%      automatic lead pairs rutine      %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

elec_beF = elcA;
elec_beF.elecpos = elecN;
elec_beF.chanpos = elecN;

elec = [elec_beF.elecpos, (1:length(elec_beF.elecpos))'];

lead = [];
elT = elec;
sel = 2;
for a = 1:length(elec_beF.elecpos)
    if(a==1)
        b = a;
        pa = b;
    end
    if(a > length(elec_beF.elecpos) - sel)
        sel = sel-1;
    end
    lead = [lead; b];
    if(a<length(elec_beF.elecpos))
        ela  = elec(b,1:3);
        elT(pa,:) = [];
        disa = [sqrt( (elT(:,1) - ela(1)).^2 + (elT(:,2) - ela(2)).^2 + (elT(:,3) - ela(3)).^2 ), elT(:,4), (1:size(elT,1))' ];
        mla = sortrows(disa, -1);
        pa = mla(sel, 3);
        b  = mla(sel,2);
    end
end 

%%%%%%%% trx lead fem %%%%%%%%%
% lead = [1:length(elec_beF.elecpos)]';
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

leadp = zeros(length(lead)-1, 2);
for a = 1:length(lead)-1
    leadp(a,:) = [lead(a) lead(a+1)];
end

elec_fdm         = elec_beF;
elec_fdm.lead    = lead;
elec_fdm.leadp   = leadp;
elec_fdm.cent    = cent;
elec_fdm.OK      = prc_OK;