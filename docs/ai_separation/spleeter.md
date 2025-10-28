# spleeter

* URL: [https://github.com/deezer/spleeter](https://github.com/deezer/spleeter)

## Abstract

Spleeter is Deezer source separation library with pretrained models written in Python and uses Tensorflow. 
It makes it easy to train source separation model (assuming you have a dataset of isolated sources), and provides already trained state-of-the-art model for performing various flavour of separation :

* Vocals (singing voice) / accompaniment separation (2 stems)
* Vocals / drums / bass / other separation (4 stems)
* Vocals / drums / bass / piano / other separation (5 stems)

2 stems and 4 stems models have high performances on the musdb dataset. 
Spleeter is also very fast as it can perform separation of audio files to 4 stems **100x faster than real-time** when run on a GPU.

We designed Spleeter so you can use it straight from command line as well as directly in your own development pipeline as a Python library. 
It can be installed with `pip` or be used with Docker.

