%Run just step 8 in loop

mergestructs = @(x,y) cell2struct([struct2cell(x),struct2cell(y)],fieldnames(x),1);
matlab_folder = pwd;
image_seg_folder = uigetdir;
cd (image_seg_folder)


pre_processed_folder_name = 'pre_processing_2022';
post_processed_folder_name = 'post_processed_2023';

macrophage_segmentation_end = '_iso_ch4_Simple Segmentation_2022.tiff';
macrophage_segmentation_end_downsampled = '_iso_ch4_downsampled_restored_Simple Segmentation_2022.tiff';
vessel_segmentation_end = '_iso_ch3_Simple Segmentation_2022.tiff';
org_particle_image_end = '_iso_ch5.tif';
np_region_dir_name = 'NP_Region_Images';


tissue_outline_save_end = '_tissue_outline_2023.tiff';
processed_macro_str = '_post_processed_macrophages_2023.tiff';
processed_ves_str = '_post_processed_vessels_2023.tiff';
nanoparticle_image_save_str = '_post_processed_nanoparticles_2023.tiff';
inverted_tissue_outline_name = '_tissue_outline_inverted_2023.tiff';
thresholded_np_name  = '_nanoparticle_image_2x_otsu_thresholded_2023.tiff';

results_file_name_px = '_Vessel_analysis_results_pixels_2023.xlsx';
results_file_name_um = 'Vessel_analysis_results_um_2023.xlsx';

neighbourhood_dir_name = 'Neighbourhood_Analysis_2023';
vessel_analysis_dir_name = 'Vessel_Analysis_2023';
metadata_file_name = '_iso_info.csv';

radius = [5];

MSC = dir('MSC*');
UT = dir('UT*');
files = mergestructs(MSC,UT);
for image = 1:size(files,1)
    [~,single_image_name] = fileparts(files(image).name);
    
    image_folder_dir = strcat(image_seg_folder,'\', single_image_name);
    
    cd(image_folder_dir)
    org_part_image = imreadfast(strcat(single_image_name, org_particle_image_end));
    tic
    %get paths and load images
    pre_processed_dir =  strcat(image_folder_dir, '\', pre_processed_folder_name);
    post_processed_dir =  strcat(image_folder_dir, '\', post_processed_folder_name);
    macro_seg_name = strcat(single_image_name, macrophage_segmentation_end);
    macro_seg_name_downsampled = strcat(single_image_name, macrophage_segmentation_end_downsampled);
    processed_macro_name = strcat(single_image_name, processed_macro_str);
    vessel_seg_name = strcat(single_image_name, vessel_segmentation_end);
    tissue_outline_name = strcat(single_image_name, inverted_tissue_outline_name);
    np_image_name = strcat(single_image_name,nanoparticle_image_save_str); 
    
    
    
    inverted_tissue_im = imreadfast(strcat(post_processed_dir, '\',tissue_outline_name));
    post_pro_np_im = imreadfast(strcat(post_processed_dir, '\',np_image_name));
    
    if exist(pre_processed_dir, 'dir')~=7
        mkdir(pre_processed_dir)
    end
    if exist(post_processed_dir, 'dir')~=7
        mkdir(post_processed_dir)
    end 
    
    metadata_name = strcat(image_seg_folder, '\', single_image_name,'\', single_image_name,metadata_file_name);
    metadata = readtable(metadata_name,delimitedTextImportOptions);
    px_per_um = str2num(metadata.ExtraVar1{2})*1E6;
    
    for rad_int = 1:size(radius,2)
        single_rad = radius(rad_int)
        STEP8_Identify_np_regions(image_seg_folder, single_image_name, ...
        post_processed_folder_name,np_region_dir_name, inverted_tissue_im, ...
        post_pro_np_im, single_rad, px_per_um )
    end
end

    
