function reset_arduino_counters_stub(arduino_obj)
%RESET_ARDUINO_COUNTERS_STUB Send RESET and wait for confirmation.

writeline(arduino_obj, "RESET");
pause(0.2);
if arduino_obj.NumBytesAvailable > 0
    response = readline(arduino_obj);
    fprintf('[Arduino] RESET response: %s\n', response);
end
end
