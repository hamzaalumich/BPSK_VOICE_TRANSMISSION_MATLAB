%ECE-550 Project
% Digital Voice Transmission System Using BPSK
% Improved final version for clear BER + time/frequency plots + saved audio

clear; clc; close all;

%% =====================================================
% STEP 1 — ANALOG VOICE SIGNAL INPUT
%% =====================================================

[fileM, pathM] = uigetfile({'*.wav;*.m4a;*.mp3'}, 'Select MESSAGE audio');
[m0, Fs0] = audioread(fullfile(pathM,fileM));

if size(m0,2) > 1
    m0 = mean(m0,2);
end

m0 = m0(:);

Tsec = 5;
m0 = m0(1:min(length(m0), round(Tsec*Fs0)));

m0 = m0 - mean(m0);
m0 = m0 ./ (max(abs(m0)) + 1e-12);

t0 = (0:length(m0)-1)'/Fs0;

figure('Name','1 - Original Analog Voice');
plot(t0,m0); grid on;
title('Original Analog Voice Signal');
xlabel('Time (s)'); ylabel('Amplitude');

plot_fft_local(m0, Fs0, '1b - Original Analog Voice Frequency Domain', [-Fs0/2 Fs0/2]);

%% =====================================================
% STEP 2 — ADC: IDEAL SAMPLING
%% =====================================================

Fs = 8000;   % 8 kHz satisfies Nyquist for speech around 4 kHz

m_ideal = resample(m0, Fs, Fs0);
m_ideal = m_ideal - mean(m_ideal);
m_ideal = m_ideal ./ (max(abs(m_ideal)) + 1e-12);

t = (0:length(m_ideal)-1)'/Fs;

figure('Name','2 - Ideal Sampled Voice');
plot(t,m_ideal); grid on;
title('Ideal Sampled Voice Signal');
xlabel('Time (s)'); ylabel('Amplitude');

plot_fft_local(m_ideal, Fs, '2b - Ideal Sampled Voice Frequency Domain', [-4000 4000]);

%% =====================================================
% STEP 3 — ADC: NON-IDEAL SAMPLING
%% =====================================================

jitter_amp = 0.10/Fs;
t_jitter = t + jitter_amp*randn(size(t));

m_nonideal = interp1(t0,m0,t_jitter,'linear','extrap');
m_nonideal = m_nonideal - mean(m_nonideal);
m_nonideal = m_nonideal ./ (max(abs(m_nonideal)) + 1e-12);

figure('Name','3 - Ideal vs Non-Ideal Sampling');
plot(t,m_ideal,'b'); hold on;
plot(t,m_nonideal,'r');
grid on;
legend('Ideal Sampling','Non-Ideal Sampling');
title('Ideal vs Non-Ideal Sampling');
xlabel('Time (s)'); ylabel('Amplitude');

plot_fft_local(m_nonideal, Fs, '3b - Non-Ideal Sampled Voice Frequency Domain', [-4000 4000]);

%% =====================================================
% STEP 4 — QUANTIZATION / ADC
%% =====================================================

nbits = 8;
L = 2^nbits;

m_index = round((m_ideal + 1)/2 * (L-1));
m_index = max(0,min(L-1,m_index));

m_quantized = 2*(m_index/(L-1)) - 1;

figure('Name','4 - ADC Quantization');
plot(t,m_ideal,'b'); hold on;
plot(t,m_quantized,'r');
grid on;
legend('Sampled Voice','Quantized Voice');
title('ADC Quantization');
xlabel('Time (s)'); ylabel('Amplitude');

plot_fft_local(m_quantized, Fs, '4c - Quantized Voice Frequency Domain', [-4000 4000]);

% Zoomed quantization view
idxQ = max(1,round(0.5*Fs)) : min(length(t), round(0.505*Fs));
figure('Name','4b - ADC Quantization Zoomed');
plot(t(idxQ),m_ideal(idxQ),'b','LineWidth',1.2); hold on;
stairs(t(idxQ),m_quantized(idxQ),'r','LineWidth',1.5);
grid on;
legend('Sampled Voice','Quantized Voice');
title('ADC Quantization Effect - Zoomed View');
xlabel('Time (s)'); ylabel('Amplitude');

%% =====================================================
% STEP 5 — BIT STREAM GENERATION
%% =====================================================

bit_matrix = dec2bin(m_index, nbits) - '0';
bits = bit_matrix.';
bits = bits(:);

Nbits = length(bits);

disp(['Total transmitted bits = ', num2str(Nbits)]);

% Communication parameters
sps = 8;
Rb = Fs * nbits;
Fs_tx = Rb * sps;
fc = Rb;

%% =====================================================
% STEP 6 — LINE CODING: POLAR NRZ
% 0 -> -1
% 1 -> +1
%% =====================================================

tx_symbols = 2*bits - 1;

figure('Name','5 - Polar NRZ Line Coding');
stairs(tx_symbols(1:120),'LineWidth',1.5);
grid on;
title('Polar NRZ Line Coding');
xlabel('Bit Index'); ylabel('Amplitude');

plot_fft_local(tx_symbols, Rb, '5b - Polar NRZ Frequency Domain', [-Rb/2 Rb/2]);

%% =====================================================
% STEP 7 — PULSE SHAPING
%% =====================================================

tx_baseband = repelem(tx_symbols,sps);

figure('Name','6 - Pulse-Shaped Baseband Signal');
plot(tx_baseband(1:1000)); grid on;
title('Pulse-Shaped Baseband Signal');
xlabel('Sample Index'); ylabel('Amplitude');

plot_fft_local(tx_baseband, Fs_tx, '6b - Pulse-Shaped Baseband Frequency Domain', [-2*Rb 2*Rb]);

%% =====================================================
% STEP 8 — BPSK MODULATION
%% =====================================================

tt = (0:length(tx_baseband)-1)'/Fs_tx;
carrier = cos(2*pi*fc*tt);

tx_bpsk = tx_baseband .* carrier;

figure('Name','7 - Carrier Signal');
plot(tt(1:1000),carrier(1:1000));
grid on;
title('Carrier Signal');
xlabel('Time (s)'); ylabel('Amplitude');

plot_fft_local(carrier, Fs_tx, '7b - Carrier Signal Frequency Domain', [-2*fc 2*fc]);

figure('Name','8 - BPSK Signal Time Domain');
plot(tt(1:1000),tx_bpsk(1:1000));
grid on;
title('BPSK Modulated Signal - Time Domain');
xlabel('Time (s)'); ylabel('Amplitude');

plot_fft_local(tx_bpsk, Fs_tx, '9 - BPSK Signal Frequency Domain', [-2*fc 2*fc]);

%% =====================================================
% STEP 9 — CHANNEL MODEL
% Channel:
% r[k] = s[k] + echo*s[k-1] + AWGN
%
% Includes:
% multipath, delay, ISI, AWGN noise
%% =====================================================

echo = 0.65;       % stronger ISI so BER before EQ is visible
SNRdB = 9;         % moderate noise for visible BER

h = [1 echo];

rx_clean = filter(h,1,tx_symbols);

sigPow = mean(rx_clean.^2);
noisePow = sigPow/(10^(SNRdB/10));
rng(10);
channel_noise = sqrt(noisePow)*randn(size(rx_clean));

rx_noisy = rx_clean + channel_noise;

figure('Name','10 - Channel Impulse Response');
stem(0:length(h)-1,h,'filled');
grid on;
title('Channel Impulse Response h[k]');
xlabel('Delay in Symbols'); ylabel('Amplitude');

plot_fft_local(h, Rb, '10b - Channel Frequency Response', [-Rb/2 Rb/2]);

figure('Name','11 - Channel Effect on Symbols');
plot(tx_symbols(1:250),'b','LineWidth',1.2); hold on;
plot(rx_noisy(1:250),'r','LineWidth',1.2);
grid on;
legend('Transmitted Symbols','Received Symbols with ISI + Noise');
title('Transmitted vs Received Symbols');
xlabel('Symbol Index'); ylabel('Amplitude');

plot_fft_local(rx_noisy, Rb, '11b - Received Symbols Frequency Domain', [-Rb/2 Rb/2]);

rx_baseband = repelem(rx_noisy,sps);
rx_bpsk = rx_baseband .* carrier;

figure('Name','12 - Received BPSK Signal After Channel');
plot(tt(1:1000),rx_bpsk(1:1000));
grid on;
title('Received BPSK Signal After Channel');
xlabel('Time (s)'); ylabel('Amplitude');

plot_fft_local(rx_bpsk, Fs_tx, '12b - Received BPSK Signal Frequency Domain', [-2*fc 2*fc]);

%% =====================================================
% STEP 10 — RECEIVER BEFORE EQUALIZATION
%% =====================================================

bits_before = rx_noisy > 0;
bits_before = bits_before(:);

BER_before = sum(bits_before ~= bits) / length(bits);

m_before_eq = bits_to_audio_local(bits_before, nbits, L);

figure('Name','13 - Voice Before Equalization');
plot(m_before_eq); grid on;
title('Voice Recovered Before Equalization');
xlabel('Sample Index'); ylabel('Amplitude');

plot_fft_local(m_before_eq, Fs, '13b - Voice Before Equalization Frequency Domain', [-4000 4000]);

%% =====================================================
% STEP 11 — ZERO-FORCING / DECISION-FEEDBACK EQUALIZER
% For channel:
% r[k] = s[k] + echo*s[k-1] + noise
%
% Equalizer:
% s_hat[k] = r[k] - echo*previous_decision
%% =====================================================

rx_eq = zeros(size(rx_noisy));
decided = zeros(size(rx_noisy));

for k = 1:length(rx_noisy)

    if k == 1
        rx_eq(k) = rx_noisy(k);
    else
        rx_eq(k) = rx_noisy(k) - echo*decided(k-1);
    end

    decided(k) = 2*(rx_eq(k) >= 0) - 1;
end

bits_after = decided > 0;
bits_after = bits_after(:);

BER_after = sum(bits_after ~= bits) / length(bits);

figure('Name','14 - Before vs After Equalization');
plot(rx_noisy(1:250),'r','LineWidth',1.2); hold on;
plot(rx_eq(1:250),'b','LineWidth',1.2);
grid on;
legend('Before Equalization','After Equalization');
title('Received Samples Before and After Equalization');
xlabel('Symbol Index'); ylabel('Amplitude');

plot_fft_local(rx_noisy, Rb, '14b - Before Equalization Frequency Domain', [-Rb/2 Rb/2]);
plot_fft_local(rx_eq, Rb, '14c - After Equalization Frequency Domain', [-Rb/2 Rb/2]);

%% =====================================================
% STEP 12 — SIGNAL RECOVERY AFTER EQUALIZATION
%% =====================================================

m_recovered = bits_to_audio_local(bits_after, nbits, L);

Lplot = min([length(m_ideal), length(m_before_eq), length(m_recovered)]);

figure('Name','15 - Voice Comparison');
plot(t(1:Lplot),m_ideal(1:Lplot),'k','LineWidth',1.2); hold on;
plot(t(1:Lplot),m_before_eq(1:Lplot),'r');
plot(t(1:Lplot),m_recovered(1:Lplot),'b');
grid on;
legend('Original','Before EQ','After EQ');
title('Original vs Before EQ vs Recovered After EQ');
xlabel('Time (s)'); ylabel('Amplitude');

plot_fft_local(m_recovered, Fs, '15b - Recovered Voice Frequency Domain', [-4000 4000]);

%% =====================================================
% STEP 13 — CLEAR NOISY AUDIO DEMO
% This is only for audio demonstration.
%% =====================================================

demo_noise_strength = 0.25;

m_noisy_demo = m_ideal + demo_noise_strength*randn(size(m_ideal));
m_noisy_demo = m_noisy_demo - mean(m_noisy_demo);
m_noisy_demo = m_noisy_demo ./ (max(abs(m_noisy_demo)) + 1e-12);

figure('Name','16 - Clear Noisy Voice Demo');
plot(t,m_ideal,'b'); hold on;
plot(t,m_noisy_demo,'r');
grid on;
legend('Original Voice','Noisy Voice Demo');
title('Clear Audible Noisy Voice Demo');
xlabel('Time (s)'); ylabel('Amplitude');

plot_fft_local(m_noisy_demo, Fs, '16b - Clear Noisy Voice Demo Frequency Domain', [-4000 4000]);

%% =====================================================
% STEP 14 — BER COMPARISON
%% =====================================================

num_errors_before = sum(bits_before ~= bits);
num_errors_after  = sum(bits_after ~= bits);

BER_before = num_errors_before / length(bits);
BER_after  = num_errors_after / length(bits);

ber_real = [BER_before BER_after];
BER_floor = 1/length(bits);
ber_plot = max(ber_real, BER_floor);

figure('Name','17 - BER Before vs After Equalization');
bar(ber_plot);
grid on;
set(gca,'XTickLabel',{'Before EQ','After EQ'});
ylabel('Bit Error Rate');
title('BER Comparison Before and After Equalization');
ylim([0 max(ber_plot)*1.6]);

text(1, ber_plot(1), sprintf('BER = %.3g\nErrors = %d', BER_before, num_errors_before), ...
    'HorizontalAlignment','center', ...
    'VerticalAlignment','bottom');

text(2, ber_plot(2), sprintf('BER = %.3g\nErrors = %d', BER_after, num_errors_after), ...
    'HorizontalAlignment','center', ...
    'VerticalAlignment','bottom');

fprintf('\n================ BER RESULTS ================\n');
fprintf('Bit Errors Before Equalization = %d\n',num_errors_before);
fprintf('Bit Errors After Equalization  = %d\n',num_errors_after);
fprintf('BER Before Equalization        = %.8f\n',BER_before);
fprintf('BER After Equalization         = %.8f\n',BER_after);
fprintf('BER Improvement                = %.2f %%\n', ...
    100*(BER_before-BER_after)/(BER_before+1e-12));
fprintf('=============================================\n');

%% =====================================================
% STEP 15 — BER VERSUS SNR
%% =====================================================

SNR_range = 0:2:24;

BER_before_vec = zeros(size(SNR_range));
BER_after_vec  = zeros(size(SNR_range));

rx_clean_temp = filter(h,1,tx_symbols);
sigPowTemp = mean(rx_clean_temp.^2);

for i = 1:length(SNR_range)

    noisePowTemp = sigPowTemp/(10^(SNR_range(i)/10));

    rng(i);
    noiseTemp = sqrt(noisePowTemp)*randn(size(rx_clean_temp));

    rx_temp = rx_clean_temp + noiseTemp;

    bits_b = rx_temp > 0;
    BER_before_vec(i) = mean(bits_b ~= bits);

    rx_eq_temp = zeros(size(rx_temp));
    decided_temp = zeros(size(rx_temp));

    for k = 1:length(rx_temp)

        if k == 1
            rx_eq_temp(k) = rx_temp(k);
        else
            rx_eq_temp(k) = rx_temp(k) - echo*decided_temp(k-1);
        end

        decided_temp(k) = 2*(rx_eq_temp(k) >= 0) - 1;
    end

    bits_a = decided_temp > 0;
    BER_after_vec(i) = mean(bits_a ~= bits);
end

BER_theory = 0.5*erfc(sqrt(10.^(SNR_range/10)));

BER_before_plot = max(BER_before_vec, BER_floor);
BER_after_plot  = max(BER_after_vec, BER_floor);
BER_theory_plot = max(BER_theory, BER_floor);

figure('Name','18 - BER vs SNR');
semilogy(SNR_range,BER_before_plot,'o-','LineWidth',1.5); hold on;
semilogy(SNR_range,BER_after_plot,'s-','LineWidth',1.5);
semilogy(SNR_range,BER_theory_plot,'k--','LineWidth',1.5);
grid on;
legend('Before Equalization','After Equalization','Theoretical BPSK AWGN','Location','southwest');
title('BER vs SNR');
xlabel('SNR (dB)');
ylabel('Bit Error Rate');
ylim([BER_floor 1]);

disp(' ');
disp('========= BER vs SNR TABLE =========');
disp(table(SNR_range.', BER_before_vec.', BER_after_vec.', BER_theory.', ...
    'VariableNames', {'SNR_dB','BER_Before_EQ','BER_After_EQ','BER_Theory'}));

%% =====================================================
% STEP 16 — PROJECT CALCULATIONS
%% =====================================================

speech_BW = 4000;
nyquist_rate = 2*speech_BW;
quantization_levels = 2^nbits;
delta_q = 2/(quantization_levels - 1);
num_samples = length(m_ideal);
total_bits = num_samples * nbits;
bit_rate = Fs * nbits;
measured_SNR_dB = 10*log10(mean(rx_clean.^2)/mean(channel_noise.^2));

disp(' ');
disp('================ PROJECT CALCULATIONS ================');
disp(['Assumed Speech Bandwidth        = ', num2str(speech_BW), ' Hz']);
disp(['Nyquist Rate                    = ', num2str(nyquist_rate), ' Hz']);
disp(['Chosen Sampling Frequency Fs    = ', num2str(Fs), ' Hz']);
disp(['Quantization Bits               = ', num2str(nbits)]);
disp(['Quantization Levels             = ', num2str(quantization_levels)]);
disp(['Quantization Step Size          = ', num2str(delta_q)]);
disp(['Number of Voice Samples         = ', num2str(num_samples)]);
disp(['Total Transmitted Bits          = ', num2str(total_bits)]);
disp(['Bit Rate                        = ', num2str(bit_rate), ' bits/sec']);
disp(['Samples per Symbol              = ', num2str(sps)]);
disp(['Transmit Sampling Frequency     = ', num2str(Fs_tx), ' Hz']);
disp(['Carrier Frequency               = ', num2str(fc), ' Hz']);
disp(['Channel Signal Power            = ', num2str(mean(rx_clean.^2))]);
disp(['Channel Noise Power             = ', num2str(mean(channel_noise.^2))]);
disp(['Measured Channel SNR            = ', num2str(measured_SNR_dB), ' dB']);
disp('======================================================');

%% =====================================================
% STEP 17 — SAVE AUDIO FILES
%% =====================================================

audiowrite('01_original_voice.wav',m_ideal,Fs);
audiowrite('02_quantized_voice.wav',m_quantized,Fs);
audiowrite('03_nonideal_sampled_voice.wav',m_nonideal,Fs);
audiowrite('04_clear_noisy_voice_demo.wav',m_noisy_demo,Fs);
audiowrite('05_voice_before_equalization.wav',m_before_eq,Fs);
audiowrite('06_recovered_voice_after_equalization.wav',m_recovered,Fs);

disp(' ');
disp('Saved audio files:');
disp('01_original_voice.wav');
disp('02_quantized_voice.wav');
disp('03_nonideal_sampled_voice.wav');
disp('04_clear_noisy_voice_demo.wav');
disp('05_voice_before_equalization.wav');
disp('06_recovered_voice_after_equalization.wav');

drawnow;

%% =====================================================
% STEP 18 — OPTIONAL PLAYBACK MENU
%% =====================================================

while true

    disp(' ');
    disp('========== AUDIO PLAYBACK MENU ==========');
    disp('1 - Play original voice');
    disp('2 - Play quantized voice');
    disp('3 - Play non-ideal sampled voice');
    disp('4 - Play clear noisy voice demo');
    disp('5 - Play voice before equalization');
    disp('6 - Play recovered voice after equalization');
    disp('0 - Exit');
    disp('=========================================');

    choice = input('Enter your choice: ');

    if choice == 1
        soundsc(m_ideal,Fs);

    elseif choice == 2
        soundsc(m_quantized,Fs);

    elseif choice == 3
        soundsc(m_nonideal,Fs);

    elseif choice == 4
        soundsc(m_noisy_demo,Fs);

    elseif choice == 5
        soundsc(m_before_eq,Fs);

    elseif choice == 6
        soundsc(m_recovered,Fs);

    elseif choice == 0
        disp('Exited playback menu.');
        break;

    else
        disp('Invalid choice.');
    end
end

%% =====================================================
% FINAL SUMMARY
%% =====================================================

disp(' ');
disp('================ FINAL SUMMARY ================');
disp(['Sampling Frequency Fs        = ',num2str(Fs),' Hz']);
disp(['Transmit Sampling Fs_tx      = ',num2str(Fs_tx),' Hz']);
disp(['Carrier Frequency fc         = ',num2str(fc),' Hz']);
disp(['Quantization Bits            = ',num2str(nbits)]);
disp(['Channel h                    = [',num2str(h),']']);
disp(['SNR                          = ',num2str(SNRdB),' dB']);
disp(['BER Before Equalization      = ',num2str(BER_before)]);
disp(['BER After Equalization       = ',num2str(BER_after)]);
disp('DONE.');
disp('================================================');

%% =====================================================
% LOCAL FUNCTION — BITS TO AUDIO
%% =====================================================

function audio_out = bits_to_audio_local(bits_in, nbits, L)

    bits_in = bits_in(:);

    numFullBytes = floor(length(bits_in)/nbits);
    bits_in = bits_in(1:numFullBytes*nbits);

    bits_matrix = reshape(bits_in,nbits,numFullBytes).';

    weights = 2.^(nbits-1:-1:0);
    index_values = bits_matrix * weights.';

    audio_out = 2*(double(index_values)/(L-1)) - 1;
    audio_out = audio_out - mean(audio_out);
    audio_out = audio_out ./ (max(abs(audio_out)) + 1e-12);
end

%% =====================================================
% LOCAL FUNCTION — FREQUENCY-DOMAIN FFT PLOT
%% =====================================================

function plot_fft_local(x, Fs, figName, xLimits)

    x = x(:);
    N = length(x);

    X = fftshift(fft(x));
    f = (-N/2:N/2-1)'*(Fs/N);

    figure('Name',figName);
    plot(f, abs(X)/N, 'LineWidth', 1.2);
    grid on;
    title(figName);
    xlabel('Frequency (Hz)');
    ylabel('|X(f)|');

    if nargin == 4
        xlim(xLimits);
    end
end