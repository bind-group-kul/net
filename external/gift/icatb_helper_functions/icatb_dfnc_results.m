function varargout = icatb_dfnc_results(dfncInfo, display_criteria)
%% DFNC results
%

icatb_defaults;
global FONT_COLOR;

if (~exist('display_criteria', 'var'))
    display_criteria = 'fnc oscillations';
end

comps = [dfncInfo.comps];
comps = comps(:);

outputDir = dfncInfo.outputDir;

cd(outputDir);

post_process_file = fullfile(outputDir,  [dfncInfo.prefix, '_post_process.mat']);

load(post_process_file);

figVisible = 'on';
if (nargout == 1)
    figVisible = 'off';
    html_dir = fullfile(dfncInfo.outputDir, 'html');
    if (~exist(html_dir, 'dir'))
        mkdir(dfncInfo.outputDir, 'html');
    end
end

network_values = zeros(1, length(dfncInfo.userInput.comp));
for nV = 1:length(network_values)
    network_values(nV) = length(dfncInfo.userInput.comp(nV).value);
end
network_names =  cellstr(char(dfncInfo.userInput.comp.name));

if (length(network_names) == 1)
    network_names = '';
end

comps = [dfncInfo.comps];
comps = comps(:);

if (strcmpi(display_criteria, 'fnc oscillations'))
    
    %% FNC Oscillations
    H(1).H = icatb_getGraphics('FNC Oscillations (1)', 'graphics', 'dfnc_summary', figVisible);
    %sh = subplot(1, 1, 1);
    sh = axes('units', 'normalized', 'position', [0.2, 0.2, 0.6, 0.6]);
    
    CLIM = [min(FNCamp(:)), max(FNCamp(:))];
    FNCamp = icatb_vec2mat(FNCamp, 1);
    icatb_plot_FNC(FNCamp, CLIM, cellstr(num2str(comps)), (1:length(comps)), H(1).H, 'Average Std Of FNC Spectra', ...
        sh, network_values, network_names);
    title('Average Std Of FNC Spectra', 'parent', sh, 'horizontalAlignment', 'center');
    set(sh, 'YColor', FONT_COLOR, 'XColor', FONT_COLOR);
    
    if (nargout == 1)
        outFile = [dfncInfo.prefix, '_avg_std_oscillations.jpg'];
        printFile(H(1).H, fullfile(html_dir, outFile));
        results(1).file = outFile;
        results(1).text = 'Spectra is computed on dFNC correlations. Standard deviation of spectra is then averaged across subjects.';
    end
    
    
    H(2).H = icatb_getGraphics('FNC Oscillations (2)', 'graphics', 'dfnc_summary', figVisible);
    
    sh = axes('units', 'normalized', 'position', [0.2, 0.2, 0.6, 0.6]);
    
    CLIM = [min(FNCcm(:)), max(FNCcm(:))];
    FNCcm = icatb_vec2mat(FNCcm, 1);
    icatb_plot_FNC(FNCcm, CLIM, cellstr(num2str(comps)), (1:length(comps)), H(2).H, 'Average Center-Of-Mass Of FNC Spectra', sh, ...
        network_values, network_names);
    title('Average Center-Of-Mass Of FNC Spectra', 'parent', sh, 'horizontalAlignment', 'center');
    set(sh, 'YColor', FONT_COLOR, 'XColor', FONT_COLOR);
    
    if (nargout == 1)
        outFile = [dfncInfo.prefix, '_avg_center_of_mass_oscillations.jpg'];
        printFile(H(end).H, fullfile(html_dir, outFile));
        results(2).file = outFile;
        results(2).text = 'Spectral center of mass is computed on dFNC correlations and averaged across subjects.';
    end
    
else
    
    %% Cluster centroids
    M = length (dfncInfo.outputFiles);
    Nwin = length(clusterInfo.IDXall) / M;
    aIND = reshape(clusterInfo.IDXall, M, Nwin);
    aIND = aIND';
    for ii = 1:dfncInfo.postprocess.num_clusters
        fig_title = ['Cluster Centroid (', num2str(ii), ')'];
        H(ii).H = icatb_getGraphics(fig_title, 'graphics', 'dfnc_summary3', figVisible);
        sh = axes('units', 'normalized', 'position', [0.2, 0.2, 0.6, 0.6]);
        CLIM = max(abs(clusterInfo.Call(:)));
        CLIM = [-CLIM, CLIM];
        tmp = icatb_vec2mat(clusterInfo.Call(ii, :), 1);
        titleStr = sprintf('%d (%d%%)', sum(clusterInfo.IDXall == ii),  round(100*sum(clusterInfo.IDXall == ii)/length(clusterInfo.IDXall)));
        icatb_plot_FNC(tmp, CLIM, cellstr(num2str(comps)), (1:length(comps)), H(ii).H, 'Correlations (z)', sh(1), network_values, network_names);
        title(titleStr, 'parent', sh(1), 'horizontalAlignment', 'center');
        axis square;
        set(sh, 'YColor', FONT_COLOR, 'XColor', FONT_COLOR);
        
        if (nargout == 1)
            outFile = [dfncInfo.prefix, '_clusters_', icatb_returnFileIndex(ii), '.jpg'];
            printFile(H(ii).H, fullfile(html_dir, outFile));
            results(ii).file = outFile;
            results(ii).text = ['Number of occurrences of centroid ', num2str(ii), ' is ', titleStr];
        end
        
    end
    
    %% Cluster Occurrences
    
    H(end + 1).H = icatb_getGraphics('Cluster Occurrences', 'graphics', 'dfnc_summary4', figVisible);
    
    numCols = ceil(sqrt(dfncInfo.postprocess.num_clusters));
    numRows = ceil(dfncInfo.postprocess.num_clusters/numCols);
    
    for ii = 1:dfncInfo.postprocess.num_clusters
        sh = subplot(numRows, numCols, ii);
        timeline = 0:(Nwin-1); timeline = timeline + dfncInfo.wsize/2; timeline = timeline*dfncInfo.TR;
        
        for bb = 1:100
            pickME = ceil(M*rand(M,1));
            octemp = 100*mean(aIND(:, pickME) == ii,2);
            plot(timeline, octemp, 'Color', [.8 .8 .8])
            hold on
        end
        
        hold on
        oc = 100*mean(aIND == ii,2);
        plot(timeline, oc, 'b')
        xlabel('time (s)', 'parent', sh); ylabel('Number Of Occurrences (100 bootstraps)', 'parent', sh);
        box off; set(sh, 'TickDir', 'out')
        title(sprintf('%d (%d%%)', sum(clusterInfo.IDXall == ii),  round(100*sum(clusterInfo.IDXall == ii)/length(clusterInfo.IDXall))), 'horizontalAlignment', 'center', 'parent', sh);
        set(sh, 'YColor', FONT_COLOR, 'XColor', FONT_COLOR);
        
    end
    
    if (nargout == 1)
        outFile = [dfncInfo.prefix, '_cluster_occurrences.jpg'];
        printFile(H(end).H, fullfile(html_dir, outFile));
        results(end + 1).file = outFile;
        results(end).text = 'No. of cluster occurrences using 100 bootstrap iterations';
    end
    
    %% State vector stats
    
    aFR = zeros(M, dfncInfo.postprocess.num_clusters);
    aTM = zeros(M, dfncInfo.postprocess.num_clusters, dfncInfo.postprocess.num_clusters);
    aMDT = zeros(M, dfncInfo.postprocess.num_clusters);
    aNT = zeros(M, 1);
    for ii = 1:M
        [FRii, TMii, MDTii, NTii] = icatb_dfnc_statevector_stats(aIND(:,ii), dfncInfo.postprocess.num_clusters);
        aFR(ii,:) = FRii;
        aTM(ii,:,:) = TMii;
        aMDT(ii,:) = MDTii;
        aNT(ii) = NTii;
    end
    
    H(end+1).H = icatb_getGraphics('State Vector Stats', 'graphics', 'dfnc_summary4', figVisible);
    
    icatb_dfnc_plot_statevector_stats(dfncInfo.postprocess.num_clusters, aFR, aTM, aMDT, aNT, H(end).H);
    
    set(findobj(H(end).H, 'type', 'axes'), 'YColor', FONT_COLOR, 'XColor', FONT_COLOR);
    
    if (nargout == 1)
        
        %else
        titleStr = 'State Vector Stats';
        outFile = [dfncInfo.prefix, '_state_vector_stats.jpg'];
        printFile(H(end).H, fullfile(html_dir, outFile));
        results(end + 1).file = outFile;
        results(end).text = 'Plot shows frequency of each cluster followed by mean dwell time in windows followed by mean of state transition matrix across subjects';
    end
    
    
end



if (nargout == 1)
    for nH = 1:length(H)
        close(H(nH).H);
    end
    varargout{1} = results;
    return;
end

icatb_plotNextPreviousExitButtons(H);


function printFile(H, file_name)

pos = get(0, 'defaultFigurePosition');
set(H, 'color', 'w');
set(H, 'position', pos);
titleH = get(findobj(H, 'type', 'axes'), 'title');
if (iscell(titleH))
    titleH = cell2mat(titleH);
    set(titleH, 'color', 'k');
end
set(titleH, 'color', 'k');
set(findobj(H, 'type', 'axes'), 'YColor', 'k', 'XColor', 'k');
set(findobj(H, 'type', 'text'), 'color', 'k');
%set(H,'PaperUnits','inches','PaperPosition', [0 0 4 3]);
saveas(H, file_name);
