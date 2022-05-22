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

```bash
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
> ytaudio .
# start PhpStorm with current folder as project
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
