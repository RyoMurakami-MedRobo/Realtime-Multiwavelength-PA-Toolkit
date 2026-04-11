% Notice:
%   This script is adapted for public release from a workflow originally
%   based on Verasonics programming examples by Medical FUSION Laboratory,
%   Worcester Polytechnic Institute.
%
%   This file is intentionally minimal and masks probe/site-specific setup.

clear; close all; clc;

addpath(fullfile(fileparts(mfilename('fullpath')), '..', 'config'));
cfg = default_config();

fprintf('=== Verasonics Host Template (Public Minimal) ===\n');
fprintf('Target server: %s:%d\n', cfg.network.server_host, cfg.network.server_port);
fprintf('Arduino link: %s @ %d baud\n', cfg.hardware.arduino_com_port, cfg.hardware.arduino_baud);

% TODO: Replace this block with your licensed Verasonics SDK setup.
% - Define Resource, Trans, TX, Receive, Recon, Process structs.
% - Bind callback so each received RF frame calls send_rf_frame_tcp_stub.
% - Keep the Arduino serial helpers below so the host can query trigger state.

tcp_client = [];
try
    tcp_client = tcpclient(cfg.network.server_host, cfg.network.server_port, ...
        'Timeout', cfg.network.tcp_timeout_sec);
catch ME
    warning('TCP client could not be created; continuing in offline demo mode: %s', ME.message);
end

arduino_obj = [];
if cfg.hardware.enable_arduino
    try
        arduino_obj = open_arduino_connection_stub(cfg.hardware.arduino_com_port, cfg.hardware.arduino_baud);
        reset_arduino_counters_stub(arduino_obj);
    catch ME
        warning('Arduino is disabled for this run: %s', ME.message);
        arduino_obj = [];
    end
end

% Minimal dry-run frame to demonstrate protocol.
frame_data = int16(zeros(cfg.shared_memory.image_width, cfg.shared_memory.image_height));
meta = struct(...
    'success_count', 0, ...
    'frame_index', 1, ...
    'timestamp_unix_ms', int64(posixtime(datetime('now')) * 1000));

% In the real callback, the host typically queries Arduino before or after
% each frame acquisition. The query here shows the communication contract.
if cfg.hardware.enable_arduino
    if ~isempty(arduino_obj)
        meta.success_count = request_arduino_success_count_stub(arduino_obj);
    end
end

send_rf_frame_tcp_stub(tcp_client, frame_data, meta);

fprintf('Template dry-run packet sent.\n');
fprintf('Integrate this sender into your Verasonics callback path.\n');
