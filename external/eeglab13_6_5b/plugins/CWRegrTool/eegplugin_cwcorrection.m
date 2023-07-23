function vers = eegplugin_cwcorrection( fig, try_strings, catch_strings)

vers = 'CW Regression Tool 0.01';

% add menu
%----------
toolsmenu = findobj(fig, 'tag', 'tools');
cwregressionmenu=uimenu(toolsmenu,'label','CW Regression Tool','separator','on','tag','CW Regression Tools');
commando1 = [ try_strings.no_check '[EEG LASTCOM] = pop_cwregression( EEG );' catch_strings.new_and_hist ];
submenu_cwregression=uimenu(cwregressionmenu,'label','Remove BCG/Hg Artifacts','tag','cwregression menu','callback',commando1);

%commando2 = [ try_strings.no_check '[EEG LASTCOM] = pop_cwregression_diagnostical( EEG );' catch_strings.new_and_hist ];
%submenu_diagnostics=uimenu(cwregressionmenu,'label','Remove BCG/Hg + create logs (slower)','separator','on','tag','diagnostics menu','callback',commando2);

%commando3 = [ try_strings.no_check '[EEG LASTCOM] = pop_check_logs( EEG );' catch_strings.new_and_hist ];
%submenu_diagnostics=uimenu(cwregressionmenu,'label','Check the logs','separator','off','tag','diagnostics menu','callback',commando3);


% commando3 = [ try_strings.no_check '[EEG LASTCOM] = pop_cwregression_fixed_delay( EEG );' catch_strings.new_and_hist ];
% submenu_diagnostics=uimenu(cwregressionmenu,'label','Subtract with given delay matrix','tag','regression with fixed delay menu','callback',commando3);


% pasmenu=uimenu(cwregressionmenu,'label','Remove pulse artifacts','tag','pas menu','callback',pascmd);