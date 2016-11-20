function [xx, meany, errorpy, errorny] = geterrors(x, y)
xx = unique(x);
meany = [];
errorpy = [];
errorny = [];
for i = 1:length(xx)
    idx = find(x == xx(i));
    meany(i) = mean(y(idx));
    errorpy(i) = max(y(idx)) - meany(i);
    errorny(i) = meany(i) - min(y(idx));
end