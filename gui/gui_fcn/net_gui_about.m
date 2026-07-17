function net_gui_about(handles)

%   .:: SPOT3D ::.
% Spatial Positioning Toolbox for head markers using 3D scans
% ---------------------
% ---------------------
% Gaia Amaranta Taberna
% v1.1 - 28.10.19
% 
% 
% "About" window
% --------------
%gui_path = fileparts(mfilename('fullpath'));

gui = figure('Visible','Off');
set(gui,'NumberTitle','Off', ...
    'Name','.:: NET ::.  -  About')
set(gui,'Resize','Off')
set(gui,'Menubar','None','Toolbar','None')

main = uiextras.VBox('Parent',gui,'Padding',20);
pan = uix.Panel('Parent',main,'Padding',5);

about = uiextras.VBox('Parent',pan,'Padding',10);
icon = uiextras.HBox('Parent',about,'Padding',10);
uiextras.Empty('Parent',icon);
ax_logo = axes('Parent',icon);
uiextras.Empty('Parent',icon);
set(ax_logo,'Visible','On')
[logo,~,alpha] = imread([handles.gui_path filesep 'logo/logo_brain.png']);
l = imshow(logo,'parent',ax_logo);
set(l,'AlphaData',alpha);
z = zoom;
setAllowAxesZoom(z,ax_logo,false);
set(icon,'Sizes',[-1 255*handles.k(1) -1])

software_title = 'Software';
uicontrol('Parent',about,'Style','Text','String',software_title,...
    'FontName','Verdana','FontSize',11.5*handles.k(2),'HorizontalAlignment','left','FontWeight','bold');
software_str = 'Available for download at: https://github.com/bind-group-kul/net';
uicontrol('Parent',about,'Style','Text','String',software_str,...
    'FontName','Verdana','FontSize',10*handles.k(2),'HorizontalAlignment','left');

paper_title = 'Related works';
uicontrol('Parent',about,'Style','Text','String',paper_title,...
    'FontName','Verdana','FontSize',11.5*handles.k(2),'HorizontalAlignment','left','FontWeight','bold');
paper1 = 'Taberna, G. A., Samogin J., Zhao M., Marino, M., Guarnieri R., Cuartas Morales E., Ganzetti M., Liu Q. & Mantini, D. Large-scale analysis of neural activity and connectivity from high-density electroencephalographic data.';
uicontrol('Parent',about,'Style','Text','String',paper1,...
    'FontName','Verdana','FontSize',10*handles.k(2),'HorizontalAlignment','left');
% paper2 = 'Taberna, G. A., Guarnieri, R. & Mantini, D. SPOT3D: Spatial positioning toolbox for head markers using 3D scans. Sci Rep 9, 12813, doi:10.1038/s41598-019-49256-0 (2019).';
% uicontrol('Parent',about,'Style','Text','String',paper2,...
%     'FontName','Tahoma','FontSize',13*handles.k(2),'HorizontalAlignment','left');

%{
uiextras.Empty('Parent',about);
logo = 'Logo by xxxx';
uicontrol('Parent',about,'Style','Text','String',logo,...
    'FontName','Tahoma','FontSize',8*handles.k(2),'HorizontalAlignment','left');
%}

set(about,'Sizes',[150 20 -1 20 -1]*handles.k(1)) %[100 20 45 20 60 60 -1 14]*handles.k(1)

set(gui,'Visible','On')
