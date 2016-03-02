function center = get_object_center(anchor, objsize, direction)
if length(anchor) == 2
    switch direction
        case 0
            center = [anchor(1) + objsize(2) / 2, anchor(2) + objsize(1) / 2];
        case 1
            center = [anchor(1) + objsize(1) / 2, anchor(2) + objsize(2) / 2];
        case -1
            center = [anchor(1) - objsize(1) / 2, anchor(2) + objsize(2) / 2];
        otherwise
            error('direction not found');
    end
elseif length(anchor) == 3
    error('not implemented');
end