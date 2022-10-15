



# %% Package Importation
import os
import re

import mne
# from mne.time_frequency import tfr_morlet
from mne.stats import permutation_cluster_1samp_test
from mne.stats import permutation_t_test
from mne.stats import spatio_temporal_cluster_1samp_test


import numpy as np
from scipy import stats as stats
import json
# import pandas as pd
# import seaborn as sns
import matplotlib.pyplot as plt


# PART 2: Calculate TFR Grand Average for vizualisation and do statistical test
export_folder = '/Volumes/Seagate Backup Plus Drive/Données_Doctorat/Données_Article#2/A2_EEGLAB_MNE/Step_3 TFR files TMS only_2022ICARun' # Reminder if first part of the script was used before
# export_folder = 'D:\Données_Doctorat\Données_Article#2\A2_EEGLAB_MNE\Step3_SecondRun'
Sham_dict = {}
Stim_dict = {}
# %% Functions for compute grand average and compare
# Load TFR average inside a dictionary
for files in os.listdir(export_folder):
    if re.search('Sham', files):
        num = re.findall(r'\d+', files)
        #print(num)
        import_fname = os.path.join(export_folder, files)
        Sham_dict["PowerP%sSham" % num] = mne.time_frequency.read_tfrs(import_fname) # key:value pair to easily identify files loaded
        # Sham_list.append(mne.time_frequency.read_tfrs(import_fname))
    else:
        num = re.findall(r'\d+', files)
        import_fname = os.path.join(export_folder, files)
        Stim_dict["PowerP%sStim" % num] = mne.time_frequency.read_tfrs(import_fname)  # key:value pair to easily identify files loaded
        #Stim_list.append(mne.time_frequency.read_tfrs(import_fname))


# %% Create grand average
# Extract values from dictionaries to a list
Sham_Nestedlist = list(Sham_dict.values())
Stim_Nestedlist = list(Stim_dict.values())

# Transform nested lists into flat lists
Sham_list = []
for elem in Sham_Nestedlist:
    Sham_list.extend(elem)
# print('Flat List : ', Sham_list)

Stim_list = []
for elem in Stim_Nestedlist:
    Stim_list.extend(elem)
#print('Flat List : ', Stim_list)

# Fusion list with both conditions to give the same channels order for all datasets
Sham_list.extend(Stim_list) # first half is Sham_list
print('Lenght of Sham_list extend is', len(Sham_list))
Both_list = Sham_list.copy()
mne.channels.equalize_channels(Both_list, copy=False, verbose=None)# give the same channel order for all datasets
print('Equalizing both_list channels order done')

# Re-do Stim list and Sham list
length = len(Both_list)
middle_index = length//2

Sham_list = Both_list[:middle_index] # first_half
# print(len(Sham_list))
Stim_list = Both_list[middle_index:] # second_half

TFR_GrandAverage_Sham = mne.grand_average(Sham_list)  # Grand Average Sham
TFR_GrandAverage_Stim = mne.grand_average(Stim_list)  # Grand Average Stim

# %% Compare two datasets with subtraction
DifferenceTFR = mne.combine_evoked([TFR_GrandAverage_Stim, TFR_GrandAverage_Sham], weights=[1, -1])

#DifferenceTFR.plot_topo(baseline=None, mode='zscore', title='Difference Stim-Sham power')

#DifferenceTFR.plot(picks='F3')
# fig, axis = plt.subplots(1, 2, figsize=(7, 4))
# DifferenceTFR.plot_topomap(ch_type='eeg', tmin=0.5, tmax=0.7, fmin=8, fmax=12,
#                    baseline=None, mode='logratio', axes=axis[0],
#                    title='Alpha', show=False)
DifferenceTFR.plot_topomap(ch_type='eeg', tmin=0.5, tmax=0.7, fmin=4, fmax=7,
                   baseline=None, mode='zscore', axes=None,
                   title='Theta', show=True)

#mne.viz.tight_layout()
#plt.show()


# %% Non-parametric statistic
# Developping_manual mode
# import_fname = 'D:\Données_Doctorat\Données_Article#2\A2_EEGLAB_MNE\Step3_SecondRun\P10_Stim_BVA epoch detrended.se-tfr.h5'
# test_TFR_data = mne.time_frequency.read_tfrs(import_fname,)
#
#
# Loop to get mean_data of each subjects in both condition and put it in a 1D-array (space)
# Initialize arrays
sham_power = np.zeros((16,58))
stim_power = np.zeros((16,58))
n_observation_sham = 0
n_observation_stim = 0
# Create Sham array
for TFRarray in Sham_list:
    # Get mean data for frequencies and time periods chosen
    data = TFRarray.data
    times = TFRarray.times
    temporal_mask = np.logical_and(0.5 <= times, times <= 0.8) # first 300ms, before arrows appearance
    mean_data = np.mean(data[:, 2:4, temporal_mask], axis=(1,2)) # get 4,5 and 6Hz wavelets in second dimension
    sham_power[n_observation_sham,:]=mean_data
    n_observation_sham +=1

# Create Stim array
for TFRarray in Stim_list:
    # Get mean data for frequencies and time periods chosen
    data = TFRarray.data
    times = TFRarray.times
    temporal_mask = np.logical_and(0.5 <= times, times <= 0.8) # first 300ms, before arrows appearance
    mean_data = np.mean(data[:, 2:4, temporal_mask], axis=(1,2)) # get 4,5 and 6Hz wavelets in second dimension
    stim_power[n_observation_stim,:]=mean_data
    n_observation_stim +=1

# %% Permutation t-test on space data with cluster correction for multiple comparison
# Contrast
Diff_power = stim_power-sham_power
# Left hemispheres
selection = mne.channels.make_1020_channel_selections(DifferenceTFR.info, midline='z')
Left_roi = selection.get('Left')
# p_threshold = 0.001
# n_subjects = 17
# t_threshold = -stats.distributions.t.ppf(p_threshold / 2., n_subjects - 1)
# print('Clustering.')
# threshold = 6.0
threshold_tfce = dict(start=0, step=0.2)
ch_adjacency, ch_names = mne.channels.find_ch_adjacency(DifferenceTFR.info, ch_type='eeg')
ch_adjacency = ch_adjacency[Left_roi][:, Left_roi]
t_obs, clusters, cluster_pv, H0 = permutation_cluster_1samp_test(Diff_power[:,Left_roi], threshold=threshold_tfce, n_permutations=1000, tail=0,
                                  adjacency=ch_adjacency, t_power=1, out_type='mask',verbose=True)

print("Smallest element in cluster_pv is:", min(cluster_pv))
#
# significant_points = cluster_pv.reshape(t_obs.shape).T < .25
# print(str(significant_points.sum()) + " points selected by TFCE ...")
#
#
# # Cluster visualisation
