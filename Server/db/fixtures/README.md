# Demo video fixture

`demo.mp4` is a generated 4-second, 320x180 H.264/yuv420p video with an AAC tone.
It contains a test pattern and no personal or externally sourced media.
All three seeded video records use copies of this same small clip, not real nature/learning footage.

Creation command (FFmpeg is only needed to regenerate the fixture, not to run the app):

```text
ffmpeg -f lavfi -i testsrc=size=320x180:rate=24 -f lavfi -i sine=frequency=440:sample_rate=44100 -t 4 -c:v libx264 -pix_fmt yuv420p -c:a aac -b:a 48k -movflags +faststart -shortest demo.mp4
```

`npm run db:seed` copies this tracked fixture into ignored `storage/videos/`.
Private uploads and local database credentials remain excluded from Git.
