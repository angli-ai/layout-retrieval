% latex generator for eccv supp
id = '00852';
index = strfind(id, '-');
if isempty(index)
    caption = id;
else
    caption = id(index+1:end);
end
inputdir = 'eccv-supp-sunrgbd';
flist = dir(fullfile(inputdir, id));
flist = {flist(:).name};
flist = setdiff(flist, {'.', '..'});
list3d = {};
listdet = {};
listorigin = {};
for i = 1:length(flist)
    if ~isempty(strfind(flist{i}, '3d'))
        list3d = [list3d flist{i}];
    elseif ~isempty(strfind(flist{i}, 'det'))
        listdet = [listdet flist{i}];
    else
        listorigin = [listorigin flist{i}];
    end
end
width = '.29\textwidth';
prefix = '\parbox{0.1\linewidth}{\vskip -3em \hspace{1em}}\parbox{0.29\linewidth}{\vskip -3em \centering \bf Detection}\parbox{0.29\linewidth}{\vskip -3em \centering \bf 3D scene}\parbox{0.29\linewidth}{\vskip -3em \centering \bf Matching}\\';
fprintf(1, '\\begin{figure}\n%s\n', prefix);
for i = 1:length(list3d)
    index = strfind(list3d{i}, '-');
    ranknum = list3d{i}(1:index(1)-1);
    fprintf(1, '\\parbox{0.1\\linewidth}{\\vskip -8em Rank %s}', ranknum);
    filepath = ['supp_imgs/' id '/' listdet{i}];
    fprintf(1, '\\includegraphics[width=%s]{%s}\n', width, filepath);
    filepath = ['supp_imgs/' id '/' list3d{i}];
    fprintf(1, '\\includegraphics[width=%s]{%s}\n', width, filepath);
    filepath = ['supp_imgs/' id '/' listorigin{i}];
    fprintf(1, '\\includegraphics[width=%s]{%s}\n', width, filepath);
fprintf(1, '\\\\\n');
end
fprintf(1, '\\caption{%s}\n', caption);
fprintf(1, '\\end{figure}\n');