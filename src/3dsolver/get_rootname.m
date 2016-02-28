function rootname = get_rootname(name)
if iscell(name)
    rootname = {};
    for i = 1:length(name)
        rootname{i} = get_rootname(name{i});
    end
    return
end

index = strfind(name, ':');
if isempty(index)
    rootname = name;
else
    rootname = name(1:index-1);
end