#!/usr/bin/env bash

# Test suite for cleanup_tracklist() function
# Run with: ./tests/run_tests.sh

# Helper function to test cleanup_tracklist via the script
test_cleanup() {
  local input="$1"
  echo "$input" | ../ytaudio.sh trackfilter 2>/dev/null
}

#####################################################################
# Tests for numbering removal
#####################################################################

test_cleanup_removes_numbering_with_parenthesis() {
  local input="1) 00:00 Saison - We Are The Machines"
  local actual=$(test_cleanup "$input")
  # Should remove "1) 00:00" prefix, preserve dash
  assert_equals "Saison - We Are The Machines" "$actual"
}

test_cleanup_removes_numbering_with_dot() {
  local input="1. 00:00 It Starts With Us - Artist Name"
  local actual=$(test_cleanup "$input")
  assert_equals "It Starts With Us - Artist Name" "$actual"
}

test_cleanup_removes_double_digit_numbering() {
  local input="10) 40:00 Tom Wigley - Never Find Me"
  local actual=$(test_cleanup "$input")
  assert_equals "Tom Wigley - Never Find Me" "$actual"
}

#####################################################################
# Tests for timestamp with slash removal
#####################################################################

test_cleanup_removes_timestamp_with_slash() {
  local input="1. 00:00 / It Starts With Us - Artist Name"
  local actual=$(test_cleanup "$input")
  assert_equals "It Starts With Us - Artist Name" "$actual"
}

test_cleanup_removes_long_timestamp() {
  local input="1:23:45 Long Track - Artist Name"
  local actual=$(test_cleanup "$input")
  assert_equals "Long Track - Artist Name" "$actual"
}

#####################################################################
# Tests for YouTube handle removal
#####################################################################

test_cleanup_removes_youtube_handle() {
  local input="Saison - We Are The Machines @nofussrecords6609"
  local actual=$(test_cleanup "$input")
  assert_equals "Saison - We Are The Machines" "$actual"
}

#####################################################################
# Tests for trailing bracket removal
#####################################################################

test_cleanup_removes_trailing_brackets() {
  local input="Track Name [MONOSIDE]"
  local actual=$(test_cleanup "$input")
  assert_equals "Track Name" "$actual"
}

test_cleanup_removes_trailing_parentheses() {
  local input="Track Name (Label)"
  local actual=$(test_cleanup "$input")
  assert_equals "Track Name" "$actual"
}

#####################################################################
# Tests for special character removal
#####################################################################

test_cleanup_removes_commas() {
  local input="Mi Casa - Man Go Funk, Venessa Jackson"
  local actual=$(test_cleanup "$input")
  # Commas are removed by gsub
  assert_equals "Mi Casa - Man Go Funk Venessa Jackson" "$actual"
}

test_cleanup_removes_apostrophes() {
  local input="Je M'en Fous"
  local actual=$(test_cleanup "$input")
  # Apostrophes are removed
  assert_equals "Je Men Fous" "$actual"
}

#####################################################################
# Tests for length truncation
#####################################################################

test_cleanup_truncates_long_lines() {
  # max_length is set to 60 in the function
  local input="This Is A Very Long Track Name That Should Be Truncated Because It Exceeds Maximum"
  local actual=$(test_cleanup "$input")
  local length=${#actual}
  assert "[ $length -le 60 ]" "Track length should be <= 60, got $length"
}

#####################################################################
# Tests for combined scenarios
#####################################################################

test_cleanup_full_tracklist_line() {
  local input="1) 00:00 Saison - We Are The Machines @nofussrecords6609"
  local actual=$(test_cleanup "$input")
  assert_equals "Saison - We Are The Machines" "$actual"
}

test_cleanup_complex_with_remix() {
  local input="2) 03:28 Kendricks (Saison Remix) - Local Options @channel"
  local actual=$(test_cleanup "$input")
  # Parentheses are removed
  assert_equals "Kendricks Saison Remix - Local Options" "$actual"
}

test_cleanup_dot_slash_format() {
  local input="1. 00:00 / It Starts With Us - Beaten Soul"
  local actual=$(test_cleanup "$input")
  assert_equals "It Starts With Us - Beaten Soul" "$actual"
}

#####################################################################
# Tests for edge cases
#####################################################################

test_cleanup_preserves_ampersand() {
  local input="Artist1 & Artist2 - Track Name"
  local actual=$(test_cleanup "$input")
  assert_equals "Artist1 & Artist2 - Track Name" "$actual"
}

test_cleanup_removes_feat_punctuation() {
  local input="Track - Artist feat. Other Artist"
  local actual=$(test_cleanup "$input")
  # The period in "feat." gets removed
  assert_equals "Track - Artist feat Other Artist" "$actual"
}
