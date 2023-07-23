%%% Convert string to number (if needed) when reading parameters from Excel file

                    % --- start excel_str2num
function c = excel_str2num(c)
    if ischar(c)
        c = str2num(c);
    end
end                 % --- end excel_str2num