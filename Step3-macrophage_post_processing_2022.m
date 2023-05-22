% Post processing Macrophage script for 2022 Ilastik Segmentation images
clear
clc


% Saves the path the to matlab folder (folder containing the script)
% User then selects the folder containing the image segmentations and
% the name of the images to be anaylyzed (UT or MSC)

run('C:\Users\admin\Documents\MATLAB\DIPimage 2.9\dipstart.m')

mergestructs = @(x,y) cell2struct([struct2cell(x),struct2cell(y)],fieldnames(x),1);
matlab_folder = pwd;
image_seg_folder = uigetdir();
cd (image_seg_folder)
%Identify Animal Image Key
MSC = dir('MSC*');
UT = dir('UT*');
files = mergestructs(MSC,UT);

for image = 1:size(files,1)
    ERROR = 0;
    %Section 1: Define the image folders and generate paths or folders as
    %needed.
    
    tic
    
    % first image shortnames are identified as the name of each image
    % subfolder in the original directory. A message is displayed to the
    % user indicating which of the images is currently being processed we
    % change directory to that image subfolder. Next subfolders where the
    % simple segementation images are contained are identified.
    
    [~,shortname] = fileparts(files(image).name);
    display (['Processing macrophages ' shortname])
    image_folder_dir = strcat(image_seg_folder,'\', shortname);
    cd(image_folder_dir)
    
    %possible image directory folders
    pre_processed_dir = strcat(image_folder_dir, '\', 'pre_processing_2022');
    pre_processing_images_dir = strcat(image_folder_dir, '\', 'Pre processing images');
    post_processing_dir=(strcat(image_folder_dir,'\', 'post_processed_2022'));
    restored_dir = strcat(pre_processing_images_dir, '\', 'Restored_segmentation');
    
    
    
    %Check to see if the defined post_processing_dir exists and if not make
    %it
    if exist(post_processing_dir , 'dir')~=7
        mkdir(post_processing_dir);
    end
    
    if exist(pre_processed_dir, 'dir') ~=7
        mkdir(pre_processed_dir);
    end
    
    %%
    %Section 2: find pre_processed_images and begin loading the variables.
    %Note tissue outlines are defined in the vessel images thus we load the
    %macrophage and vessel images into the script.
    
    %all vessels are stained with Cy3 = Channel 3
    %all macrophages are stained with Cy5 = Channel 4
    %Dapi was not used to label the tissue as not all tissues were DAPI
    %stained.
    
    cd(pre_processed_dir)
    
    vessel_seg_im_name = strcat(shortname, '_iso_ch3_Simple Segmentation_2022.tiff'); %pre_processing_dir
    pre_pro_vessel_seg_im_name = strcat(shortname,'_pre_processed_vessels_Simple Segmentation_2022.tiff');
    %     macro_seg_im_name = strcat(shortname, '_iso_ch4_Simple Segmentation_2022.tiff'); %pre_processing_dir
    macro_seg_im_name = strcat(shortname, '_pre_processed_macrophage_Simple Segmentation_2022.tiff'); %pre_processing_dir
    
    %macro_seg_downsampled = strcat(shortname, '_iso_ch4_downsampled_restored_Simple Segmentation_2022.tiff');%pre_processing_dir
    macro_seg_downsampled = strcat(shortname, '_pre_processed_macrophage_downsampled_restored_Simple Segmentation_2022.tif');%pre_processing_dir
    tissue_outline_name = strcat(shortname, '_tissue_outline_2022.tiff'); %post_processing_dir
    
    %%%%Tissue Outline%%%%
    
    %If tissue outline name does not exist we make the tissue outline by
    %loading in the channel and filling holes in the tissue.
    %label_3 in vessel images is background (everything that is not
    %tissue)
    
    try
        cd(pre_processing_images_dir)
        vessels = imreadfast(pre_pro_vessel_seg_im_name);
    catch ME
        ERROR = 1 ;
        fprintf(['Vessel File Not Available\n']);
    end
    
    if ERROR == 1
        try
            cd(pre_processed_dir)
            vessels = imreadfast(vessel_seg_im_name);
        catch ME
            ERROR = ERROR +1 ;
            fprintf(['Vessel File Not Available\n']);
        end
    end
    
    cd(post_processing_dir)
    %If the vessel file is not available we can not process the macrophage
    %channel as we do not have the tissue outline.
    
    %Here we first check if there is a vessel file, if not we continue on.
    %If the vessel file exists we see if we have already created a tissue
    %outline and if yes we open that image.
    
    %If we have not already created a tissue outline image we generate one
    %by filling tissue holes and eroding then dilating the image. We then
    %write the issue outline image to a .tiff file
    
    if ERROR == 2
        continue
    elseif exist(tissue_outline_name, 'file') ==2
        cd(post_processing_dir)
        tissue_area = imreadfast(tissue_outline_name);
    else
        not_tissue_only = (vessels ~= 3);
        fill_holes = imfill(not_tissue_only, 'holes');
        se = strel('sphere', 5);
        tissue_erode = imerode(fill_holes, se);
        tissue_dil = imdilate(tissue_erode, se);
        %fill_holes = imfill(tissue_dil, 'holes');
        majority = bwmorph3(tissue_dil, 'majority');
        closed = imclose(majority, se);
        
        tissue = (closed == 0); %swap labels to identify tissue)
        tissue_area = uint16(tissue);
        
        num_slices = size(tissue_area,3);
        
        cd(post_processing_dir)
        imwrite(uint16(tissue_area(:,:,1)),tissue_outline_name);
        for p = 2:num_slices
            imwrite(uint16(tissue_area(:,:,p)),tissue_outline_name, 'WriteMode','append');
        end
        
    end
    
    
    %%%%% Macrophage %%%%%
    
    %If we do not have a tissue outline we skip the image.
    
    %If we have a tissue image we then try to open the image. As some
    %images needed to be downsampled before processing we open these images
    %if the original sized segmented images were unavailable.
    
    if ERROR ==2
        continue
    else
        
        try
            cd(pre_processing_images_dir)
            macro_seg = imreadfast(macro_seg_im_name);
        catch
            warning('Cannot open file')
            cd(restored_dir)
            macro_seg = imreadfast( macro_seg_downsampled);
        end
        
        
        %Images are all binary unit8 with values of 0 and 255. Here we
        % threshold the images and transform it to a logical data type so
        % the values are either 0 =  background or 1 = feature.
        
        if max(max(max(macro_seg)))== 255
            macro_seg = ~(threshold(macro_seg));
            macro_seg = logical(macro_seg);
        end
        macro_ch = macro_seg == 1;
        vessels_only = vessels == 1;
        
        % to avoid any flourescence signal overlab between our different
        % tumours we remove any pixels identifed in the segmentation that
        % are also labeled in the vessel channel.
        
        macro_only = (macro_ch - vessels_only)==1;
        
        %Here we set a filter size and then use this to remove any noise in
        %the segmentation before dilating the idenified macrophage signal
        se = strel('sphere', 1);
        remove_sm_noise = bwareaopen(macro_only, 18, 26);
        
        %Here we use dipimage to perform a Euclidean distance transform,
        %generate "seeds" for the macrophage image and then use these to
        %generate our final dilated macrophages.
        
        se = strel('sphere', 1);
        dt_thresh_dil =  dt(remove_sm_noise);
        dil_noise_free = imdilate(remove_sm_noise, se);
        D = bwdist(~dil_noise_free);
        D = -D;
        
        seeds = maxima(dt_thresh_dil,2,0);
        seeds2 = dilation(seeds,4.5)>0;
        im_out = waterseed(seeds2, max(dt_thresh_dil)-dt_thresh_dil,2,0,0);
        threshmacro_im = dil_noise_free;
        threshmacro_im(im_out) = false;
        thresh_macro_open = opening(threshmacro_im, 3, 'elliptic');
        thresh_macro_open = uint16(thresh_macro_open);
        
        % finally we save the final images as a tiff
        cd(pre_processed_dir)
        imwrite(uint16(thresh_macro_open(:,:,1)),strcat(shortname,'_macro_post_processed_2022_final.tiff'));
        num_slices = size(uint16(thresh_macro_open),3);
        for p = 2:num_slices
            imwrite(uint16(thresh_macro_open(:,:,p)),strcat(shortname,'_macro_post_processed_2022_final.tiff'), 'WriteMode','append');
        end
        toc
        
    end
    
    
    
    
    
    
    
end
