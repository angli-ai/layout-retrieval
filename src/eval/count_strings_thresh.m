function output = count_strings_thresh(input, thresh)
names = input.classname;
conf = input.conf;
bg_conf = input.bg_conf;
index = bg_conf < conf & conf > thresh;
output = count_strings(names(index));