% M . EEC045 - CODIFICACAO DE INFORMACAO MULTIMEDIA
%
% second audio assignment
%
% due date : may 24 , 2026
%
% Made by : Guilherme Rodrigues up202208878 & Joao Oliveira up202205302

%% Pergunta 2 - Quantizacao de audio no dominio das frequencias
% UC: Codificacao de Informacao Multimedia

clear; close all; clc;

% Parametros principais
inpfile = 'sound.wav';
outdir = 'resultados_DFT';
if ~exist(outdir, 'dir')
    mkdir(outdir);
end

N = 1024;
N2 = N/2;
win = sin(pi/N*((0:N-1)' + 0.5));   % equivalente a h[n]=sin(pi/N*(0.5+n))
alvos_snr = [5 10 15 20];           % dB
variantes = {'global', 'colorido'};

% Intervalo inicial de procura de SMR. Pode ser alargado se necessario.
SMR_MIN = -20;
SMR_MAX = 80;
NITER = 18;                         % iteracoes da bisseccao
frame_figura = 25;                  % trama usada para os graficos ilustrativos

%% Leitura do sinal
[x, FS] = audioread(inpfile);
if size(x,2) > 1
    warning('O ficheiro tem mais do que um canal. Vai ser usado apenas o canal esquerdo.');
    x = x(:,1);
end
x = x(:);

fprintf('Ficheiro: %s\n', inpfile);
fprintf('Frequencia de amostragem: %d Hz\n', FS);
fprintf('Duracao: %.3f s\n\n', length(x)/FS);

%% Confirmacao da reconstrucao sem quantizacao
[y0, ~] = processa_DFT_quantizacao(x, FS, N, N2, win, 'none', 100, frame_figura);
snr0 = calcula_snr(x, y0);
fprintf('SNR sem quantizacao, apenas analise/sintese: %.2f dB\n\n', snr0);

%% Calibracao automatica de SMR para cada SNR alvo e variante
resultados = struct([]);
idx = 1;

for iv = 1:numel(variantes)
    variante = variantes{iv};

    for ia = 1:numel(alvos_snr)
        snr_alvo = alvos_snr(ia);

        [melhor_SMR, melhor_SNR, y] = procura_SMR_para_SNR( ...
            x, FS, N, N2, win, variante, snr_alvo, SMR_MIN, SMR_MAX, NITER);

        nomewav = sprintf('DFT_%s_SNRalvo_%02ddB_SMR_%+.2fdB.wav', ...
            variante, snr_alvo, melhor_SMR);
        audiowrite(fullfile(outdir, nomewav), y, FS);

        resultados(idx).Transformada = "DFT";
        resultados(idx).Variante = string(variante);
        resultados(idx).SNR_alvo_dB = snr_alvo;
        resultados(idx).SMR_usado_dB = melhor_SMR;
        resultados(idx).SNR_obtido_dB = melhor_SNR;
        resultados(idx).Ficheiro_WAV = string(nomewav);

        fprintf('%8s | SNR alvo = %2d dB | SMR = %+7.3f dB | SNR obtido = %7.3f dB\n', ...
            variante, snr_alvo, melhor_SMR, melhor_SNR);

        % Figuras pedidas no enunciado: exemplos para SNR ~5 dB e ~20 dB
        if snr_alvo == 5 || snr_alvo == 20
            [~, dados_fig] = processa_DFT_quantizacao(x, FS, N, N2, win, ...
                variante, melhor_SMR, frame_figura);

            nomefig = sprintf('espetros_DFT_%s_SNRalvo_%02ddB.png', variante, snr_alvo);
            plota_espetros_sinal_ruido(dados_fig, FS, N, variante, snr_alvo, melhor_SNR, ...
                fullfile(outdir, nomefig));
        end

        idx = idx + 1;
    end
end

T = struct2table(resultados);
disp(T);

writetable(T, fullfile(outdir, 'tabela_resultados_DFT.csv'), 'Delimiter',';');

fprintf('\nProcessamento terminado. Resultados guardados em: %s\n', outdir);
fprintf('Nota: a avaliacao subjetiva ITU-R deve ser preenchida apos escuta comparativa.\n');

%% ========================================================================
%% Funcoes locais
%% ========================================================================

function [melhor_SMR, melhor_SNR, melhor_y] = procura_SMR_para_SNR( ...
    x, FS, N, N2, win, variante, snr_alvo, smr_min, smr_max, niter)

    % Aumentar SMR reduz o erro de quantizacao e tende a aumentar a SNR final.
    lo = smr_min;
    hi = smr_max;

    melhor_SMR = NaN;
    melhor_SNR = -Inf;
    melhor_y = [];

    for it = 1:niter
        mid = (lo + hi)/2;

        [y, ~] = processa_DFT_quantizacao(x, FS, N, N2, win, variante, mid, 1);
        snr_mid = calcula_snr(x, y);

        if abs(snr_mid - snr_alvo) < abs(melhor_SNR - snr_alvo)
            melhor_SMR = mid;
            melhor_SNR = snr_mid;
            melhor_y = y;
        end

        if snr_mid < snr_alvo
            % Quantizacao demasiado grosseira: aumentar SMR.
            lo = mid;
        else
            % Quantizacao demasiado fina: diminuir SMR.
            hi = mid;
        end
    end

    % Recalcular no melhor ponto encontrado.
    [melhor_y, ~] = processa_DFT_quantizacao(x, FS, N, N2, win, variante, melhor_SMR, 1);
    melhor_SNR = calcula_snr(x, melhor_y);
end

function [y, dados_fig] = processa_DFT_quantizacao(x, FS, N, N2, win, variante, SMR_dB, frame_figura)
    %#ok<INUSD>
    N2 = N/2;

    % Padding de N/2 amostras no inicio e no fim para evitar erro artificial
    % nas extremidades durante overlap-add com janela seno.
    xpad = [zeros(N2,1); x(:); zeros(N2,1)];

    nframes = floor((length(xpad)-N)/N2) + 1;
    ypad = zeros(size(xpad));

    dados_fig = struct();
    guardou_fig = false;

    for frame = 1:nframes
        ini = 1 + (frame-1)*N2;
        idx = ini:ini+N-1;

        segmento = xpad(idx);
        xw = segmento .* win;

        X = fft(xw);
        X_original = X;

        if strcmpi(variante, 'none')
            Xq = X;
        else
            Xq = quantiza_espetro_DFT(X, variante, SMR_dB);
        end

        % Garantir simetria hermitiana, necessaria para obter sinal real apos IFFT.
        Xq(1) = real(Xq(1));
        Xq(N2+1) = real(Xq(N2+1));
        Xq(N:-1:N2+2) = conj(Xq(2:N2));

        yw = real(ifft(Xq));
        yw = yw .* win;

        ypad(idx) = ypad(idx) + yw;

        if frame == frame_figura && ~guardou_fig
            dados_fig.X_original = X_original;
            dados_fig.X_quantizado = Xq;
            dados_fig.E = Xq - X_original;
            dados_fig.frame = frame;
            guardou_fig = true;
        end
    end

    y = ypad(N2+1:N2+length(x));

    % Evitar clipping ao gravar WAV, sem alterar se estiver dentro da gama.
    maxabs = max(abs(y));
    if maxabs > 1
        y = y / maxabs * 0.999;
        warning('Sinal normalizado para evitar clipping.');
    end
end

function Xq = quantiza_espetro_DFT(X, variante, SMR_dB)
    N = length(X);
    N2 = N/2;
    SMR = 10^(SMR_dB/10);

    Xq = zeros(size(X));

    switch lower(variante)
        case 'global'
            % Passo unico para todos os coeficientes.
            % Pela aproximacao de quantizacao uniforme:
            % variancia por dimensao real = Delta^2/12.
            P = sum(abs(X).^2);
            Pn = P / SMR;
            Delta = sqrt(6 * Pn / N);

            Xq(1) = quantiza_uniforme_real(real(X(1)), Delta);
            Xq(N2+1) = quantiza_uniforme_real(real(X(N2+1)), Delta);

            k = 2:N2;
            Xq(k) = quantiza_uniforme_real(real(X(k)), Delta) + ...
                    1i*quantiza_uniforme_real(imag(X(k)), Delta);

        case 'colorido'
            % Passo individual: ruido aproximadamente proporcional a potencia
            % local de cada coeficiente espectral, dando SMR uniforme.
            mag2 = abs(X(1:N2+1)).^2;

            Delta = zeros(N2+1,1);
            Delta(1) = sqrt(12 * mag2(1) / SMR);
            Delta(N2+1) = sqrt(12 * mag2(N2+1) / SMR);

            k = 2:N2;
            Delta(k) = sqrt(6 * mag2(k) / SMR);

            % Para evitar divisao por zero em bins exatamente nulos.
            Delta(Delta < eps) = eps;

            Xq(1) = quantiza_uniforme_real(real(X(1)), Delta(1));
            Xq(N2+1) = quantiza_uniforme_real(real(X(N2+1)), Delta(N2+1));

            Xq(k) = quantiza_uniforme_real(real(X(k)), Delta(k)) + ...
                    1i*quantiza_uniforme_real(imag(X(k)), Delta(k));

        otherwise
            error('Variante desconhecida: %s', variante);
    end
end

function y = quantiza_uniforme_real(x, Delta)
    % Quantizador uniforme mid-tread: Q(x)=Delta*round(x/Delta).
    y = Delta .* round(x ./ Delta);
end

function snr_dB = calcula_snr(x, y)
    x = x(:);
    y = y(:);
    L = min(length(x), length(y));
    x = x(1:L);
    y = y(1:L);

    erro = x - y;
    snr_dB = 10*log10(sum(x.^2) / max(sum(erro.^2), eps));
end

function plota_espetros_sinal_ruido(dados_fig, FS, N, variante, snr_alvo, snr_obtido, nomeficheiro)
    N2 = N/2;
    reg = 1:N2+1;
    f = FS/N*(reg-1);

    X = dados_fig.X_original;
    E = dados_fig.E;

    figure('Color','w');
    plot(f, 20*log10(abs(X(reg)) + eps), 'LineWidth', 1.0);
    hold on;
    plot(f, 20*log10(abs(E(reg)) + eps), 'LineWidth', 1.0);
    grid on;
    xlabel('Frequencia (Hz)');
    ylabel('Modulo espectral (dB)');
    title(sprintf('DFT - %s - SNR alvo %d dB, SNR obtido %.2f dB', ...
        variante, snr_alvo, snr_obtido), 'Interpreter', 'none');
    legend('Sinal original', 'Ruido de quantizacao', 'Location', 'best');

    exportgraphics(gcf, nomeficheiro, 'Resolution', 200);
end
