function [p, q, z_support] = get_coords(config, objname, objid, direction, X)
subobjname = get_subobjname(objname);
if isempty(subobjname)
    p = X;
    s = config.relation.sizes(objid, :)';
    if vector_eq(direction, [0 1])
        error('should not happen');
    elseif vector_eq(direction, [0 0]) || vector_eq(direction, [2 2])
        q = X + repmat(s([2 1 4]), 1, 2);
    elseif vector_eq(direction, [1 1]) || vector_eq(direction, [3 3])
        q = X + repmat(s([1 2 4]), 1, 2);
    end
else
    subobjclass = [config.relation.class{objid} ':' subobjname];
    index = find(strcmp(config.objmodels.subobjs, subobjclass));
    assert(~isempty(index), ['cannot find sub object class: ' subobjclass]);
    cubmat = config.objmodels.cuboids_mat(:, :, index);
    if vector_eq(direction, [0 1])
        error('should not happen');
    elseif vector_eq(direction, [0 0])
        s = config.relation.sizes(objid, :);
        xx = cubmat * s';
        xx(4:5) = [xx(5) xx(4)];
        xx(1:2) = [xx(2) xx(1)];
    p = X + repmat(xx(1:3), 1, 2);
    q = X + repmat(xx(1:3) + xx(4:6), 1, 2);
    elseif vector_eq(direction, [1 1])
        s = config.relation.sizes(objid, :);
        xx = cubmat * s';
    p = X + repmat(xx(1:3), 1, 2);
    q = X + repmat(xx(1:3) + xx(4:6), 1, 2);
    elseif vector_eq(direction, [3 3])
        s = config.relation.sizes(objid, :);
        xx = cubmat * s';
        xx(1:2) = -xx(1:2) + s(1:2)';
        xx(4:5) = -xx(4:5);
        q = X + repmat(xx(1:3) + [0;0;xx(6)], 1, 2);
        p = X + repmat(xx(1:3) + [xx(4:5);0], 1, 2);
    elseif vector_eq(direction, [2 2])
        s = config.relation.sizes(objid, :);
        xx = cubmat * s';
        xx(1:2) = -xx([2 1]) + s([2 1])';
        xx(4:5) = -xx([5 4]);
        q = X + repmat(xx(1:3) + [0;0;xx(6)], 1, 2);
        p = X + repmat(xx(1:3) + [xx(4:5);0], 1, 2);
    end
end
z_support = X(3, :) + s(3);