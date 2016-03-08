function plot_layouts(config, layouts, outputdir)
if nargin < 3
    outputdir = [];
end

if ~isempty(outputdir) && ~exist(outputdir, 'dir')
    mkdir(outputdir);
end

Nlayouts = length(layouts);
layout2d = {};

cmap = colormap;
for i = 1:Nlayouts
    layout = layouts{i};
    Nobj = size(layout.objs, 2);
    figure(1);
    scatter3(layout.cam(1), layout.cam(2), layout.cam(3), 'x'); hold on;
    bbox2d = [];
    for j = 1:Nobj
        c = get_color(config.relation.class{j});
        pts = [];
        switch config.relation.class{j}
            case {'bed', 'chair', 'sofa', 'desk', 'table', 'piano_bench'}
                pts2d = [];
                for k = 1:length(config.objmodels.subobjs)
                    if strncmp(config.objmodels.subobjs{k}, config.relation.class{j}, length(config.relation.class{j}))
                        [p, q] = get_abs_coords(config, config.objmodels.subobjs{k}, j, layout.objs(4, j), layout.objs(1:3, j));
                        figure(1);
                        [x, y, z] = plot_cuboid(p, q, c);
                        hold on;
                        pts = [x(:) y(:) z(:)];
                        [kpts2d, zbuf] = camera_projection(pts, layout.cam, pi/2 + layout.cam_ax/180*pi, layout.focal);
                        x = reshape(kpts2d(1, :), 4, 6);
                        y = reshape(kpts2d(2, :), 4, 6);
                        figure(2);
                        fill(x, y, c);
                        hold on;
                        pts2d = cat(2, pts2d, kpts2d);
                    end
                end
            otherwise
                [p, q] = get_abs_coords(config, config.relation.nouns{j}, j, layout.objs(4, j), layout.objs(1:3, j));
                figure(1);
                [x, y, z] = plot_cuboid(p, q, c);
                hold on;
                pts = [x(:) y(:) z(:)];
                [pts2d, zbuf] = camera_projection(pts, layout.cam, pi/2 + layout.cam_ax/180*pi, layout.focal);
                figure(2);
                x = reshape(pts2d(1, :), 4, 6);
                y = reshape(pts2d(2, :), 4, 6);
                fill(x, y, c);
                hold on;
        end
        bbox = [min(pts2d, [], 2); max(pts2d, [], 2)];
        figure(3);
        fill([bbox(1), bbox(3), bbox(3), bbox(1)], ...
            [bbox(2), bbox(2), bbox(4), bbox(4)], c);
        hold on;
        bbox2d = [bbox2d; bbox'];
        % project to 2d: pts
%         [pts2d, zbuf] = camera_projection(pts, layout.cam, pi/2 + layout.cam_ax/180*pi, layout.focal);
    end
    h = figure(1);
    axis equal;
    hold off;
    if ~isempty(outputdir)
        saveas(h, fullfile(outputdir, num2str(i, 'layout-%d-3d.jpg')));
    end
    h = figure(2);
    axis equal;
    hold off;
    if ~isempty(outputdir)
        saveas(h, fullfile(outputdir, num2str(i, 'layout-%d-2d.jpg')));
    end
    h = figure(3);
    axis equal;
    hold off;
    for j = 1:Nobj
        bbox = bbox2d(j, :);
        rectangle('Position', [bbox(1:2) bbox(3:4)-bbox(1:2)], 'edgecolor', 'r', 'linewidth', 2);
        text(bbox(1), bbox(4), config.relation.class{j}, 'backgroundcolor', 'w', 'edgecolor', 'k', ...
    'interpreter', 'none');
    end
    if ~isempty(outputdir)
        saveas(h, fullfile(outputdir, num2str(i, 'layout-%d-bbox.jpg')));
    end
    layout_table = table(config.relation.class', bbox2d(:, 1), bbox2d(:, 2), bbox2d(:, 3), bbox2d(:, 4), ...
        'VariableNames',{'classname' 'X1' 'Y1' 'X2' 'Y2'});
    layout2d{i} = layout_table;
%     plot([bbox(1), bbox(3), bbox(3), bbox(1), bbox(1)], ...
%         [bbox(2), bbox(2), bbox(4), bbox(4), bbox(2)], 'Color', cmap(c, :));
%     hold on;
end

save(fullfile(outputdir, 'layout2d.mat'), 'layout2d');

function [img_pt, zbuffer] = camera_projection(pts, cam, theta, focal)
rp = bsxfun(@minus, pts, cam);
rp = rotation_z(theta) * rp';
img_pt = focal * (rp([1 3], :) ./ rp([2 2],:));
zbuffer = rp(1, :);

function P = rotation_z(theta)
P = [cos(theta), sin(theta), 0; ...
    -sin(theta), cos(theta), 0; ...
    0, 0, 1];

function [x, y, z] = plot_cuboid(p, q, c)
x = [p(1) q(1) q(1) p(1); p(1) q(1) q(1) p(1); p(1) p(1) p(1) p(1); q(1) q(1) q(1) q(1); p(1) p(1) q(1) q(1); p(1) p(1) q(1) q(1)]';
y = [p(2) p(2) q(2) q(2); p(2) p(2) q(2) q(2); p(2) q(2) q(2) p(2); p(2) q(2) q(2) p(2); p(2) p(2) p(2) p(2); q(2) q(2) q(2) q(2)]';
z = [p(3) p(3) p(3) p(3); q(3) q(3) q(3) q(3); p(3) p(3) q(3) q(3); p(3) p(3) q(3) q(3); p(3) q(3) q(3) p(3); p(3) q(3) q(3) p(3)]';
fill3(x, y, z, c);
        
function [p, q] = get_abs_coords(config, objname, objid, direction, X)
subobjname = get_subobjname(objname);
if isempty(subobjname)
    p = X;
    s = config.relation.sizes(objid, :)';
    if direction == 0
        q = X + s([2 1 4]);
    elseif direction == 1
        q = X + s([1 2 4]);
    end
else
    subobjclass = [config.relation.class{objid} ':' subobjname];
    index = find(strcmp(config.objmodels.subobjs, subobjclass));
    assert(~isempty(index), ['cannot find sub object class: ' subobjclass]);
    cubmat = config.objmodels.cuboids_mat(:, :, index);
    if direction == 0
        s = config.relation.sizes(objid, :);
        xx = cubmat * s';
        xx(4:5) = [xx(5) xx(4)];
        xx(1:2) = [xx(2) xx(1)];
    elseif direction == 1
        s = config.relation.sizes(objid, :);
        xx = cubmat * s';
    end
    p = X + xx(1:3);
    q = X + xx(1:3) + xx(4:6);
end