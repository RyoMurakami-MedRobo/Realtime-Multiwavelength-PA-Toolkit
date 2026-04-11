function shared_memory_write_package(state, package_data, meta)
%SHARED_MEMORY_WRITE_PACKAGE Writes one package into a DAT slot.

cfg = state.config;

if nargin < 3 || isempty(meta)
    meta = struct();
end

if ~isa(package_data, 'int16')
    package_data = int16(package_data);
end

expected_size = [cfg.image_width, cfg.image_height, cfg.num_wavelengths];
if ~isequal(size(package_data), expected_size)
    error('Package size mismatch. Expected [%d %d %d], got [%d %d %d].', ...
        expected_size(1), expected_size(2), expected_size(3), ...
        size(package_data, 1), size(package_data, 2), size(package_data, 3));
end

header = read_header(state.mmf, cfg);
idx = double(header.total_packages) + 1;
if idx > cfg.max_packages
    error('Package capacity exceeded. Increase max_packages in config.');
end

slot_offset = cfg.header_size + (idx - 1) * cfg.slot_size;
payload_bytes = typecast(package_data(:), 'uint8');
timestamp_unix_ms = get_meta_int64(meta, 'timestamp_unix_ms', int64(posixtime(datetime('now')) * 1000));
success_count = uint32(get_meta_scalar(meta, 'success_count', 0));

write_slot_field(state.mmf, slot_offset + cfg.slot_status_offset, cfg.slot_ready);
write_slot_field(state.mmf, slot_offset + cfg.slot_package_index_offset, uint32(idx));
write_slot_field(state.mmf, slot_offset + cfg.slot_success_count_offset, success_count);
write_slot_field(state.mmf, slot_offset + cfg.slot_timestamp_offset, int64(timestamp_unix_ms));
state.mmf.Data(1).data(1, slot_offset + cfg.slot_payload_offset + 1 : slot_offset + cfg.slot_payload_offset + numel(payload_bytes)) = payload_bytes;

header.total_packages = uint32(idx);
header.valid_packages = uint32(idx);
header.last_success_count = success_count;
header.server_active = uint8(1);
write_header(state.mmf, cfg, header);
end

function value = get_meta_scalar(meta, field_name, default_value)
if isstruct(meta) && isfield(meta, field_name) && ~isempty(meta.(field_name))
    value = meta.(field_name);
else
    value = default_value;
end
end

function value = get_meta_int64(meta, field_name, default_value)
value = get_meta_scalar(meta, field_name, default_value);
value = int64(value);
end

function header = read_header(mmf, cfg)
header.total_packages = typecast(mmf.Data(1).data(1, cfg.offset_total_packages + 1 : cfg.offset_total_packages + 4), 'uint32');
header.valid_packages = typecast(mmf.Data(1).data(1, cfg.offset_valid_packages + 1 : cfg.offset_valid_packages + 4), 'uint32');
header.processed_packages = typecast(mmf.Data(1).data(1, cfg.offset_processed_packages + 1 : cfg.offset_processed_packages + 4), 'uint32');
header.last_success_count = typecast(mmf.Data(1).data(1, cfg.offset_last_success_count + 1 : cfg.offset_last_success_count + 4), 'uint32');
header.server_active = mmf.Data(1).data(1, cfg.offset_server_active + 1);
end

function write_header(mmf, cfg, header)
write_slot_field(mmf, cfg.offset_total_packages, uint32(header.total_packages));
write_slot_field(mmf, cfg.offset_valid_packages, uint32(header.valid_packages));
write_slot_field(mmf, cfg.offset_processed_packages, uint32(header.processed_packages));
write_slot_field(mmf, cfg.offset_last_success_count, uint32(header.last_success_count));
write_slot_field(mmf, cfg.offset_server_active, uint8(header.server_active));
write_slot_field(mmf, cfg.offset_num_wavelengths, uint32(cfg.num_wavelengths));
write_slot_field(mmf, cfg.offset_frames_per_wavelength, uint32(cfg.frames_per_wavelength));
write_slot_field(mmf, cfg.offset_image_width, uint32(cfg.image_width));
write_slot_field(mmf, cfg.offset_image_height, uint32(cfg.image_height));
write_slot_field(mmf, cfg.offset_max_packages, uint32(cfg.max_packages));
write_slot_field(mmf, cfg.offset_slot_size, uint32(cfg.slot_size));
end

function write_slot_field(mmf, offset, value)
bytes = typecast(value, 'uint8');
mmf.Data(1).data(1, offset + 1 : offset + numel(bytes)) = bytes;
end
