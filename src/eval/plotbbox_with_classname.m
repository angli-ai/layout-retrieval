function plotbbox_with_classname(bbox, classname, conf)
rectangle('Position', bbox, 'edgecolor', 'r', 'linewidth', 2);
text(bbox(1), bbox(2), [classname, num2str(conf, ' %.3f')], 'backgroundcolor', 'w', 'edgecolor', 'k', ...
    'interpreter', 'none');