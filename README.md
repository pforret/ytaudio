![bash_unit CI](https://github.com/pforret/ytaudio/workflows/bash_unit%20CI/badge.svg)
![Shellcheck CI](https://github.com/pforret/ytaudio/workflows/Shellcheck%20CI/badge.svg)
![GH Language](https://img.shields.io/github/languages/top/pforret/ytaudio)
![GH stars](https://img.shields.io/github/stars/pforret/ytaudio)
![GH tag](https://img.shields.io/github/v/tag/pforret/ytaudio)
![GH License](https://img.shields.io/github/license/pforret/ytaudio)
[![basher install](https://img.shields.io/badge/basher-install-white?logo=gnu-bash&style=flat)](https://basher.gitparade.com/package/)

# ytaudio

![](assets/unsplash.youtube.jpg)
Get audio from YT

## 🔥 Usage

```
Program : ytaudio  by peter@forret.com
Version : v0.1.0 (May 22 09:30:13 2022)
Purpose : Get audio from YT
Usage   : ytaudio [-h] [-q] [-v] [-f] [-l <log_dir>] [-t <tmp_dir>] [-o <outdir>] [-f <format>] [-y <quality>] <action> <input?>
Flags, options and parameters:
    -h|--help        : [flag] show usage [default: off]
    -q|--quiet       : [flag] no output [default: off]
    -v|--verbose     : [flag] also show debug messages [default: off]
    -f|--force       : [flag] do not ask for confirmation (always yes) [default: off]
    -l|--log_dir <?> : [option] folder for log files   [default: /Users/pforret/log/ytaudio]
    -t|--tmp_dir <?> : [option] folder for temp files  [default: /tmp/ytaudio]
    -o|--outdir <?>  : [option] output folder  [default: .]
    -f|--format <?>  : [option] output audio format  [default: mp3]
    -y|--quality <?> : [option] audio quality  [default: 1]
    <action>         : [choice] action to perform  [options: get,loop,parallel,check,env,update]
    <input>          : [parameter] input URL (optional)
```

## ⚡️ Examples

```bash
# downlad 1 URL
% ytaudio get "https://www.youtube.com/watch?v=SFU1GeGFpzY"
[youtube] SFU1GeGFpzY: Downloading webpage
[download] Destination: ./Tears For Fears - Everybody Wants To Rule The World.251s.webm
[download] 100% of 4.02MiB in 01:01
[ffmpeg] Destination: ./Tears For Fears - Everybody Wants To Rule The World.251s.mp3
Deleting original file ./Tears For Fears - Everybody Wants To Rule The World.251s.webm (pass -k to keep)

# copy/paste URLs to download them one by one
% ytaudio loop
Copy/paste a URL and press <return> to start the download (one at a time)
https://www.youtube.com/watch?v=7dtpj8qa1hQ
[youtube] 7dtpj8qa1hQ: Downloading webpage
[download] Destination: ./Funky Drummer (Bonus Beat Reprise).177s.m4a
[download] 100% of 2.73MiB in 00:36
[ffmpeg] Correcting container in "./Funky Drummer (Bonus Beat Reprise).177s.m4a"
[ffmpeg] Destination: ./Funky Drummer (Bonus Beat Reprise).177s.mp3
Deleting original file ./Funky Drummer (Bonus Beat Reprise).177s.m4a (pass -k to keep)
https://www.youtube.com/watch?v=T1j1_aeK6WA
[youtube] T1j1_aeK6WA: Downloading webpage
[download] Destination: ./Bernard 'Pretty' Purdie - The Legendary Purdie Shuffle.388s.m4a
[download] 100% of 5.99MiB in 01:32
[ffmpeg] Correcting container in "./Bernard 'Pretty' Purdie - The Legendary Purdie Shuffle.388s.m4a"
[ffmpeg] Destination: ./Bernard 'Pretty' Purdie - The Legendary Purdie Shuffle.388s.mp3
Deleting original file ./Bernard 'Pretty' Purdie - The Legendary Purdie Shuffle.388s.m4a (pass -k to keep)

✅  Program finished!> ytaudio parallel

# copy/paste URls to start the download (in parallel)
% ytaudio parallel                                         
Copy/paste a URL and press <return> to start the download (in background)
https://www.youtube.com/watch?v=5J7IrPVLc4U                                    
✅  Downloading https://www.youtube.com/watch?v=5J7IrPVLc4U
https://www.youtube.com/watch?v=ghcsrblhn7A
✅  Downloading https://www.youtube.com/watch?v=ghcsrblhn7A
[ffmpeg] Destination: ./Steely Dan - Hey Nineteen - HQ Audio -- LYRICS.295s.mp3
[ffmpeg] Destination: ./Steely Dan - Dirty Work.191s.mp3

✅  Program finished!
```

## 🚀 Installation

with [basher](https://github.com/basherpm/basher)

	$ basher install pforret/ytaudio

or with `git`

	$ git clone https://github.com/pforret/ytaudio.git
	$ cd ytaudio

## 📝 Acknowledgements

* script created with [bashew](https://github.com/pforret/bashew)

&copy; 2022 Peter Forret
