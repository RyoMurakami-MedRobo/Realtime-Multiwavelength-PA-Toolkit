clear; close all; clc;

script_dir = fileparts(mfilename('fullpath'));
addpath(fullfile(script_dir, '..', 'config'));
addpath(fullfile(script_dir, '..', 'shared_memory'));

cfg = default_config();
state = shared_memory_init('server', cfg.shared_memory);

fprintf('=== TCP Server Skeleton ===\n');
fprintf('Listening target: %s:%d\n', cfg.network.server_host, cfg.network.server_port);
fprintf('Simulation mode: %d\n', cfg.modes.simulation_only);

if cfg.modes.simulation_only
    package_data = int16(zeros(cfg.shared_memory.image_width, cfg.shared_memory.image_height, cfg.shared_memory.num_wavelengths));
    for w = 1:cfg.shared_memory.num_wavelengths
        package_data(:, :, w) = int16(w * 10);
    end

    meta = struct(...
        'success_count', 1, ...
        'package_index', 1, ...
        'timestamp_unix_ms', int64(posixtime(datetime('now')) * 1000));

    shared_memory_write_package(state, package_data, meta);
    fprintf('Wrote one mock package to DAT shared-memory backend.\n');
else
    % TODO: Replace with tcpserver callback-based implementation.
    % Recommended flow:
    % 1) Parse fixed header from Verasonics host packet.
    % 2) Assemble per-frame RF image.
    % 3) Aggregate by wavelength and averaging count.
    % 4) Write package to shared memory via shared_memory_write_package.
    error('TCP receive path is a TODO in this public minimal release.');
end
