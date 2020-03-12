function [tfs] = dft(irs, dft_definition)
%DFT Discrete Fourier transform
%   Is always performed along the first dimension of irs
%   dft_definition: 'matlab' (negative exponent in forward transform) or 
%                   'williams' (positive exponent in forward transform)

if strcmp(dft_definition, 'matlab')
    tfs = fft(irs, [], 1);
elseif strcmp(dft_definition, 'williams')
    tfs = ifft(irs) * size(irs, 1);
else 
    warning('Unknown method.');
end

end

