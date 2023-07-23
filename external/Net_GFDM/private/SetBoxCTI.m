function mribx = SetBoxCTI( cti_a, bx )

Tr = eye(4);
Tr(1,4) = bx(1,1)-1;  Tr(2,4) = bx(2,1)-1;  Tr(3,4) = bx(3,1)-1;  

mri_sgbx = cti_a.anatomy(bx(1,1):bx(1,2), bx(2,1):bx(2,2), bx(3,1):bx(3,2), :);

mribx = [];
mribx.dim       = [ size(mri_sgbx,1) size(mri_sgbx,2) size(mri_sgbx,3) ];
mribx.transform = Tr;
mribx.segTr     = cti_a.transform;
% mribx.coordsys  = segmentedmri.coordsys;
mribx.unit      = cti_a.unit;
mribx.anatomy   = mri_sgbx;
mribx.box       = bx;

