clear
clc




function [thresholded_np_image]= STEP7_nanoparticle_post_processing_function(image_folder_path, ...
    image_name, pre_processed_dir_name, post_processed_dir_name, ...
    original_nanoparticle_image, nanoparticle_image_save_str )

% Saves the path the to matlab folder (folder containing the script)
% User then selects the folder containing the image segmentations and
% the name of the images to be anaylyzed (UT or MSC)


image_seg_folder = image_folder_path
cd (image_seg_folder)
 
    % first image shortnames are identified as the name of each image
    % subfolder in the original directory. A message is displayed to the
    % user indicating which of the images is currently being processed we
    % change directory to that image subfolder. Next subfolders where the
    % simple segementation images are contained are identified.
    
    [~,image_name] = fileparts(files(image).name);
    display (['Processing Nanoparticles ' image_name])
    image_folder_dir = strcat(image_seg_folder,'\', image_name);
    cd(image_folder_dir)
    
    pre_processed_dir = strcat(image_folder_dir, '\', 'pre_processed_dir_name');
    post_processing_dir=(strcat(image_folder_dir,'\', 'post_processed_dir_name'));
    
    


    np_ch_name = strcat(image_name,'_iso_ch5.tif');
    np_processed_name = strcat(image_name, '_particles_post_processed_2023.tiff');
    scaled_processed_name = strcat(image_name, '_scaled_nanoparticles_2022.tiff');

    tissue_outline = strcat(image_name, '_tissue_outline_2022.tiff');
    tissue_inverted =  strcat(image_name, '_tissue_outline_inverted_2022.tiff');
    
    
    if exist(np_ch_name, 'file') ~= 2
        display (['No Segmentation File ']);
    else
        
%         NP_im = imreadfast(np_ch_name);
        cd(post_processing_dir)
        if exist(np_processed_name, 'file') == 2
            display (['File already processed ']);
        else
            cd(image_folder_dir);
            NP_im = imreadfast(np_ch_name);
            cd(post_processing_dir)
            thresh_val = graythresh(NP_im);
            thresholded_np = imbinarize(NP_im, thresh_val*2);
            thresh_np = uint16(thresholded_np);
            tissue_im = imreadfast(tissue_outline);
            invert_tissue = tissue_im == 0;
            invert_tissue = uint16(invert_tissue);
            mask_np = thresh_np.*NP_im;
           % cd(post_processing_dir)
            
            
            if exist(tissue_inverted, 'file') ~= 2
                tissue_inverted_name = tissue_inverted;
                clear options;
                options.overwrite = true;
                options.compress = 'lzw';
                saveastiff(uint16(invert_tissue), tissue_inverted_name, options);   
                
%                 num_slices = size(NP_im,3);
%                 imwrite(invert_tissue(:,:,1),tissue_inverted);
%                 for p = 2:num_slices
%                     imwrite(invert_tissue(:,:,p),tissue_inverted, 'WriteMode','append');
%                 end
            end
            
            mask_name = np_processed_name;
            clear options;
            options.overwrite = true;
            options.compress = 'lzw';
            saveastiff(uint16(mask_np), mask_name, options);   
            
            
            
%             
                
            
    end
    end
end
