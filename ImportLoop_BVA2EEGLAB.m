% EEGLAB history file generated on the 16-Mar-2020
% ------------------------------------------------

%Modification de François Thiffault, mars 2020

% Au lieu d'importer un à un les fichiers EEG brute, le script 
% effectue une boucle pour importer tous les fichiers à extension .mat. Une
% fois le fichier importer, il l'enregistre en format EEGlab (.set).
 
%%%%%%%%%

%% Changer de répertoire actuel (current folder) pour aller dans celui dans
% lequel se trouve les fichier mat.
%1. Entrer le nom de votre dossier après cd
cd 'D:\Données_Doctorat\Données_Article#2\A2_EEGLAB_MNE\temporaire';

% test/manual mode
%input = 'P07_Stim_Edit_Channels.mat';

% Former une série (array) avec le nom des fichiers mat à transformer
listing = dir;
num = size(listing,1);
% num = 12;
a = '.mat'; % adjust depending what type of file you want to import
b = '_BVA';
%% Boucle pour importer tous les fichier avec extension .mat du répertoire
for i = 1:num
    if contains(listing(i).name,a)
        input = listing(i).name;
        EEG = pop_loadbva(input); % for BVA matlab files
        %EEG = pop_biosig(input);
        subj_id = regexp(input,'P\d*_S\w*m','match');
        output = char(strcat(subj_id,b));
        [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'setname',output,'savenew',output,'overwrite','on','gui','off'); 
        eeglab redraw; 
    end
end

