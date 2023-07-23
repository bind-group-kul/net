%%% Check if all required fields are filled in (EEG, sensors position, structural MRI)

                    % --- start nodata
function flag = nodata(c)
    flag = isempty(c) || strcmpi(c,' ') || strcmpi(num2str(c),'NaN');
end                 % --- end nodata