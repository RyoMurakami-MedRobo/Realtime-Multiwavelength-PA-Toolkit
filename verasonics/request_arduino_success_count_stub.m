function success_count = request_arduino_success_count_stub(arduino_obj)
%REQUEST_ARDUINO_SUCCESS_COUNT_STUB Query the Arduino success counter with 'R'.

writeline(arduino_obj, "R");
response = readline(arduino_obj);
success_count = str2double(response);

if isempty(success_count) || isnan(success_count)
    success_count = 0;
end
end
