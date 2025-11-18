# iTunes Search API

Used for looking up track metadata including artist, title, album, year, genre, artwork, and country.

## Request

### URL Format

```
https://itunes.apple.com/search?term={query}&entity=song&limit=1
```

### Parameters

| Parameter | Value | Description |
|-----------|-------|-------------|
| `term` | URL-encoded search query | e.g., `artist+name+song+title` |
| `entity` | `song` | Limit results to music tracks |
| `limit` | `1` | Return only the best match |

### Example Request

```bash
curl -s "https://itunes.apple.com/search?term=daft+punk+get+lucky&entity=song&limit=1"
```

## Response

### JSON Structure

```json
{
  "resultCount": 1,
  "results": [
    {
      "wrapperType": "track",
      "kind": "song",
      "artistId": 5468295,
      "collectionId": 617154241,
      "trackId": 617154366,
      "artistName": "Daft Punk",
      "collectionName": "Random Access Memories",
      "trackName": "Get Lucky (feat. Pharrell Williams & Nile Rodgers)",
      "collectionCensoredName": "Random Access Memories",
      "trackCensoredName": "Get Lucky (feat. Pharrell Williams & Nile Rodgers)",
      "artistViewUrl": "https://music.apple.com/us/artist/daft-punk/5468295?uo=4",
      "collectionViewUrl": "https://music.apple.com/us/album/get-lucky-feat-pharrell-williams-nile-rodgers/617154241?i=617154366&uo=4",
      "trackViewUrl": "https://music.apple.com/us/album/get-lucky-feat-pharrell-williams-nile-rodgers/617154241?i=617154366&uo=4",
      "previewUrl": "https://audio-ssl.itunes.apple.com/itunes-assets/AudioPreview125/v4/...",
      "artworkUrl30": "https://is1-ssl.mzstatic.com/image/thumb/.../30x30bb.jpg",
      "artworkUrl60": "https://is1-ssl.mzstatic.com/image/thumb/.../60x60bb.jpg",
      "artworkUrl100": "https://is1-ssl.mzstatic.com/image/thumb/.../100x100bb.jpg",
      "collectionPrice": 11.99,
      "trackPrice": 1.29,
      "releaseDate": "2013-04-19T12:00:00Z",
      "collectionExplicitness": "notExplicit",
      "trackExplicitness": "notExplicit",
      "discCount": 1,
      "discNumber": 1,
      "trackCount": 13,
      "trackNumber": 8,
      "trackTimeMillis": 369626,
      "country": "USA",
      "currency": "USD",
      "primaryGenreName": "Electronic",
      "isStreamable": true
    }
  ]
}
```

### Fields Used by ytaudio

| Field              | Description                 | Example                      |
|--------------------|-----------------------------|------------------------------|
| `resultCount`      | Number of results returned  | `1`                          |
| `artistName`       | Artist/band name            | `"Daft Punk"`                |
| `trackName`        | Song title                  | `"Get Lucky"`                |
| `collectionName`   | Album name                  | `"Random Access Memories"`   |
| `releaseDate`      | Release date (ISO 8601)     | `"2013-04-19T12:00:00Z"`     |
| `primaryGenreName` | Music genre                 | `"Electronic"`               |
| `artworkUrl100`    | Album artwork URL (100x100) | `"https://...100x100bb.jpg"` |
| `country`          | Store country code          | `"USA"`                      |

### Artwork URL Scaling

The `artworkUrl100` returns a 100x100 pixel image. ytaudio replaces `100x100` with `600x600` in the URL to get a higher resolution image for embedding:

```
Original:  https://is1-ssl.mzstatic.com/image/thumb/.../100x100bb.jpg
Upscaled:  https://is1-ssl.mzstatic.com/image/thumb/.../600x600bb.jpg
```

## Notes

- No API key required
- Rate limiting is lenient but be respectful
- Results are typically fast and accurate for popular tracks
- Country field reflects the iTunes store region (e.g., USA, GBR, JPN)
