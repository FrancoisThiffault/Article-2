# Article vWM-TMS-Theta

This repersitory countains two scripts. 

One is about using TMS-EEG signal analyzer and EEGLab MATLAB toolboxes to correct TMS artifacts in EEG signal. The EEG dataset was collected during an change-detection experiment for measuring visual working memory capacity. Contains in files:
- ImportLoop_BVA2EEGLAB (importing BrainVision Analyzer 2 files into EEGLAB and save them in .set files format)
- New_analysis_tesa_part1
- New_analysis_tesa_part2
A script was written to try different methods during development. The script is called: Genaral_purpose_TESA_loop.


The second script was made to extract time-frequency activities in EEG signal after TMS burst. It is written using python package MNE.
It is divided in two files. 
- TF_FromTESA_TMS_Only_2022ICA: Extraction of Time-Frequency activities for averaged segments of trials with TMS burst only.
