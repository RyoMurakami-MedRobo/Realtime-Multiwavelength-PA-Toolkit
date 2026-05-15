function setup_paths()
%SETUP_PATHS Adds toolkit subfolders to the current MATLAB session path.
%
% Run this once after opening MATLAB at the repository root. After this,
% server/run_tcp_server, client/run_processing_client, the shared-memory
% helpers, the Verasonics stubs, and the sample data utilities are all
% reachable from anywhere on the path.

root = fileparts(mfilename('fullpath'));

subdirs = { ...
    'config', ...
    'shared_memory', ...
    'server', ...
    'client', ...
    'verasonics', ...
    'sample_data'};

for i = 1:numel(subdirs)
    addpath(fullfile(root, subdirs{i}));
end

fprintf('Realtime-Multiwavelength-PA-Toolkit paths added (%d folders).\n', numel(subdirs));
end
