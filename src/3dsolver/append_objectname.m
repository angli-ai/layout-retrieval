function output = append_objectname(name, suffix)
% object name = string:string or string
% suffix is inserted right before ':'
index = strfind(name, ':');
if isempty(index)
    output = [name '-' suffix];
else
    output = [name(1:index-1) '-' suffix ':' name(index+1:end)];
end