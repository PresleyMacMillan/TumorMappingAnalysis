
function [cell_array] = Step4_label_macrophage_binary(czi_processed_folder, ...
    image_name, pre_processing_dir_name, post_processing_dir_name, ...
    processed_macro_image, labeled_image_name_str)



run('C:\Users\admin\Documents\MATLAB\DIPimage 2.9\dipstart.m')


image_seg_folder = czi_processed_folder;
cd(image_seg_folder);
str_to_return = string();


image_dir = strcat(image_seg_folder,'\',image_name);
dir_pre_processed_images= strcat(image_dir,'\', pre_processing_dir_name);
dir_post_processed =  strcat(image_dir, '\', post_processing_dir_name);
labeled_macro_name = strcat(dir_post_processed, '\',image_name, labeled_image_name_str);


if exist(labeled_macro_name, 'file')==2
    disp([image_name ' Labeled Macro Image Already Exists'])
    str_to_return(i) = strcat(image_name, " Already exists");
else
    display(['Adding Macrophage Labels  ' image_name])
    str_to_return(i) = strcat("Adding Macrophage Labels  ", image_name);
    
    if exist(dir_post_processed, 'dir')~=7
        mkdir(dir_post_processed);
    end
    
end

macro_im = processed_macro_image
labeled_im = bwlabeln(macro_im);
cd(dir_post_processed)
message = str_to_return;

labeled_name= labeled_macro_name;
clear options;
options.overwrite = true;
options.compress = 'lzw';
saveastiff(uint16(labeled_im), labeled_name, options);

message = str_to_return;
end




message=str_to_return;
if message == ""
    message=strcat("No images folders by the name ", image_name, " in this folder");
    disp(message)
end

cell_array = cellstr(message);
