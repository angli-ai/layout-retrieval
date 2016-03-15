% eccv analysis 3dgp
% eccv_analysis

dataset = 'sunrgbd';

imageid = '292';
gtid = str2num(imageid);
scorepath = '../eval-data/output-3dgp-1-5-gt';

imagepath_det = '/Users/ang/projects/layout3d/sunrgbd-dataset/sunrgbd_fastrcnn/detection-test-vis';
imagepath_gt = '/Users/ang/projects/layout3d/3dgp-dataset/testimages_gt';

scores = load(fullfile(scorepath, [imageid, '.mat']));
scores = max(scores.final_score, [], 2);
bar(scores);

[~, rank_id] = sort(scores, 'descend');
[~, rank] = sort(rank_id);

% print gt score
gtscore = scores(gtid);
fprintf(1, 'GT (#%d) score: %f\n', gtid, gtscore);

% print gt rank
gtrank = rank(gtid);
fprintf(1, 'GT (#%d) rank: %d\n', gtid, gtrank);

% show top 1 image
top_id = rank_id(2);
% det_image = imread(fullfile(imagepath_det, num2str(top_id, 'vis_%05d.jpg')));
gt_image = imread(fullfile(imagepath_gt, num2str(top_id, '%03d.jpg')));
% det_image_gt = imread(fullfile(imagepath_det, num2str(gtid, 'vis_%05d.jpg')));
% subplot(1, 2, 1);
% imshow(det_image);
% subplot(1, 2, 2);
imshow(gt_image);
title(num2str(top_id, '%03d.jpg'));