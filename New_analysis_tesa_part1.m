

% Author: François Thiffault
% 1st version: March-April 2020 
% 2nd version: May-June 2022
%%%%%%%%%

%% Loading, saving and other parameters

cd 'D:\Données_Doctorat\Données_Article#2\A2_EEGLAB_MNE\Step_0 EEGLABSetFiles';

% Saving folder
% save_path = '/Volumes/Seagate Backup Plus Drive/Données_Doctorat/Données_Article#2/A2_EEGLAB_MNE/Step_1 TESA intermediates files';
save_path = 'D:\Données_Doctorat\Données_Article#2\A2_EEGLAB_MNE\Step_1 TESA intermediates files_2022Run';

% Bad channel to deactivate before running ICA
% Note: 
% - They are interpolate in part 2
% - Reusing Python dictionnaries in Matlab 
Bad_chanDict = py.dict(pyargs('P01_Sham', 'None', 'P01_Stim', {'F1', 'PO8'}, 'P03_Sham', 'None', 'P03_Stim', 'F3', 'P04_Sham', {'AF4','C3'},...,
                 'P04_Stim', 'None', 'P05_Sham', 'F3', 'P05_Stim', 'None', 'P06_Sham', 'TP8', 'P06_Stim', 'None',...
                 'P07_Sham', 'None', 'P07_Stim', {'F3', 'CP4'}, 'P08_Sham', 'P6', 'P08_Stim', {'AF8', 'C4'},...
                 'P09_Sham', 'Fp1', 'P09_Stim', {'F4', 'AF8'}, 'P10_Sham', {'Fp1', 'AF8', 'P6', 'PO3'},...
                 'P10_Stim', {'Fp1', 'P6'}, 'P12_Sham', {'Fp1', 'P6'}, 'P12_Stim', {'C4', 'AF8'},...
                 'P13_Sham', {'Fp1', 'P6', 'CP4'}, 'P13_Stim', {'Fp1', 'FC5'}, 'P14_Sham', {'Fp1', 'C4', 'AF8'},...
                 'P14_Stim', {'C4', 'FC3'}, 'P15_Sham', 'None', 'P15_Stim', {'Fp1', 'P6'}, 'P16_Sham', 'Fp1',...
                 'P16_Stim', 'None', 'P17_Sham', 'None', 'P17_Stim', {'Fp2', 'C4', 'FC1', 'P1'}, 'P19_Sham', 'Fp1',...
                 'P19_Stim', 'None', 'P20_Sham', 'None', 'P20_Stim', {'Fp1', 'FC4', 'FC1'}));

% Relevant E-prime event markers
ev = {'Sync(1)','Sync(10)','Sync(11)','Sync(14)','Sync(15)','Sync(2)',...
     'Sync(4)','Sync(5)','Sync(7)','Sync(8)', 'Sync(16)'};


% Form an array with filename to iterate on it
listing = dir;
num = size(listing,1);
%test mode
% num = 8;

% manual mode
input = 'P17_Stim_BVA.set';

% Type of file to load
a = 'BVA.set';
% Naming generated files
b = '_segmented'; % First files generated ; segmented files
c = '_IC Calculated'; % Second files generated ; pulses removes and ICA calculated

%% Transformation loop
for i = 1:num
    if contains(listing(i).name,a)
        input = listing(i).name;
        EEG = pop_loadset('filename',input);
        EEG = eeg_checkset( EEG );
        eeglab redraw;

        
        %% Part 1: Find pulses timestamp
        % Remove bad channels
        subj_id = regexp(input,'P\d*_S\w*m','match'); % extract dataset name core (subject number)
        Bad_chan = Bad_chanDict{string(subj_id)};
        if isa(Bad_chan,'py.tuple')
            mat_Bad_chan = cellstr(string(cell(Bad_chan)));
            EEG = pop_select( EEG, 'nochannel',mat_Bad_chan);
        elseif string(Bad_chan) ~= 'None'
            mat_Bad_chan = cellstr(string(Bad_chan));
            EEG = pop_select( EEG, 'nochannel',mat_Bad_chan);
        else
            mat_Bad_chan = cellstr(string(Bad_chan));
        end
        EEG = eeg_checkset( EEG );
        eeglab redraw;

        % Find pulse artefacts
        % loop to verify if F3 channel is present 
        if any(contains(mat_Bad_chan, 'F3'))
        EEG = pop_tesa_findpulse( EEG, 'F1', 'refract', 190, 'rate', 250, 'tmsLabel','TMS', 'plots', 'off');
        EEG = eeg_checkset( EEG );
        eeglab redraw;
        else
        EEG = pop_tesa_findpulse( EEG, 'F3', 'refract', 190, 'rate', 250, 'tmsLabel','TMS', 'plots', 'off');
        EEG = eeg_checkset( EEG );
        eeglab redraw;    
        end
        

        % Segment data countaining Trials, TMS burst and baseline
        EEG = pop_epoch( EEG, {  'Sync(1)'  'Sync(10)'  'Sync(11)'  'Sync(2)'  ...
        'Sync(4)'  'Sync(5)' 'Sync(14)'  'Sync(15)' 'Sync(7)'  'Sync(8)'  }, [-2.5 1.1]);
        EEG = eeg_checkset( EEG );
        eeglab redraw
        
        % Rename last TMS event marker as with 'TMS5'
        % Note : This step could had been done automaitcally with
        % pop_tesa_findpulse if the sampling rate was 3 kHz and above
        for x = 1:size(EEG.event,2)
            if any(ismember(ev,char((EEG.event(x).type)))) % found the index of the trial E-Prime event
                if x > 1
                    if strcmp((EEG.event(x-1).type),'TMS') % verify there is no 'Sync(16)' event marker before E-Prime event (shouldn't)
                       EEG.event(x-1).type = 'TMS5';
                    end
                end
            end
        end
        EEG = eeg_checkset( EEG );
        eeglab redraw
        
        % Save the first part and continue
        file_name = char(strcat(subj_id, b));
        EEG = pop_saveset( EEG, 'filename', file_name, 'filepath', ...
            save_path);

        %% Part 2: Remove TMS pulse and Calculate ICA inverse Matrix
        % Re-center segment around last TMS pulse
        EEG = pop_epoch( EEG, {  'TMS5'  }, [-1.4        1.75]);
        EEG = eeg_checkset( EEG );
        eeglab redraw

        % Demean
        EEG = pop_rmbase( EEG, [-1399 1749] ,[]);
        EEG = eeg_checkset( EEG );
        eeglab redraw
        
        %Remove TMS pulse TMS
%       Note: you can remove less if you are interested in TEP
        EEG = pop_tesa_removedata( EEG, [-10 25], [], {'TMS'});
        EEG = pop_tesa_removedata( EEG, [-10 25], [], {'TMS5'});
        EEG.setname = char(strcat(subj_id,' TMSremoved'));
        EEG = eeg_checkset( EEG );
        eeglab redraw;
%         
%         % Run an ICA to isolate component related to decay artefacts
        EEG = pop_tesa_fastica( EEG, 'approach', 'symm', 'g', 'gauss', 'stabilization', 'on' );
        EEG.setname=char(strcat(subj_id,' IC Calculated'));
        EEG = eeg_checkset( EEG );
        eeglab redraw;
        
        % Save data and ICA matrix with a new name
        subj_id = regexp(input,'P\d*_S\w*m','match');
        file_name =char(strcat(subj_id, c));
        EEG = pop_saveset( EEG, 'filename', file_name, 'filepath', save_path);
    end
end
