#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Wed Feb  2 16:49:45 2022

@author: francoisthiffault
"""

# %% Package Importation
import os
import re

import mne
from mne.time_frequency import tfr_morlet

import numpy as np
import json
# import pandas as pd
# import seaborn as sns
# import matplotlib.pyplot as plt


Stat_dict ={}
# PART 1: Calculate TFR for each participant datasets
# %% Data Importation
data_folder = '/Volumes/Seagate Backup Plus Drive/Données_Doctorat/Données_Article#2/A2_EEGLAB_MNE/Step_2 EEGLAB_TESA to MNE_2022ICARun'
# To use pipeline without a loop
files = 'P03_Stim Blink_removed with ICA.set'


# Make a loop to iterate over epochs got after TESA pipeline
end_of_file = 'Blink_removed with ICA.set'
for files in os.listdir(data_folder):
    if files.endswith(end_of_file):
        input_fname = os.path.join(data_folder, files)
        # print(files)
        epochs_TESA = mne.read_epochs_eeglab(input_fname, events=None, event_id=None, eog=(), verbose=None,
                                            uint16_codec=None)
        epochs_TMS = epochs_TESA['TMS(14)', 'TMS(15)']  # Select epoch with TMS only
        if bool(epochs_TMS.ch_names.count('HEOGL')):
            #epochs_TMS.set_channel_types({'HEOGR': 'eog', 'HEOGL': 'eog', 'VEOGR': 'eog'})  # set types of some channels
            epochs_TMS.drop_channels(['HEOGR', 'HEOGL', 'VEOGR' ])
        else:
            #epochs_TMS.set_channel_types({'HEOGR': 'eog', 'VEOGR': 'eog'})
            epochs_TMS.drop_channels(['HEOGR', 'VEOGR'])
        subjects = files[0:8]
        initial = epochs_TMS.__len__()

        # If verification needed
        # epochs_TMS.plot_sensors(ch_type='eeg', show_names=True, title='Before loading montage')
        lowpass_freq = 40  # (Note: Baseline epochs are too short for bandstop filter)
        # epochs_TMS.filter(l_freq=None, h_freq=lowpass_freq)
        #epochs_TMS.plot(n_epochs=2)
        #epochs_TMS.average().plot( ylim = dict(eeg=[-20, 20]))
        # print(raw.annotations)

        # %% Preprocessing on continuous data
        # Drop unused channel before re-referencing to the average in the context of Time-Frequency analysis
        if bool(epochs_TMS.ch_names.count('MasR')):
            epochs_TMS.drop_channels(['MasR'])
        # Load idealized montage for Topoplot
        epochs_TMS.set_montage('standard_1020')
        # epochs_TMS.plot_sensors(ch_type='eeg', show_names=True, title='After loading montage') # Sanity Topoplot
        # Re-reference to the average
        epochs_TMS.set_eeg_reference(ref_channels='average')
        # If verification needed
        # epochs_TMS.average().plot(scalings=dict(eeg=100e-6), n_epochs=5)


        # %% Save epochs events_dict
        events = epochs_TMS.events
        event_dict = epochs_TMS.event_id
        epochs_info = epochs_TMS.info
        del epochs_TESA

        # %% Create two sub-epoch, entrainment and baseline period
        # Remove reject tmin and tmax criteria before croping
        epochs_TMS.reject_tmin = None
        epochs_TMS.reject_tmax = None
        epoch_baseline = epochs_TMS.copy().crop(tmin=-1.4, tmax=-0.9)
        # epoch_baseline = epochs_TMS.copy().crop(tmin=-1.4, tmax=-0.7) # +200 ms to include artefacts
        epoch_entrain = epochs_TMS.copy().crop(tmin=0.1, tmax=1)
        # epoch_entrain = epochs_TMS.copy().crop(tmin=-0.1, tmax=0.9) # +100 ms to include artefacts
        # Export epochs as numpy array
        np_baseline = epoch_baseline.get_data(picks="all")
        np_entrain = epoch_entrain.get_data(picks="all")
        # Info to put back the marker later if needed
        # numTrials = np.ma.size(np_entrain, axis=0)
        # dataset_length = numTrials*(4900+5000)
        # Mirrors_Epochs_events = np.column_stack((np.arange(0, dataset_length, (4900+5000)), np.zeros(numTrials, dtype=int),
        #                                          events[:, 2]))
        del epochs_TMS
        del epoch_entrain
        del epoch_baseline

        # %% Create epochs mirror images and concatenate them
        # baseline mirror image
        np_base_mirror1 = np.flip(np_baseline[:, :, :500], axis=2)  # mirror image before epoch
        np_base_mirror2 = np.flip(np_baseline[:, :, -500:], axis=2)  # mirror image after epoch
        # np_base_mirror1 = np.flip(np_baseline[:, :, :700], axis=2)
        # np_base_mirror2 = np.flip(np_baseline[:, :, -700:], axis=2)
        # entrainment mirror image
        np_entrain_mirror1 = np.flip(np_entrain[:, :, :900], axis=2) # mirror image of 550 ms before burst (baseline)
        np_entrain_mirror2 = np.flip(np_entrain[:, :, -900:], axis=2) # mirror image of the last 1100
        # np_entrain_mirror1 = np.flip(np_entrain[:, :, :1000], axis=2)
        # np_entrain_mirror2 = np.flip(np_entrain[:, :, -1000:], axis=2)
        # Concatenate mirror images and epochs
        # Baseline safety margin: 1650 ms before and after segment of interest
        np_baseline_WithMirrors = np.concatenate((np_base_mirror1, np_baseline, np_base_mirror1, np_baseline,
                                                  np_base_mirror2, np_baseline,np_base_mirror2), axis=2)
        # Entrainment safety margin: 1800 ms before and after segment of interest
        np_entrain_WithMirrors = np.concatenate((np_entrain, np_entrain_mirror1, np_entrain, np_entrain_mirror2,
                                                 np_entrain), axis=2)
        np_FusionedToClean = np.concatenate((np_baseline_WithMirrors, np_entrain_WithMirrors ), axis=2)
        del np_base_mirror1
        del np_base_mirror2
        del np_entrain_mirror1
        del np_entrain_mirror2
        del np_baseline
        del np_entrain

        # Recreate epochs from numpy arrays
        # Entrain_WithMirrors = mne.EpochsArray(np_entrain_WithMirrors, epochs_info, events=None, event_id=None)
        # Baseline_WithMirrors = mne.EpochsArray(np_baseline_WithMirrors, epochs_info, events=None, event_id=None)
        FusionedToClean = mne.EpochsArray(np_FusionedToClean, epochs_info, events=None,
                                           event_id=None)
        del np_entrain_WithMirrors
        del np_baseline_WithMirrors

        # # Original
        # epoch_entrain[0:2].plot(scalings=dict(eeg=100e-6), n_epochs=5, title='Entrain_noMirrors')
        # Extended with mirror images
        # Entrain_WithMirrors[0:2].plot(scalings=dict(eeg=100e-6), n_epochs=5, title='Entrain_WithMirrors')
        # Original
        # epoch_baseline[0:10].plot(scalings=dict(eeg=100e-6), n_epochs=5, title='Baseline_noMirrors')
        # Extended with mirror images
        # Baseline_WithMirrors[0:10].plot(scalings=dict(eeg=100e-6), n_epochs=5, title='Baseline_WithMirrors')
        # %% Compare original, crops and extended epochs with mirror images if needed
        # FusionedToClean.plot(scalings=dict(eeg=100e-6), events=Mirrors_Epochs_events, n_epochs=2, event_id=event_dict,
                             # title='FusionedToClean')
        # FusionedbaselineCrop = FusionedToClean.copy().crop(tmin=1.5, tmax=2)
        # FusionedentrainmentCrop = FusionedToClean.copy().crop(tmin=5.3, tmax=6.2)
        # FusionedentrainmentCrop.plot(scalings=dict(eeg=100e-6), n_epochs=2)


        # %% Filters
        lowpass_freq = 40 # (Note: Baseline epochs are too short for bandstop filter)
        highpass_freq = 1 #
        FusionedToClean.filter(l_freq=highpass_freq, h_freq=lowpass_freq)

        # rejected trials with artefacts during baseline period
        FusionedToClean.reject_tmin = 1.5
        FusionedToClean.reject_tmax = 2.0
        FusionedToClean.drop_bad(reject=dict(eeg=160e-6))
        # rejected trials with artefacts during entrainment period
        FusionedToClean.reject_tmin = 5.3
        FusionedToClean.reject_tmax = 6.2
        FusionedToClean.drop_bad(reject=dict(eeg=160e-6))
        # drop_stat = epochs_Mirrors.drop_log_stats
        remains = FusionedToClean.__len__()
        Stat_dict.update({subjects: [initial, remains]})
        print(subjects + ' has ' + str(remains) + ' TMS only trials')
        if remains >= 40:

            # %% Power spectrum
            # epochs_clean.plot_psd(fmin=2., fmax=40., average=True, spatial_colors=False)
            # epochs_clean.plot_psd_topomap(ch_type='eeg', normalize=False)

            # %% Morlet wavelet
            # freqs_log = np.logspace(*np.log10([2, 30]), num=12)
            freqs_lin = np.arange(2, 30, 1)
            # n_cycles = freqs / 2.  # different number of cycle per frequency
            n_cycles = 5
            power_fusioned = tfr_morlet(FusionedToClean.average(), freqs=freqs_lin, n_cycles=n_cycles,
                                        use_fft=True, return_itc=False, decim=3, n_jobs=1)
                                        # Use average method to obtain evoked activity

            # Separate baseline and entrainment periods and Remove mirror images
            # power_fusioned.plot_topo(baseline=None, mode='zscore', title='power_fusioned')
            power_baselineCrop = power_fusioned.copy().crop(tmin=1.5, tmax=2)
            power_entrainmentCrop = power_fusioned.copy().crop(tmin=5.3, tmax=6.2)
            del power_fusioned

            # Calculate Power spectrum density
            # kwargs = dict(fmin=2, fmax=40, n_jobs=1)
            # psds_welch_mean, freqs_mean = psd_welch(epochs, average='mean', **kwargs)

            # Concatenate

            Morlet_power = np.concatenate((power_baselineCrop.data, power_entrainmentCrop.data), axis=2)
            del power_baselineCrop

            # Enter numpy array in a TFR container
            # Morlet_info = mne.create_info(power_entrainmentCrop.info.ch_names, power_entrainmentCrop.info['sfreq'],
                                          # ch_types='eeg', verbose=None)
            Morlet_times = np.arange(0, 1.406, 0.003)
            Morlet_average = mne.time_frequency.AverageTFR(FusionedToClean.info, Morlet_power, Morlet_times,
                                                           power_entrainmentCrop.freqs, remains, comment=None,
                                                           method=None, verbose=None)

            # Morlet_average.apply_baseline((0, 0.5), mode='logratio', verbose=None)
            del power_entrainmentCrop
            del FusionedToClean

            # Plot Morlet TFR
            # Morlet_average.plot_topo(baseline=(0, 0.5), mode='zscore', title=subjects)
            # Morlet_average.plot([5], baseline=(0, 550), mode='zlogratio', title=Morlet_average.ch_names[5])
            #
            # fig, axis = plt.subplots(1, 2, figsize=(7, 4))
            # powertrials.plot_topomap(ch_type='eeg', tmin=None, tmax=None, fmin=8, fmax=12,
            #                    baseline=None, mode='logratio',
            #                    title='Alpha', show=True)
            # powertrials.plot_topomap(ch_type='eeg', tmin=None, tmax=None, fmin=13, fmax=25,
            #                    baseline=None, mode='logratio', axes=axis[1],
            #                    title='Beta', show=False)
            #
            # mne.viz.tight_layout()
            # plt.show()

            # %% Saving epochs calculated
            # Take the subject number and the stimulation condition name
            idx = re.search(r"P\d+_S\w+m",files)
            export_name = idx.group()+'_TMS-tfr_NoBaseline.h5' # Concatenate to the end of the filename -tfr.h5
            # export_folder = 'D:\Données_Doctorat\Données_Article#2\A2_EEGLAB_MNE\Step_3 TFR files TMS only'
            export_folder = '/Volumes/Seagate Backup Plus Drive/Données_Doctorat/Données_Article#2/A2_EEGLAB_MNE/Step_3 TFR files TMS only_2022ICARun_NoBaseline'
            export_fname = os.path.join(export_folder, export_name)
            mne.time_frequency.write_tfrs(export_fname, Morlet_average, overwrite=True)
        else:
            print(subjects+' did not have at least 40 good TMS only trials')
            print(subjects + ' has ' + str(remains) + ' TMS only trials')



f = open("Stat_dict.txt", "w")
f.write( str(Stat_dict) )
f.close()

# f = open("Stat_dict.txt", "r")
# print(f.read())

