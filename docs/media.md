# Media

The `media` domain stores images and videos and serves them at the sizes each surface needs. Any domain can attach
media to its entities: posts and short videos (`content_management`), news articles, product and category images
(`catalog`), logos (`brand`).

## Scope

Kept deliberately simple. In scope, for on-demand (non-live) media:

- **Images:** photo posts and carousels, news photos, product images, avatars and logos.
- **Short video:** vertical 9:16 clips (TikTok, Reels, Shorts style), feed and news clips, played as progressive MP4.
  Animated GIFs are ingested as silent videos.
- **Sizes:** named presets (width, height, contain or cover, format), generated eagerly on upload or on request, and
  listing which sizes a media item has.
- **Ingestion:** direct client upload to a signed URL, and import from a URL (wire photos).
- **Display metadata:** dimensions, duration, alt text, credit, ThumbHash placeholder, poster frame.

Out of scope for now: live streaming, HLS/DASH and DRM; ad hoc sizes outside presets; codec, bitrate and quality
control; focal-point cropping; clips and animated previews; captions; resumable uploads; editing; moderation (a
generic capability over entity ARNs, like likes and comments); tracking where media is used (the attaching domain
owns that).

## Model

| Message | What it is |
|---|---|
| `Media` | The owned resource, ARN `tenant:Media:id`. Lifecycle `UPLOAD_PENDING → PROCESSING → READY \| FAILED`, owner, source file, and `oneof { Image, Video }` once ready. |
| `Image`, `Video` | Snapshots that other domains embed. Copy `Media.image` / `Media.video` as-is; they carry what a feed needs for layout without another call (size, aspect ratio, placeholder, alt text). |
| `RenditionPreset` | A named size: `RenditionSpec` (width, height, fit, format), the media type it applies to, and whether it's generated eagerly. Its spec can't change; create a new preset instead. |
| `Rendition` | One generated file for a preset: actual size, format, bytes, state and a URL that may be signed and expire. |

Rules:

- Renditions never upscale beyond the source.
- `Image.renditions` and `Video.renditions` are output only and filled at read time, because URLs expire. Embedding
  domains store the snapshot without them.
- A still format (JPEG, PNG, WebP) on a video preset gives its poster frame.

## Suggested default presets

Current platform specs converge on 9:16 at 1080×1920 for short video and 4:5 at 1080×1350 for feed photos.

| Preset | Spec | Used for |
|---|---|---|
| `thumb_square_150` | image, 150×150 cover | avatars, grids, notifications |
| `image_w640`, `image_w1080` | image, width only | feed and article images, 1x and 2x |
| `feed_4x5_1080` | image, 1080×1350 cover | portrait photo feed slot |
| `grid_square_540` | video, 540×540 cover, WebP | profile grid tile of a video |
| `video_720`, `video_1080` | video, 1280×1280 / 1920×1920 contain, MP4 | playback on slow and fast networks; a 9:16 clip comes out 720×1280 / 1080×1920 |

## Sources

- Cloudflare Images, [named variants](https://developers.cloudflare.com/images/transform-images/) (presets are the same idea)
- Mux, [static MP4 renditions](https://www.mux.com/docs/guides/enable-static-mp4-renditions) (rendition ladder, no upscaling)
- Cloudinary, [eager transformations](https://cloudinary.com/documentation/eager_and_incoming_transformations) and [named transformations](https://cloudinary.com/documentation/named_transformations) (eager presets; why preset specs are immutable)
- [ThumbHash](https://evanw.github.io/thumbhash/)
- Short-video specs: [Questera short-form video specs](https://viberoll.questera.ai/learn/short-form-video-specs/)
