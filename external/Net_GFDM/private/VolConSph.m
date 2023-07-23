function [cr, ct] = VolConSph(cs, f)

cr = cs/f^(2/3);
ct = cr*f;