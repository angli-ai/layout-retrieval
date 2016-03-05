function boundmap = build_boundmap(config, X)
Nrel = size(config.relation.rel, 1);
Nobj = length(config.relation.class);
lb = zeros(3, Nobj, Nobj);
ub = zeros(3, Nobj, Nobj);
lb(:) = -inf;
ub(:) = inf;

for i = 1:Nobj
    lb(:, i, i) = 0;
    ub(:, i, i) = 0;
end

dnear = config.spatial.near;
datt = config.spatial.attach;

for i = 1:Nrel
    semantic = config.relation.rel(i, :);
    obj1 = get_objectid(semantic{1}, config.relation.nouns);
    rel = semantic{3};
%     [p1, q1] = get_coords(config, semantic{1}, obj1, X(obj1*4, :), X((obj1-1)*4+(1:3),:));
%     [p2, q2] = get_coords(config, semantic{2}, obj2, X(obj2*4, :), X((obj2-1)*4+(1:3),:));
    s1 = get_dir_objsize(config, obj1, X(obj1*4, :));
    if iscell(semantic{2})
        continue;
    else
        obj2 = get_objectid(semantic{2}, config.relation.nouns);
        s2 = get_dir_objsize(config, obj2, X(obj2*4, :));
    end
    switch rel
        case {'near', 'next-to', 'close-to', 'left', 'right', 'in_front_of', 'front', 'behind'}
            lb(:, obj1, obj2) = max(lb(:, obj1, obj2), -s1(1:3)-dnear);
            ub(:, obj1, obj2) = min(ub(:, obj1, obj2), s2(1:3)+dnear);
        case 'attach'
            lb(:, obj1, obj2) = max(lb(:, obj1, obj2), -s1(1:3)-datt);
            ub(:, obj1, obj2) = min(ub(:, obj1, obj2), s2(1:3)+datt);
        
        case {'side-by-side', 'in-a-row'}
            lb(:, obj1, obj2) = max(lb(:, obj1, obj2), -s1(1:3)-datt);
            ub(:, obj1, obj2) = min(ub(:, obj1, obj2), s2(1:3)+datt);
            
        case 'above'
            lb(:, obj1, obj2) = max(lb(:, obj1, obj2), -s1(1:3)-dnear);
            ub(:, obj1, obj2) = min(ub(:, obj1, obj2), s2(1:3)+dnear);
            lb(3, obj1, obj2) = max(lb(3, obj1, obj2), s2(3)+datt);
            ub(3, obj1, obj2) = min(ub(3, obj1, obj2), s2(3)+dnear);
            lb(1:2, obj1, obj2) = max(lb(1:2, obj1, obj2), -s1(1:2)/2);
            ub(1:2, obj1, obj2) = min(ub(1:2, obj1, obj2), -s1(1:2)/2+s2(1:2));
            
        case {'on'}
            lb(3, obj1, obj2) = max(lb(3, obj1, obj2), s2(4));
            ub(3, obj1, obj2) = min(ub(3, obj1, obj2), s2(4));
            lb(1:2, obj1, obj2) = max(lb(1:2, obj1, obj2), 0);
            ub(1:2, obj1, obj2) = min(ub(1:2, obj1, obj2), -s1(1:2)+s2(1:2));
            
        case {'under'}
            lb(1:2, obj1, obj2) = max(lb(1:2, obj1, obj2), -s1(1:2));
            ub(1:2, obj1, obj2) = min(ub(1:2, obj1, obj2), +s2(1:2));
            
        otherwise
%                 error(['rel' rel ' not found']);
    end
end

while true
    changed = false;
    for k = 1:3
        for i = 1:Nobj
            for j = 1:Nobj
                if -lb(k, j, i) < ub(k, i, j) - eps
                    ub(k, i, j) = -lb(k, j, i);
                    changed = true;
                end
                if -ub(k, j, i) > lb(k, i, j) + eps
                    lb(k, i, j) = -ub(k, j, i);
                    changed = true;
                end
                for u = 1:Nobj
                    if lb(k, i, u) + lb(k, u, j) > lb(k, i, j) + eps
                        lb(k, i, j) = lb(k, i, u) + lb(k, u, j);
                        changed = true;
                    end
                    if ub(k, i, u) + ub(k, u, j) < ub(k, i, j) - eps
                        ub(k, i, j) = ub(k, i, u) + ub(k, u, j);
                        changed = true;
                    end
                end
            end
        end
    end
    if ~changed
        break;
    end
end

boundmap = [];
boundmap.N = Nobj;
boundmap.lb = lb;
boundmap.ub = ub;