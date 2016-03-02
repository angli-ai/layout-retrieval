function layouts = interval_branch_bound(config)

Nobj = length(config.relation.nouns);

X = [repmat([0 config.room.width; ...
    0 config.room.length; ...
    0 config.room.height; ...
    0 1], Nobj, 1); [0, config.room.width]];

% set dir=0 for cube object
for i = 1:Nobj
    if config.relation.sizes(i, 1) == config.relation.sizes(i, 2) ...
            && config.relation.sizes(i, 3) == config.relation.sizes(i,4)
        X(i*4, :) = [0 0];
    end
end

% set z=0 for grounded objects
touch_ground = config.relation.support;
for i = 1:length(config.relation.rel)
    switch config.relation.rel{i, 3}
        case {'on', 'on-top-of', 'above'}
            obj_name = get_rootname(config.relation.rel{i, 1});
            obj_id = get_objectid(obj_name, config.relation.nouns);
            touch_ground(obj_id) = false;
    end
end
for i = 1:Nobj
    if touch_ground(i)
        X(i*4-1, :) = [0, 0];
    end
end

layouts = {};
% determine the upper wall and left wall first
% single object attached to two walls
for i = 1:Nobj
    X0 = X;
%     if config.relation.sizes(i, 1) ~= config.relation.sizes(i, 2)
    if config.relation.againstwall(i)
        directions = [0, 1];
    else
        directions = [0];
    end
    X0(i*4-2, :) = 0;
    for j = directions
        X0(i*4, :) = [j j];
        X0(i*4-2, :) = get_object_center([0, 0], config.relation.sizes(i, :), j);
        new_layouts = do_interval_branch_bound(X0, config);
        layouts = [layouts, new_layouts];
    end
end

% two objects attached to the walls
for i = 1:Nobj
    X0 = X;
    % if obj_i with y = 0
%     if strcmp(config.relation.class{i}, 'bed')
%     if config.relation.sizes(i, 1) ~= config.relation.sizes(i, 2)
    if config.relation.againstwall(i)
        X0(i*4, :) = [0, 0];
    end
    loc = get_object_center([0, 0], config.relation.sizes(i, :), 0);
    X0(i*4-2,:) = [loc(2) loc(2)];
    for j = 1:Nobj
        if i == j, continue, end
        % if obj_j with x = 0
        X1 = X0;
        loc = get_object_center([0, 0], config.relation.sizes(j, :), 0);
%         if config.relation.sizes(j, 1) ~= config.relation.sizes(j, 2)
        if config.relation.againstwall(j)
            X1(j*4, :) = [1, 1];
            loc = get_object_center([0, 0], config.relation.sizes(j, :), 1);
        end
        X1(j*4-3,:) = [loc(1) loc(1)];
        new_layouts = do_interval_branch_bound(X1, config);
        layouts = [layouts, new_layouts];
    end
end