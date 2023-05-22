clear
clc


% Saves the path the to matlab folder (folder containing the script)
% User then selects the folder containing the image segmentations and
% the name of the images to be anaylyzed (UT or MSC)

run('C:\Users\admin\Documents\MATLAB\DIPimage 2.9\dipstart.m')
mergestructs = @(x,y) cell2struct([struct2cell(x),struct2cell(y)],fieldnames(x),1);
matlab_folder = pwd;
image_seg_folder = uigetdir;
cd (image_seg_folder)
MSC = dir('MSC');
UT = dir('UT11-T-stack1*');
files = mergestructs(MSC,UT);
%for image= 4
for image = 1:size(files,1)
    ERROR = 0;
    %Section 1: Define the image folders and generate paths or folders as
    %needed.
    Done = 0;
    tic
    
    % first image shortnames are identified as the name of each image
    % subfolder in the original directory. A message is displayed to the
    % user indicating which of the images is currently being processed we
    % change directory to that image subfolder. Next subfolders where the
    % simple segementation images are contained are identified.
    
    [~,shortname] = fileparts(files(image).name);
    display (['Processing Vessels ' shortname])
    image_folder_dir = strcat(image_seg_folder,'\', shortname);
    cd(image_folder_dir)
    
    pre_processed_dir = strcat(image_folder_dir, '\', 'pre_processing_2022');
    post_processing_dir=(strcat(image_folder_dir,'\', 'post_processed_2022'));
    
    
    %testing dirs
    
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
    
    vessel_seg_im_name = strcat(shortname,'_iso_ch3_Simple Segmentation_2022.tiff');
    not_written = ('N:\Presley\Tumour Mapping Project\TumourImages\not_processed_images.xlsx');
    not_written_txt = ('N:\Presley\Tumour Mapping Project\TumourImages\not_processed_images.txt');
    finished_processing = ('N:\Presley\Tumour Mapping Project\TumourImages\images_finished_post_processing.txt');
    vessel_processed_name = strcat(shortname, '_vessels_post_processed_2022.tiff');
    
    if exist(vessel_seg_im_name, 'file') ~= 2
        display (['No Segmentation File ']);
    else
        
        vessel_channel = imreadfast(vessel_seg_im_name);
        cd(post_processing_dir)
        
        if exist(vessel_processed_name, 'file') == 2
            display (['File already processed ']);
        else
            vessels = (vessel_channel == 1);
            se = strel('sphere', 5);
            se2 = strel('sphere', 2);
            remove_sm_noise = bwareaopen(vessels, 26, 26); %5
            
            dil_noise_free = imdilate(remove_sm_noise, se2);
            er = erosion( dil_noise_free, 3, 'elliptic');
            %er = imerode( remove_sm_noise, se2);
            %er = erosion( remove_sm_noise, 3, 'elliptic');
            %close = closing(er, 3, 'elliptic');
            ves_processed = erosion(er, 3, 'elliptic');
            
            
            ves_processed_uint16 = uint16(ves_processed);
            num_slices = size(vessels,3);
            
            cd(post_processing_dir)
            
            imwrite(ves_processed_uint16(:,:,1),vessel_processed_name);
            for p = 2:num_slices
                imwrite(ves_processed_uint16(:,:,p),vessel_processed_name, 'WriteMode','append');
            end
        end
    end
    toc
end

