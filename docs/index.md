![bash_unit CI](https://github.com/pforret/ytaudio/workflows/bash_unit%20CI/badge.svg)
![Shellcheck CI](https://github.com/pforret/ytaudio/workflows/Shellcheck%20CI/badge.svg)
![GH Language](https://img.shields.io/github/languages/top/pforret/ytaudio)
![GH stars](https://img.shields.io/github/stars/pforret/ytaudio)
![GH tag](https://img.shields.io/github/v/tag/pforret/ytaudio)
![GH License](https://img.shields.io/github/license/pforret/ytaudio)
[![basher install](https://img.shields.io/badge/basher-install-white?logo=gnu-bash&style=flat)](https://basher.gitparade.com/package/)

# [pforret/ytaudio](https://github.com/pforret/ytaudio)

![](assets/ytaudio.jpg)
ytaudio is a bash script for downloading audio from YouTube/SoundCloud and optionally splitting into stems using AI.
Built with the bashew framework, it's a command-line tool with multiple action modes.

## 🔥 Usage

```
Program : ytaudio  by peter@forret.com
Version : v1.6.0 (Nov 22 09:53:46 2025)
Purpose : Download audio (YouTube/Soundcloud/...) and split into stems
Usage   : ytaudio [-h] [-q] [-v] [-f] [-C] [-I] [-M] [-N] [-P] [-T] [-l <log_dir>] [-t <tmp_dir>] [-D <DOWNLOADER>] [-F <FORMAT>] [-G <GENRE>] [-O <OUT_DIR>] [-Q <QUALITY>] [-S <SPLITTER>] [-X <MAX>] [-Y <MIN>] <action> <input?>
Flags, options and parameters:
    -h|--help        : [flag] show usage [default: off]
    -q|--quiet       : [flag] no output [default: off]
    -v|--verbose     : [flag] also show debug messages [default: off]
    -f|--force       : [flag] do not ask for confirmation (always yes) [default: off]
    -C|--CLEAN       : [flag] cleanup the output file name [default: off]
    -I|--INFO        : [flag] lookup metadata and tag file [default: off]
    -M|--MP3         : [flag] transcode to high-quality MP3 [default: off]
    -N|--NORMALIZE   : [flag] normalize output audio [default: off]
    -P|--SPECTRO     : [flag] generate spectrogram image [default: off]
    -T|--TRIM        : [flag] trim silence from beginning/end [default: off]
    -l|--log_dir <?> : [option] folder for log files   [default: log]
    -t|--tmp_dir <?> : [option] folder for temp files  [default: tmp]
    -D|--DOWNLOADER <?>: [option] download binary  [default: yt-dlp]
    -F|--FORMAT <?>  : [option] output audio format  [default: wav]
    -G|--GENRE <?>   : [option] force mp3 genre
    -O|--OUT_DIR <?> : [option] output folder  [default: .]
    -Q|--QUALITY <?> : [option] audio quality  [default: 1]
    -S|--SPLITTER <?>: [option] stem splitting (full/voice)
    -X|--MAX <?>     : [option] max duration in seconds  [default: 480]
    -Y|--MIN <?>     : [option] min duration in seconds  [default: 180]
    <action>         : [choice] action to perform  [options: get,search,loop,tracklist,trackfilter,parallel,check,env,update]
    <input>          : [parameter] input URL (optional)

### TIPS & EXAMPLES
* use ytaudio get to download 1 URL
  ytaudio get https://www.youtube.com/watch?v=mMfxI3r_LyA
* use ytaudio search to download 1 URL
  ytaudio search "Modjo - Lady"
* use ytaudio loop to keep downloading one URL after the other
  ytaudio loop
* use ytaudio tracklist to receive a whole tracklist and download one by one
  cat tracklist.txt | ytaudio tracklist
* use ytaudio tracklist to receive a whole tracklist and clean it up
  cat tracklist.txt | ytaudio trackfilter
* use ytaudio parallel to download URLs simultaneously
  ytaudio parallel
* use ytaudio check to check if this script is ready to execute and what values the options/flags are
  ytaudio check
* use ytaudio env to generate an example .env file
  ytaudio env > .env
* use ytaudio update to update to the latest version
  ytaudio update
* >>> bash script created with pforret/bashew
```

## ⚡️ Examples

```bash
# download 1 URL (basic)
% ytaudio get "https://www.youtube.com/watch?v=SFU1GeGFpzY"
./Tears_For_Fears_-_Everybody_Wants_To_Rule_The_World.wav

# and this happened
#    19:13:14 | [ytaudio] 1.4.0 started
#    19:13:14 | yt-dlp https://www.youtube.com/watch?v=SFU1GeGFpzY
#    19:13:22 | [ytaudio] ended after 9 secs


# download 1 URL (with options)
% ytaudio -N -M -C get "https://www.youtube.com/watch?v=SFU1GeGFpzY"
./TearsForFears-EverybodyWantsToRuleTheWorld.mp3

# and this happened
#    19:06:16 | [ytaudio] 1.4.0 started
#    19:06:16 | yt-dlp https://www.youtube.com/watch?v=SFU1GeGFpzY
#    19:06:26 | Normalize output/Tears_For_Fears_-_Everybody_Wants_To_Rule_The_World.wav (-14 LUFS)
#    19:06:35 | Loudness corrected: { 'volume_r128': -13.9 LUFS, 'mean_volume': -16.8 dB } => { 'volume_r128': -13.6 LUFS, 'mean_volume': -16.4 dB }
#    19:06:35 | ffmpeg output/Tears_For_Fears_-_Everybody_Wants_To_Rule_The_World.wav -> output/Tears_For_Fears_-_Everybody_Wants_To_Rule_The_World.mp3
#    19:06:38 | Cleanup: 'Tears_For_Fears_-_Everybody_Wants_To_Rule_The_World.mp3' => 'TearsForFears-EverybodyWantsToRuleTheWorld.mp3'
#    19:06:38 | [ytaudio] ended after 23 secs


# copy/paste URLs to download them one by one
% ytaudio loop
Copy/paste a URL and press <return> to start the download (one at a time)
https://www.youtube.com/watch?v=5J7IrPVLc4U
output/SteelyDan-HeyNineteen.mp3
https://www.youtube.com/watch?v=ghcsrblhn7A
output/SteelyDan-DirtyWork.mp3

✅  Program finished!

# copy/paste URLs to start the download (in parallel)
% ytaudio parallel
Copy/paste a URL and press <return> to start the download (in background)
https://www.youtube.com/watch?v=5J7IrPVLc4U
https://www.youtube.com/watch?v=ghcsrblhn7A
output/SteelyDan-HeyNineteen.mp3
output/SteelyDan-DirtyWork.mp3

✅  Program finished!

# download with metadata lookup and tagging (-I)
# embeds artist, title, album, year, genre, country, and album artwork
% ytaudio -I -M -C get "https://www.youtube.com/watch?v=SFU1GeGFpzY"
./TearsForFears_EverybodyWantsToRuleTheWorld.mp3

# and this happened
#    19:10:00 | yt-dlp https://www.youtube.com/watch?v=SFU1GeGFpzY
#    19:10:10 | Metadata (itunes): Tears For Fears - Everybody Wants To Rule The World [Songs from the Big Chair] (1985) Pop [USA]
#    19:10:12 | Rename: TearsForFears-EverybodyWantsToRuleTheWorld.mp3 => TearsForFears_EverybodyWantsToRuleTheWorld.mp3

# download with spectrogram image (-P)
% ytaudio -M -P get "https://www.youtube.com/watch?v=SFU1GeGFpzY"
./Tears_For_Fears_-_Everybody_Wants_To_Rule_The_World.mp3

# creates both:
#   Tears_For_Fears_-_Everybody_Wants_To_Rule_The_World.mp3
#   Tears_For_Fears_-_Everybody_Wants_To_Rule_The_World.spectro.jpg

# full processing pipeline: trim, normalize, metadata, MP3, clean filename, spectrogram
% ytaudio -T -N -I -M -C -P get "https://www.youtube.com/watch?v=SFU1GeGFpzY"
./TearsForFears_EverybodyWantsToRuleTheWorld.mp3

# and this happened
#    19:15:00 | yt-dlp https://www.youtube.com/watch?v=SFU1GeGFpzY
#    19:15:08 | Trim silence Tears_For_Fears_-_Everybody_Wants_To_Rule_The_World.wav
#    19:15:10 | Normalize Tears_For_Fears_-_Everybody_Wants_To_Rule_The_World.wav (-14 LUFS)
#    19:15:18 | ffmpeg -> TearsForFears_EverybodyWantsToRuleTheWorld.mp3
#    19:15:20 | Metadata (itunes): Tears For Fears - Everybody Wants To Rule The World
#    19:15:22 | Spectrogram: TearsForFears_EverybodyWantsToRuleTheWorld.spectro.jpg
```

## 🚀 Installation

with [basher](https://github.com/basherpm/basher)

	$ basher install pforret/ytaudio

or with `git`

	$ git clone https://github.com/pforret/ytaudio.git
	$ cd ytaudio

This script needs the following programs on your system:

* file downloader [github.com/yt-dlp/yt-dlp](https://github.com/yt-dlp/yt-dlp)
* stem splitter [github.com/facebookresearch/demucs](https://github.com/facebookresearch/demucs)

```shell
python3 -m pip install -U yt-dlp
# or on macOS: 'brew install yt-dlp'

python3 -m pip install -U demucs
```

## 📝 Acknowledgements

* script created with [bashew](https://github.com/pforret/bashew)

&copy; 2022-2025 Peter Forret
