# EnCodec (Meta)

* URL: [audiocraft.metademolab.com/encodec.html](https://audiocraft.metademolab.com/encodec.html)
* URL: [github.com/facebookresearch/audiocraft/blob/main/docs/ENCODEC.md](https://github.com/facebookresearch/audiocraft/blob/main/docs/ENCODEC.md)

## Abstract

We introduce EnCodec, a state-of-the-art real-time, high-fidelity, audio codec leveraging neural networks. EnCodec is trained specifically to compress any kind of audio and reconstruct the original signal with high fidelity. It consists of an autoencoder with a residual vector quantization bottleneck that produces several parallel streams of audio tokens with a fixed vocabulary. The different streams capture different levels of information of the audio waveform, allowing to reconstruct the audio with high fidelity from all the streams.

We further propose a Multi-Band Diffusion framework that generates any audio modality with higher perceived quality from EnCodec’s low-bitrate discrete representations.

In addition to the audio compression use case, EnCodec compressed representation can be used as inputs for audio language modeling tasks as demonstrated in the AudioGen and MusicGen works.
