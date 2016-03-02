function subobjname = get_subobjname(name)
index = strfind(name, ':');
if isempty(index)
    subobjname = '';
else
    subobjname = name(index+1:end);
end