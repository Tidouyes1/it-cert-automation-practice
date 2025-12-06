%% Exemple complet de cha\u00eene d'acquisition aller-retour
% Ce script MATLAB/Octave construit un signal analogique simple, applique
% une mise en forme anti-repliement à spectre triangulaire, num\u00e9rise, traite
% puis reconstruit le signal avec les filtres correspondants. Toutes les
% \u00e9tapes de la cha\u00eene sont trac\u00e9es pour visualiser l'\u00e9volution du signal.
%
% Ex\u00e9cution : lancer le script tel quel dans MATLAB ou Octave. Les figures
% apparaissent dans l'ordre des \u00e9tapes. Le code utilise uniquement des objets
% math\u00e9matiques simples (sinuso\u00efdes, fen\u00eatre triangulaire, filtres FIR).

clear; close all; clc;

%% Param\u00e8tres g\u00e9n\u00e9raux
fs_analog = 20000;   % Grille dense pour approximer le continu (Hz)
duree = 0.05;        % Dur\u00e9e d'observation (s)
fs_adc = 2000;       % Fr\u00e9quence d'\u00e9chantillonnage de l'ADC (Hz)

% Grille temporelle "analogique" et signal d'entr\u00e9e compos\u00e9 de sinuso\u00efdes
te = 0:1/fs_analog:duree;
signal_entree = 0.7*sin(2*pi*80*te) + 0.25*sin(2*pi*180*te) + 0.15*sin(2*pi*320*te);

%% Filtre anti-repliement \u00e0 spectre triangulaire (fen\u00eatre de Bartlett)
ordre_fir = 61;              % Doit rester impair pour une r\u00e9ponse lin\u00e9aire en phase
fc = 400;                    % Bande passante utile (Hz)
fenetre_tri = bartlett(ordre_fir); % Fen\u00eatre triangulaire
h_anti_alias = fir1(ordre_fir-1, 2*fc/fs_analog, fenetre_tri);

% R\u00e9ponse en fr\u00e9quence du filtre (spectre triangulaire en amplitude)
[H,freq] = freqz(h_anti_alias, 1, 2048, fs_analog);
figure('Name', 'Spectre du filtre anti-repliement');
plot(freq, abs(H), 'LineWidth', 1.5);
grid on; xlabel('Fr\u00e9quence (Hz)'); ylabel('Gain');
title('Amplitude du filtre anti-repliement (fen\u00eatre triangulaire)');

% Signal filtr\u00e9 avant \u00e9chantillonnage (z\u00e9ro-phase pour limiter la distorsion)
signal_filtre = filtfilt(h_anti_alias, 1, signal_entree);

%% \u00c9chantillonnage et quantification (aller)
n_ech = 0:1/fs_adc:duree;
% Interpolation du signal filtr\u00e9 sur les instants d'\u00e9chantillonnage
signal_echantillonne = interp1(te, signal_filtre, n_ech, 'linear');

% Quantificateur uniforme sur 12 bits centr\u00e9s autour de 0
nb_bits = 12;
q_fullscale = 1.0; % pleine \u00e9chelle sym\u00e9trique
pas_q = 2*q_fullscale / (2^nb_bits);
signal_quantifie = pas_q * round(signal_echantillonne / pas_q);

%% Cha\u00eene num\u00e9rique (traitement simple)
gain_num = 1.5;
filtre_moy = ones(1, 3) / 3; % Filtre moyenneur pour lisser le bruit de quantif
signal_numerique = filter(filtre_moy, 1, gain_num * signal_quantifie);

%% Conversion num\u00e9rique-analogique (retour)
% \u00c9tape de maintien d'ordre z\u00e9ro (ZOH) : on reconstruit un signal d'\u00e9chelle
signal_zoh = repelem(signal_numerique, round(fs_analog/fs_adc));

% Recalage temporel pour la grille analogique
tezoh = 0:1/fs_analog:(length(signal_zoh)-1)/fs_analog;

% Filtre de lissage (m\u00eame r\u00e9ponse triangulaire que l'anti-aliasing)
signal_reconstruit = filtfilt(h_anti_alias, 1, signal_zoh);

%% Visualisation temporelle de chaque \u00e9tape
figure('Name', 'Cha\u00eene d''acquisition compl\u00e8te');
subplot(4,2,1); plot(te, signal_entree, 'b'); grid on;
title('Signal analogique d''entr\u00e9e'); xlabel('Temps (s)'); ylabel('Amplitude');

subplot(4,2,2); plot(te, signal_filtre, 'g'); grid on;
title('Apr\u00e8s filtre anti-repliement'); xlabel('Temps (s)');

subplot(4,2,3); stem(n_ech, signal_echantillonne, 'filled'); grid on;
title('\u00c9chantillons ADC (avant quantif)'); xlabel('Temps (s)');

subplot(4,2,4); stem(n_ech, signal_quantifie, 'filled'); grid on;
title('Signal quantifi\u00e9 (12 bits)'); xlabel('Temps (s)');

subplot(4,2,5); stem(n_ech, signal_numerique, 'filled'); grid on;
title('Traitement num\u00e9rique (gain + moyenne)'); xlabel('Temps (s)');

subplot(4,2,6); plot(tezoh, signal_zoh, 'm'); grid on;
title('Sortie DAC (maintien d''ordre z\u00e9ro)'); xlabel('Temps (s)');

subplot(4,2,7); plot(tezoh, signal_reconstruit, 'r'); grid on;
title('Signal reconstruit filtr\u00e9'); xlabel('Temps (s)');

% Comparaison finale
subplot(4,2,8); hold on; plot(te, signal_entree, 'b');
plot(tezoh, signal_reconstruit, 'r--'); grid on;
legend('Entr\u00e9e analogique', 'Sortie analogique reconst.');
title('Comparaison aller-retour'); xlabel('Temps (s)');

%% Spectres (optionnel) : visualisation du contenu fr\u00e9quentiel
figure('Name', 'Spectres des signaux principaux');
Nfft = 4096;

% Fonction utilitaire pour densit\u00e9 spectrale simple
spectre = @(sig) fftshift(abs(fft(sig, Nfft)));
freq_axis = linspace(-fs_analog/2, fs_analog/2, Nfft);

plot(freq_axis, spectre(signal_entree), 'DisplayName', 'Entr\u00e9e analogique'); hold on;
plot(freq_axis, spectre(signal_filtre), 'DisplayName', 'Apr\u00e8s anti-repliement');
plot(freq_axis, spectre(signal_reconstruit), '--', 'DisplayName', 'Sortie reconstruite');

xlim([-600 600]); grid on; legend('Location', 'best');
xlabel('Fr\u00e9quence (Hz)'); ylabel('|FFT| normalis\u00e9e');
title('Spectres (fen\u00eatre triangulaire visible sur le filtre)');

%% Notes
% - Le filtre de Bartlett donne un spectre en "tri" lissant les transitions
%   de bande et rend visible la forme triangulaire sur la r\u00e9ponse en fr\u00e9quence.
% - Toutes les \u00e9tapes utilisent des op\u00e9rations \u00e9l\u00e9mentaires pour visualiser
%   clairement l'effet de chaque bloc de la cha\u00eene d'acquisition.
