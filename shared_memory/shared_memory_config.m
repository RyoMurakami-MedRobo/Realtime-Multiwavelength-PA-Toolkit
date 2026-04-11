function cfg = shared_memory_config(user_cfg)
%SHARED_MEMORY_CONFIG Returns the public DAT-backed shared-memory layout.

if nargin < 1 || ~isstruct(user_cfg)
    user_cfg = struct();
end

cfg = struct();

cfg.file_path = fullfile(tempdir, 'shared_image_data_public.dat');
cfg.image_width = 1792;
cfg.image_height = 128;
cfg.num_wavelengths = 4;
cfg.frames_per_wavelength = 4;
cfg.max_packages = 128;
cfg.data_type = 'int16';
cfg.bytes_per_pixel = 2;

fields = fieldnames(user_cfg);
for i = 1:numel(fields)
    cfg.(fields{i}) = user_cfg.(fields{i});
end

cfg.frame_elements = cfg.image_width * cfg.image_height;
cfg.package_elements = cfg.frame_elements * cfg.num_wavelengths;
cfg.package_payload_bytes = cfg.package_elements * cfg.bytes_per_pixel;

cfg.header_size = 48;
cfg.slot_header_size = 20;
cfg.slot_size = cfg.slot_header_size + cfg.package_payload_bytes;
cfg.total_size = cfg.header_size + cfg.slot_size * cfg.max_packages;

cfg.offset_total_packages = 0;
cfg.offset_valid_packages = 4;
cfg.offset_processed_packages = 8;
cfg.offset_last_success_count = 12;
cfg.offset_server_active = 16;
cfg.offset_reserved_1 = 17;
cfg.offset_num_wavelengths = 20;
cfg.offset_frames_per_wavelength = 24;
cfg.offset_image_width = 28;
cfg.offset_image_height = 32;
cfg.offset_max_packages = 36;
cfg.offset_slot_size = 40;

cfg.slot_status_offset = 0;
cfg.slot_package_index_offset = 4;
cfg.slot_success_count_offset = 8;
cfg.slot_timestamp_offset = 12;
cfg.slot_payload_offset = 20;

cfg.slot_empty = uint8(0);
cfg.slot_ready = uint8(1);
cfg.slot_processed = uint8(2);
end