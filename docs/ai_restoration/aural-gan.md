# AURAL_GAN predictive

* URL: [https://github.com/Gabeiscool420/AURAL_GAN-predictive_model](https://github.com/Gabeiscool420/AURAL_GAN-predictive_model)

## Abstract

This project aims to transform low-quality phone recordings into professional-quality audio using a Generative Adversarial Network (GAN). 
The system is designed to work with acoustic guitar recordings, but it can be adapted to work with other instruments.

The system works in two main stages:

* Training: In this stage, the system is trained on a dataset of high-quality and low-quality audio files. It learns to transform low-quality audio into high-quality audio by minimizing the difference between the transformed audio and the original high-quality audio. The system uses a GAN architecture, which consists of two neural networks, the Generator and the Discriminator, competing against each other. The Generator tries to create high-quality audio from low-quality input, while the Discriminator tries to distinguish between real high-quality audio and the audio produced by the Generator.
* Prediction: In this stage, the system takes a low-quality audio file as input and transforms it into a high-quality audio file. This process is accomplished by running the low-quality audio through the trained Generator network.
