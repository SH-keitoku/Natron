#!/bin/bash
# [CI only] FFmpeg 8 removed AVCodec::pix_fmts (deprecated since 7.1). The pinned
# openfx-io still reads it, so route those reads through avcodec_get_supported_config().
# Usage: patch_openfx_io_ffmpeg8.sh <openfx-io dir>
set -eu
f="$1/FFmpeg/WriteFFmpeg.cpp"
[ -f "$f" ] || { echo "no $f"; exit 0; }
grep -q "natronCodecPixFmts" "$f" && { echo "already patched"; exit 0; }
python3 - "$f" <<'PY'
import sys, re
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
helper = r'''
// [CI patch] FFmpeg >= 7.1 exposes pixel formats via avcodec_get_supported_config();
// FFmpeg 8 removed AVCodec::pix_fmts.
static const AVPixelFormat*
natronCodecPixFmts(const AVCodec* codec)
{
#if LIBAVCODEC_VERSION_INT >= AV_VERSION_INT(61, 13, 100)
    const void* fmts = nullptr;
    int n = 0;
    if (avcodec_get_supported_config(nullptr, codec, AV_CODEC_CONFIG_PIX_FORMAT, 0, &fmts, &n) < 0) {
        return nullptr;
    }
    return static_cast<const AVPixelFormat*>(fmts);
#else
    return codec->pix_fmts;
#endif
}
'''
anchor = '#include "IOUtility.h"'
assert anchor in s
s = s.replace(anchor, helper + anchor, 1)
s, n = re.subn(r'videoCodec->pix_fmts\b', 'natronCodecPixFmts(videoCodec)', s)
# keep the commented-out reference untouched in meaning; count replacements
print("replaced", n)
open(p, "w", encoding="utf-8").write(s)
PY
