% afdm_precalculate_leads.m
% Ernesto Cuartas M (ECM), 24/04/2017
% Email:  ecuartasmo@unal.edu.co

function lead = gfdm_precalculate_leads( cfg )

% source memory allocation space
if(strcmp(cfg.gmask, 'source'))    
    pos = cfg.grid.pos;
    ins = cfg.grid.inside;
    Tr  = cfg.mri.transform;
    
    [nonz val] = find(ins == 1);
    posi = pos(nonz,:);
    posi = posi * 10; % to mm
    posmri = ft_warp_apply(Tr^(-1), posi); % transform to head coordinates
    
    cfg_gm = [];
    cfg_gm.source_loc = posmri;
    cfg_gm.c_idx = cfg.vol.c_idx;
    cfg_gm.NoNonZeros = cfg.vol.Nz;
    gm_idx = FindSourceReciprocitySpace( cfg_gm );
    
elseif(strcmp(cfg.gmask, 'gm'))
    Seg = cfg.mri.anatomy;
    gmvol = logical( Seg == cfg.conductivity.gm_idx ); 
    cfg_gm = [];
    cfg_gm.c_idx = cfg.vol.c_idx;
    cfg_gm.gmvol = gmvol;
    cfg_gm.NoNonZeros = cfg.vol.Nz;
    gm_idx = FindGMReciprocitySpace( cfg_gm );
    
else
    gm_idx = ones(cfg.vol.Nz, 1);
end

folderDOS  = [cfg.folder '\tmp'];
folderLead = [folderDOS '\leads'];

if(cfg.save_lead_pair)
    if ~isdir(folderLead)
        mkdir(folderLead);  % Create the output folder if it doesn't exist..
        disp(['NET - Generating output_folder: ' folderLead]);
    end
end

elc = cfg.elec_OK.chanpos;
lds = cfg.elec_OK.leadp;

nele = cfg.elec_OK.nelec;
c_idx = cfg.vol.c_idx;
% Ep = zeros(nele, 1);
% for a = 1:nele
%     Ep(a) = c_idx(elc(a,1)-1, elc(a,2)-1, elc(a,3)-1) - 1;
% end

mA = cfg.vol.stiff;
% Building iLU decomposition for the solver
[iL,iU] = ilu(mA,struct('droptol',1e-15));

tol   = cfg.solver.tol;
maxit = cfg.solver.maxit;
Cidx  = cfg.vol.Cidx;
Nz    = cfg.vol.Nz;
NoLeads = length(lds);

lead.vol    = cfg.vol;
lead.c_idx  = cfg.vol.c_idx;
lead.VoxelSize = cfg.vol.VoxelSize;
lead.solver = cfg.solver;
lead.mri    = cfg.mri;
lead.elec   = cfg.elec_OK;
lead.conductivity = cfg.conductivity;
lead.register = cfg.register;
lead.fname = ['precalculated_lead_afdm.mat'];


% lead.conductivity.csf_label = csf_label;
lead.indexes = sparse(Cidx);
lead.pots = sparse(Nz,NoLeads);
lindx = lead.indexes;

lead.solver.tleads = zeros(NoLeads,1);
lead.solver.fla = zeros(NoLeads,1);
lead.solver.rra = zeros(NoLeads,1);
lead.solver.ita = zeros(NoLeads,1);
lead.solver.rva = cell(NoLeads,1);

% Saving Non Zero index
if(cfg.save_lead_pair)
    save([folderLead '\head_model_lead_indx.mat'],'lindx', '-v7.3');
end

tott = 0;
for k = 1:NoLeads
    tic
    fprintf('Calculating LeadPair %d/%d\n', k, NoLeads);
    B = sparse(zeros(Nz,1));
    
    ld1 = lds(k,1);
    ld2 = lds(k,2);
    
    p1 = c_idx( elc(ld1,1), elc(ld1,2), elc(ld1,3) );
    p2 = c_idx( elc(ld2,1), elc(ld2,2), elc(ld2,3) );
    
    B(p1) = 1;
    B(p2) = -1;
    
    % Iterative non stacionary BiCG Stabilazed solver with iLU preconditioner
    [xa, fla, rra, ita, rva] = bicgstab(mA,B,tol,maxit, iL, iU);
    potk = xa .* gm_idx;

    lead.pots(:,k) = sparse(potk);
    
    fnamek = [folderLead '\head_model_lead_' int2str(k) '.mat'];
    % Saving leadpairs
    if(cfg.save_lead_pair)
        save(fnamek,'xa', '-v7.3');
    end
    
    tbicg = toc;
    tott = tott + tbicg;
    
    lead.solver.tleads(k) = tbicg;
    lead.solver.fla(k) = fla;
    lead.solver.rra(k) = rra;
    lead.solver.ita(k) = ita;
    lead.solver.rva{k} = rva;
    
    fprintf('LeadPair %d ready - time: %f  - lead: %d -> %d\n', k, tbicg, ld1, ld2);
    fprintf('Flag: %d   |   Relative residual: %e \n', fla, rra);
    if(cfg.save_lead_pair)
        fprintf('File Saved: %s\n', fnamek);
    end
end

lead.solver.tott = tott;

% Saving precalculated leadfield Potentials
if(cfg.save_lead)
    save(lead.fname,'lead','-v7.3');
end

fprintf('LeadField ready - Total time: %f\n', tott);
% disp(lead.fname);    