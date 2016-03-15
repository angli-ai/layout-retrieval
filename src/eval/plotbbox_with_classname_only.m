function plotbbox_with_classname_only(bbox, classname)
rectangle('Position', bbox, 'edgecolor', 'r', 'linewidth', 2);
text(bbox(1), bbox(2), classname, 'backgroundcolor', 'w', 'edgecolor', 'k', ...
    'interpreter', 'none', 'fontsize', 20, 'verticalalignment', 'top');