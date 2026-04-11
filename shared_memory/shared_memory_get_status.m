function status = shared_memory_get_status(state)
%SHARED_MEMORY_GET_STATUS Returns status information from the DAT backend.

cfg = state.config;

status.total_frames = 0;
status.valid_frames = 0;
status.processed_frames = 0;
status.unprocessed_frames = 0;
status.last_success_count = 0;
status.server_active = false;
status.num_wavelengths = cfg.num_wavelengths;
status.frames_per_wavelength = cfg.frames_per_wavelength;
status.available_frames = [];

if ~isfile(state.file_path)
    return;
end

header = read_header(state.mmf, cfg);
status.total_frames = double(header.total_packages);
status.valid_frames = double(header.valid_packages);
status.processed_frames = double(header.processed_packages);
status.unprocessed_frames = max(0, status.valid_frames - status.processed_frames);
status.last_success_count = double(header.last_success_count);
status.server_active = logical(header.server_active);

if status.unprocessed_frames > 0
    status.available_frames = (status.processed_frames + 1):status.valid_frames;
end
end

function header = read_header(mmf, cfg)
header.total_packages = typecast(mmf.Data(1).data(1, cfg.offset_total_packages + 1 : cfg.offset_total_packages + 4), 'uint32');
header.valid_packages = typecast(mmf.Data(1).data(1, cfg.offset_valid_packages + 1 : cfg.offset_valid_packages + 4), 'uint32');
header.processed_packages = typecast(mmf.Data(1).data(1, cfg.offset_processed_packages + 1 : cfg.offset_processed_packages + 4), 'uint32');
header.last_success_count = typecast(mmf.Data(1).data(1, cfg.offset_last_success_count + 1 : cfg.offset_last_success_count + 4), 'uint32');
header.server_active = mmf.Data(1).data(1, cfg.offset_server_active + 1);
end
