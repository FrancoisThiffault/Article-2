% EEGLAB history file generated on the 16-Mar-2020
% ------------------------------------------------

%Modification de François Thiffault, Février 2022

% This script coulb be used to load, transform and save a group of EEELAB
% .set files.
 
%%%%%%%%%

%% Changer de répertoire actuel (current folder) pour aller dans celui dans
% lequel se trouve les fichier set.
%1. Entrer le nom de votre dossier après cd
cd '/Volumes/Seagate Backup Plus Drive/Données_Doctorat/Données_Article#2/A2_EEGLAB_MNE/Step_2 EEGLAB_TESA to BVA';

% ev = {'Sync(1)','Sync(10)','Sync(11)','Sync(14)','Sync(15)','Sync(2)',...
%     'Sync(4)','Sync(5)','Sync(7)','Sync(8)', 'Sync(16)'};

% ev = {'TMS(1)','TMS(10)','TMS(11)','TMS(14)','TMS(15)','TMS(2)',...
%     'TMS(4)','TMS(5)','TMS(7)','TMS(8)'};

%trig = 'Sync(16)';

% Form an array to iterate on it
listing = dir;
num = size(listing,1);
% manual mode
% input = 'P01_Sham Interpolated.set';
a = 'Interpolated.set'; % Type of file to load
% b = 'Interpolated'; % Point of the filename from which we want to rename
% c = 'events corrected'; % New name for the dataset
save_path = '/Volumes/Seagate Backup Plus Drive/Données_Doctorat/BVA_EEG/Raw/A2_withTESA_2022/';
%% Transformation loop
for i = 1:num
    if contains(listing(i).name,a)
        input = listing(i).name;
        EEG = pop_loadset('filename',input);

        % Export data set in BVA format
        original_name = regexp(input,'P\d*_S\w*m','match');
        file_path = char(strcat(save_path,original_name));
        pop_writebva(EEG,file_path);

        % Arrange channel names capitalization
%         EEG=pop_chanedit(EEG, 'changefield',{1,'labels','Fp1'}, ...
%             'changefield',{2,'labels','Fp2'});
        
        % Keep Only one Marker per trial (for MNE-Python compatibility)
        % EEG = event_destroyer(EEG,ev);

        % Rename first strimtracker marker
        % EEG = Rename_stimtracker_marker(EEG,trig);

        % Cut the epochs
%         EEG = pop_epoch( EEG, {'Sync(1)' 'Sync(10)' 'Sync(11)' 'Sync(14)'  ...
%             'Sync(15)' 'Sync(2)' 'Sync(4)' 'Sync(5)' 'Sync(7)' 'Sync(8)'}, ...
%             [-0.7         0.8], 'epochinfo', 'yes');

        % Detrending
%         EEG = pop_tesa_detrend( EEG, 'linear', [-700,750]);

        % Save modification with a new name
        % original_name = regexp(input,'P\d*_S\w*m','match');
        % set_name =char(strcat(original_name, c));
        % EEG = pop_saveset( EEG, 'filename', set_name, 'filepath', ...
        % save_path);
        % EEG = pop_saveset( EEG, 'savemode','resave');
    end
end

