function print_table_tex(T)
N = size(T, 1);
vars = T.Properties.VariableNames;
for i = 1:N
    for k = 1:length(vars)
        elem = T.(vars{k})(i);
        if k ~= 1
            fprintf(1, '&');
        end
        if isnumeric(elem)
            fprintf(1, '%.2f', elem);
        elseif iscell(elem)
            fprintf(1, '%s', elem{1});
        end
    end
    fprintf(1, '\\\\\\hline\n');
end