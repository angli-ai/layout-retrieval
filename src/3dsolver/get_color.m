function c = get_color(classname)
classes = {'bed', 'dresser', 'lamp', 'night-stand', 'picture', ...
    'pillow', 'garage-bin', 'whiteboard', 'sofa', 'tv', 'chair', ...
    'desk', 'table'};
c = find(strcmp(classname, classes));
if isempty(c)
    c = 0;
end