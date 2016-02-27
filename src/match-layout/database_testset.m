% load detection/filenames for testset 
% will also have a map (150ID -> testsetID)
function [database_detections, database_imgnames, IDmap_150_testset] = database_testset()

% detection results of image database
database_detections = load('../../3dgp/data-v1/3dgp/testfiles_detections.mat');
database_detections = database_detections.detections.im_results;
database_imgnames = load('../../3dgp/data-v1/3dgp/datasplit.mat');
database_imgnames = database_imgnames.testfiles;


% 150 image list
fid = fopen('../../3dgp/data-v1/corresp.txt');
corresp_content = textscan(fid,'%s','Delimiter',' ');
fclose(fid);
imglist_imgnames = cell(length(corresp_content{1})/2,1);
for i=1:length(imglist_imgnames)
    imglist_imgnames{i} = ['images/' corresp_content{1}{i*2}];
end


% store a map of testset (423 images) filename to ID in database_detections
filename2IDmap = containers.Map('KeyType','char','ValueType','int32');
for i=1:length(database_imgnames)
    filename2IDmap(database_imgnames{i}) = i;
end

% store a map of 150 images ID to ID in testset
IDmap_150_testset = containers.Map('KeyType','int32','ValueType','int32');
for i=1:length(imglist_imgnames)
    if isKey(filename2IDmap, imglist_imgnames{i})
        IDmap_150_testset(i) = filename2IDmap(imglist_imgnames{i});
    end
end

end
