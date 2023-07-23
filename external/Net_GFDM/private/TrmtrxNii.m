function T = TrmtrxNii( mri )

T = [mri.hdr.hist.srow_x; mri.hdr.hist.srow_y; mri.hdr.hist.srow_z; 0 0 0 1];