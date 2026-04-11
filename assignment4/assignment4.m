% M . EEC045 - CODIFICACAO DE INFORMACAO MULTIMEDIA
%
% second audio assignment
%
% due date : april 12 , 2026
%
% Made by : Guilherme Rodrigues up202208878 & Joao Oliveira up202205302

%% ###################### TASK 1 ####################

clear; clc;

% Parameters
Fs = 22050;          % Sampling frequency 
f0 = 440;            % Fundamental frequency (1/T) 
T = 1/f0;            % Period in seconds
A = 5000;            % Amplitude value 
num_terms = 5;       % First 5 terms of the summation

% Time vector for visualizing one period
t = 0 : 1/Fs : T;

% Initialize the signal vector
x_t = zeros(size(t));

% Implementation of Equation (2.13)
% x(t) = -sum_{k=1}^{5} ( (2*A) / (pi*k) ) * sin( (2*pi/T) * k * t )
for k = 1:num_terms
    harmonic_amplitude = (2 * A) / (pi * k);
    x_t = x_t - harmonic_amplitude * sin((2 * pi / T) * k * t);
end

% Visualization
figure;
plot(t, x_t, 'LineWidth', 1.5);
grid on;
title(['Synthesis of Sawtooth Wave (First ', num2str(num_terms), ' terms)']);
xlabel('Time (s)');
ylabel('Amplitude');
axis([0 T -A*1.2 A*1.2]); % Set axis to show full amplitude clearly

% using 100 terms
num_terms = 100;
Fs  = 100000;

% Reinitialize the signal vector for the new number of terms
t = 0 : 1/Fs : T;
x_t = zeros(size(t));

% Implementation of Equation (2.13)
% x(t) = -sum_{k=1}^{5} ( (2*A) / (pi*k) ) * sin( (2*pi/T) * k * t )
for k = 1:num_terms
    harmonic_amplitude = (2 * A) / (pi * k);
    x_t = x_t - harmonic_amplitude * sin((2 * pi / T) * k * t);
end

% Visualization
figure;
plot(t, x_t, 'LineWidth', 1.5);
grid on;
title(['Synthesis of Sawtooth Wave (First ', num2str(num_terms), ' terms)']);
xlabel('Time (s)');
ylabel('Amplitude');
axis([0 T -A*1.2 A*1.2]); % Set axis to show full amplitude clearly

%% ###################### TASK 2 ####################

function amostras = geranota(nota, duracao, Fs)
    % geranota(nota, duracao, Fs)
    % nota: multiplicative factor relative to LA4 (440Hz)
    % duracao: duration of the note in seconds 
    % Fs: sampling frequency in Hz [cite: 15]

    % 1. Calculate the fundamental period T0 
    T0 = 1.0 / (440.0 * nota); 
    
    % 2. Define the time vector for the specified duration
    t = 0 : 1/Fs : duracao - (1/Fs);
    
    % 3. Synthesize the first 5 terms of the summation (Eq. 2.13)
    % Using A = 5000 as defined in Task 1
    A = 5000;
    amostras = zeros(size(t));
    for k = 1:5
        termo = (2 * A / (pi * k)) * sin(2 * pi * k * t / T0);
        amostras = amostras - termo;
    end
    
    % 4. Normalization to range [-1, 1[
    amostras = amostras / max(abs(amostras));
    
    % 5. Fade-in and Fade-out (1/10 of the total length) 
    L = floor(length(amostras) / 10);
    
    % First quarter of a sine wave period for modulation 
    % Modulation goes from 0 to 1 (fade-in) and 1 to 0 (fade-out)
    t_fade = (0:L-1) / (4*L); 
    envelope_in = sin(2 * pi * t_fade);
    envelope_out = fliplr(envelope_in);
    
    % Apply envelopes to the start and end 
    amostras(1:L) = amostras(1:L) .* envelope_in;
    amostras(end-L+1:end) = amostras(end-L+1:end) .* envelope_out;
end

% Test with a 2-second LA4 note (nota = 1)
Fs = 22050;
sinal = geranota(1, 2.0, Fs);

% Plot to see the fade-in and fade-out
sound ( sinal / max ( abs ( sinal ) ) , Fs ) ;
plot(sinal);
title('Sinal com Fade-in e Fade-out');
xlabel('Amostras'); ylabel('Amplitude');

%% ###################### TASK 3 ####################

% 1. Parameters
Fs = 22050;      % Sampling frequency
dur = 0.3;       % Duration of each note (300 ms) 

% 2. Define Note Ratios (Equally Tempered Scale relative to LA4)
% Ratios are 2^(n/12) where n is the number of semitones from LA4
f_do  = 2^(-9/12);
f_re  = 2^(-7/12);
f_mi  = 2^(-5/12);
f_fa  = 2^(-4/12);
f_sol = 2^(-2/12);

% 3. Define the "Pauta" 
% Sequence: do re mi fa fa fa do re do re re re do sol fa mi mi mi do re mi fa
pauta = [f_do, f_re, f_mi, f_fa, f_fa, f_fa, f_do, f_re, f_do, f_re, f_re, f_re, f_do, f_sol, f_fa, f_mi, f_mi, f_mi, f_do, f_re, f_mi, f_fa];

% 4. Synthesize the Audio
musica_completa = [];

for n = pauta
    % Generate the note using the function from Task 2
    amostra_nota = geranota(n, dur, Fs);
    
    % Concatenate the samples
    musica_completa = [musica_completa, amostra_nota];
end

% 5. Final Normalization and Playback 
% Ensure range is within [-1, 1[
musica_completa = musica_completa / max(abs(musica_completa));

% Listen to the synthesized music
sound(musica_completa, Fs);

% 6. Optional: Save to a WAV file for the report [cite: 36]
audiowrite('resultado_pauta.wav', musica_completa, Fs);

disp('Playback complete. Audio saved as resultado_pauta.wav');

pause(length(musica_completa)/Fs + 1);

%% ###################### TASK 4 ####################

Fs = 22050; 

% Notas da Escala (Rácios relativos a LA4)
do  = 2^(-9/12); 
re  = 2^(-7/12); 
mi  = 2^(-5/12); 
fa  = 2^(-4/12); 
sol = 2^(-2/12);
la  = 1.0;
si  = 2^(2/12);
do2 = 2^(3/12); % Dó uma oitava acima

% Unidades de tempo (em segundos)
C = 0.25; % Colcheia (Curta)
S = 0.50; % Semínima (Normal)
M = 1.00; % Mínima (Longa)

% Pauta: "Pa-ra-bens a vo-ce, nes-ta da-ta que-ri-da"
notas = [sol, sol, la, sol, do2, si, ...
         sol, sol, la, sol, re, do2];
         
duracoes = [C, C, S, S, S, M, ...
            C, C, S, S, S, M];

musica_final = [];

for i = 1:length(notas)
    % A tua função geranota deve estar no mesmo diretório
    amostra = geranota(notas(i), duracoes(i), Fs);
    musica_final = [musica_final, amostra];
end

% Normalizar e tocar
musica_final = musica_final / max(abs(musica_final));
sound(musica_final, Fs);

% Guardar para o relatório
audiowrite('parabens_final.wav', musica_final, Fs);

%% ###################### TASK 5 ####################

Fs = 22050; 

% 1. Carregar o sinal original

[sinal_u2, Fs_orig] = audioread('u2.wav');

% 2. Gerar Espetrograma para Análise (IMAGEM PARA O RELATÓRIO)
figure;
spectrogram(sinal_u2, 1024, 512, 1024, Fs, 'yaxis');
title('Análise de Fourier: Espetrograma de u2.wav');
view(0, 90); % Vista de topo para identificar notas facilmente