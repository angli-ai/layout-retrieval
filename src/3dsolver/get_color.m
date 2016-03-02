function c = get_color(classname)
switch classname
    case 'bed'
        c = 1;
    case 'dresser'
        c = 2;
    case 'lamp'
        c = 3;
    case 'night-stand'
        c = 4;
    case 'picture'
        c = 5;
    otherwise
        c = 0;
end