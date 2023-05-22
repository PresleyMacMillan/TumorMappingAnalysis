import os
import numpy as np 
import pandas as pd 
import raster_geometry as rg 
import time
from skimage import io
import neighbourhood_analysis_functions as nf

# path_to_image_folder = 'N:/Presley/Tumour Mapping Project/Tumour_testing_full/U87-GNP50nm/0.5h/MSC158-T-stack1-Nov29-2018'

# path_to_folder = f'{path_to_image_folder}/post_processed_2023'

# tissue_path = f'{path_to_folder}/MSC158-T-stack1-Nov29-2018_tissue_outline_inverted_2023.tiff'

# vessel_path = f'{path_to_folder}/MSC158-T-stack1-Nov29-2018_post_processed_vessels_2023.tiff'

# macro_path = f'{path_to_folder}/MSC158-T-stack1-Nov29-2018_post_processed_macrophages_2023.tiff'

# np_path = f'{path_to_folder}/MSC158-T-stack1-Nov29-2018_post_processed_nanoparticles_2023.tiff'

# metadata_path = f'{path_to_image_folder}/MSC158-T-stack1-Nov29-2018_iso_info.csv'

# meta_data = pd.read_csv(metadata_path)

# pixel_size = round(float(meta_data['newphys'][0])*(10**6))

# tissue_im = io.imread(tissue_path)

# vessel_im = io.imread(vessel_path)

# macro_im = io.imread(macro_path)

# np_im = io.imread(np_path)

# start_time = time.time()

def sphere_sampling(path_to_image_folder, tissue_im, vessel_im, macro_im, np_im, radius_um, sample_number, metadata_pix_size):
    
    #dataframe to save results
    iod_df = pd.DataFrame()
    
    
    
    save_folder_path = f'{path_to_image_folder}/Neighbourhood_Analysis_2023/Summary_Dataframes'
    
    if not os.path.exists(save_folder_path):
        os.mkdir(save_folder_path)
    
    dataframe_save_path = f'{save_folder_path}/{image_name}_{sample_number}x_{radius_um}um_sphere_sampling_index_of_dispersion.csv' 
    center_pt_path = f'{save_folder_path}/{image_name}_{sample_number}x_{radius_um}um_sphere_sampling_center_pts.csv'
    

    radius = radius_um/metadata_pix_size
    center_list = []
    z_size = tissue_im.shape[0]
    y_size = tissue_im.shape[1]
    x_size = tissue_im.shape[2]

    image_shape = (z_size, y_size, x_size)
    mask_size_list = []
    tissue_pix_list = [] 
    macro_pix_list = []
    vessel_pix_list = [] 
    np_pix_list = []
    pct_tissue_list = []
    pct_macro_in_tis_list = [] 
    pct_ves_in_tis_list = []
    pct_np_in_tis_list = []
    z_list = []
    y_list = []
    x_list = [] 

    count = 0 
    while count < sample_number: 
        center = (
    np.random.randint(high=z_size, low=0),
    np.random.randint(high=y_size, low=0),
    np.random.randint(high=x_size, low=0)
    )

        center_list.append(center)
        count = count + 1
    center_df = pd.DataFrame(center_list, columns=['z', 'y', 'x'])
    center_df.to_csv(center_pt_path)
    for center_pt in center_list:

        # start_time = time.time()
        z = center_pt[0]
        y = center_pt[1]
        x = center_pt[2]
        sphere_mask = (rg.nd_superellipsoid(
                image_shape, radius, 2.0, center_pt, 3,
                rel_position=False, rel_sizes=False, smoothing=False)).astype(int)


        mask_pix = np.count_nonzero(sphere_mask)
        tissue_pix =np.count_nonzero(sphere_mask *tissue_im)
        if tissue_pix==0:
            continue
        else:
            macro_pix = np.count_nonzero(sphere_mask * macro_im)
            vessel_pix = np.count_nonzero(sphere_mask * vessel_im)
            np_pix = np.count_nonzero(sphere_mask * np_im)

        # print("--- %s seconds ---" % (time.time() - start_time))


        pct_tissue = tissue_pix/mask_pix*100


        pct_macro_in_tissue = macro_pix/tissue_pix*100
        pct_ves_in_tissue = vessel_pix/tissue_pix*100
        pct_np_in_tissue = np_pix/ tissue_pix*100

        z_list.append(z)
        y_list.append(y)
        x_list.append(x)
        mask_size_list.append(mask_pix)
        tissue_pix_list.append(tissue_pix)
        macro_pix_list.append(macro_pix)
        vessel_pix_list.append(vessel_pix)
        np_pix_list.append(np_pix)
        pct_tissue_list.append(pct_tissue)
        pct_macro_in_tis_list.append(pct_macro_in_tissue)
        pct_ves_in_tis_list.append(pct_ves_in_tissue)
        pct_np_in_tis_list.append(pct_np_in_tissue)
                
        # print("--- %s seconds ---" % (time.time() - start_time))
    iod_df['z'] = z_list
    iod_df['y'] = y_list
    iod_df['x'] = x_list
    iod_df['mask_size'] = mask_size_list
    iod_df['tissue_pixels'] = tissue_pix_list
    iod_df['macro_pixels'] = macro_pix_list
    iod_df['vessel_pixels'] = vessel_pix_list
    iod_df['np_pixels'] = np_pix_list
    iod_df['pct_tissue'] = pct_tissue_list
    iod_df['pct_macro_per_tissue'] = pct_macro_in_tis_list
    iod_df['pct_ves_per_tissue'] = pct_ves_in_tis_list
    iod_df['pct_np_per_tissue'] = pct_np_in_tis_list
    
    
    save_folder_path = f'{path_to_image_folder}/Neighbourhood_Analysis_2023/Summary_Dataframes'
    
    iod_df.to_csv(dataframe_save_path)
    
    return(iod_df, center_list, dataframe_save_path)


def sphere_sampleing_example_figure(tissue_im, 
                                    num_samples=10, 
                                    sphere_size_um=25, 
                                    pixel_size=2):
    '''The purpose of this function is to generate a sammple mask that can be applied to an image a to illustrate how sampling in done'''
    
    array_shape = tissue_im.shape
    
    z_size=array_shape[0]
    y_size= array_shape[1]
    x_size=array_shape[2]
    
    
    radius = sphere_size_um/pixel_size
    center_list = []

    image_shape = (z_size, y_size, x_size)
    
    z_list = []
    y_list = []
    x_list = [] 
    
    mask =np.zeros(image_shape)
    count = 0 
    while count < num_samples: 
        center = (
        np.random.randint(high=z_size, low=0),
        np.random.randint(high=y_size, low=0),
        np.random.randint(high=x_size, low=0)
        )

        center_list.append(center)
        count = count + 1


    for center_pt in center_list:
        sphere_mask = (rg.nd_superellipsoid(
                image_shape, radius, 2.0, center_pt, 3,
                rel_position=False, rel_sizes=False, smoothing=False)).astype(int)
        
        
        mask_pix = np.count_nonzero(sphere_mask)
        tissue_pix =np.count_nonzero(sphere_mask *tissue_im)
        if tissue_pix==0:
            continue
        
        mask = mask+sphere_mask
    
    
    
    
    return(mask)
    
    
if __name__ == '__main__':
    
    
    top_folder_path = nf.get_folder_path()
    subfolders = nf.generate_list_subfolders(top_folder_path)
    
    image_list = []
    
    for im in subfolders:
        if 'MSC' in im:
            image_list.append(im)
        elif 'UT' in im:
            image_list.append(im)   
    
    
    sample_num = 1000
    radius_um = int(input("enter radius:"))             
    for image_folder_path in image_list:
    #for image_folder_path in [subfolders[0]]:
        start_time = time.time()        
        image_name = image_folder_path.split('\\')[-1]

        print('Sampling ',image_name, 'and saving sample df ')

        processed_folder = f'{image_folder_path}/post_processed_2023'
        
        tissue_path = f'{processed_folder}/{image_name}_tissue_outline_inverted_2023.tiff'
        vessel_path = f'{processed_folder}/{image_name}_post_processed_vessels_2023.tiff'
        macro_path = f'{processed_folder}/{image_name}_post_processed_macrophages_2023.tiff'
        np_path = f'{processed_folder}/{image_name}_post_processed_nanoparticles_2023.tiff'
        metadata_path = f'{image_folder_path}/{image_name}_iso_info.csv'
        meta_data = pd.read_csv(metadata_path)
        pixel_size = round(float(meta_data['newphys'][0])*(10**6))

        tissue_im = io.imread(tissue_path)
        vessel_im = io.imread(vessel_path)
        macro_im = io.imread(macro_path)
        np_im = io.imread(np_path)
        

        
        df, pts, pth =  sphere_sampling(image_folder_path, 
                                        tissue_im, 
                                        vessel_im, 
                                        macro_im, 
                                        np_im, 
                                        radius_um, 
                                        sample_num, 
                                        pixel_size)
        print("--- %s seconds ---" % (time.time() - start_time))
        
    # path_to_image_folder = 'N:/Presley/Tumour Mapping Project/Tumour_testing_full/U87-GNP50nm/0.5h/MSC158-T-stack1-Nov29-2018'

# path_to_folder = f'{path_to_image_folder}/post_processed_2023'

# tissue_path = f'{path_to_folder}/MSC158-T-stack1-Nov29-2018_tissue_outline_inverted_2023.tiff'

# vessel_path = f'{path_to_folder}/MSC158-T-stack1-Nov29-2018_post_processed_vessels_2023.tiff'

# macro_path = f'{path_to_folder}/MSC158-T-stack1-Nov29-2018_post_processed_macrophages_2023.tiff'

# np_path = f'{path_to_folder}/MSC158-T-stack1-Nov29-2018_post_processed_nanoparticles_2023.tiff'

# metadata_path = f'{path_to_image_folder}/MSC158-T-stack1-Nov29-2018_iso_info.csv'

# meta_data = pd.read_csv(metadata_path)

# pixel_size = round(float(meta_data['newphys'][0])*(10**6))

# tissue_im = io.imread(tissue_path)

# vessel_im = io.imread(vessel_path)

# macro_im = io.imread(macro_path)

# np_im = io.imread(np_path)

# start_time = time.time()



# count = 0 
# while count < 10: 
#     center = (
#   np.random.randint(high=z_size, low=0),
#   np.random.randint(high=y_size, low=0),
#   np.random.randint(high=x_size, low=0)
# )

#     center_list.append(center)
#     count = count + 1

# for center_pt in center_list:

#     start_time = time.time()
#     z = center_pt[0]
#     y = center_pt[1]
#     x = center_pt[2]
#     sphere_mask = (rg.nd_superellipsoid(
#             image_shape, radius, 2.0, center_pt, 3,
#             rel_position=False, rel_sizes=False, smoothing=False)).astype(int)


#     start_time = time.time()
#     sphere = sphere_mask.flatten()
#     tissue = tissue.flatten()
#     macro_flat = macro_im.flatten()
#     vessel_flat = vessel_im.flatten()
#     np_flat = np_im.flatten()

#     z_coords = np.arange(0, z_size, 1)
#     y_coords = np.arange(0, y_size, 1)
#     x_coords = np.arange(0, x_size, 1)

#     z_idx = np.tile(z_coords, x_size*y_size)
#     y_idx = np.tile(np.repeat(y_coords, z_size), x_size)
#     x_idx = np.repeat(x_coords, z_size*y_size)
#     df = pd.DataFrame({'x_idx':x_idx,
#                     'y_idx':y_idx,
#                     'z_idx':z_idx,
#                     'sphere_sample':sphere,
#                     'tissue':tissue_flat,
#                     'macro':macro_flat,
#                     'vessel': vessel_flat,
#                     'np': np_flat
#                     })

#     sample_df = df[df['sphere_sample']==1]
#     tissue_pix = sum(sample_df['tissue'])
#     if not tissue_pix==0:
    
#         macro_pix = sum(sample_df['macro'])
#         vessel_pix = sum(sample_df['vessel'])
#         # sphere_ind = df[df['label']==1]

#         pct_tissue = tissue_pix/mask_pix
   

#         pct_macro_in_tissue = macro_pix/tissue_pix
#         pct_ves_in_tissue = vessel_pix/tissue_pix
#         pct_np_in_tissue = np_pix/ tissue_pix
 


#     print("--- %s seconds ---" % (time.time() - start_time))