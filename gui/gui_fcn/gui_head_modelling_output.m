function gui_head_modelling_output(handles)

k = handles.k;
fontsize = handles.fontsize;
fontname = handles.fontname;

fig_name = 'Head modelling sample outputs';

findwindow = findobj('Tag','fig_visual','-and','Name',fig_name);
if ~isempty(findwindow)
    close(findwindow);
end

fig_output = figure('Units','Normalized','Position',[0.01 0.08 0.23 0.25],...
        'NumberTitle','Off','Name',fig_name,'Tag','fig_visual');
fig_output.set('Menubar','none');

mainbox = uiextras.VBox('Parent',fig_output,'Padding',10*min(k));

    uicontrol('Parent',mainbox,'Style','Text','String','Choose output(s) to visualize:',...
        'FontName',fontname,'FontSize',fontsize);    

    hbox = uiextras.HBox('Parent',mainbox,'Spacing',10*min(k),'Padding',5*min(k));
    
        uiextras.Empty('Parent',hbox);

        box_buttons = uiextras.VBox('Parent',hbox,'Padding',5*min(k));
            uicontrol('Parent',box_buttons,'Style','pushbutton','String','Pre-processed MRI','Tag','img_prepro',...
                'FontName',fontname,'FontSize',fontsize,'Callback',@show_img);
            uicontrol('Parent',box_buttons,'Style','pushbutton','String','Segmented MRI','Tag','img_segm',...
                'FontName',fontname,'FontSize',fontsize,'Callback',@show_img);
            s = '<html>3D MRI +<br />electrodes</html>';
            uicontrol('Parent',box_buttons,'Style','pushbutton','String',s,...
                'FontName',fontname,'FontSize',fontsize,'Callback',@show_3d);
        set(box_buttons,'Sizes',[50*k(2) 50*k(2) 50*k(2)])

        uiextras.Empty('Parent',hbox);
    
    set(hbox,'Sizes',[-1 200*k(2) -1])
set(mainbox,'Sizes',[-1 180*k(2)])

guidata(fig_output,handles)
end

%% GUI callback functions

                    % --- start function
function template_function(hObject, eventdata, handles)
handles = guidata(gcbo);

guidata(gcbo,handles)
end                 % --- end function

                    % --- start show_img
function show_img(hObject, eventdata, handles)
handles = guidata(gcbo);

idx_dataset = get(handles.menu_visual_dataset,'String');
idx_dataset = idx_dataset(get(handles.menu_visual_dataset,'Value'));

if strcmp(hObject.Tag,'img_prepro')
    fig_img = figure('Units','Normalized','Position',[0.3 0.0 0.64 1],...
        'NumberTitle','Off','Name',[char(idx_dataset) ' - Pre-processed MR image']);
    nii = load_nii(handles.img_filename);
else
    fig_img = figure('Units','Normalized','Position',[0.32 0.0 0.64 1],...
        'NumberTitle','Off','Name',[char(idx_dataset) ' - Segmented MR image']);
    nii = load_nii(handles.segimg_filename);
    opt.setcolorindex = 4;
end
opt.command = 'init';
opt.setarea = [0.05 0.05 0.9 0.9];
opt.usecolorbar = 0;
set(gcf, 'Pointer', 'watch');
view_nii(fig_img,nii,opt);
set(gcf, 'Pointer', 'arrow');
guidata(gcbo,handles);
end                 % --- end show_img

                    % --- start show_3d
function show_3d(hObject, eventdata, handles)
handles = guidata(gcbo);

idx_dataset = get(handles.menu_visual_dataset,'String');
idx_dataset = idx_dataset(get(handles.menu_visual_dataset,'Value'));

fig_img = figure('Units','Normalized','Position',[0.34 0.0 0.64 1],...
    'NumberTitle','Off','Name',[char(idx_dataset) ' - 3D MR image with electrodes (inflated)']);
fig_img.set('Menubar','figure');
set(gcf, 'Pointer', 'watch');
ax = axes(fig_img,'Visible','On');
view(ax,3); daspect(ax,[1,1,1]);
drawnow

VF=spm_vol(handles.img_filename);
[image,xyz]=spm_read_vols(VF);
mask=zeros(size(image));
mask(image>0.05*max(image(:)))=1;
mask_full=imfill(mask,4);
[fx,fy,fz] = gradient(mask_full);
border=zeros(size(mask_full));
border(abs(fx)+abs(fy)+abs(fz)>0)=1;
headshape=xyz(:,border==1)';
scatter3(ax,headshape(:,1),-headshape(:,2),headshape(:,3),...
    50,[0.6 0.6 0.6],'Marker','o','MarkerFaceColor',[1 1 1],'SizeData',5); %,'MarkerEdgeAlpha',0.6);

hold(ax,'on')

[~,tpl_locs] = evalc('readlocs(handles.elec_filename);');
Cw = struct2cell(tpl_locs) ;
coord_tpl_orig=cell2mat(Cw(2:4,:)');
handles.tot_elec = size(coord_tpl_orig,1);
coord_tpl_zoom=coord_tpl_orig+3.*sign(coord_tpl_orig);
scatter3(ax,coord_tpl_zoom(:,1),-coord_tpl_zoom(:,2),coord_tpl_zoom(:,3),700,'b.');

c = cellstr(Cw(1,:)); dx = 3; dy = 3; dz = 5;
text(ax,coord_tpl_zoom(:,1)+(dx*sign(coord_tpl_zoom(:,1))),-coord_tpl_zoom(:,2)-(dy*sign(coord_tpl_zoom(:,2))),coord_tpl_zoom(:,3)+(dz*sign(coord_tpl_zoom(:,3))), c, ...
    'FontSize',12); %,11,'FontWeight','bold');

set(gcf, 'Pointer', 'arrow');
axis square % JS 07.2023

guidata(gcbo,handles)
end                 % --- end show_3d