function create_mock_dataset(output_path)
%CREATE_MOCK_DATASET Creates a tiny educational mock MAT dataset.

if nargin < 1
    output_path = fullfile(fileparts(mfilename('fullpath')), 'mock_dataset.mat');
end

rng(7);
mock = struct();
mock.description = 'Tiny mock package for public skeleton dry-run';
mock.image_width = 16;
mock.image_height = 8;
mock.num_wavelengths = 4;
mock.frames_per_wavelength = 2;
mock.package_data = int16(randi([-100, 100], ...
    mock.image_width, mock.image_height, mock.num_wavelengths));
mock.meta = struct(...
    'success_count', 1, ...
    'package_index', 1, ...
    'timestamp', datestr(now, 'yyyy-mm-dd HH:MM:SS.FFF'));

save(output_path, 'mock');
fprintf('Mock dataset created: %s\n', output_path);
end
