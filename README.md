# BPSK Voice Transmission System in MATLAB

An end-to-end digital communication system for transmitting and recovering a voice signal using Binary Phase Shift Keying (BPSK), Additive White Gaussian Noise (AWGN), intersymbol interference (ISI), coherent demodulation, zero-forcing equalization, and Bit Error Rate (BER) analysis.

---

## Overview

This project implements a complete digital voice-transmission system in MATLAB.

A real voice recording is sampled and quantized into digital data. The generated bitstream is encoded using polar NRZ line coding, pulse-shaped, modulated using BPSK, and transmitted through a simulated channel containing AWGN and ISI.

At the receiver, coherent demodulation and zero-forcing equalization are applied to recover the transmitted bits and reconstruct the voice signal.

The system is evaluated using:

- BER before and after equalization
- BER versus SNR analysis
- Comparison with theoretical BPSK performance
- Ideal versus non-ideal sampling
- Time-domain and frequency-domain analysis
- Original and recovered voice comparison

---

## Key Results

| Performance Metric | Before Equalization | After Equalization |
|---|---:|---:|
| Bit Error Rate | 0.0918 | 0.0204 |
| Error Percentage | 9.18% | 2.04% |
| Relative BER Reduction | — | 77.8% |

The zero-forcing equalizer reduced the BER from **0.0918 to 0.0204**, corresponding to an improvement of approximately **77.8%**.

This demonstrates that ISI was a major source of detection errors and that equalization significantly improved system reliability.

---

## System Workflow

```text
Voice Input
    ↓
Sampling at 8 kHz
    ↓
8-bit Quantization
    ↓
Binary Encoding
    ↓
Polar NRZ Line Coding
    ↓
Rectangular Pulse Shaping
    ↓
BPSK Modulation
    ↓
AWGN and ISI Channel
    ↓
Coherent Demodulation
    ↓
Symbol Sampling
    ↓
Zero-Forcing Equalization
    ↓
Bit Detection
    ↓
Voice Reconstruction
```

---

## Main Features

- Real voice-signal processing
- 8 kHz sampling
- Ideal and non-ideal sampling comparison
- Sampling-jitter simulation
- 8-bit uniform quantization
- Binary data conversion
- Polar NRZ line coding
- Rectangular pulse shaping
- BPSK modulation
- AWGN channel modeling
- Two-tap ISI channel modeling
- Coherent demodulation
- Recursive zero-forcing equalization
- Hard-decision bit detection
- Voice reconstruction
- BER before and after equalization
- BER-versus-SNR simulation
- Theoretical BPSK BER comparison
- FFT-based spectral analysis

---

## Transmitter

### Sampling

The voice signal is sampled at:

```text
Fs = 8000 Hz
```

The selected sampling frequency follows the Nyquist criterion:

```math
F_s \geq 2B
```

where:

- \(F_s\) is the sampling frequency
- \(B\) is the signal bandwidth

The project also compares ideal sampling with non-ideal sampling affected by timing jitter.

### Quantization

The sampled signal is quantized using an 8-bit uniform quantizer:

```math
L = 2^8 = 256
```

where \(L\) is the number of available quantization levels.

Quantization converts the continuous signal amplitudes into discrete numerical values suitable for binary transmission.

### Polar NRZ Encoding

The binary data is mapped into polar NRZ symbols:

```text
Bit 0 → -1
Bit 1 → +1
```

### Pulse Shaping

Each symbol is repeated over a fixed number of samples to create a rectangular pulse-shaped baseband waveform.

Rectangular pulse shaping provides a simple implementation, but its abrupt transitions result in wider spectral sidelobes than raised-cosine pulse shaping.

### BPSK Modulation

The transmitted BPSK signal is:

```math
s(t)=m(t)\cos(2\pi f_c t)
```

where:

- \(m(t)\) is the polar baseband signal
- \(f_c\) is the carrier frequency
- \(s(t)\) is the modulated BPSK signal

A positive symbol produces a 0-degree carrier phase, while a negative symbol produces a 180-degree phase reversal.

---

## Channel Model

The communication channel introduces AWGN and ISI:

```math
r[k]=s[k]+\alpha s[k-1]+n[k]
```

where:

- \(s[k]\) is the current transmitted symbol
- \(\alpha s[k-1]\) is the delayed ISI component
- \(\alpha\) is the ISI coefficient
- \(n[k]\) is Additive White Gaussian Noise
- \(r[k]\) is the received signal

The delayed symbol component causes overlap between neighboring symbols and increases the probability of incorrect detection.

The channel can be represented by a two-tap impulse response:

```math
h[k]=[1,\alpha]
```

---

## Receiver and Equalization

### Coherent Demodulation

The received waveform is multiplied by a synchronized carrier to shift the signal back to baseband:

```math
z(t)=r(t)\cos(2\pi f_c t)
```

The resulting signal is filtered and sampled at the expected symbol locations.

### Zero-Forcing Equalizer

A recursive zero-forcing equalizer is applied:

```math
\hat{s}[k]=r[k]-\alpha\hat{s}[k-1]
```

The equalizer estimates and subtracts the interference caused by the previous symbol.

This reduces deterministic ISI and moves the recovered symbols closer to the ideal BPSK levels of \(-1\) and \(+1\).

Zero-forcing equalization does not remove additive noise and may amplify some noise components.

### Bit Detection

The equalized symbols are converted back into binary data using:

```math
\hat{b}[k]=
\begin{cases}
1, & \hat{s}[k] > 0 \\
0, & \hat{s}[k] \leq 0
\end{cases}
```

The detected bits are then grouped into 8-bit samples and converted back into voice amplitudes.

---

## BER Analysis

Bit Error Rate is calculated as:

```math
\mathrm{BER}
=
\frac{\text{Number of bit errors}}
{\text{Total transmitted bits}}
```

The measured results were:

```text
BER before equalization = 0.0918
BER after equalization  = 0.0204
```

The relative BER reduction is:

```math
\mathrm{Improvement}
=
\frac{
\mathrm{BER}_{before}
-
\mathrm{BER}_{after}
}{
\mathrm{BER}_{before}
}
\times 100
```

The calculated improvement is approximately:

```text
77.8%
```

---

## BER Versus SNR

The project evaluates BER over multiple SNR values for:

- The system before equalization
- The system after equalization
- The theoretical BPSK AWGN reference

The theoretical BER for coherent BPSK is:

```math
\mathrm{BER}_{theory}
=
\frac{1}{2}
\mathrm{erfc}
\left(
\sqrt{\frac{E_b}{N_0}}
\right)
```

The simulated BER is higher than the theoretical curve because the implemented system includes:

- Intersymbol interference
- Quantization effects
- Sampling imperfections
- Channel memory
- AWGN

The BER results show that:

- BER decreases as SNR increases
- Equalization improves performance
- The equalized system outperforms the non-equalized system
- The theoretical curve represents an ideal AWGN-only reference

---

## Repository Files

```text
BPSK_VOICE_TRANSMISSION_MATLAB/
├── README.md
├── LICENSE
├── bpsk_voice_transmission.m
├── BPSK_Voice_Transmission_Report.pdf
└── audio_signal.m4a
```

### `bpsk_voice_transmission.m`

Main MATLAB script containing:

- Voice preprocessing
- Sampling and jitter simulation
- Quantization
- Binary encoding
- Polar NRZ mapping
- Pulse shaping
- BPSK modulation
- AWGN and ISI channel simulation
- Coherent demodulation
- Zero-forcing equalization
- Bit detection
- Voice reconstruction
- BER analysis
- BER-versus-SNR evaluation

### `audio_signal.m4a`

Input voice recording used as the original message signal.

### `BPSK_Voice_Transmission_Report.pdf`

Complete technical report containing the system theory, equations, plots, BER results, discussion, conclusion, and future improvements.

---

## Requirements

- MATLAB
- Signal Processing Toolbox
- Communications Toolbox, depending on the functions used in the script

---

## How to Run and Use

### 1. Download the Repository

Download the repository as a ZIP file or clone it using Git.

### 2. Open the Project in MATLAB

Open MATLAB and set the repository folder as the current working directory.

### 3. Confirm the Required Files

Make sure these files are located in the same folder:

```text
bpsk_voice_transmission.m
audio_signal.m4a
```

### 4. Run the Simulation

Enter the following command in the MATLAB Command Window:

```matlab
run('bpsk_voice_transmission.m')
```

You may also open the script in the MATLAB Editor and press **Run**.

### 5. Review the Results

The script automatically performs the complete communication-system simulation and generates plots for:

- Original voice waveform
- Original voice spectrum
- Ideal sampled signal
- Ideal versus non-ideal sampling
- Quantized signal
- Polar NRZ line coding
- Pulse-shaped baseband signal
- BPSK-modulated signal
- Channel impulse response
- Transmitted and received symbols
- Signal before and after equalization
- Recovered voice spectrum
- BER before and after equalization
- BER versus SNR
- Theoretical BPSK comparison

The MATLAB Command Window displays the calculated BER values and equalization improvement.

### Using a Different Voice Recording

To test another audio recording:

1. Place the new file in the repository folder.
2. Rename it:

```text
audio_signal.m4a
```

Alternatively, update the filename inside the MATLAB script:

```matlab
audioFile = 'your_audio_file.wav';
```

MATLAB-supported audio formats such as `.m4a` and `.wav` can be used.

For faster execution, use a short voice recording.

---

## Main Conclusions

- ISI significantly increased the system's detection-error rate.
- Zero-forcing equalization substantially improved transmission reliability.
- BER decreased as SNR increased.
- The equalized system consistently outperformed the non-equalized system.
- The simulated system performed below the theoretical BPSK limit because the channel included noise, ISI, and implementation effects.
- Equalization reduced deterministic channel distortion but did not eliminate AWGN.
- Receiver design and channel equalization are critical to reliable digital communication.

---

## Limitations

The current implementation assumes:

- Ideal carrier synchronization
- A known ISI coefficient
- A simple two-tap channel
- Rectangular pulse shaping
- Hard-decision detection
- Uniform 8-bit quantization
- No carrier-frequency offset
- No carrier-phase offset
- No timing-recovery loop
- No forward-error-correction coding

---

## Future Improvements

Possible extensions include:

- MMSE equalization
- Decision-feedback equalization
- Adaptive LMS or RLS equalization
- Raised-cosine pulse shaping
- Root-raised-cosine matched filtering
- Eye-diagram analysis
- Constellation diagrams
- More realistic multipath channels
- Carrier and timing synchronization errors
- Forward-error-correction coding
- Comparison with QPSK and QAM
- Real-time microphone input

---

## Conclusion

This project successfully implements an end-to-end digital voice-transmission system using BPSK in MATLAB.

The system converts a voice signal into digital data through sampling and 8-bit quantization, applies polar NRZ encoding and pulse shaping, modulates the data using BPSK, and transmits it through a channel containing AWGN and ISI.

At the receiver, coherent demodulation and zero-forcing equalization recover the transmitted information. The equalizer reduced the BER from **0.0918 to 0.0204**, representing an improvement of approximately **77.8%**.

The results demonstrate the importance of equalization in channels affected by memory and show the difference between ideal theoretical BPSK performance and a practical system containing noise, ISI, quantization, and sampling imperfections.

---

## Technical Report

[View the complete BPSK Voice Transmission Report](BPSK_Voice_Transmission_Report.pdf)

---

## License

This project is licensed under the [MIT License](LICENSE).
