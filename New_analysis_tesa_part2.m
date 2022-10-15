
% Author: François Thiffault
% 1st version: March-April 2020 
% 2nd version: May-June 2022
%%%%%%%%%

%% Loading, saving and other parameters

cd 'D:\Données_Doctorat\Données_Article#2\A2_EEGLAB_MNE\Step_1 TESA intermediates files_2022Run';

% Saving folder
% save_path = '/Volumes/Seagate Backup Plus Drive/Données_Doctorat/Données_Article#2/A2_EEGLAB_MNE/Step_1 TESA intermediates files';
save_path = 'D:\Données_Doctorat\Données_Article#2\A2_EEGLAB_MNE\Step_1 TESA intermediates files_2022Run';


%% A) Manual steps - Components selection: TMS related artefacts
% Type of file to save 
a = ' pruned with ICA';

% Load a file
input = 'P20_Stim_IC Calculated.set';
EEG = pop_loadset('filename',input);
EEG = eeg_checkset( EEG );
eeglab redraw;

% Choose components
EEG = pop_tesa_compselect( EEG,'compCheck','on','remove','on','saveWeights',...
'on','figSize','large','plotTimeX',[-1200 1100],'plotFreqX',[1 100],'freqScale',...
'log','tmsMuscle','off','tmsMuscleThresh',8,'tmsMuscleWin',[11 30],'tmsMuscleFeedback',...
'off','blink','off','blinkThresh',2.5,'blinkElecs',{'Fp1','Fp2'},'blinkFeedback',...
'off','move','off','moveThresh',2,'moveElecs',{'F7','F8'},'moveFeedback','off',...
'muscle','off','muscleThresh',-0.31,'muscleFreqIn',[7 70],'muscleFreqEx',[48 52],...
'muscleFeedback','off','elecNoise','off','elecNoiseThresh',4,'elecNoiseFeedback','off' );


% Save corrected data 
EEG = eeg_checkset( EEG );
subj_id = regexp(input,'P\d*_S\w*m','match');
EEG.setname = char(strcat(subj_id,a));
EEG = pop_saveset( EEG, 'filename', EEG.setname, 'filepath', save_path);
eeglab redraw;

%% B) Transformation loop

%cd 'D:\Données_Doctorat\Données_Article#2\A2_EEGLAB_MNE\Step_1 TESA intermediates files_2022Run';
cd '/Volumes/Seagate Backup Plus Drive/Données_Doctorat/Données_Article#2/A2_EEGLAB_MNE/Step_1 TESA intermediates files_2022Run';

% load_path = 'D:\Données_Doctorat\Données_Article#2\A2_EEGLAB_MNE\Step_0 EEGLABSetFiles';
load_path = '/Volumes/Seagate Backup Plus Drive/Données_Doctorat/Données_Article#2/A2_EEGLAB_MNE/Step_0 EEGLABSetFiles';

% save_path_BVA = 'D:\Données_Doctorat\Données_Article#2\A2_EEGLAB_MNE\Step_2 EEGLAB_TESA to BVA';
save_path_BVA = '/Volumes/Seagate Backup Plus Drive/Données_Doctorat/Données_Article#2/A2_EEGLAB_MNE/Step_2 EEGLAB_TESA to BVA';

save_path_MNE = '/Volumes/Seagate Backup Plus Drive/Données_Doctorat/Données_Article#2/A2_EEGLAB_MNE/Step_2 EEGLAB_TESA to MNE';

% Form an array with filename to iterate on it
listing = dir;
num = size(listing,1);

% Marker to keep for MNE-python epochs
ev = {'TMS(1)','TMS(10)','TMS(11)','TMS(14)','TMS(15)','TMS(2)',...
    'TMS(4)','TMS(5)','TMS(7)','TMS(8)'};

% test mode
% input = 'P01_Sham pruned with ICA.set';

% Type of file to load
a = ' pruned with ICA.set';
% Naming generated files
b = '_BVA.set'; % Types of dataset countaining all channels for interpolation
c = '_Interpolated'; % Second files generated ; pulses removes and ICA calculated
% d = '_ 2nd ICA calculated';

for i = 1:num
    if contains(listing(i).name,a)
        input = listing(i).name;
        EEG = pop_loadset('filename',input);
        [ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 1 );
        EEG = eeg_checkset( EEG );
        eeglab redraw;

        % Interpolate signal around pulses location
        EEG = pop_tesa_interpdata( EEG, 'cubic', [20 20] );

        
      % Load a reference dataset to interpolate bad channels
        subj_id = regexp(input,'P\d*_S\w*m','match');
        input_interpol = char(strcat(subj_id, b));  
        EEG = pop_loadset('filename',input_interpol,  'filepath', load_path);
        [ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 2 );
        eeglab redraw;

        % Interpolate bad channels
        [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 2,'retrieve',1,'study',0);
        eeglab redraw;
        EEG = pop_interp(EEG, ALLEEG(2).chanlocs, 'spherical');
        EEG.setname=char(strcat(subj_id,' Interpolated'));
        EEG = eeg_checkset( EEG );
        eeglab redraw;
        
        % Select and rename first StimTracker marker
            for x = 1:size(EEG.event,2)
                if strcmp((EEG.event(x).type),'Sync(16)')
                    if strcmp((EEG.event(x-2).type),'TMS5') % found index of TMS event
                     % save the type of event betweenn TMS and sync(16) event
                        last_ev = sscanf(EEG.event(x-1).type,'Sync(%d)'); % create an new type for the first sync(16) based on the E-Prime event
                        new_ev = last_ev + 16;
                        new_ev = int2str(new_ev);
                        EEG.event(x).type = new_ev;
                    end
                end
            end
        
        % Save those steps
        % Save interpolated data 
        file_name = EEG.setname;
        EEG = pop_saveset( EEG, 'filename', file_name, 'filepath', save_path_BVA);
        eeglab redraw;


        % Create datasets for time-frequency analysis

        
        % Remove interpolate value before second ICA
        EEG = pop_tesa_removedata( EEG, [-10 25], [], {'TMS'});
        EEG = pop_tesa_removedata( EEG, [-10 25], [], {'TMS5'});
        EEG.setname = char(strcat(subj_id,' TMSremoved'));
        EEG = eeg_checkset( EEG );
        eeglab redraw;


        % Keep Only one Marker per trial (for MNE-Python compatibility)
        % a)Give unique identity to last pulse marker  based on following
        % E-Prime marker
            for x = 1:size(EEG.event,2)
                if strcmp((EEG.event(x).type),'TMS5') % found index of TMS event
                   last_ev = sscanf(EEG.event(x+1).type,'Sync(%d)'); % create an new type for the last TMS pulses based on the E-Prime event
                   new_ev = int2str(last_ev);
                   new_ev = strcat('TMS(',new_ev,')');
                   EEG.event(x).type = new_ev;
                end
            end
        EEG.setname=char(strcat(subj_id,'_Marker Adjusted'));
        EEG = eeg_checkset( EEG );
        % b)Supress all other marker in trials WARNING: EventDestroyer is
        % an homade fonction base on pop_xxx. Input is all the marker that
        % you want to keep. All others are eliminate.
        EEG = event_destroyer(EEG,ev);


        % Calculer les composantes indépendantes une deuxième fois
        EEG = pop_tesa_fastica( EEG, 'approach', 'symm', 'g', 'gauss', 'stabilization', 'on' );
        EEG.setname=char(strcat(subj_id,'_ 2nd ICA calculated'));
        EEG = eeg_checkset( EEG );
        eeglab redraw;

        % Save detrended and marker ajusted data 
        file_name = EEG.setname;
        EEG = pop_saveset( EEG, 'filename', file_name, 'filepath', save_path_MNE);
        eeglab redraw;
     end
end
 %% C) Manual steps - Components selection: Blink
% % a = ' Blink_removed with ICA';
% % 
% % % Load a file
% % input = 'P20_Stim_IC Calculated.set';
% % EEG = pop_loadset('filename',input);
% % EEG = eeg_checkset( EEG );
% % eeglab redraw;
% % 
% % % Choose components
% % EEG = pop_tesa_compselect( EEG,'compCheck','on','remove','on','saveWeights',...
% % 'on','figSize','large','plotTimeX',[-1200 1100],'plotFreqX',[1 100],'freqScale',...
% % 'log','tmsMuscle','off','tmsMuscleThresh',8,'tmsMuscleWin',[11 30],'tmsMuscleFeedback',...
% % 'off','blink','off','blinkThresh',2.5,'blinkElecs',{'Fp1','Fp2'},'blinkFeedback',...
% % 'off','move','off','moveThresh',2,'moveElecs',{'F7','F8'},'moveFeedback','off',...
% % 'muscle','off','muscleThresh',-0.31,'muscleFreqIn',[7 70],'muscleFreqEx',[48 52],...
% % 'muscleFeedback','off','elecNoise','off','elecNoiseThresh',4,'elecNoiseFeedback','off' );
% % 
        % Detrending for time-frequency analysis
        % Detrend baseline period
        EEG = pop_tesa_detrend( EEG, 'linear', [-1400,-875]);
        % Detrend post burst period
        EEG = pop_tesa_detrend( EEG, 'linear', [100,1725]);
% % 
% % % Save corrected data 
% % EEG = eeg_checkset( EEG );
% % subj_id = regexp(input,'P\d*_S\w*m','match');
% % EEG.setname = char(strcat(subj_id,a));
% % EEG = pop_saveset( EEG, 'filename', EEG.setname, 'filepath', save_path);
% % eeglab redraw;

        