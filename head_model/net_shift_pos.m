function [posf]=net_shift_pos(pos,inward_shift)

% TRIANGULATION
% -------------

pos=pos+0.0001*randn(size(pos));

x=pos(:,1);
y=pos(:,2);
z=pos(:,3);


xm=mean(x);
ym=mean(y);
zm=mean(z);

xn=x-xm;
yn=y-ym;
zn=z-zm;


tri = delaunay(xn,yn); % ex. tri(i,j) -> P(tri(i,j),:)


% NORMAL VECTORS and AVERAGE VECTOR FOR EACH POINT
% ------------------------------------------------

pos=[xn yn zn];


A = pos(tri(:,3),:)-pos(tri(:,1),:); % A = P(3)-P(1)
B = pos(tri(:,2),:)-pos(tri(:,1),:); % B = P(2)-P(1)
n = cross(A,B);

nmod = zeros(length(n),1);
for i = 1:length(n)
    nmod(i) = norm(n(i,:),2);
end

variance=std(pos,1);

navg = zeros(size(pos));
normals = zeros(size(pos));
for i=1:length(pos)
    % Triangles for each vertex
    [vertpos,~] = ind2sub(size(tri), find(tri == i));
    if not(isempty(vertpos))
    %vpos(i,1) = {vertpos};
    % Average direction for each vertex
    navg(i,:) = mean(n(vertpos,:));
    %navg_mod(i) = norm(navg(i,:),2);
    normals(i,:) = navg(i,:)/norm(navg(i,:),2);
    if norm(pos(i,:)+0.5*variance.*normals(i,:))>norm(pos(i,:))
        normals(i,:)=-normals(i,:);
        %disp(i);
    end
    else
        disp('error with triangulation!');
        return;
    end
end


% NEW ELECTRODES POSITIONS
% ------------------------

% Find point along direction at fixed distance 'inward_shift'

% Find coordinates of possible new points P1 and P2
x1 = xn+normals(:,1)*inward_shift; 
y1 = yn+normals(:,2)*inward_shift; 
z1 = zn+normals(:,3)*inward_shift; 
pos1 = [x1, y1, z1];


posf(:,1)=pos1(:,1)+xm;
posf(:,2)=pos1(:,2)+ym;
posf(:,3)=pos1(:,3)+zm;

% figure; plot3(x,y,z,'rx');
% hold on; plot3(x1,y1,z1,'bx');