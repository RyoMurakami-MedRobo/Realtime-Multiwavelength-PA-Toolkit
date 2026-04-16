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
    fprintf('Starting TCP server...\n');
    server = tcpserver(cfg.network.server_host, cfg.network.server_port);
    server.InputBufferSize = 100 * 1024 * 1024;
    
    expected_header_bytes = 16;
    expected_image_bytes = cfg.shared_memory.image_width * cfg.shared_memory.image_height * 2; % int16
    expected_total_bytes = expected_header_bytes + expected_image_bytes;

    fprintf('Waiting for incoming data...\n');
    
    num_wl = cfg.shared_memory.num_wavelengths;
    frames_per_wl = cfg.shared_memory.frames_per_wavelength;
    layout_mode = cfg.modes.package_layout_mode;
    
    wavelength_buffer = cell(num_wl, 1);
    for w=1:num_wl
        wavelength_buffer{w} = zeros(cfg.shared_memory.image_width, cfg.shared_memory.image_height, frames_per_wl, 'int16');
    end
    
    valid_start_count = 2; % Typically skip the first dummy pulse
    fprintf('Package layout mode: %s\n', layout_mode);
    
    active_package_sequence = -1;
    valid_frames_count = zeros(num_wl, 1);
    
    while true
        if server.Connected && server.NumBytesAvailable >= expected_total_bytes
            raw_data = read(server, expected_total_bytes);
            
            % Process excess
            excess_bytes = server.NumBytesAvailable;
            if excess_bytes > 0
                read(server, excess_bytes); % drop excess
            end
            
            % Parse header: int32([h, w, success_count, frame_index])
            header_data = typecast(uint8(raw_data(1:16)), 'int32');
            h = header_data(1);
            w = header_data(2);
            success_count = header_data(3);
            % frame_index = header_data(4);
            
            if success_count < valid_start_count
                continue; % skip warmup frames
            end
            
            image_data = raw_data(17:end);
            frame_data = reshape(typecast(uint8(image_data), 'int16'), h, w);
            
            % Map frame to block or cyclic structure
            relative_count = double(success_count - valid_start_count);
            frames_per_package = num_wl * frames_per_wl;
            
            package_sequence = floor(relative_count / frames_per_package);
            relative_in_package = mod(relative_count, frames_per_package);
            
            % Flush and commit package if sequence automatically advanced 
            % (handles cases where the final frame of a package was dropped)
            if active_package_sequence >= 0 && package_sequence > active_package_sequence
                package_data = zeros(cfg.shared_memory.image_width, cfg.shared_memory.image_height, num_wl, 'int16');
                for ww = 1:num_wl
                    if valid_frames_count(ww) > 0
                        % Average only valid slots
                        package_data(:,:,ww) = int16(sum(double(wavelength_buffer{ww}), 3) ./ valid_frames_count(ww));
                    end
                    % Reset buffer
                    wavelength_buffer{ww}(:) = 0;
                    valid_frames_count(ww) = 0;
                end
                
                meta = struct(...
                    'success_count', success_count, ...
                    'timestamp_unix_ms', int64(posixtime(datetime('now')) * 1000));
                    
                shared_memory_write_package(state, package_data, meta);
                fprintf('Package [%d] committed (Triggered by missing EOF). success_count=%d.\n', active_package_sequence, success_count);
                active_package_sequence = package_sequence;
            elseif active_package_sequence < 0
                active_package_sequence = package_sequence;
            end
            
            if strcmpi(layout_mode, 'block')
                % Layout AAAA BBBB CCCC
                wl_idx = floor(relative_in_package / frames_per_wl) + 1;
                frame_idx = mod(relative_in_package, frames_per_wl) + 1;
            elseif strcmpi(layout_mode, 'cyclic')
                % Layout ABC ABC ABC ABC
                wl_idx = mod(relative_in_package, num_wl) + 1;
                frame_idx = floor(relative_in_package / num_wl) + 1;
            else
                error('Unknown package layout mode: %s', layout_mode);
            end
            
            wavelength_buffer{wl_idx}(:,:,frame_idx) = frame_data;
            valid_frames_count(wl_idx) = valid_frames_count(wl_idx) + 1;
            
            % When a cycle is complete, average frames and commit to shared memory
            if relative_in_package == frames_per_package - 1
                package_data = zeros(cfg.shared_memory.image_width, cfg.shared_memory.image_height, num_wl, 'int16');
                for ww = 1:num_wl
                    if valid_frames_count(ww) > 0
                        % Average only valid slots
                        package_data(:,:,ww) = int16(sum(double(wavelength_buffer{ww}), 3) ./ valid_frames_count(ww));
                    end
                    % Reset buffer
                    wavelength_buffer{ww}(:) = 0;
                    valid_frames_count(ww) = 0;
                end
                
                meta = struct(...
                    'success_count', success_count, ...
                    'timestamp_unix_ms', int64(posixtime(datetime('now')) * 1000));
                    
                shared_memory_write_package(state, package_data, meta);
                fprintf('Package [%d] committed safely. success_count=%d.\n', active_package_sequence, success_count);
                active_package_sequence = -1;
            end
        else
            pause(0.01);
        end
    end
end
