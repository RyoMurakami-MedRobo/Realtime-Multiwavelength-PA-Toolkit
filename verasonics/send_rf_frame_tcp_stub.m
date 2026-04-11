function send_rf_frame_tcp_stub(tcp_client, frame_data, meta)
%SEND_RF_FRAME_TCP_STUB Minimal packet sender (public protocol example).

if ~isa(frame_data, 'int16')
    error('frame_data must be int16');
end

[h, w] = size(frame_data);
header = int32([h, w, meta.success_count, meta.frame_index]);

if isempty(tcp_client)
    fprintf('[Offline Demo] Packet prepared: %dx%d, success_count=%d, frame_index=%d\n', ...
        h, w, meta.success_count, meta.frame_index);
    return;
end

write(tcp_client, typecast(header, 'uint8'), 'uint8');
write(tcp_client, typecast(frame_data(:), 'uint8'), 'uint8');
end
