function plotbbox_with_classname_only(bbox, classname, color, linewidth)
if nargin < 3
    color = 'r';
    linewidth = 2;
end
rectangle('Position', bbox, 'edgecolor', color, 'linewidth', linewidth);
text(bbox(1), bbox(2), classname, 'backgroundcolor', 'w', 'edgecolor', 'k', ...
    'interpreter', 'none', 'fontsize', 20, 'verticalalignment', 'top');