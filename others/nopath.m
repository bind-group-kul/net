%%% Check if all input files exist

                    % --- start nopath
function flag = nopath(c)
    flag = not(nodata(c) || exist(c,'file'));
end                 % --- end nopath