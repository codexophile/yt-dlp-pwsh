# yt-dlp PowerShell GUI

This project provides a PowerShell GUI wrapper around `yt-dlp` for downloading
videos, images, carousel posts, playlists, and channel feeds.

## Collections

URLs that contain multiple media items are downloaded as collections when
**Download all items in playlists, channels, and carousel posts** is enabled.
This includes playlist URLs, channel URLs, and posts that expose multiple
images or videos.

The wrapper uses yt-dlp's per-entry download archive at
[`archive/download-archive.txt`](./archive/download-archive.txt). If a
collection download is interrupted, running the same URL again skips entries
that yt-dlp has already completed.

The optional **Playlist items** field accepts yt-dlp item selectors, for
example:

```text
1-10
1,3,5
1-10,15
```

Leave the field blank to download every item available to yt-dlp. The archive
still prevents completed entries from being downloaded again.

Collection metadata is stored as one `.info.json` document in [`archive/`](./archive/),
including its `entries` array. Completion reporting lists all files created in
the destination during the collection run instead of checking only one video
ID.

To force a URL to be treated as one item, clear the collection checkbox. The
wrapper then passes `--no-playlist` to yt-dlp.

## Examples

Open the interactive GUI for a carousel, playlist, or channel:

```powershell
.\yt-dlp.ps1 -url "https://example.com/playlist-or-channel"
```

Download only selected playlist entries by entering `1-10,15` in the
**Playlist items** field before proceeding.

Use the no-prompt mode with an explicit destination:

```powershell
.\yt-dlp.ps1 -url "https://example.com/playlist" `
  -mode noprompt -destination "C:\Users\Me\Downloads"
```

The no-prompt mode uses collection downloading by default. Use the GUI when
you need to disable playlist expansion or select a playlist item range.
