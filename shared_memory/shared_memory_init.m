function state = shared_memory_init(role, user_cfg)
%SHARED_MEMORY_INIT Initializes the public DAT-backed shared-memory file.

sm = shared_memory_config(user_cfg);

state = struct();
state.role = role;
state.file_path = sm.file_path;
state.max_packages = sm.max_packages;
state.config = sm;
state.mmf = [];

if strcmpi(role, 'server')
    if isfile(sm.file_path)
        delete(sm.file_path);
    end

    fid = fopen(sm.file_path, 'w+b');
    if fid < 0
        error('Failed to create shared memory file: %s', sm.file_path);
    end
    try
        chunk_size = 10 * 1024 * 1024;
        remaining = sm.total_size;
        zeros_chunk = zeros(1, min(chunk_size, remaining), 'uint8');
        while remaining > 0
            write_size = min(chunk_size, remaining);
            if numel(zeros_chunk) ~= write_size
                zeros_chunk = zeros(1, write_size, 'uint8');
            end
            fwrite(fid, zeros_chunk, 'uint8');
            remaining = remaining - write_size;
        end
    catch ME
        fclose(fid);
        error('Failed to size shared memory file: %s', ME.message);
    end
    fclose(fid);
elseif ~isfile(sm.file_path)
    error('Shared backend file not found. Start server first: %s', sm.file_path);
end

state.mmf = memmapfile(sm.file_path, ...
    'Format', {'uint8', [1, sm.total_size], 'data'}, ...
    'Writable', true, ...
    'Repeat', 1);

if strcmpi(role, 'server')
    write_header_field(state.mmf, sm.offset_total_packages, uint32(0));
    write_header_field(state.mmf, sm.offset_valid_packages, uint32(0));
    write_header_field(state.mmf, sm.offset_processed_packages, uint32(0));
    write_header_field(state.mmf, sm.offset_last_success_count, uint32(0));
    write_header_field(state.mmf, sm.offset_server_active, uint8(1));
    write_header_field(state.mmf, sm.offset_num_wavelengths, uint32(sm.num_wavelengths));
    write_header_field(state.mmf, sm.offset_frames_per_wavelength, uint32(sm.frames_per_wavelength));
    write_header_field(state.mmf, sm.offset_image_width, uint32(sm.image_width));
    write_header_field(state.mmf, sm.offset_image_height, uint32(sm.image_height));
    write_header_field(state.mmf, sm.offset_max_packages, uint32(sm.max_packages));
    write_header_field(state.mmf, sm.offset_slot_size, uint32(sm.slot_size));
end
end

function write_header_field(mmf, offset, value)
bytes = typecast(value, 'uint8');
mmf.Data(1).data(1, offset + 1 : offset + numel(bytes)) = bytes;
end
