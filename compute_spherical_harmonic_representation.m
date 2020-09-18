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
% - Choose the spherical harmonics definition (line 20).
% - Choose the DFT definition (line 21).
% - Choose the dataset (lines 22-).

clear;

addpath('_tools');

sph_definition = 'real_w_cs'; % see file _tools/sphharm.m for the options
dft_definition = 'matlab'; % see file _tools/dft.m for the options

% -- musical instruments --

%dataset_file_name = 'musical_instruments/oboe_modern_TUB_RWTH/Oboe_modern_et_ff_c5.mat';

% -- loudspeakers --

%dataset_file_name = 'loudspeakers/loudspeaker_cube_DirPat/loudspeaker_cube_driver_1.mat';
dataset_file_name = 'loudspeakers/loudspeakers_3D3A/Genelec_8351A.mat';

% -- voice --

%dataset_file_name = 'voice/singing_voice_DirPat/singing_voice_a_long_sweep_reg.mat';


% -------------------------------------------------------------------------

dataset = load(dataset_file_name);

% Convert to frequency domain
dataset.tfs = dft(dataset.irs, dft_definition);

% Change desired order here
%dataset.order = 3;

% compute the coefficients
dataset.coefficients = least_squares_sh_fit(dataset.order, dataset.tfs, dataset.azimuth, dataset.colatitude, sph_definition);

% verify the spherical harmonics decomposition against the measurement data
rms_error = verify_spherical_harmonics_decomposition(dataset, sph_definition);

fprintf('\n The RMS error between the SH decomposition and the data at the support points is:\n');
fprintf('%f dB\n\n', 20*log10(rms_error));

% plot the directivity
f_to_plot = [500 1000 2000 4000];
balloon_plot(dataset.coefficients, dataset.order, dataset.fs, sph_definition, f_to_plot);

% store a png of the balloon plots
%saveas(gcf, [dataset_file_name(1:end-3) 'png']);

% plot a few example spectra
plot_magnitude_spectra(dataset.coefficients, dataset.order, dataset.fs, sph_definition);

% store a png of the magnitude spectra
%title('Unscaled Magnitude Spectra in the Horizontal Plane'); saveas(gcf, [dataset_file_name(1:end-4) '_spec.png']);
