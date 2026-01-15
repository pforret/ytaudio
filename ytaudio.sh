#!/usr/bin/env bash
### ==============================================================================
### SO HOW DO YOU PROCEED WITH YOUR SCRIPT?
### 1. define the flags/options/parameters and defaults you need in Option:config()
### 2. implement the different actions in Script:main() with helper functions
### 3. implement helper functions you defined in previous step
### ==============================================================================

### Created by Peter Forret ( pforret ) on 2022-05-20
### Based on https://github.com/pforret/bashew 1.18.6
script_version="0.0.1" # if there is a VERSION.md in this script's folder, it will take priority for version number
readonly script_author="peter@forret.com"
readonly script_created="2022-05-20"
readonly run_as_root=-1 # run_as_root: 0 = don't check anything / 1 = script MUST run as root / -1 = script MAY NOT run as root

## some initialization
action=""
script_prefix=""
script_basename=""
install_package=""
temp_files=()

function Option:config() {
  grep <<<"
#commented lines will be filtered
flag|h|help|show usage
flag|q|quiet|no output
flag|v|verbose|also show debug messages
flag|f|force|do not ask for confirmation (always yes)
flag|C|CLEAN|cleanup the output file name
flag|I|INFO|lookup metadata and tag file
flag|M|MP3|transcode to high-quality MP3
flag|N|NORMALIZE|normalize output audio
flag|P|SPECTRO|generate spectrogram image
flag|T|TRIM|trim silence from beginning/end
option|l|log_dir|folder for log files |log
option|t|tmp_dir|folder for temp files|tmp
option|D|DOWNLOADER|download binary|yt-dlp
option|F|FORMAT|output audio format|wav
option|G|GENRE|force mp3 genre|
option|O|OUT_DIR|output folder|.
option|Q|QUALITY|audio quality|1
option|S|SPLITTER|stem splitting (full/voice)|
option|X|MAX|max duration in seconds|600
option|Y|MIN|min duration in seconds|180
choice|1|action|action to perform|get,search,loop,tracklist,trackfilter,parallel,check,env,update
param|?|input|input URL
" -v -e '^#' -e '^\s*$'
}

#####################################################################
## Put your Script:main script here
#####################################################################

Script:main() {
  IO:log "[$script_basename] $script_version started"

  Os:require "awk"
  Os:require "$DOWNLOADER"

  action=$(Str:lower "$action")
  case $action in
  get)
    #TIP: use «$script_prefix get» to download 1 URL
    #TIP:> $script_prefix get https://www.youtube.com/watch?v=mMfxI3r_LyA
    # shellcheck disable=SC2154
    download_to_file "$input"
    ;;

  search)
    #TIP: use «$script_prefix search» to download 1 URL
    #TIP:> $script_prefix search "Modjo - Lady"
    local url
    # shellcheck disable=SC2154
    url="$(search_in_youtube "$input")"
    download_to_file "$url" "$input"
    ;;

  loop)
    #TIP: use «$script_prefix loop» to keep downloading one URL after the other
    #TIP:> $script_prefix loop
    local url
    IO:print "Copy/paste a URL and press <return> to start the download (one at a time)"
    while read -r url; do
      [[ -z "$url" ]] && IO:success "Program finished!" && Script:exit
      download_to_file "$url" "$input"
    done
    ;;

  tracklist)
    #TIP: use «$script_prefix tracklist» to receive a whole tracklist and download one by one
    #TIP:> cat tracklist.txt | $script_prefix tracklist
    local url today clean_list url line
    IO:print "Copy/paste the tracklist"

    today=$(date '+%Y-%m-%d')
    [[ ! -d "$OUT_DIR" ]] && mkdir -p "$OUT_DIR"
    clean_list="$OUT_DIR/tracklist.$today.$$.txt"
    IO:debug "Clean track list in $clean_list"

    cleanup_tracklist |
      tee "$clean_list" |
      while read -r line; do
        IO:announce "Look for: '$line'"
        [[ -z "$line" ]] && IO:success "Program finished!" && Script:exit
        url="$(search_in_youtube "$line" < /dev/null)"
        IO:debug "Found URL: $url"
        [[ -n "$url" ]] && download_to_file "$url" "$line" < /dev/null
      done
    ;;

  trackfilter)
    #TIP: use «$script_prefix tracklist» to receive a whole tracklist and clean it up
    #TIP:> cat tracklist.txt | $script_prefix trackfilter
    local url
    [[ -t 0 ]] && IO:print "Copy/paste the tracklist" >&2

    cleanup_tracklist |
      while read -r input; do
        [[ -z "$input" ]] && break
        echo "$input"
      done
    ;;

  parallel)
    #TIP: use «$script_prefix parallel» to download URLs simultaneously
    #TIP:> $script_prefix parallel
    local url
    IO:print "Copy/paste a URL and press <return> to start the download (in background)"
    IO:progress " "
    while read -r url; do
      [[ -z "$url" ]] && IO:success "Program finished!" && Script:exit
      download_to_file "$url" &
    done
    ;;

  check | env)
    ## leave this default action, it will make it easier to test your script
    #TIP: use «$script_prefix check» to check if this script is ready to execute and what values the options/flags are
    #TIP:> $script_prefix check
    #TIP: use «$script_prefix env» to generate an example .env file
    #TIP:> $script_prefix env > .env
    Script:check
    ;;

  update)
    ## leave this default action, it will make it easier to test your script
    #TIP: use «$script_prefix update» to update to the latest version
    #TIP:> $script_prefix update
    Script:git_pull
    local BIN_DOWNLOADER
    BIN_DOWNLOADER="$(command -v yt-dlp)"
    [[ "$BIN_DOWNLOADER" == "/opt/homebrew/bin/yt-dlp" ]] && brew upgrade yt-dlp
    ;;

  *)
    IO:die "action [$action] not recognized"
    ;;
  esac
  IO:log "[$script_basename] ended after $SECONDS secs"
  #TIP: >>> bash script created with «pforret/bashew»
  #TIP: >>> for bash development, also check IO:print «pforret/setver» and «pforret/IO:progressbar»
}

#####################################################################
## Put your helper scripts here
#####################################################################

function search_in_youtube() {
  # input:  query string like: "Artist - Title"
  # output: best matching YouTube video URL (empty on failure)
  # uses:   yt-dlp via $DOWNLOADER
  local query url uniq log_media
  # accept entire arg list as query to preserve spaces
  query="$*"
  # trim leading/trailing whitespace
  query="${query##[[:space:]]*}"
  query="${query%%*[[:space:]]}"

  if [[ -z "$query" ]]; then
    IO:debug "search_in_youtube: empty query"
    echo ""
    return 1
  fi

  uniq=$(echo "$query" | Str:digest 6)
  # log per search like in download_to_file
  # shellcheck disable=SC2154
  log_media="$log_dir/ytaudio.youtube.com.$uniq.log"

  IO:debug "Search YouTube for: $query"
  IO:log "SEARCH: $query"

  # Primary attempt: ytsearch1 (best match)
  # We print the webpage URL; --no-playlist to avoid channel/playlist URLs
  url=$("$DOWNLOADER" \
    --no-warnings \
    --no-playlist \
    --default-search "ytsearch" \
    --print "%(webpage_url)s" \
    "ytsearch1:$query" 2>>"$log_media" | head -n1 | tr -d '\r')

  # Fallback: try top results and pick the first valid URL
  if [[ -z "$url" ]]; then
    url=$("$DOWNLOADER" \
      --no-warnings \
      --no-playlist \
      --default-search "ytsearch" \
      --print "%(webpage_url)s" \
      "ytsearch5:$query" 2>>"$log_media" | grep -E '^https?://[^ ]+' | head -n1 | tr -d '\r')
  fi

  if [[ -z "$url" ]]; then
    IO:debug "No YouTube result for: $query"
    echo ""
    return 2
  fi

  IO:debug "YouTube best match: $url"
  echo "$url"
}

function download_to_file() {
  local url="$1"
  local search_query="${2:-}" # Optional: original search query for metadata lookup
  IO:debug "download_to_file: '$url' '$search_query'"
  local output_download
  local output_root
  local uniq
  uniq=$(echo "$url" | Str:digest 6)
  host=$(parse_host "$url")
  # shellcheck disable=SC2154
  local log_media="$log_dir/ytaudio.$host.$uniq.log"

  # shellcheck disable=SC2154
  local yt_options=(--no-part
    --restrict-filenames
    --cache-dir "$tmp_dir"
    --audio-format "$FORMAT"
    --audio-quality "$QUALITY"
    --match-filter "duration > $MIN & duration < $MAX"
    --no-progress
    --console-title
    -x
    -o "$tmp_dir/%(title)s.%(ext)s")

  IO:progress "Downloading $url          "
  local final_output=""
  # shellcheck disable=SC2154
  IO:debug "Download $url ... "
  IO:log "$DOWNLOADER $url"
  output_download=$("$DOWNLOADER" "${yt_options[@]}" "$url" 2>> "$log_media" |
    grep "Destination:" |
    tail -1 |
    cut -f3- -d' ')

  if [[ -z "$output_download" ]] ; then
     IO:alert "No Youtube video could be downloaded"
     echo ""
     return 1
  fi
  [[ ! -f "$output_download" ]] && IO:die "Output file [$output_download] not found"
  final_output="$output_download"

  if [[ "$TRIM" -gt 0 ]]; then
    IO:progress "Trim silence $(basename "$final_output")          "
    Os:require ffmpeg
    IO:debug "Trimming silence from ${output_download} ..."
    IO:log "Trim silence ${output_download}"
    local output_trimmed duration_before duration_after
    output_trimmed="${output_download%.*}_trimmed.${FORMAT}"

    # Get duration before trimming
    duration_before=$(ffprobe -v quiet -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$output_download")

    ffmpeg -hide_banner -i "$output_download" \
      -af "silenceremove=start_periods=1:start_silence=0.1:start_threshold=-50dB:detection=peak,areverse,silenceremove=start_periods=1:start_silence=0.1:start_threshold=-50dB:detection=peak,areverse" \
      -y "$output_trimmed" 2>>"$log_media"
    if [[ -f "$output_trimmed" ]]; then
      # Get duration after trimming
      duration_after=$(ffprobe -v quiet -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$output_trimmed")

      if [[ "$duration_before" != "$duration_after" ]]; then
        IO:debug "Trimmed: ${duration_before}s => ${duration_after}s"
        IO:log "Trimmed: ${duration_before}s => ${duration_after}s"
      fi
      mv -f "$output_trimmed" "$output_download"
    fi
    final_output="$output_download"
  fi

  if [[ "$NORMALIZE" -gt 0 ]]; then
    IO:progress "Normalize $(basename "$final_output")          "
    local loudness_before loudness_after
    ## ffmpeg -i "$audio_file" -af loudnorm=I=-14:LRA=11:TP=-1.5 -y "normalized_"$audio_file
    Os:require ffmpeg
    loudness_before="$(measure_volume "$output_download")"
    IO:debug "Normalizing ${output_download} ..."
    IO:log "Normalize ${output_download} (-14 LUFS)"
    local output_normalized
    output_normalized="${output_download%.*}_normalized.${FORMAT}"
    ffmpeg -hide_banner -i "$output_download" -af "loudnorm=I=-9:LRA=3:TP=-1" -y "$output_normalized" 2>>"$log_media"
    loudness_after="$(measure_volume "$output_normalized")"
    if [[ "$loudness_before" != "$loudness_after" ]]; then
      IO:debug "Loudness corrected: $loudness_before => $loudness_after"
      IO:log "Loudness corrected: $loudness_before => $loudness_after"
      mv -f "$output_normalized" "$output_download"
    else
      rm "$output_normalized"
    fi
    final_output="$output_download"
    IO:debug "Normalized ${output_download}"
  fi

  output_root=$(basename "$final_output" ".$FORMAT")
  if [[ -n "$SPLITTER" ]]; then
    IO:progress "Split $(basename "$final_output")          "
    Os:require demucs "python3 -m pip install -U demucs"
    IO:progress "Splitting ${final_output})"
    IO:log "Split ${final_output} $SPLITTER"
    case "$SPLITTER" in
    # demucs --help
    #usage: demucs.separate [-h] [-s SIG | -n NAME] [--repo REPO] [-v] [-o OUT] [--filename FILENAME] [-d DEVICE] [--shifts SHIFTS] [--overlap OVERLAP] [--no-split | --segment SEGMENT] [--two-stems STEM] [--int24 | --float32] [--clip-mode {rescale,clamp}] [--mp3] [--mp3-bitrate MP3_BITRATE] [-j JOBS]
    #                       tracks [tracks ...]
    #

    full)
      demucs -o "$tmp_dir" "$output_download" &>>"$log_file"
      find "$tmp_dir" -name "*.wav" | grep "$output_root/"
      ;;

    voice)
      demucs -o "$tmp_dir" --two-stems voice "$output_download" &>>"$log_file"
      find "$tmp_dir" -name "*.wav" | grep "$output_root/"
      ;;

    none)
      IO:debug "skip SPLITTER"
      ;;

    *)
      IO:die "Splitter [$SPLITTER] not supported"
      ;;
    esac

  fi

  if [[ "$MP3" -gt 0 ]]; then
    IO:progress "Transcode $(basename "$final_output")          "
    # ffmpeg -i "normalized_"$audio_file -b:a 320k "dj_ready_$(basename "$url").mp3"
    local input_compress="$output_download"
    ## replace .wav by .mp3 in ${input_compress}
    local output_compress="${input_compress%.wav}.mp3"
    IO:debug "Transcoding ${input_compress}"
    IO:log "ffmpeg $input_compress -> $output_compress"
    ffmpeg -i "$input_compress" -b:a 320k -y "$output_compress" 2>>"$log_media"
    [[ -f "$output_compress" ]] && rm "$input_compress"
    IO:debug "Transcoded ${output_compress}"
    final_output="$output_compress"
  fi

  if [[ "$CLEAN" -gt 0 ]]; then
    IO:progress "Clean $(basename "$final_output")          "
    local folder old_name new_name
    folder="$(dirname "$final_output")"
    old_name="$(basename "$final_output")"
    new_name="$(echo "$old_name" | awk '
    {
        gsub(/_Video\./,".");
        gsub(/\._/,"");
        gsub(/_/,"");
        gsub(/OfficialMusicVideo/,"");
        gsub(/OfficialVideo/,"");
        gsub(/OfficialAudio/,"");
        gsub(/LYRICS/,"");
        gsub(/Remastered/,"");
        gsub(/HQAudio/,"");
        gsub(/\-\-+/,"-");
        gsub(/\-\./,".");
        print;
        }')"
    IO:debug "Cleanup: '$old_name' => '$new_name'"
    if [[ "$new_name" != "$old_name" ]]; then
      IO:log "Cleanup: '$old_name' => '$new_name'"
      mv "$folder/$old_name" "$folder/$new_name"
      final_output="$folder/$new_name"
    fi
  fi

  if [[ "$INFO" -gt 0 ]]; then
    IO:progress "Lookup metadata $(basename "$final_output")          "
    local metadata_result
    # Use provided search query, or extract from filename as fallback
    if [[ -z "$search_query" ]]; then
      search_query=$(basename "$final_output" | sed 's/\.[^.]*$//' | sed 's/_/ /g' | sed 's/-/ /g')
      IO:debug "Extracted search query from filename: $search_query"
    else
      IO:debug "Using provided search query: $search_query"
    fi

    metadata_result=$(lookup_metadata "$search_query")

    if [[ -n "$metadata_result" ]]; then
      # Parse metadata: source|artist|title|album|year|genre|artwork_url|country
      local meta_source meta_artist meta_title meta_album meta_year meta_genre meta_artwork meta_country
      meta_source=$(echo "$metadata_result" | cut -d'|' -f1)
      meta_artist=$(echo "$metadata_result" | cut -d'|' -f2)
      meta_title=$(echo "$metadata_result" | cut -d'|' -f3)
      meta_album=$(echo "$metadata_result" | cut -d'|' -f4)
      meta_year=$(echo "$metadata_result" | cut -d'|' -f5)
      meta_genre=$(echo "$metadata_result" | cut -d'|' -f6)
      meta_artwork=$(echo "$metadata_result" | cut -d'|' -f7)
      meta_country=$(echo "$metadata_result" | cut -d'|' -f8)

      IO:debug "Metadata from $meta_source: $meta_artist - $meta_title"
      IO:log "Metadata ($meta_source): $meta_artist - $meta_title [$meta_album] ($meta_year) $meta_genre [$meta_country]"

      # Tag the audio file
      IO:progress "Tagging $(basename "$final_output")          "
      tag_audio_file "$final_output" "$meta_artist" "$meta_title" "$meta_album" "$meta_year" "$meta_genre" "$meta_artwork" "$meta_country" "$url" "$search_query"

      # Rename file based on metadata
      local new_filename folder extension
      folder=$(dirname "$final_output")
      extension="${final_output##*.}"
      new_filename=$(format_filename "$meta_artist" "$meta_title")

      if [[ -n "$new_filename" ]] && [[ "$new_filename" != "_" ]]; then
        local new_path="$folder/${new_filename}.${extension}"
        if [[ "$new_path" != "$final_output" ]]; then
          IO:debug "Rename: $(basename "$final_output") => ${new_filename}.${extension}"
          IO:log "Rename: $(basename "$final_output") => ${new_filename}.${extension}"
          mv "$final_output" "$new_path"
          final_output="$new_path"
        fi
      fi
    else
      IO:debug "No metadata found, keeping original filename"
    fi
  fi

  if [[ "$SPECTRO" -gt 0 ]]; then
    IO:progress "Generate spectrogram $(basename "$final_output")          "
    local spectro_file
    spectro_file=$(generate_spectrogram "$final_output" "$log_media")
    if [[ -n "$spectro_file" ]]; then
      IO:debug "Spectrogram saved: $spectro_file"
    fi
  fi

  # Move final output from tmp_dir to OUT_DIR
  if [[ -f "$final_output" ]]; then
    local final_basename final_destination
    final_basename=$(basename "$final_output")
    final_destination="$OUT_DIR/$final_basename"
    IO:debug "Moving final output: $final_output -> $final_destination"
    mv "$final_output" "$final_destination"
    final_output="$final_destination"

    # Also move spectrogram if it exists
    local spectro_basename spectro_source spectro_dest
    spectro_basename="${final_basename%.*}.spectro.jpg"
    spectro_source="$tmp_dir/$spectro_basename"
    spectro_dest="$OUT_DIR/$spectro_basename"
    if [[ -f "$spectro_source" ]]; then
      IO:debug "Moving spectrogram: $spectro_source -> $spectro_dest"
      mv "$spectro_source" "$spectro_dest"
    fi

    # Move demucs output directories if they exist
    if [[ -n "$SPLITTER" ]] && [[ "$SPLITTER" != "none" ]]; then
      local demucs_dir="$tmp_dir/htdemucs/$output_root"
      if [[ -d "$demucs_dir" ]]; then
        IO:debug "Moving demucs output: $demucs_dir -> $OUT_DIR/htdemucs/"
        mkdir -p "$OUT_DIR/htdemucs"
        mv "$demucs_dir" "$OUT_DIR/htdemucs/"
      fi
    fi
  fi

  IO:print "$final_output                                                       "
}

function measure_volume() {
  local volume_r128 volume_db
  volume_r128=$(ffmpeg -hide_banner -i "$1" -filter:a "ebur128=framelog=quiet" -f null - 2>&1 | awk '/I:/ { print $2,$3}')
  volume_db=$(ffmpeg -hide_banner -i "$1" -filter:a "volumedetect" -f null - 2>&1 | awk '/mean_volume/ {print $5,$6}')
  echo "{ 'volume_r128': $volume_r128, 'mean_volume': $volume_db }"
}

function parse_host() {
  # input: https://www.youtube.com/watch?v=fKKNPLowteY
  # output: www.youtube.com
  #
  # Extract the host part from a URL, handling cases with/without scheme,
  # credentials, ports, paths, queries, and fragments.
  # Returns empty string and non-zero exit if no input provided.
  local url host
  url="${1:-}"
  if [[ -z "$url" ]]; then
    echo ""
    return 1
  fi
  # Ensure we have a // delimiter to simplify stripping the scheme
  if [[ "$url" != *"://"* ]]; then
    url="//$url"
  fi
  # Remove scheme (up to and including //)
  host="${url#*//}"
  # Trim path, query, fragment
  host="${host%%/*}"
  host="${host%%\?*}"
  host="${host%%\#*}"
  # Remove credentials if present (user:pass@host)
  host="${host#*@}"
  # Remove port if present (:port)
  host="${host%%:*}"
  # remove "www." if present
  host="${host#www.}"

  echo "$host"
}

function search_itunes() {
  # Search iTunes API for track metadata
  # Input: search query (e.g., "artist name song title")
  # Output: JSON with artist, title, album, year, genre (or empty on failure)
  local query="$1"
  local encoded_query result

  [[ -z "$query" ]] && echo "" && return 1

  # URL encode the query (simple version)
  encoded_query=$(echo "$query" | sed 's/ /+/g' | sed 's/[^a-zA-Z0-9+]//g')

  IO:debug "iTunes search: $query"
  result=$(curl -s --max-time 10 "https://itunes.apple.com/search?term=${encoded_query}&entity=song&limit=1")

  local count
  count=$(echo "$result" | grep -o '"resultCount":[0-9]*' | cut -d: -f2)

  if [[ "$count" -gt 0 ]]; then
    # Extract metadata from iTunes response
    local artist title album year genre artwork_url country
    artist=$(echo "$result" | grep -o '"artistName":"[^"]*"' | head -1 | cut -d'"' -f4)
    title=$(echo "$result" | grep -o '"trackName":"[^"]*"' | head -1 | cut -d'"' -f4)
    album=$(echo "$result" | grep -o '"collectionName":"[^"]*"' | head -1 | cut -d'"' -f4)
    year=$(echo "$result" | grep -o '"releaseDate":"[^"]*"' | head -1 | cut -d'"' -f4 | cut -c1-4)
    genre=$(echo "$result" | grep -o '"primaryGenreName":"[^"]*"' | head -1 | cut -d'"' -f4)
    artwork_url=$(echo "$result" | grep -o '"artworkUrl100":"[^"]*"' | head -1 | cut -d'"' -f4)
    country=$(echo "$result" | grep -o '"country":"[^"]*"' | head -1 | cut -d'"' -f4)

    # Upscale artwork URL from 100x100 to 600x600 for better quality
    artwork_url="${artwork_url//100x100/600x600}"

    IO:debug "iTunes found: $artist - $title ($year) [$country]"
    echo "itunes|$artist|$title|$album|$year|$genre|$artwork_url|$country"
  else
    IO:debug "iTunes: no results"
    echo ""
  fi
}

function search_musicbrainz() {
  # Search MusicBrainz API for track metadata
  # Input: search query (e.g., "artist name song title")
  # Output: JSON with artist, title, album, year, genre (or empty on failure)
  local query="$1"
  local encoded_query result

  [[ -z "$query" ]] && echo "" && return 1

  # URL encode the query
  encoded_query="${query// /%20}"

  IO:debug "MusicBrainz search: $query"
  result=$(curl -s --max-time 10 \
    -H "User-Agent: ytaudio/1.0 (https://github.com/pforret/ytaudio)" \
    "https://musicbrainz.org/ws/2/recording/?query=${encoded_query}&fmt=json&limit=1")

  local count
  count=$(echo "$result" | grep -o '"count":[0-9]*' | head -1 | cut -d: -f2)

  if [[ "$count" -gt 0 ]]; then
    # Extract metadata from MusicBrainz response
    local artist title album year
    artist=$(echo "$result" | grep -o '"artist-credit":\[{"name":"[^"]*"' | head -1 | sed 's/.*"name":"//' | sed 's/"$//')
    title=$(echo "$result" | grep -o '"title":"[^"]*"' | head -1 | cut -d'"' -f4)
    year=$(echo "$result" | grep -o '"first-release-date":"[^"]*"' | head -1 | cut -d'"' -f4 | cut -c1-4)
    # MusicBrainz doesn't return album in recording search easily, use title as fallback
    album=$(echo "$result" | grep -o '"releases":\[{"id":"[^"]*","status-id":"[^"]*","count":[0-9]*,"title":"[^"]*"' | head -1 | sed 's/.*"title":"//' | sed 's/"$//')
    [[ -z "$album" ]] && album="$title"

    if [[ -n "$artist" ]] && [[ -n "$title" ]]; then
      IO:debug "MusicBrainz found: $artist - $title ($year)"
      echo "musicbrainz|$artist|$title|$album|$year|||"
    else
      IO:debug "MusicBrainz: incomplete data"
      echo ""
    fi
  else
    IO:debug "MusicBrainz: no results"
    echo ""
  fi
}

function validate_metadata() {
  # Check if returned metadata matches the search query
  # Input: search_query, artist, title
  # Output: 0 if valid, 1 if not
  local query="$1"
  local artist="$2"
  local title="$3"

  # Normalize strings for comparison (lowercase, remove special chars, keep spaces)
  local query_lower artist_lower title_lower combined_result
  query_lower=$(echo "$query" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9' ' ')
  artist_lower=$(echo "$artist" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9' ' ')
  title_lower=$(echo "$title" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9' ' ')
  combined_result="$artist_lower $title_lower"

  IO:debug "Validation - query_lower='$query_lower' combined_result='$combined_result'"

  # Check if query words appear in the result (artist + title)
  local match_count=0
  local total_words=0
  local word
  for word in $(echo "$query_lower" | tr " " "\n"); do
    # Skip common words
    [[ "$word" == "the" || "$word" == "and" || "$word" == "a" || "$word" == "an" ]] && continue
    [[ "$word" == "feat" || "$word" == "featuring" || "$word" == "ft" ]] && continue
    [[ ${#word} -lt 3 ]] && continue

    ((total_words++))
    if [[ "$combined_result" == *"$word"* ]]; then
      ((match_count++))
    fi
  done

  # Require at least 50% of words to match, with a minimum of 2
  local min_matches=2
  local half_words=$(((total_words + 1) / 2)) # Round up
  [[ $half_words -gt $min_matches ]] && min_matches=$half_words
  [[ $total_words -lt 2 ]] && min_matches=$total_words

  if [[ $match_count -ge $min_matches ]]; then
    IO:debug "Metadata validation passed ($match_count/$total_words words, need $min_matches): artist='$artist' title='$title' matches query='$query'"
    return 0
  else
    IO:debug "Metadata validation failed ($match_count/$total_words words, need $min_matches): artist='$artist' title='$title' does NOT match query='$query'"
    return 1
  fi
}

function lookup_metadata() {
  # Try multiple services to find track metadata
  # Input: search query
  # Output: pipe-separated metadata string
  local query="$1"
  local result

  [[ -z "$query" ]] && echo "" && return 1

  IO:progress "Looking up metadata for: $query"

  # Try iTunes first (faster, better for recent releases)
  result=$(search_itunes "$query")
  if [[ -n "$result" ]]; then
    # Validate the result matches our query
    local artist title
    artist=$(echo "$result" | cut -d'|' -f2)
    title=$(echo "$result" | cut -d'|' -f3)
    if validate_metadata "$query" "$artist" "$title"; then
      echo "$result"
      return 0
    else
      IO:debug "iTunes result rejected: $artist - $title"
    fi
  fi

  # Fall back to MusicBrainz
  sleep 1 # Rate limiting
  result=$(search_musicbrainz "$query")
  if [[ -n "$result" ]]; then
    # Validate the result matches our query
    local artist title
    artist=$(echo "$result" | cut -d'|' -f2)
    title=$(echo "$result" | cut -d'|' -f3)
    if validate_metadata "$query" "$artist" "$title"; then
      echo "$result"
      return 0
    else
      IO:debug "MusicBrainz result rejected: $artist - $title"
    fi
  fi

  IO:debug "No valid metadata found for: $query"
  echo ""
  return 1
}

function tag_audio_file() {
  # Embed metadata into audio file using ffmpeg
  # Input: file_path, artist, title, album, year, genre, artwork_url, country, source_url, search_query
  local input_file="$1"
  local artist="$2"
  local title="$3"
  local album="$4"
  local year="$5"
  local genre="$6"
  local artwork_url="${7:-}"
  local country="${8:-}"
  local source_url="${9:-}"
  local search_query="${10:-}"

  [[ ! -f "$input_file" ]] && return 1

  Os:require ffmpeg

  local extension="${input_file##*.}"
  local output_file="${input_file%.*}_tagged.${extension}"
  local artwork_file=""
  [[ -n "$GENRE" ]] && genre="$GENRE"

  IO:debug "Tagging: $input_file"
  IO:debug "  Artist: $artist"
  IO:debug "  Title: $title"
  IO:debug "  Album: $album"
  IO:debug "  Year: $year"
  IO:debug "  Genre: $genre"
  IO:debug "  Country: $country"
  IO:debug "  Artwork: $artwork_url"
  IO:debug "  Source: $source_url"
  IO:debug "  Search: $search_query"

  artwork_file=""
  # Download artwork if URL provided
  if [[ -n "$artwork_url" ]]; then
    artwork_file=$(Os:tempfile jpg)
    IO:debug "Downloading artwork to: $artwork_file"
    if curl -s --max-time 10 -o "$artwork_file" "$artwork_url"; then
      IO:debug "Artwork downloaded successfully"
    fi
  else
    artwork_file=$(Os:tempfile jpg)
    splashmark -w 600 -c 600 -3 " " -e dark,pixel,grain -i "$title" -k "$artist" url "https://cataas.com/cat?$RANDOM" "$artwork_file"
    IO:debug "Random Artwork generated successfully"
  fi

  # Build ffmpeg metadata options
  local metadata_opts=()
  [[ -n "$artist" ]] && metadata_opts+=(-metadata "artist=$artist")
  [[ -n "$title" ]] && metadata_opts+=(-metadata "title=$title")
  [[ -n "$album" ]] && metadata_opts+=(-metadata "album=$album")
  [[ -n "$year" ]] && metadata_opts+=(-metadata "date=$year")
  [[ -n "$genre" ]] && metadata_opts+=(-metadata "genre=$genre")
  [[ -n "$country" ]] && metadata_opts+=(-metadata "country=$country")
  [[ -n "$source_url" ]] && metadata_opts+=(-metadata "comment=Source: $source_url")
  [[ -n "$search_query" ]] && metadata_opts+=(-metadata "description=$search_query")

  # Build ffmpeg command based on whether we have artwork
  if [[ -n "$artwork_file" ]] && [[ -f "$artwork_file" ]]; then
    # Embed artwork along with metadata
    # For MP3: use -i for artwork, map both streams, set disposition
    if [[ "$extension" == "mp3" ]]; then
      ffmpeg -hide_banner -i "$input_file" -i "$artwork_file" \
        -map 0:a -map 1:0 \
        -c:a copy -c:v:0 mjpeg \
        -id3v2_version 3 \
        -metadata:s:v title="Album cover" -metadata:s:v comment="Cover (front)" \
        "${metadata_opts[@]}" \
        -y "$output_file" 2>>"${log_media:-/dev/null}"
    else
      # For other formats (WAV, FLAC, etc.) - just add metadata without artwork
      ffmpeg -hide_banner -i "$input_file" -c copy "${metadata_opts[@]}" -y "$output_file" 2>>"${log_media:-/dev/null}"
    fi
  else
    # No artwork - just metadata
    ffmpeg -hide_banner -i "$input_file" -c copy "${metadata_opts[@]}" -y "$output_file" 2>>"${log_media:-/dev/null}"
  fi

  [[ -f "$artwork_file" ]] && rm "$artwork_file"

  if [[ -f "$output_file" ]]; then
    mv -f "$output_file" "$input_file"
    IO:debug "Tagged: $input_file"
    return 0
  else
    IO:debug "Tagging failed for: $input_file"
    return 1
  fi
}

function format_filename() {
  # Format filename from metadata: ArtistName_SongTitle.ext
  # Input: artist, title
  # Output: formatted filename (without extension)
  local artist="$1"
  local title="$2"

  # Clean up artist and title for filename
  # Remove special characters, replace spaces with nothing (CamelCase style)
  local clean_artist clean_title

  clean_artist=$(Str:title "$artist")
  IO:debug "Clean Artist: $clean_artist"
  clean_title=$(Str:title "$title")
  IO:debug "Clean Title : $clean_title"

  # Remove 'Mix' or 'Mixed' at the end of the title
  clean_title=$(echo "$clean_title" | sed 's/Mixed$//' | sed 's/Mix$//')

  echo "${clean_artist}_${clean_title}"
}

function generate_spectrogram() {
  # Generate a spectrogram image from an audio file
  # Input: audio_file path
  # Output: creates <basename>.spectro.jpg in the same folder
  local input_file="$1"
  local log_file="${2:-/dev/null}"

  [[ ! -f "$input_file" ]] && return 1

  Os:require ffmpeg

  local folder basename output_file
  folder=$(dirname "$input_file")
  basename=$(basename "$input_file")
  basename="${basename%.*}"
  output_file="$folder/${basename}.spectro.jpg"

  IO:debug "Generating spectrogram: $output_file"
  IO:log "Spectrogram: $input_file -> $output_file"

  # Generate spectrogram using ffmpeg showspectrumpic filter
  # - size: 1920x480 for a widescreen spectrogram
  # - mode: combined (shows full frequency spectrum)
  # - color: intensity (good contrast)
  ffmpeg -hide_banner -i "$input_file" \
    -lavfi "showspectrumpic=s=1920x480:mode=combined:color=intensity:scale=log" \
    -y "$output_file" 2>>"$log_file"

  if [[ -f "$output_file" ]]; then
    IO:debug "Spectrogram created: $output_file"
    echo "$output_file"
    return 0
  else
    IO:debug "Spectrogram generation failed for: $input_file"
    return 1
  fi
}

function cleanup_tracklist() {
  #  Input:
  #  1) 00:00 Saison - We Are The Machines ‪@nofussrecords6609‬
  #  2) 03:28 Kendricks (Saison Remix) - Local Options ‪@nofussrecords6609‬
  #  3) 08:36 Daniel Haze - Acid Nights (Don't Let Me Go) ‪@CandyFlipRecords‬
  #  4) 13:12 Queens - Romy Black, Husky ‪@nofussrecords6609‬
  #  5) 17:58 Mi Casa - Man Go Funk, Venessa Jackson ‪@DobarHouse‬
  #  6) 22:24 Heat Up The House - Mainline ‪@PleasedAsPunchMusic‬
  #  7) 26:22 Clap Your Hands - ColorJaxx ‪@nofussrecords6609‬
  #  8) 31:04 Eridu - Je M'en Fous ‪@Flipsight‬
  #  9) 35:17 Vertigini - Soul Thing ‪@dobrovinyl‬
  #  10) 40:00 Tom Wigley - Never Find Me (FT Edit) ‪@55_MUSIC‬
  #
  #  Output:
  #  Saison We Are The Machines
  #  Kendricks Saison Remix Local Options
  #  Daniel Haze Acid Nights Dont Let Me Go
  #  Queens Romy Black, Husky
  #  Mi Casa Man Go Funk, Venessa Jackson
  #  Heat Up The House Mainline
  #  Clap Your Hands ColorJaxx
  #  Eridu Je Men Fous
  #  Vertigini Soul Thing
  #  Tom Wigley Never Find Me FT Edit

  awk '
  {
    # Remove leading/trailing whitespace
    gsub(/^[ \t\r\n]+/, "", $0);
    gsub(/[ \t\r\n]+$/, "", $0);

    # Skip empty lines
    if (length($0) == 0) next;

    # Remove numbering at the beginning (e.g., "1)", "1.", "10)")
    gsub(/^[0-9]+[.)][ \t]*/, "", $0);

    # Remove timestamps (e.g., "00:00", "03:28", "1:23:45") and optional / after
    gsub(/^[0-9]+:[0-9]+(:[0-9]+)?[ \t]*\/?[ \t]*/, "", $0);

    # Remove YouTube handles (e.g., "@nofussrecords6609", "‪@nofussrecords6609‬")
    gsub(/[‪‬]*@[a-zA-Z0-9_]+[‪‬]*/, "", $0);

    # also remove strings between [] at the end of the line
    # e.g.  [Groove Culture] or [MONOSIDE]
    gsub(/\[[^\]]*\][ \t]*$/, "", $0);
    gsub(/\([^\)]*\)[ \t]*$/, "", $0);

    # Remove common special characters used in titles
    gsub(/[\(\),.]/, "", $0);

    # Clean up apostrophes
    gsub(/[''ʼ]/, "", $0);

    max_length=60
    # limit one line to max_length chars, but dont cut words in the middle
    # to avoid: Fahy & Sanchez - Disco Queen (Monkey Wrench Remix) - Unofficial Flavour Trip Edit (Alimish)
    if (length($0) > 0) {
        if (length($0) > max_length) {
            truncated = substr($0, 1, max_length);
            if (match(truncated, /.*[ ]/)) {
                $0 = substr(truncated, 1, RLENGTH - 1);
            } else {
                $0 = truncated;
            }
        }
        # Remove extra whitespace
        gsub(/[ \t]+/, " ", $0);
        gsub(/^[ \t]+/, "", $0);
        gsub(/[ \t]+$/, "", $0);
        print $0;
    }
  }' | tr -d "'"
}

#####################################################################
################### DO NOT MODIFY BELOW THIS LINE ###################
#####################################################################

# set strict mode -  via http://redsymbol.net/articles/unofficial-bash-strict-mode/
# removed -e because it made basic [[ testing ]] difficult
set -uo pipefail
IFS=$'\n\t'
force=0
help=0
error_prefix=""

#to enable verbose even before option parsing
verbose=0
[[ $# -gt 0 ]] && [[ $1 == "-v" ]] && verbose=1

#to enable quiet even before option parsing
quiet=0
[[ $# -gt 0 ]] && [[ $1 == "-q" ]] && quiet=1

### stdIO:print/stderr output
function IO:initialize() {
  [[ "${BASH_SOURCE[0]:-}" != "${0}" ]] && sourced=1 || sourced=0
  [[ -t 1 ]] && piped=0 || piped=1 # detect if output is piped
  if [[ $piped -eq 0 ]]; then
    txtReset=$(tput sgr0)
    txtError=$(tput setaf 160)
    txtInfo=$(tput setaf 2)
    txtWarn=$(tput setaf 214)
    txtBold=$(tput bold)
    txtItalic=$(tput sitm)
    txtUnderline=$(tput smul)
  else
    txtReset=""
    txtError=""
    txtInfo=""
    txtInfo=""
    txtWarn=""
    txtBold=""
    txtItalic=""
    txtUnderline=""
  fi

  local unicode
  [[ $(echo -e '\xe2\x82\xac') == '€' ]] && unicode=1 || unicode=0 # detect if unicode is supported
  if [[ $unicode -gt 0 ]]; then
    char_succes="✅"
    char_fail="⛔"
    char_alert="✴️"
    char_wait="⏳"
    info_icon="🌼"
    config_icon="🌱"
    clean_icon="🧽"
    require_icon="🔌"
  else
    char_succes="OK "
    char_fail="!! "
    char_alert="?? "
    char_wait="..."
    info_icon="(i)"
    config_icon="[c]"
    clean_icon="[c]"
    require_icon="[r]"
  fi
  error_prefix="${txtError}>${txtReset}"
}

function IO:print() {
  ((quiet)) && true || printf '%b\n' "$*"
}

function IO:debug() {
  ((verbose)) && IO:print "${txtInfo}# $* ${txtReset}" >&2
  true
}

function IO:die() {
  IO:print "${txtError}${char_fail} $script_basename${txtReset}: $*" >&2
  tput bel
  Script:exit
}

function IO:alert() {
  IO:print "${txtWarn}${char_alert}${txtReset}: ${txtUnderline}$*${txtReset}" >&2
}

function IO:success() {
  IO:print "${txtInfo}${char_succes}${txtReset}  ${txtBold}$*${txtReset}"
}

function IO:announce() {
  IO:print "${txtInfo}${char_wait}${txtReset}  ${txtItalic}$*${txtReset}"
  sleep 1
}

function IO:progress() {
  ((quiet)) || (
    local screen_width
    screen_width=$(tput cols 2>/dev/null || echo 80)
    local rest_of_line
    rest_of_line=$((screen_width - 5))

    if ((piped)); then
      IO:print "... $*" >&2
    else
      printf "... %-${rest_of_line}b\r" "$*                                             " >&2
    fi
  )
}

### interactive
function IO:confirm() {
  ((force)) && return 0
  read -r -p "$1 [y/N] " -n 1
  echo " "
  [[ $REPLY =~ ^[Yy]$ ]]
}

function IO:question() {
  local ANSWER
  local DEFAULT=${2:-}
  read -r -p "$1 ($DEFAULT) > " ANSWER
  [[ -z "$ANSWER" ]] && echo "$DEFAULT" || echo "$ANSWER"
}

function IO:log() {
  [[ -n "${log_file:-}" ]] && echo "$(date '+%H:%M:%S') | $*" >>"$log_file"
}

function Tool:calc() {
  awk "BEGIN {print $*} ; "
}

function Tool:time() {
  if [[ $(command -v perl) ]]; then
    perl -MTime::HiRes=time -e 'printf "%.3f\n", time'
  elif [[ $(command -v php) ]]; then
    php -r 'echo microtime(true) . "\n"; '
  elif [[ $(command -v python) ]]; then
    python -c "import time; print(time.time()) "
  else
    date "+%s" | awk '{printf("%.3f\n",$1)}'
  fi
}

### string processing

function Str:trim() {
  local var="$*"
  # remove leading whitespace characters
  var="${var#"${var%%[![:space:]]*}"}"
  # remove trailing whitespace characters
  var="${var%"${var##*[![:space:]]}"}"
  printf '%s' "$var"
}

function Str:lower() {
  if [[ -n "$1" ]]; then
    local input="$*"
    echo "${input,,}"
  else
    awk '{print tolower($0)}'
  fi
}

function Str:upper() {
  if [[ -n "$1" ]]; then
    local input="$*"
    echo "${input^^}"
  else
    awk '{print toupper($0)}'
  fi
}

function Str:ascii() {
  # remove all characters with accents/diacritics to latin alphabet
  # shellcheck disable=SC2020
  sed 'y/àáâäæãåāǎçćčèéêëēėęěîïííīįìǐłñńôöòóœøōǒõßśšûüǔùǖǘǚǜúūÿžźżÀÁÂÄÆÃÅĀǍÇĆČÈÉÊËĒĖĘĚÎÏÍÍĪĮÌǏŁÑŃÔÖÒÓŒØŌǑÕẞŚŠÛÜǓÙǕǗǙǛÚŪŸŽŹŻ/aaaaaaaaaccceeeeeeeeiiiiiiiilnnooooooooosssuuuuuuuuuuyzzzAAAAAAAAACCCEEEEEEEEIIIIIIIILNNOOOOOOOOOSSSUUUUUUUUUUYZZZ/'
}

function Str:slugify() {
  # Str:slugify <input> <separator>
  # Str:slugify "Jack, Jill & Clémence LTD"      => jack-jill-clemence-ltd
  # Str:slugify "Jack, Jill & Clémence LTD" "_"  => jack_jill_clemence_ltd
  separator="${2:-}"
  [[ -z "$separator" ]] && separator="-"
  Str:lower "$1" |
    Str:ascii |
    awk '{
          gsub(/[\[\]@#$%^&*;,.:()<>!?\/+=_]/," ",$0);
          gsub(/^  */,"",$0);
          gsub(/  *$/,"",$0);
          gsub(/  */,"-",$0);
          gsub(/[^a-z0-9\-]/,"");
          print;
          }' |
    sed "s/-/$separator/g"
}

function Str:title() {
  # Str:title <input> <separator>
  # Str:title "Jack, Jill & Clémence LTD"     => JackJillClemenceLtd
  # Str:title "Jack, Jill & Clémence LTD" "_" => Jack_Jill_Clemence_Ltd
  separator="${2:-}"
  # shellcheck disable=SC2020
  Str:lower "$1" |
    tr 'àáâäæãåāçćčèéêëēėęîïííīįìłñńôöòóœøōõßśšûüùúūÿžźż' 'aaaaaaaaccceeeeeeeiiiiiiilnnoooooooosssuuuuuyzzz' |
    awk '{ gsub(/[\[\]@#$%^&*;,.:()<>!?\/+=_"'"'"'-]/," ",$0); print $0; }' |
    awk '{
          for (i=1; i<=NF; ++i) {
              $i = toupper(substr($i,1,1)) tolower(substr($i,2))
          };
          print $0;
          }' |
    sed "s/ /$separator/g" |
    cut -c1-50
}

function Str:digest() {
  local length=${1:-6}
  if [[ -n $(command -v md5sum) ]]; then
    # regular linux
    md5sum | cut -c1-"$length"
  else
    # macos
    md5 | cut -c1-"$length"
  fi
}

trap "IO:die \"ERROR \$? after \$SECONDS seconds \n\
\${error_prefix} last command : '\$BASH_COMMAND' \" \
\$(< \$script_install_path awk -v lineno=\$LINENO \
'NR == lineno {print \"\${error_prefix} from line \" lineno \" : \" \$0}')" INT TERM EXIT
# cf https://askubuntu.com/questions/513932/what-is-the-bash-command-variable-good-for

Script:exit() {
  local temp_file
  for temp_file in "${temp_files[@]}"; do
    [[ -f "$temp_file" ]] && (
      IO:debug "Delete temp file [$temp_file]"
      rm -f "$temp_file"
    )
  done
  trap - INT TERM EXIT
  IO:debug "$script_basename finished after $SECONDS seconds"
  exit 0
}

Script:check_version() {
  (
    # shellcheck disable=SC2164
    pushd "$script_install_folder" &>/dev/null
    if [[ -d .git ]]; then
      local remote
      remote="$(git remote -v | grep fetch | awk 'NR == 1 {print $2}')"
      IO:progress "Check for latest version - $remote"
      git remote update &>/dev/null
      if [[ $(git rev-list --count "HEAD...HEAD@{upstream}" 2>/dev/null) -gt 0 ]]; then
        IO:print "There is a more recent update of this script - run <<$script_prefix update>> to update"
      fi
    fi
    # shellcheck disable=SC2164
    popd &>/dev/null
  )
}

Script:git_pull() {
  # run in background to avoid problems with modifying a running interpreted script
  (
    sleep 1
    cd "$script_install_folder" && git pull
  ) &
}

Script:show_tips() {
  ((sourced)) && return 0
  # shellcheck disable=SC2016
  grep <"${BASH_SOURCE[0]}" -v '$0' |
    awk \
      -v green="$txtInfo" \
      -v yellow="$txtWarn" \
      -v reset="$txtReset" \
      '
      /TIP: /  {$1=""; gsub(/«/,green); gsub(/»/,reset); print "*" $0}
      /TIP:> / {$1=""; print " " yellow $0 reset}
      ' |
    awk \
      -v script_basename="$script_basename" \
      -v script_prefix="$script_prefix" \
      '{
      gsub(/\$script_basename/,script_basename);
      gsub(/\$script_prefix/,script_prefix);
      print ;
      }'
}

Script:check() {
  if [[ -n $(Option:filter flag) ]]; then
    IO:print "## ${txtInfo}boolean flags${txtReset}:"
    Option:filter flag |
      while read -r name; do
        if ((piped)); then
          eval "echo \"$name=\$${name:-}\""
        else
          eval "echo -n \"$name=\$${name:-}  \""
        fi
      done
    IO:print " "
    IO:print " "
  fi

  if [[ -n $(Option:filter option) ]]; then
    IO:print "## ${txtInfo}option defaults${txtReset}:"
    Option:filter option |
      while read -r name; do
        if ((piped)); then
          eval "echo \"$name=\$${name:-}\""
        else
          eval "echo -n \"$name=\$${name:-}  \""
        fi
      done
    IO:print " "
    IO:print " "
  fi

  if [[ -n $(Option:filter list) ]]; then
    IO:print "## ${txtInfo}list options${txtReset}:"
    Option:filter list |
      while read -r name; do
        if ((piped)); then
          eval "echo \"$name=(\${${name}[@]})\""
        else
          eval "echo -n \"$name=(\${${name}[@]})  \""
        fi
      done
    IO:print " "
    IO:print " "
  fi

  if [[ -n $(Option:filter param) ]]; then
    if ((piped)); then
      IO:debug "Skip parameters for .env files"
    else
      IO:print "## ${txtInfo}parameters${txtReset}:"
      Option:filter param |
        while read -r name; do
          # shellcheck disable=SC2015
          ((piped)) && eval "echo \"$name=\\\"\${$name:-}\\\"\"" || eval "echo -n \"$name=\\\"\${$name:-}\\\"  \""
        done
      echo " "
    fi
    IO:print " "
  fi

  if [[ -n $(Option:filter choice) ]]; then
    if ((piped)); then
      IO:debug "Skip choices for .env files"
    else
      IO:print "## ${txtInfo}choice${txtReset}:"
      Option:filter choice |
        while read -r name; do
          # shellcheck disable=SC2015
          ((piped)) && eval "echo \"$name=\\\"\${$name:-}\\\"\"" || eval "echo -n \"$name=\\\"\${$name:-}\\\"  \""
        done
      echo " "
    fi
    IO:print " "
  fi

  IO:print "## ${txtInfo}required commands${txtReset}:"
  Script:show_required
}

Option:usage() {
  IO:print "Program : ${txtInfo}$script_basename${txtReset}  by ${txtWarn}$script_author${txtReset}"
  IO:print "Version : ${txtInfo}v$script_version${txtReset} (${txtWarn}$script_modified${txtReset})"
  IO:print "Purpose : ${txtInfo}Download audio (YouTube/Soundcloud/...) and split into stems${txtReset}"
  echo -n "Usage   : $script_basename"
  Option:config |
    awk '
  BEGIN { FS="|"; OFS=" "; one_line="" ; fulltext="Flags, options and parameters:"}
  $1 ~ /flag/  {
    fulltext = fulltext sprintf("\n    -%1s|--%-12s: [flag] %s [default: off]",$2,$3,$4) ;
    one_line  = one_line " [-" $2 "]"
    }
  $1 ~ /option/  {
    fulltext = fulltext sprintf("\n    -%1s|--%-12s: [option] %s",$2,$3 " <?>",$4) ;
    if($5!=""){fulltext = fulltext "  [default: " $5 "]"; }
    one_line  = one_line " [-" $2 " <" $3 ">]"
    }
  $1 ~ /list/  {
    fulltext = fulltext sprintf("\n    -%1s|--%-12s: [list] %s (array)",$2,$3 " <?>",$4) ;
    fulltext = fulltext "  [default empty]";
    one_line  = one_line " [-" $2 " <" $3 ">]"
    }
  $1 ~ /secret/  {
    fulltext = fulltext sprintf("\n    -%1s|--%s <%s>: [secret] %s",$2,$3,"?",$4) ;
      one_line  = one_line " [-" $2 " <" $3 ">]"
    }
  $1 ~ /param/ {
    if($2 == "1"){
          fulltext = fulltext sprintf("\n    %-17s: [parameter] %s","<"$3">",$4);
          one_line  = one_line " <" $3 ">"
     }
     if($2 == "?"){
          fulltext = fulltext sprintf("\n    %-17s: [parameter] %s (optional)","<"$3">",$4);
          one_line  = one_line " <" $3 "?>"
     }
     if($2 == "n"){
          fulltext = fulltext sprintf("\n    %-17s: [parameters] %s (1 or more)","<"$3">",$4);
          one_line  = one_line " <" $3 " …>"
     }
    }
  $1 ~ /choice/ {
        fulltext = fulltext sprintf("\n    %-17s: [choice] %s","<"$3">",$4);
        if($5!=""){fulltext = fulltext "  [options: " $5 "]"; }
        one_line  = one_line " <" $3 ">"
    }
    END {print one_line; print fulltext}
  '
}

function Option:filter() {
  Option:config | grep "$1|" | cut -d'|' -f3 | sort | grep -v '^\s*$'
}

function Script:show_required() {
  grep 'Os:require' "$script_install_path" |
    grep -v -E '\(\)|grep|# Os:require' |
    awk -v install="# $install_package " '
    function ltrim(s) { sub(/^[ "\t\r\n]+/, "", s); return s }
    function rtrim(s) { sub(/[ "\t\r\n]+$/, "", s); return s }
    function trim(s) { return rtrim(ltrim(s)); }
    NF == 2 {print install trim($2); }
    NF == 3 {print install trim($3); }
    NF > 3  {$1=""; $2=""; $0=trim($0); print "# " trim($0);}
  ' |
    sort -u
}

function Option:initialize() {
  local init_command
  init_command=$(Option:config |
    grep -v "verbose|" |
    awk '
    BEGIN { FS="|"; OFS=" ";}
    $1 ~ /flag/   && $5 == "" {print $3 "=0; "}
    $1 ~ /flag/   && $5 != "" {print $3 "=\"" $5 "\"; "}
    $1 ~ /option/ && $5 == "" {print $3 "=\"\"; "}
    $1 ~ /option/ && $5 != "" {print $3 "=\"" $5 "\"; "}
    $1 ~ /choice/   {print $3 "=\"\"; "}
    $1 ~ /list/     {print $3 "=(); "}
    $1 ~ /secret/   {print $3 "=\"\"; "}
    ')
  if [[ -n "$init_command" ]]; then
    eval "$init_command"
  fi
}

function Option:has_single() { Option:config | grep 'param|1|' >/dev/null; }
function Option:has_choice() { Option:config | grep 'choice|1' >/dev/null; }
function Option:has_optional() { Option:config | grep 'param|?|' >/dev/null; }
function Option:has_multi() { Option:config | grep 'param|n|' >/dev/null; }

function Option:parse() {
  if [[ $# -eq 0 ]]; then
    Option:usage >&2
    Script:exit
  fi

  ## first process all the -x --xxxx flags and options
  while true; do
    # flag <flag> is saved as $flag = 0/1
    # option <option> is saved as $option
    if [[ $# -eq 0 ]]; then
      ## all parameters processed
      break
    fi
    if [[ ! $1 == -?* ]]; then
      ## all flags/options processed
      break
    fi
    local save_option
    save_option=$(Option:config |
      awk -v opt="$1" '
        BEGIN { FS="|"; OFS=" ";}
        $1 ~ /flag/   &&  "-"$2 == opt {print $3"=1"}
        $1 ~ /flag/   && "--"$3 == opt {print $3"=1"}
        $1 ~ /option/ &&  "-"$2 == opt {print $3"=$2; shift"}
        $1 ~ /option/ && "--"$3 == opt {print $3"=$2; shift"}
        $1 ~ /list/ &&  "-"$2 == opt {print $3"+=($2); shift"}
        $1 ~ /list/ && "--"$3 == opt {print $3"=($2); shift"}
        $1 ~ /secret/ &&  "-"$2 == opt {print $3"=$2; shift #noshow"}
        $1 ~ /secret/ && "--"$3 == opt {print $3"=$2; shift #noshow"}
        ')
    if [[ -n "$save_option" ]]; then
      if echo "$save_option" | grep shift >>/dev/null; then
        local save_var
        save_var=$(echo "$save_option" | cut -d= -f1)
        IO:debug "$config_icon parameter: ${save_var}=$2"
      else
        IO:debug "$config_icon flag: $save_option"
      fi
      eval "$save_option"
    else
      IO:die "cannot interpret option [$1]"
    fi
    shift
  done

  ((help)) && (
    Option:usage
    Script:check_version
    IO:print "                                  "
    echo "### TIPS & EXAMPLES"
    Script:show_tips

  ) && Script:exit

  local option_list
  local option_count
  local choices
  local single_params
  ## then run through the given parameters
  if Option:has_choice; then
    choices=$(Option:config | awk -F"|" '
      $1 == "choice" && $2 == 1 {print $3}
      ')
    option_list=$(xargs <<<"$choices")
    option_count=$(wc <<<"$choices" -w | xargs)
    IO:debug "$config_icon Expect : $option_count choice(s): $option_list"
    [[ $# -eq 0 ]] && IO:die "need the choice(s) [$option_list]"

    local choices_list
    local valid_choice
    local param
    for param in $choices; do
      [[ $# -eq 0 ]] && IO:die "need choice [$param]"
      [[ -z "$1" ]] && IO:die "need choice [$param]"
      IO:debug "$config_icon Assign : $param=$1"
      # check if choice is in list
      choices_list=$(Option:config | awk -F"|" -v choice="$param" '$1 == "choice" && $3 = choice {print $5}')
      valid_choice=$(tr <<<"$choices_list" "," "\n" | grep "$1")
      [[ -z "$valid_choice" ]] && IO:die "choice [$1] is not valid, should be in list [$choices_list]"

      eval "$param=\"$1\""
      shift
    done
  else
    IO:debug "$config_icon No choices to process"
    choices=""
    option_count=0
  fi

  if Option:has_single; then
    single_params=$(Option:config | awk -F"|" '
      $1 == "param" && $2 == 1 {print $3}
      ')
    option_list=$(xargs <<<"$single_params")
    option_count=$(wc <<<"$single_params" -w | xargs)
    IO:debug "$config_icon Expect : $option_count single parameter(s): $option_list"
    [[ $# -eq 0 ]] && IO:die "need the parameter(s) [$option_list]"

    for param in $single_params; do
      [[ $# -eq 0 ]] && IO:die "need parameter [$param]"
      [[ -z "$1" ]] && IO:die "need parameter [$param]"
      IO:debug "$config_icon Assign : $param=$1"
      eval "$param=\"$1\""
      shift
    done
  else
    IO:debug "$config_icon No single params to process"
    single_params=""
    option_count=0
  fi

  if Option:has_optional; then
    local optional_params
    local optional_count
    optional_params=$(Option:config | grep 'param|?|' | cut -d'|' -f3)
    optional_count=$(wc <<<"$optional_params" -w | xargs)
    IO:debug "$config_icon Expect : $optional_count optional parameter(s): $(echo "$optional_params" | xargs)"

    for param in $optional_params; do
      IO:debug "$config_icon Assign : $param=${1:-}"
      eval "$param=\"${1:-}\""
      shift
    done
  else
    IO:debug "$config_icon No optional params to process"
    optional_params=""
    optional_count=0
  fi

  if Option:has_multi; then
    #IO:debug "Process: multi param"
    local multi_count
    local multi_param
    multi_count=$(Option:config | grep -c 'param|n|')
    multi_param=$(Option:config | grep 'param|n|' | cut -d'|' -f3)
    IO:debug "$config_icon Expect : $multi_count multi parameter: $multi_param"
    ((multi_count > 1)) && IO:die "cannot have >1 'multi' parameter: [$multi_param]"
    ((multi_count > 0)) && [[ $# -eq 0 ]] && IO:die "need the (multi) parameter [$multi_param]"
    # save the rest of the params in the multi param
    if [[ -n "$*" ]]; then
      IO:debug "$config_icon Assign : $multi_param=$*"
      eval "$multi_param=( $* )"
    fi
  else
    multi_count=0
    multi_param=""
    [[ $# -gt 0 ]] && IO:die "cannot interpret extra parameters"
  fi
}

function Os:require() {
  local install_instructions
  local binary
  local words
  local path_binary
  # $1 = binary that is required
  binary="$1"
  path_binary=$(command -v "$binary" 2>/dev/null)
  [[ -n "$path_binary" ]] && IO:debug "️$require_icon required [$binary] -> $path_binary" && return 0
  # $2 = how to install it
  words=$(echo "${2:-}" | wc -w)
  if ((force)); then
    IO:announce "Installing [$1] ..."
    case $words in
    0) eval "$install_package $1" ;;
      # Os:require ffmpeg -- binary and package have the same name
    1) eval "$install_package $2" ;;
      # Os:require convert imagemagick -- binary and package have different names
    *) eval "${2:-}" ;;
      # Os:require primitive "go get -u github.com/fogleman/primitive" -- non-standard package manager
    esac
  else
    install_instructions="$install_package $1"
    [[ $words -eq 1 ]] && install_instructions="$install_package $2"
    [[ $words -gt 1 ]] && install_instructions="${2:-}"

    IO:alert "$script_basename needs [$binary] but it cannot be found"
    IO:alert "1) install package  : $install_instructions"
    IO:alert "2) check path       : export PATH=\"[path of your binary]:\$PATH\""
    IO:die "Missing program/script [$binary]"
  fi
}

function Os:folder() {
  if [[ -n "$1" ]]; then
    local folder="$1"
    local max_days=${2:-365}
    if [[ ! -d "$folder" ]]; then
      IO:debug "$clean_icon Create folder : [$folder]"
      mkdir -p "$folder"
    else
      IO:debug "$clean_icon Cleanup folder: [$folder] - delete files older than $max_days day(s)"
      find "$folder" -mtime "+$max_days" -type f -exec rm {} \;
    fi
  fi
}

function Os:follow_link() {
  [[ ! -L "$1" ]] && echo "$1" && return 0
  local file_folder
  local link_folder
  local link_name
  file_folder="$(dirname "$1")"
  # resolve relative to absolute path
  [[ "$file_folder" != /* ]] && link_folder="$(cd -P "$file_folder" &>/dev/null && pwd)"
  local symlink
  symlink=$(readlink "$1")
  link_folder=$(dirname "$symlink")
  link_name=$(basename "$symlink")
  [[ -z "$link_folder" ]] && link_folder="$file_folder"
  [[ "$link_folder" == \.* ]] && link_folder="$(cd -P "$file_folder" && cd -P "$link_folder" &>/dev/null && pwd)"
  IO:debug "$info_icon Symbolic ln: $1 -> [$symlink]"
  Os:follow_link "$link_folder/$link_name"
}

function Os:notify() {
  # cf https://levelup.gitconnected.com/5-modern-bash-scripting-techniques-that-only-a-few-programmers-know-4abb58ddadad
  local message="$1"
  local source="${2:-$script_basename}"

  [[ -n $(command -v notify-send) ]] && notify-send "$source" "$message"                                      # for Linux
  [[ -n $(command -v osascript) ]] && osascript -e "display notification \"$message\" with title \"$source\"" # for MacOS
}

function Os:busy() {
  # show spinner as long as process $pid is running
  local pid="$1"
  local message="${2:-}"
  local frames=("|" "/" "-" "\\")
  (
    while kill -0 "$pid" &>/dev/null; do
      for frame in "${frames[@]}"; do
        printf "\r[ $frame ] %s..." "$message"
        sleep 0.5
      done
    done
    printf "\n"
  )
}

function Os:beep() {
  local type="${1=-info}"
  case $type in
  *)
    tput bel
    ;;
  esac
}

function Script:meta() {
  local git_repo_remote=""
  local git_repo_root=""
  local os_kernel=""
  local os_machine=""
  local os_name=""
  local os_version=""
  local script_hash="?"
  local script_lines="?"
  local shell_brand=""
  local shell_version=""

  script_prefix=$(basename "${BASH_SOURCE[0]}" .sh)
  script_basename=$(basename "${BASH_SOURCE[0]}")
  execution_day=$(date "+%Y-%m-%d")

  script_install_path="${BASH_SOURCE[0]}"
  IO:debug "$info_icon Script path: $script_install_path"
  script_install_path=$(Os:follow_link "$script_install_path")
  IO:debug "$info_icon Linked path: $script_install_path"
  script_install_folder="$(cd -P "$(dirname "$script_install_path")" && pwd)"
  IO:debug "$info_icon In folder  : $script_install_folder"
  if [[ -f "$script_install_path" ]]; then
    script_hash=$(Str:digest <"$script_install_path" 8)
    script_lines=$(awk <"$script_install_path" 'END {print NR}')
  fi

  # get shell/operating system/versions
  shell_brand="sh"
  shell_version="?"
  [[ -n "${ZSH_VERSION:-}" ]] && shell_brand="zsh" && shell_version="$ZSH_VERSION"
  [[ -n "${BASH_VERSION:-}" ]] && shell_brand="bash" && shell_version="$BASH_VERSION"
  [[ -n "${FISH_VERSION:-}" ]] && shell_brand="fish" && shell_version="$FISH_VERSION"
  [[ -n "${KSH_VERSION:-}" ]] && shell_brand="ksh" && shell_version="$KSH_VERSION"
  IO:debug "$info_icon Shell type : $shell_brand - version $shell_version"

  os_kernel=$(uname -s)
  os_version=$(uname -r)
  os_machine=$(uname -m)
  install_package=""
  case "$os_kernel" in
  CYGWIN* | MSYS* | MINGW*)
    os_name="Windows"
    ;;
  Darwin)
    os_name=$(sw_vers -productName)       # macOS
    os_version=$(sw_vers -productVersion) # 11.1
    install_package="brew install"
    ;;
  Linux | GNU*)
    if [[ $(command -v lsb_release) ]]; then
      # 'normal' Linux distributions
      os_name=$(lsb_release -i | awk -F: '{$1=""; gsub(/^[\s\t]+/,"",$2); gsub(/[\s\t]+$/,"",$2); print $2}')    # Ubuntu/Raspbian
      os_version=$(lsb_release -r | awk -F: '{$1=""; gsub(/^[\s\t]+/,"",$2); gsub(/[\s\t]+$/,"",$2); print $2}') # 20.04
    else
      # Synology, QNAP,
      os_name="Linux"
    fi
    [[ -x /bin/apt-cyg ]] && install_package="apt-cyg install"     # Cygwin
    [[ -x /bin/dpkg ]] && install_package="dpkg -i"                # Synology
    [[ -x /opt/bin/ipkg ]] && install_package="ipkg install"       # Synology
    [[ -x /usr/sbin/pkg ]] && install_package="pkg install"        # BSD
    [[ -x /usr/bin/pacman ]] && install_package="pacman -S"        # Arch Linux
    [[ -x /usr/bin/zypper ]] && install_package="zypper install"   # Suse Linux
    [[ -x /usr/bin/emerge ]] && install_package="emerge"           # Gentoo
    [[ -x /usr/bin/yum ]] && install_package="yum install"         # RedHat RHEL/CentOS/Fedora
    [[ -x /usr/bin/apk ]] && install_package="apk add"             # Alpine
    [[ -x /usr/bin/apt-get ]] && install_package="apt-get install" # Debian
    [[ -x /usr/bin/apt ]] && install_package="apt install"         # Ubuntu
    ;;

  esac
  IO:debug "$info_icon System OS  : $os_name ($os_kernel) $os_version on $os_machine"
  IO:debug "$info_icon Package mgt: $install_package"

  # get last modified date of this script
  script_modified="??"
  [[ "$os_kernel" == "Linux" ]] && script_modified=$(stat -c %y "$script_install_path" 2>/dev/null | cut -c1-16) # generic linux
  [[ "$os_kernel" == "Darwin" ]] && script_modified=$(stat -f "%Sm" "$script_install_path" 2>/dev/null)          # for MacOS

  IO:debug "$info_icon Version  : $script_version"
  IO:debug "$info_icon Created  : $script_created"
  IO:debug "$info_icon Modified : $script_modified"

  IO:debug "$info_icon Lines    : $script_lines lines / md5: $script_hash"
  IO:debug "$info_icon User     : $USER@$HOSTNAME"

  # if run inside a git repo, detect for which remote repo it is
  if git status &>/dev/null; then
    git_repo_remote=$(git remote -v | awk '/(fetch)/ {print $2}')
    IO:debug "$info_icon git remote : $git_repo_remote"
    git_repo_root=$(git rev-parse --show-toplevel)
    IO:debug "$info_icon git folder : $git_repo_root"
  fi

  # get script version from VERSION.md file - which is automatically updated by pforret/setver
  [[ -f "$script_install_folder/VERSION.md" ]] && script_version=$(cat "$script_install_folder/VERSION.md")
  # get script version from git tag file - which is automatically updated by pforret/setver
  [[ -n "$git_repo_root" ]] && [[ -n "$(git tag &>/dev/null)" ]] && script_version=$(git tag --sort=version:refname | tail -1)
}

function Script:initialize() {
  log_file=""
  if [[ -n "${tmp_dir:-}" ]]; then
    # clean up TMP folder after 1 day
    Os:folder "$tmp_dir" 1
  fi
  if [[ -n "${log_dir:-}" ]]; then
    Os:folder "$log_dir" 30
    log_file="$log_dir/$script_prefix.$execution_day.log"
    IO:debug "$config_icon log_file: $log_file"
  fi
}

function Os:tempfile() {
  local extension=${1:-txt}
  local file="${tmp_dir:-/tmp}/$execution_day.$RANDOM.$extension"
  IO:debug "$config_icon tmp_file: $file"
  temp_files+=("$file")
  echo "$file"
}

function Os:import_env() {
  local env_files
  env_files=(
    "$script_install_folder/.env"
    "$script_install_folder/.$script_prefix.env"
    "$script_install_folder/$script_prefix.env"
    "./.env"
    "./.$script_prefix.env"
    "./$script_prefix.env"
  )

  local env_file
  for env_file in "${env_files[@]}"; do
    if [[ -f "$env_file" ]]; then
      IO:debug "$config_icon Read  dotenv: [$env_file]"
      local clean_file
      clean_file=$(Os:clean_env "$env_file")
      # shellcheck disable=SC1090
      source "$clean_file" && rm "$clean_file"
    fi
  done
}

function Os:clean_env() {
  local input="$1"
  local output="$1.__.sh"
  [[ ! -f "$input" ]] && IO:die "Input file [$input] does not exist"
  IO:debug "$clean_icon Clean dotenv: [$output]"
  awk <"$input" '
      function ltrim(s) { sub(/^[ \t\r\n]+/, "", s); return s }
      function rtrim(s) { sub(/[ \t\r\n]+$/, "", s); return s }
      function trim(s) { return rtrim(ltrim(s)); }
      /=/ { # skip lines with no equation
        $0=trim($0);
        if(substr($0,1,1) != "#"){ # skip comments
          equal=index($0, "=");
          key=trim(substr($0,1,equal-1));
          val=trim(substr($0,equal+1));
          if(match(val,/^".*"$/) || match(val,/^\047.*\047$/)){
            print key "=" val
          } else {
            print key "=\"" val "\""
          }
        }
      }
  ' >"$output"
  echo "$output"
}

IO:initialize # output settings
Script:meta   # find installation folder

[[ $run_as_root == 1 ]] && [[ $UID -ne 0 ]] && IO:die "user is $USER, MUST be root to run [$script_basename]"
[[ $run_as_root == -1 ]] && [[ $UID -eq 0 ]] && IO:die "user is $USER, CANNOT be root to run [$script_basename]"

Option:initialize # set default values for flags & options
Os:import_env     # overwrite with .env if any

if [[ $sourced -eq 0 ]]; then
  Option:parse "$@" # overwrite with specified options if any
  Script:initialize # clean up folders
  Script:main       # run Script:main program
  Script:exit       # exit and clean up
else
  # just disable the trap, don't execute Script:main
  trap - INT TERM EXIT
fi
