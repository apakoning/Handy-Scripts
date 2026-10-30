#!/usr/bin/env bash
set -u

COOKIE="$HOME/Downloads/themartialman.com_cookies.txt"
COURSE_URL="https://themartialman.com/courses/initiation-into-hermetics-with-sifu-mark-rasmus/"
OUTDIR="$HOME/Videos/TheMartialMan/Initiation-Into-Hermetics"
UA="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36"

mkdir -p "$OUTDIR" work logs

echo "[+] Fetching course page..."
curl -L -b "$COOKIE" -A "$UA" "$COURSE_URL" -o work/course.html

echo "[+] Extracting lesson URLs..."
grep -Eo 'https://themartialman\.com/lessons/[^"]+/' work/course.html \
  | sed 's/#038;//g' \
  | sort -u > work/lesson_urls.txt

COUNT=$(wc -l < work/lesson_urls.txt)
echo "[+] Found $COUNT lessons."

nl -w3 -s' ' work/lesson_urls.txt > work/numbered_lessons.txt

while read -r NUM URL; do
  SLUG=$(basename "$URL")
  SAFE_SLUG=$(echo "$SLUG" | sed 's/-/ /g; s/\b\(.\)/\u\1/g' | tr -cd '[:alnum:] ._-')
  FILE="$OUTDIR/${NUM} - ${SAFE_SLUG}.mp4"

  if [[ -s "$FILE" ]]; then
    echo "[skip] $FILE"
    continue
  fi

  echo
  echo "[+] $NUM $URL"

  PAGE="work/${NUM}.html"
  curl -L -b "$COOKIE" -A "$UA" "$URL" -o "$PAGE"

  M3U8=$(grep -o 'https://[^"]*playlist\.m3u8[^"]*' "$PAGE" | head -n1)
  M3U8="${M3U8//&#038;/&}"

  if [[ -z "$M3U8" ]]; then
    echo "[fail] No m3u8 found for $URL" | tee -a logs/failures.log
    continue
  fi

  yt-dlp \
    --add-header "Referer:$URL" \
    --add-header "Origin:https://themartialman.com" \
    --user-agent "$UA" \
    --continue \
    --no-overwrites \
    -o "$FILE" \
    "$M3U8" || echo "[fail] yt-dlp failed for $URL" | tee -a logs/failures.log

  sleep 1
done < work/numbered_lessons.txt

echo
echo "[+] Done. Failures, if any:"
cat logs/failures.log 2>/dev/null || true

