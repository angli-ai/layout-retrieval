function visualize_layouts

load('layout.mat', 'layouts', 'objs');

h = figure(1);


for k = 1:size(layouts, 2)
    subplot(2, 2, k);
    nobjs = size(layouts, 1) / 2;
    colors = hsv(nobjs);

    x = layouts(1:2:end, k);
    y = layouts(2:2:end, k);
    xmin = min(x); ymin = min(y);
    xmax = max(x); ymax = max(y);
    N = size(x, 1);
    hold on;
    for i = 1:N
        plot(x(i), y(i), 'o', ...
        'MarkerEdgeColor','k',...
                    'MarkerFaceColor', colors(i, :),...
                    'MarkerSize',10);
        viscircles([x(i) y(i)], 0.5, 'EdgeColor', colors(i, :));
        text(x(i), y(i), objs{i});
    end
    hold off;
    axis equal
    s = 0.5;
    xlim([xmin-s, xmax+s]);
    ylim([ymin-s, ymax+s]);
    set(gca,'YDir','reverse');
end

saveas(h, 'possible_layouts.jpg');