function [Pcorrect] = calc_percor(errTable,deg);
% Calculate percent correct from an error table (a confusion matrix)
%
% Copyright (c) 2009, Okito Yamashita, ATR CNS, oyamashi@atr.jp.
% Modified by SH, 2014,May

Nsamp = sum(errTable(:));
Ncor  = sum(diag(errTable));

Pcorrect = Ncor/Nsamp * 100;  % percent 

