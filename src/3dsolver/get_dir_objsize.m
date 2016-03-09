function [s, o] = get_dir_objsize(config, objname, objid, direction)
subobjname = get_subobjname(objname);
if isempty(subobjname)
    s = config.relation.sizes(objid, :)';
    if vector_eq(direction, [0 1])
        error('should not happen');
    elseif vector_eq(direction, [0 0]) || vector_eq(direction, [2 2])
        s = s([2 1 4 3]);
    elseif vector_eq(direction, [1 1]) || vector_eq(direction, [3 3])
        s = s([1 2 4 3]); % lx, ly, hz, lz
    end
    o = [0 0 0];
else
    % has sub component.
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
        o = xx(1:3);
        s = xx(4:6);
    elseif vector_eq(direction, [1 1])
        s = config.relation.sizes(objid, :);
        xx = cubmat * s';
    o = xx(1:3);
    s = xx(4:6);
    elseif vector_eq(direction, [3 3])
        s = config.relation.sizes(objid, :);
        xx = cubmat * s';
        xx(1:2) = -xx(1:2) + s(1:2)';
        xx(4:5) = -xx(4:5);
        o = xx(1:3) + [0;0;xx(6)];
        s = xx(1:3) + [xx(4:5);0] - o;
    elseif vector_eq(direction, [2 2])
        s = config.relation.sizes(objid, :);
        xx = cubmat * s';
        xx(1:2) = -xx([2 1]) + s([2 1])';
        xx(4:5) = -xx([5 4]);
        o = xx(1:3) + [0;0;xx(6)];
        s = xx(1:3) + [xx(4:5);0] - o;
    end
    s(4) = s(3);
end