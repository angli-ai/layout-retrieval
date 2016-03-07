index = query_index;
output = {};
for i = index
    output = [output num2str(i, '%05d.jpg')];
end
fout = fopen('query_images.txt', 'w+');
fprintf(fout, '%s\n', output{:});
fclose(fout);