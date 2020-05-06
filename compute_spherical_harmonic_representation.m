% Compute the spherical harmonic model of a given dataset. The output are
% the according spherical harmonic coefficients. The decomposition is 
% verified against the measurement data, and the RMS error is displayed.
%
% The script also plots a few example magnitude spectra inside the
% horizontal plane.
%
% Author: Jens Ahrens, March 2020
% 
% Instructions:
%
% - Choose the spherical harmonics definition (line 16).
% - Choose the DFT definition (line 17).
% - Choose the dataset (line 19).

clear;

addpath('_tools');

sph_definition = 'real_w_cs'; % see file _tools/sphharm.m for the options
dft_definition = 'matlab'; % see file _tools/dft.m for the options

%dataset_file_name = 'loudspeaker_cube_DirPat/irs_DirPat_loudspeaker_cube_1_N6.mat';
%dataset_file_name = 'loudspeaker_cube_DirPat/irs_DirPat_loudspeaker_cube_2_N6.mat';
%dataset_file_name = 'loudspeaker_cube_DirPat/irs_DirPat_loudspeaker_cube_3_N6.mat';
%dataset_file_name = 'loudspeaker_cube_DirPat/irs_DirPat_loudspeaker_cube_4_N6.mat';

%dataset_file_name = 'singing_voice_DirPat/irs_DirPat_a_long_sweep_N9_non-reg.mat';
%dataset_file_name = 'singing_voice_DirPat/irs_DirPat_a_long_sweep_N9_reg.mat';

%dataset_file_name = 'singing_voice_DirPat/irs_DirPat_a_closed_sweep_N9_non-reg.mat';
%dataset_file_name = 'singing_voice_DirPat/irs_DirPat_a_closed_sweep_N9_reg.mat';

%dataset_file_name = 'singing_voice_DirPat/irs_DirPat_a_open_sweep_N9_non-reg.mat';
%dataset_file_name = 'singing_voice_DirPat/irs_DirPat_a_open_sweep_N9_reg.mat';

%dataset_file_name = 'singing_voice_DirPat/irs_DirPat_a_wide_sweep_N9_non-reg.mat';
%dataset_file_name = 'singing_voice_DirPat/irs_DirPat_a_wide_sweep_N9_reg.mat';

dataset_file_name = 'oboe_TUB_RWTH/irs_Oboe_modern_c5_N4.mat';

% -------------------------------------------------------------------------

dataset = load(dataset_file_name);

% Convert to frequency domain
dataset.tfs = dft(dataset.irs, dft_definition);

% compute the coefficients
dataset.coefficients = least_squares_sh_fit(dataset.order, dataset.tfs, dataset.azimuth, dataset.colatitude, sph_definition);

% verify the spherical harmonics decomposition against the measurement data
rms_error = verify_spherical_harmonics_decomposition(dataset, sph_definition);

fprintf('\n The RMS error between the SH decomposition and the measurement data is:\n');
fprintf('%f dB\n\n', 20*log10(rms_error));

% plot the directivity
balloon_plot(dataset.coefficients, dataset.order, dataset.fs, sph_definition);

% store a png of the balloon plots
%saveas(gcf, [dataset_file_name(1:end-3) 'png']);

% plot a few example spectra
plot_magnitude_spectra(dataset.coefficients, dataset.order, dataset.fs, sph_definition);

% store a png of the magnitude spectra
%title('Unscaled Magnitude Spectra in the Horizontal Plane'); saveas(gcf, [dataset_file_name(1:end-4) '_spec.png']);