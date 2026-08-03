# OneSend optical test video

onesend-optical-test.mp4 is a tiny, repeatable fixture for testing OneSend's
optical file-transfer path. It is intentionally high-contrast black and white:
the frame is made from a white outline, solid panels, and moving geometric
blocks so that it remains easy to inspect during repeated runs.

The clip is an original, copyright-safe alternative to using a music video or
an internet test clip. It contains no downloaded footage, no Bad Apple video,
and no commercial song or MV. The visual is generated from primitive shapes and
the audio is a short synthesized oscillator tone. The fixture may therefore be
distributed with this MIT-licensed project.

Current generated media:

- 10.0 seconds, 320×180 pixels, 12 fps
- H.264 Baseline video, yuv420p
- Mono AAC audio at 8 kHz
- Smaller than 500 KB; exact ffprobe output is recorded in ffprobe.txt

Regenerate the asset from the repository root with:

    bash tool/generate_demo_video.sh

The loader API is in lib/services/sample_file_service.dart. It returns this
file as a PickedTransfer with the clear filename onesend-optical-test.mp4 and
MIME type video/mp4.
