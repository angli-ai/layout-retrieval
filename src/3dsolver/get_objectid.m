function index = get_objectid(objectname, nameset)
objectname = get_rootname(objectname);
index = find(strcmp(objectname, nameset));
assert(~isempty(index), ['cannot find objectname: ' objectname]);