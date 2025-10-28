# demucs
 
* URL: [https://github.com/facebookresearch/demucs](https://github.com/facebookresearch/demucs) (archived)
* URL: [https://github.com/adefossez/demucs](https://github.com/adefossez/demucs)

## Abstract

Demucs is a state-of-the-art music source separation model, currently capable of separating drums, bass, and vocals from the rest of the accompaniment. Demucs is based on a U-Net convolutional architecture inspired by Wave-U-Net. The v4 version features Hybrid Transformer Demucs, a hybrid spectrogram/waveform separation model using Transformers. It is based on Hybrid Demucs (also provided in this repo), with the innermost layers replaced by a cross-domain Transformer Encoder. This Transformer uses self-attention within each domain, and cross-attention across domains. The model achieves a SDR of 9.00 dB on the MUSDB HQ test set. Moreover, when using sparse attention kernels to extend its receptive field and per source fine-tuning, we achieve state-of-the-art 9.20 dB of SDR.

