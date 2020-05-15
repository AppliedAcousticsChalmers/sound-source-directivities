function [rms_error, D] = verify_spherical_harmonics_decomposition(dataset, sph_definition)
% Compare a reconstruction of the data at the measurement locations with
% the measurement data

% compute the directivity on the spatial grid
D = zeros(size(dataset.coefficients, 1), size(dataset.azimuth, 2));

for l = 0 : dataset.order
    for m = -l : l
        D = D + repmat(dataset.coefficients(:, l^2+l+m+1), [1 size(dataset.azimuth, 2)]) .* repmat(sphharm(l, m, dataset.colatitude, dataset.azimuth, sph_definition), [size(dataset.coefficients, 1) 1]); 
    end
end

rms_error = rms(D(:) - dataset.tfs(:));

end


