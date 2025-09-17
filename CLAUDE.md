# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ytaudio is a bash script for downloading audio from YouTube/SoundCloud and optionally splitting into stems using AI.
Built with the bashew framework, it's a command-line tool with multiple action modes.

## Usage

* use **ytaudio get** to download 1 URL
  `ytaudio get <url>`

* use **ytaudio loop** to download multiple URLs sequentially (one at a time)
```bash
> ytaudio loop
# Copy/paste a URL and press <return> to start the download (sequentially)
```

* use **ytaudio parallel** to download multiple URLs in parallel (at the same time)
```bash
> ytaudio parallel
# Copy/paste a URL and press <return> to start the download (simultaneously)
```

* use **ytaudio env** to generate an example .env file
  `ytaudio env > .env`

## Core Architecture

- **Main script**: `ytaudio.sh` - Single executable bash script (~1000 lines)
- **Framework**: Built on bashew framework for argument parsing and utilities
- **Dependencies**: Requires external tools: yt-dlp (downloading) and demucs (stem splitting)
- **Actions**: get (single download), loop (interactive), parallel (background downloads), check, env, update

## Development Commands

### Testing
```bash
# Run all tests using bash_unit
./tests/run_tests.sh

# Individual test files
tests/bash_unit tests/test_basic.sh
tests/bash_unit tests/test_download.sh
```

### Code Quality
```bash
# Run shellcheck on all shell scripts
shellcheck *.sh

# Pre-commit hook runs shellcheck automatically on staged files
```

### Dependencies
Script requires these external tools to be installed:
```bash
python3 -m pip install -U yt-dlp
python3 -m pip install -U demucs
# or on macOS: brew install yt-dlp
```

## Key Configuration

The script uses bashew's option parsing framework defined in `Option:config()` function:
- Flags: help, quiet, verbose, force
- Options: DOWNLOADER (yt-dlp), FORMAT (wav), OUT_DIR (.), QUALITY (1), SPLITTER (full/voice)
- Parameters: action (choice), input (optional URL)

## CI/CD

- **GitHub Actions**: bash_unit tests and shellcheck validation
- **Pre-commit hook**: Runs shellcheck on staged shell files
- **Skip CI**: Use `[skip ci]` in commit message to skip CI
- **macOS testing**: Add `[macos]` to commit message for macOS CI runs