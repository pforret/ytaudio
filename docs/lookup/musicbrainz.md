# MusicBrainz Recording Search API

Used as a fallback for looking up track metadata when iTunes doesn't return results.

## Request

### URL Format

```
https://musicbrainz.org/ws/2/recording/?query={query}&fmt=json&limit=1
```

### Parameters

| Parameter | Value                    | Description                          |
|-----------|--------------------------|--------------------------------------|
| `query`   | URL-encoded search query | e.g., `artist%20name%20song%20title` |
| `fmt`     | `json`                   | Return JSON format (default is XML)  |
| `limit`   | `1`                      | Return only the best match           |

### Required Headers

| Header       | Value                                              | Description                        |
|--------------|----------------------------------------------------|------------------------------------|
| `User-Agent` | `ytaudio/1.0 (https://github.com/pforret/ytaudio)` | Required by MusicBrainz API policy |

### Example Request

```bash
curl -s \
  -H "User-Agent: ytaudio/1.0 (https://github.com/pforret/ytaudio)" \
  "https://musicbrainz.org/ws/2/recording/?query=daft%20punk%20get%20lucky&fmt=json&limit=1"
```

## Response

### JSON Structure

```json
{
  "created": "2024-01-15T10:30:00.000Z",
  "count": 1234,
  "offset": 0,
  "recordings": [
    {
      "id": "1b9a1e3c-3c1e-4b5a-8c1e-1234567890ab",
      "score": 100,
      "title": "Get Lucky",
      "length": 369000,
      "disambiguation": "",
      "video": false,
      "artist-credit": [
        {
          "name": "Daft Punk",
          "artist": {
            "id": "056e4f3e-d505-4dad-8ec1-d04f521cbb56",
            "name": "Daft Punk",
            "sort-name": "Daft Punk",
            "type": "Group",
            "type-id": "e431f5f6-b5d2-343d-8b36-72607fffb74b"
          },
          "joinphrase": " feat. "
        },
        {
          "name": "Pharrell Williams",
          "artist": {
            "id": "1f9df192-a621-4f54-8850-2c5373b7eac9",
            "name": "Pharrell Williams",
            "sort-name": "Williams, Pharrell"
          }
        }
      ],
      "first-release-date": "2013-04-19",
      "releases": [
        {
          "id": "f5093c06-23e3-404f-aeaa-40f72885ee3a",
          "status-id": "4e304316-386d-3409-af2e-78857eec5cfe",
          "count": 1,
          "title": "Random Access Memories",
          "status": "Official",
          "artist-credit": [...],
          "release-group": {
            "id": "bce66f5b-c89b-46fc-a7f0-1c1c7d8c9e8f",
            "type-id": "f529b476-6e62-324f-b0aa-1f3e33d313fc",
            "primary-type-id": "f529b476-6e62-324f-b0aa-1f3e33d313fc",
            "title": "Random Access Memories",
            "primary-type": "Album"
          },
          "date": "2013-05-17",
          "country": "XW",
          "release-events": [...],
          "track-count": 13
        }
      ],
      "isrcs": ["USQX91300105"],
      "tags": [
        {
          "count": 5,
          "name": "electronic"
        },
        {
          "count": 3,
          "name": "disco"
        }
      ]
    }
  ]
}
```

### Fields Used by ytaudio

| Field                                 | Description                         | Example                    |
|---------------------------------------|-------------------------------------|----------------------------|
| `count`                               | Total number of matching recordings | `1234`                     |
| `recordings[0].title`                 | Song title                          | `"Get Lucky"`              |
| `recordings[0].artist-credit[0].name` | Primary artist name                 | `"Daft Punk"`              |
| `recordings[0].first-release-date`    | First release date                  | `"2013-04-19"`             |
| `recordings[0].releases[0].title`     | Album/release title                 | `"Random Access Memories"` |

### Extracted Metadata

ytaudio extracts and uses:

- **Artist**: From `artist-credit[0].name`
- **Title**: From `title`
- **Album**: From `releases[0].title` (falls back to title if not found)
- **Year**: First 4 characters of `first-release-date`
- **Genre**: Not available in recording search (left empty)
- **Artwork**: Not available (left empty)
- **Country**: Not available (left empty)

## Notes

- **User-Agent Required**: MusicBrainz requires a proper User-Agent header identifying your application
- **Rate Limiting**: Maximum 1 request per second for unauthenticated requests
- **Rate Limit Handling**: ytaudio adds a 1-second delay before MusicBrainz queries
- **Data Quality**: MusicBrainz is community-curated, results may vary in completeness
- **No Artwork**: Unlike iTunes, MusicBrainz doesn't provide artwork URLs directly (would need Cover Art Archive API)

## Related APIs

- **Cover Art Archive**: `https://coverartarchive.org/release/{mbid}` - For album artwork
- **MusicBrainz Artist**: `https://musicbrainz.org/ws/2/artist/` - For artist details
- **MusicBrainz Release**: `https://musicbrainz.org/ws/2/release/` - For album details

## References

- [MusicBrainz API Documentation](https://musicbrainz.org/doc/MusicBrainz_API)
- [MusicBrainz Search API](https://musicbrainz.org/doc/MusicBrainz_API/Search)
