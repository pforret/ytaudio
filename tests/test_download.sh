#!/usr/bin/env bash
# test functions should start with test_
# using https://github.com/pgrange/bash_unit
#  fail
#  assert
#  assert "test -e /tmp/the_file"
#  assert_fails "grep this /tmp/the_file" "should not write 'this' in /tmp/the_file"
#  assert_status_code 25 code
#  assert_equals "a string" "another string" "a string should be another string"
#  assert_not_equals "a string" "a string" "a string should be different from another string"
#  fake ps echo hello world

root_folder=$(cd .. && pwd) # tests/.. is root folder
# shellcheck disable=SC2012
# shellcheck disable=SC2035
root_script=$(find "$root_folder" -maxdepth 1 -name "*.sh" | head -1) # normally there should be only 1
[[ -z "$(command -v python3)" ]] && sudo apt -q install python3
[[ -z "$(command -v ffmpeg)" ]] && sudo apt -q install ffmpeg
[[ -z "$(command -v yt-dlp)" ]] && python3 -m pip install -U yt-dlp
fi


test_download_youtube() {
  # script without parameters should give usage info
  local output_file
  output_file="$("$root_script" --FORMAT wav --OUT_DIR ../temp --SPLITTER "" get "https://www.youtube.com/watch?v=XEjLoHdbVeE")"
  assert_equals "../temp/ABBA_-_Gimme_Gimme_Gimme_A_Man_After_Midnight.210s.wav" "$output_file"
  assert_equals 40235618 "$(< "$output_file" wc -c | awk '{print $1}')"
}

test_download_soundcloud() {
  # script without parameters should give usage info
  local output_file
  output_file="$("$root_script" --FORMAT wav --OUT_DIR ../temp --SPLITTER "" get "https://soundcloud.com/kaytranada/janet-jackson-if-kaytranada")"
  assert_equals "../temp/Janet_Jackson_-_If_Kaytranada_Remix.237.819s.wav" "$output_file"
  assert_equals 41946794 "$(< "$output_file" wc -c | awk '{print $1}')"
}

test_download_mixcloud() {
  # script without parameters should give usage info
  local output_file
  output_file="$("$root_script" --FORMAT wav --OUT_DIR ../temp --SPLITTER "" get "https://www.mixcloud.com/djsupermarkt_tooslowtd/minimix-for-tstd-edits-10-those-guys-from-athens-limited-colored-double-7/")"
  assert_equals "../temp/Minimix_for_TSTD_EDITS_10_-_Those_Guys_From_Athens_Limited_colored_Double_7.394s.wav" "$output_file"
  assert_equals 69513294 "$(< "$output_file" wc -c | awk '{print $1}')"
}

test_download_apple_podcast() {
  # script without parameters should give usage info
  local output_file
  output_file="$("$root_script" --FORMAT wav --OUT_DIR ../temp --SPLITTER "" get "https://podcasts.apple.com/us/podcast/hearing-aids-by-roddy-doyle/id1281767970?i=1000632032467")"
  assert_equals "../temp/Hearing_Aids_by_Roddy_Doyle.852s.wav" "$output_file"
  assert_equals 150460628 "$(< "$output_file" wc -c | awk '{print $1}')"
}

