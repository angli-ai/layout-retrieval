function coords = get_model_coords(config, objname, objid, direction, X)
objclass = config.relation.class{objid};
index = find(strcmp(objclass, config.objmodels.objects));
coords = {};
if ~isempty(index)
    assert(length(index) == 1);
    objindex = config.objmodels.objindex{index};
    for i = objindex
        [p, q] = get_coords(config, config.objmodels.subobjs{i}, objid, direction, X);
        coords = [coords, {{p, q}}];
    end
else
    [p, q] = get_coords(config, objname, objid, direction, X);
    coords = {{p, q}};
end
        
        