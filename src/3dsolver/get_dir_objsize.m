function s = get_dir_objsize(config, objid, direction)
s = config.relation.sizes(objid, :)';
if vector_eq(direction, [0 1])
    error('should not happen');
elseif vector_eq(direction, [0 0])
    s = s([2 1 4 3]);
elseif vector_eq(direction, [1 1])
    s = s([1 2 4 3]); % lx, ly, hz, lz
end