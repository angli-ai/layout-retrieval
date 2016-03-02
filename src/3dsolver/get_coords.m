function [p, q] = get_coords(config, objname, objid, direction, X)
subobjname = get_subobjname(objname);
if isempty(subobjname)
    p = X;
    s = config.relation.sizes(objid, :)';
    if vector_eq(direction, [0 1])
        error('should not happen');
    elseif vector_eq(direction, [0 0])
        q = X + repmat(s([2 1 4]), 1, 2);
    elseif vector_eq(direction, [1 1])
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
    elseif vector_eq(direction, [1 1])
        s = config.relation.sizes(objid, :);
        xx = cubmat * s';
    end
    p = X + repmat(xx(1:3), 1, 2);
    q = X + repmat(xx(1:3) + xx(4:6), 1, 2);
end