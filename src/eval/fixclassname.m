function classname = fixclassname(classname)
switch classname
    case 'garage-bin'
        classname = 'garbage_bin'; % fix error
    case 'triple-sofa'
        classname = 'sofa';
end
classname(strfind(classname, '-')) = '_';