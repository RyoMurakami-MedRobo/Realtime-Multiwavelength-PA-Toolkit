function arduino_obj = open_arduino_connection_stub(com_port, baud_rate)
%OPEN_ARDUINO_CONNECTION_STUB Open the serial connection used for Arduino I/O.

arduino_obj = serialport(com_port, baud_rate);
pause(1.0);
end
