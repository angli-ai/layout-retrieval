% visualize

layout = load('layout.mat');
image = load('images.mat');

Nlayout3d = length(image.data.layouts);
for i = 1:Nlayout3d
    i3d = image.data.layouts(i).layout3d;
    i2d = image.data.layouts(i).layout2d;
    
    n2d = length(i2d);
    for j = 1:n2d
        ij2d = i2d(j);
        subplot(1, 2, 2);
        for k = 1:length(ij2d.objects)
            plot_cubes(ij2d.objects(k));
        end
    end
end