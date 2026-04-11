function [ok, package_data, meta] = shared_memory_read_package(state)
%SHARED_MEMORY_READ_PACKAGE Returns the first ready package from the DAT file.

ok = false;
package_data = [];
meta = struct();

cfg = state.config;
header = read_header(state.mmf, cfg);

if double(header.valid_packages) < 1
    return;
end

for idx = 1:double(header.valid_packages)
    slot_offset = cfg.header_size + (idx - 1) * cfg.slot_size;
    slot_status = state.mmf.Data(1).data(1, slot_offset + cfg.slot_status_offset + 1);
    if slot_status ~= cfg.slot_ready
        continue;
    end

    payload_bytes = state.mmf.Data(1).data(1, slot_offset + cfg.slot_payload_offset + 1 : slot_offset + cfg.slot_payload_offset + cfg.package_payload_bytes);
    payload = typecast(payload_bytes, 'int16');
    package_data = reshape(payload, cfg.image_width, cfg.image_height, cfg.num_wavelengths);

    meta.package_index = double(typecast(state.mmf.Data(1).data(1, slot_offset + cfg.slot_package_index_offset + 1 : slot_offset + cfg.slot_package_index_offset + 4), 'uint32'));
    meta.success_count = double(typecast(state.mmf.Data(1).data(1, slot_offset + cfg.slot_success_count_offset + 1 : slot_offset + cfg.slot_success_count_offset + 4), 'uint32'));
    meta.timestamp_unix_ms = double(typecast(state.mmf.Data(1).data(1, slot_offset + cfg.slot_timestamp_offset + 1 : slot_offset + cfg.slot_timestamp_offset + 8), 'int64'));
    meta.slot_status = double(slot_status);

    ok = true;
    return;
end
end

function header = read_header(mmf, cfg)
header.total_packages = typecast(mmf.Data(1).data(1, cfg.offset_total_packages + 1 : cfg.offset_total_packages + 4), 'uint32');
header.valid_packages = typecast(mmf.Data(1).data(1, cfg.offset_valid_packages + 1 : cfg.offset_valid_packages + 4), 'uint32');
header.processed_packages = typecast(mmf.Data(1).data(1, cfg.offset_processed_packages + 1 : cfg.offset_processed_packages + 4), 'uint32');
end
