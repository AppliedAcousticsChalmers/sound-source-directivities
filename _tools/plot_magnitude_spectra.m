function [] = plot_magnitude_spectra(coefficients, order, fs, sph_definition)
% Plots the magnitude spectra for a few directions around the main lobe
% in the horizontal plane

% frequency vector
f = linspace(5*eps, fs, size(coefficients, 1)).';

% select a few directions
azimuth    = (0 : 45 : 719)/180 * pi;
colatitude = pi/2;

% compute the directivity on the spatial grid
D = zeros(size(coefficients, 1), size(azimuth, 2));

for l = 0 : order
    for m = -l : l
        D = D + repmat(coefficients(:, l^2+l+m+1), [1 size(azimuth, 2)]) .* repmat(sphharm(l, m, colatitude, azimuth, sph_definition), [size(coefficients, 1) 1]); 
    end
end

% find main lobe
[~, ind] = max(rms(D(:, 1:end/2), 1));

% plot only the main lobe and 4 adjacent directions
D = D(:, ind(1) : ind(1)+4);

% plot selected directions
figure('Position', [100 100 500 200]);
set(gcf, 'Color', [1 1 1]);
semilogx(f, 20*log10(abs(D)), 'Linewidth', 2);
xlim([30 fs/2]);
grid on;

xlabel( 'Frequency (Hz)', 'Interpreter', 'latex' );
ylabel( 'Magnitude (dB)', 'Interpreter', 'latex' );

title(sprintf('Unscaled Magnitude Spectra in the Horizontal Plane (%d deg to %d deg azimuth)', round(azimuth(ind(1))/pi*180), round(azimuth(ind(1)+4)/pi*180)));

end
