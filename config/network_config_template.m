function net = network_config_template()
%NETWORK_CONFIG_TEMPLATE Fill this with your local network values.

net = struct();
net.server_host = 'SERVER_HOST_PLACEHOLDER';
net.server_port = 8080;
net.allowed_client_hosts = {'ALLOWED_CLIENTS_PLACEHOLDER'};

% TODO: Adjust firewall rules externally for selected server_port.
end
