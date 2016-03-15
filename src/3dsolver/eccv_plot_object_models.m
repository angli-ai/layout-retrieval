% plot object models

objectname = 'night-stand';

outputdir = 'objmodels';
if ~exist(outputdir, 'dir')
    mkdir(outputdir);
end

classname = objectname;
if strncmp(objectname, 'bed', 3)
    % default queen size: (L, W, Hl, Hh) = (2.0, 1.5, 0.75, 1.5)
    objectsizes = [2.0, 1.5, 0.75, 1.5];
elseif strncmp(objectname, 'pillow', 6)
    objectsizes = [0.1, 0.5, 0.25, 0.25];
elseif strncmp(objectname, 'garbage-bin', 10)
    objectsizes = [0.25, 0.25, 0.5, 0.5];
 elseif strncmp(objectname, 'picture', 7)
    objectsizes = [0.05, 0.5, 0.5, 0.5];
elseif strncmp(objectname, 'door', 4)
    objectsizes = [0.05, 1.0, 2.0, 2.0];
elseif strncmp(objectname, 'mirror', 6)
    objectsizes = [0.05, 0.5, 0.5, 0.5];
elseif strncmp(objectname, 'sink', 4)
    objectsizes = [0.5, 0.5, 0.25, 0.25];
elseif strncmp(objectname, 'whiteboard', 10)
    objectsizes = [0.05, 1, 1, 1];
elseif strncmp(objectname, 'sofa', 4)
    objectsizes = [0.75, 0.75, 0.5, 1];
elseif strncmp(objectname, 'double-sofa', 11)
    objectsizes = [0.75, 0.75 * 2, 0.5, 0.75];
    classname = 'sofa';
elseif strncmp(objectname, 'triple-sofa', 11)
    objectsizes = [0.75, 0.75 * 3, 0.5, 0.75];
    classname = 'sofa';
elseif strncmp(objectname, 'tv', 2)
    objectsizes = [0.2, 1.0, 0.6, 0.6];
elseif strncmp(objectname, 'monitor', 7)
    objectsizes = [0.1, 0.3, 0.3, 0.3];
elseif strncmp(objectname, 'lamp', 4)
    objectsizes = [0.25, 0.25, 0.5, 0.5];
elseif strncmp(objectname, 'dresser', 7)
    objectsizes = [0.25, 1.5, 1.0, 1.0];
elseif strncmp(objectname, 'cabinet', 7)
    objectsizes = [0.5, 1.0, 0.5, 0.5];
elseif strncmp(objectname, 'chair', 5)
    objectsizes = [0.5, 0.5, 0.5, 1.0];
elseif strncmp(objectname, 'table', 5)
    objectsizes = [0.8, 0.8, 0.8, 0.8];
elseif strncmp(objectname, 'dining-table', 12)
    objectsizes = [0.8, 1.6, 0.8, 0.8];
    classname = 'table';
elseif strncmp(objectname, 'long-table', 12)
    objectsizes = [0.8, 1.6, 0.8, 0.8];
    classname = 'table';
elseif strncmp(objectname, 'desk', 4)
    objectsizes = [0.8, 1.6, 0.8, 0.8];
elseif strncmp(objectname, 'night-stand', 11)
    objectsizes = [0.5, 0.5, 0.75, 0.75];
elseif strncmp(objectname, 'side-table', 10)
    objectsizes = [0.5, 0.5, 0.75, 0.75];
elseif strncmp(objectname, 'box', 3)
    objectsizes = [0.5, 0.5, 0.5, 0.5];
elseif strncmp(objectname, 'piano-bench', 11)
    objectsizes = [0.5, 1.0, 0.5, 0.5];
elseif strncmp(objectname, 'piano', 5)
    objectsizes = [1.0, 1.8, 1.0, 1.0];
else % default size
    error();
    objectsizes = [objectsizes; 0.5, 0.5, 0.5, 0.5];
end

models = get_object_models();

index = find(strcmp(classname, models.objects));
h = figure(1);
if isempty(index)
    % single cuboid representation
    s = objectsizes;
    p = [0 0 0];
    q = s([1 2 4]);
    plot_cuboid(p, q, 1);
else
    objindex = models.objindex{index};
    s = objectsizes;
    for k = 1:length(objindex)
        index = objindex(k);
        subobjs = models.subobjs{index};
        cuboids = models.cuboids{index};
        cubmat = models.cuboids_mat(:, :, index);
        xx = cubmat * s';
        p = xx(1:3);
        q = xx(1:3) + xx(4:6);
        plot_cuboid(p, q, k);
        hold on;
    end
    hold off;
end
xlabel('X');
ylabel('Y');
zlabel('Z');
axis equal;
view([30 15]);
saveas(h, fullfile(outputdir, [objectname '.png']));
