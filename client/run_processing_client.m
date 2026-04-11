clear; close all; clc;

script_dir = fileparts(mfilename('fullpath'));
addpath(fullfile(script_dir, '..', 'config'));
addpath(fullfile(script_dir, '..', 'shared_memory'));

cfg = default_config();
state = shared_memory_init('client', cfg.shared_memory);

fprintf('=== Processing Client Skeleton ===\n');
status = shared_memory_get_status(state);
fprintf('Backend file: %s\n', state.file_path);
fprintf('Available packages: %d\n', status.unprocessed_frames);

idle_polls = 0;
idle_polls_limit = 10;

while true
    [ok, package_data, meta] = shared_memory_read_package(state);
    if ~ok
        status = shared_memory_get_status(state);
        if status.unprocessed_frames == 0
            idle_polls = idle_polls + 1;
            if idle_polls >= idle_polls_limit
                break;
            end
        else
            idle_polls = 0;
        end
        pause(0.2);
        continue;
    end

    idle_polls = 0;
    result = process_package_stub(package_data);
    shared_memory_mark_processed(state, meta.package_index);

    fprintf('Processed package %d | score=%.3f\n', meta.package_index, result.score);
end

fprintf('Client loop finished.\n');

function result = process_package_stub(package_data)
%PROCESS_PACKAGE_STUB Replace with beamforming/decomposition/detection pipeline.

x = double(package_data(:));
result = struct();
result.score = mean(abs(x));
end
