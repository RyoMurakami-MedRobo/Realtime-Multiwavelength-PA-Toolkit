function shared_memory_mark_processed(state, package_index)
%SHARED_MEMORY_MARK_PROCESSED Marks a DAT slot as processed.

cfg = state.config;
header = read_header(state.mmf, cfg);

if package_index < 1 || package_index > double(header.valid_packages)
    error('Invalid package index: %d', package_index);
end

slot_offset = cfg.header_size + (package_index - 1) * cfg.slot_size;
slot_status = state.mmf.Data(1).data(1, slot_offset + cfg.slot_status_offset + 1);

if slot_status == cfg.slot_ready
    state.mmf.Data(1).data(1, slot_offset + cfg.slot_status_offset + 1) = cfg.slot_processed;
    processed = double(header.processed_packages) + 1;
    write_header_field(state.mmf, cfg.offset_processed_packages, uint32(processed));
end
end

function header = read_header(mmf, cfg)
header.valid_packages = typecast(mmf.Data(1).data(1, cfg.offset_valid_packages + 1 : cfg.offset_valid_packages + 4), 'uint32');
header.processed_packages = typecast(mmf.Data(1).data(1, cfg.offset_processed_packages + 1 : cfg.offset_processed_packages + 4), 'uint32');
end

function write_header_field(mmf, offset, value)
bytes = typecast(value, 'uint8');
mmf.Data(1).data(1, offset + 1 : offset + numel(bytes)) = bytes;
end
