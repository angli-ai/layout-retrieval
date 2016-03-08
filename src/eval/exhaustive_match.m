function [score, s, x, y] = exhaustive_match(layout, image, config)
Xmin = min([image.X1; image.X2]);
Ymin = min([image.Y1; image.Y2]);
Xmax = max([image.X1; image.X2]);
Ymax = max([image.Y1; image.Y2]);
Xmax_l = 1;
Ymax_l = max([layout.Y1; layout.Y2]);
s = []; x = []; y = [];
if isempty(Xmax)
    score = 0;
    return;
end
step = 10;
for scale = config.scales * min((Xmax - Xmin) / Xmax_l, (Ymax-Ymin) / Ymax_l)
    lxmax = Xmax_l * scale;
    lymax = Ymax_l * scale;
    for tx = Xmin:step:Xmax-lxmax
        for ty = Ymin:step:Ymax-lymax
            s = [s, scale];
            x = [x, tx];
            y = [y, ty];
        end
    end
end

Ngrids = length(s);
Nobj = size(layout, 1);
score = zeros(1, Ngrids);
prev_classname = '';
for i = 1:Nobj
    classname = layout.classname{i};
    classname = fixclassname(classname);
    
    x1 = layout.X1(i) * s + x;
    y1 = layout.Y1(i) * s + y;
    x2 = layout.X2(i) * s + x;
    y2 = layout.Y2(i) * s + y;
    a = (y2 - y1) .* (x2 - x1);
    index = find(strcmp(image.classname, classname));
    if isempty(index), continue, end
    maxp = [];
    Ncandid = length(index);
    if strcmp(classname, prev_classname)
        dup = true;
    else
        dup = false;
        valid = ones(Ncandid, Ngrids);
    end
    prev_classname = classname;
    pick = zeros(1, Ngrids);
    for jj = 1:length(index)
        j = index(jj);
        pos = [image.X1(j) image.Y1(j) image.X2(j) image.Y2(j)];
        area = (pos(3) - pos(1)) * (pos(4) - pos(2));
        conf = image.conf(j);
        interx1 = max(x1, pos(1));
        intery1 = max(y1, pos(2));
        interx2 = min(x2, pos(3));
        intery2 = min(y2, pos(4));
        interA = max(0, (interx2 - interx1)) .* max(0, (intery2 - intery1));
        iou = interA ./ (a + area - interA);
        p = iou * conf;
        p = p .* valid(jj, :);
        if isempty(maxp)
            maxp = p;
            pick(:) = jj;
        else
            pick(p > maxp) = jj;
            maxp = max(p, maxp);
        end
    end
    score = score + maxp;
    valid((0:Ngrids-1)*Ncandid+pick) = 0;
end
score = score / Nobj;