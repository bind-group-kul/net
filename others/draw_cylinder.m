function h=draw_cylinder(D,H,A)

%D = 5;   % Diameter
%H = 10;  % Height
%A = 360; % Angles to plot
theta = (0 : 1 : (A-1))*360/A;
X = [(D/2*cosd(theta))'  (D/2*sind(theta))' ones(A,1)*H/2];
X = [X ; X*[1,0,0;0,1,0;0,0,-1]];
options = {'Qt','Qbb','Qc'};
Tes = delaunayTriangulation(X(:,1),X(:,2),X(:,3)); %,options);
h=tetramesh(Tes); %,X);
%colormap(white);
%face_alpha = 1.0;
%alpha(face_alpha)
%shading flat
%axis equal
%light('Position',[-0.58674 -0.05336 0.80801],'Style','infinite')
%light('Position',[-0.58674 -0.05336 -0.80801],'Style','infinite')