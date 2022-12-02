function [Ynm] = sphharm(n, m, beta, alpha, type)
% Spherical harmonics of degree n and order m.
%
% [Ynm] = sphharm(n, m, beta, alpha, type);
%
% n           - spherical harmonic degree
% m           - spherical harmonic order
% beta        - colatitude to be calculated
% alpha       - azimuth to be calculated 
% type        - 'complex' (default), 'complex_wo_cs', 'real_wo_cs',
%               'real_w_cs', 'wikipedia'
%
% alpha and beta can be arrays but have to be of same size or one of them
% has to be a scalar.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This work is supplementary material for the book                        %
%                                                                         %
% Jens Ahrens, Analytic Methods of Sound Field Synthesis, Springer-Verlag %
% Berlin Heidelberg, 2012, http://dx.doi.org/10.1007/978-3-642-25743-8    %
%                                                                         %
% It has been downloaded from http://soundfieldsynthesis.org and is       %
% licensed under a Creative Commons Attribution-NonCommercial-ShareAlike  % 
% 3.0 Unported License. Please cite the book appropriately if you use     % 
% these materials in your own work.                                       %
%                                                                         %
% (c) 2012 by Jens Ahrens                                                 %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if (nargin < 5)
    type = 'complex';
end

if (n < 0)
    error('Degree(n) must not be negative.')
end

if (n < abs(m))
    warning('Absolute value of order m must be less than or equal to the degree n.'); 
    Ynm = zeros( size( alpha ) );
    return;
end

Lnm = asslegendre(n, abs(m), cos(beta));

factor_1     = (2*n + 1) / (4*pi);
factor_2     = factorial(n - m) ./ factorial(n + m);
factor_2_abs = factorial(n - abs(m)) ./ factorial(n + abs(m));

% Complex spherical harmonics (used in (Ahrens, 2012), (Gumerov and Duraiswami, 2004))
if (strcmp(type, 'complex'))
    
    Ynm = (-1).^m .* sqrt(factor_1 .* factor_2_abs) .* Lnm .* exp(1i .* m .* alpha);

% Complex without Condon-Shortley phase cancelation; same as scipy
elseif (strcmp(type, 'complex_wo_cs'))
    
    Lnm = asslegendre(n, m, cos(beta));
    
    Ynm = sqrt(factor_1 .* factor_2) .* Lnm .* exp(1i .* m .* alpha);
    
% Real valued spherical harmonics with Condon-Shortley phase cancelation (and with |m| 
% in the sine!); as defined on https://en.wikipedia.org/wiki/Spherical_harmonics
% this is the one that is used in Ambisonics
elseif(strcmp(type, 'real'))
        
    if (m ~= 0)
        factor_1 = 2 * factor_1;
    end
    
    if (m < 0)
        Ynm = (-1).^m .* sqrt(factor_1 .* factor_2_abs) .* Lnm .* sin(abs(m) .* alpha);
    else % m >= 0
        Ynm = (-1).^m .* sqrt(factor_1 .* factor_2_abs) .* Lnm .* cos(m .* alpha);
    end
    
else
    error('Unknown type.');    
    
end

end
