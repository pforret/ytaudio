# Repository Guidelines

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

## Project Structure & Module Organization
Source scripts live at the repository root: `ytaudio` is the primary entry point and mirrors `ytaudio.sh` for development convenience. 
Supporting assets (promo imagery, templates) are under `assets/`, while generated audio lives in `output/` and should stay out of version control. 
Testing scaffolding resides in `tests/` (see `tests/test_basic.sh` and `tests/test_download.sh`), and command reference material is in `docs/`.

## Build, Test, and Development Commands
Use `./ytaudio check` for a quick dependency and configuration audit. 
Run `shellcheck ytaudio` to lint proposed changes before raising a PR. 
Execute `bash tests/run_tests.sh` to launch the Bash Unit suite; it calls every `tests/test_*.sh`. 
For manual verification, try `./ytaudio get "<media-url>" --OUT_DIR output` and confirm the produced file lands in `output/`.

## Coding Style & Naming Conventions
Match the existing Bash style: two-space indentation, lowercase function names (e.g., `download_to_file`), and uppercase flag variables that align with Bashew’s parser (`$FORMAT`, `$OUT_DIR`). Keep helper functions near their usage and favor `IO:`/`Os:` helpers supplied by Bashew over raw `echo` or `which`. Always run `shellcheck` on touched scripts and address warnings.

## Testing Guidelines
Tests rely on `bash_unit`; install it (`brew install bash_unit` or see upstream docs) before running `bash tests/run_tests.sh`. The download suite expects `python3`, `ffmpeg`, and `yt-dlp`; confirm they are on the PATH to avoid flaky assertions. Add new test files as `tests/test_<topic>.sh`, exposing functions that start with `test_`, and keep network-heavy scenarios opt-in.

## Commit & Pull Request Guidelines
Follow the concise prefixes used in history: `MOD:` for behavioral changes, `setver:` when bumping `VERSION.md`, and keep the rest of the line focused on the touched area. For pull requests, include: what changed, why it matters, relevant `./ytaudio` or test output, and any follow-up work. Link issues when applicable and attach terminal snippets instead of screenshots whenever possible.
