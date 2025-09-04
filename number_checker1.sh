#!/usr/bin/env bash
# cap_scanner.sh - robust scanner for HTB Cap machine
#
# Usage:
#   ./cap_scanner.sh -s 1 -e 200 -b "http://10.10.10.245/data" -D -d
#
# Flags:
#  -s START ID
#  -e END ID
#  -b BASE_URL (default http://10.10.10.245/data)
#  -t TIMEOUT (seconds, default 3)
#  -d debug (print snippet for no-match pages)
#  -D auto-download found pcaps to ./pcaps/

START=0
END=100
BASE_URL="http://10.10.10.245/data"
TIMEOUT=3
DEBUG=0
AUTO_DL=0
OUT_HTML_DIR="found_html"
PCAP_DIR="pcaps"

while getopts "s:e:b:t:dDh" opt; do
  case $opt in
    s) START="$OPTARG" ;;
    e) END="$OPTARG" ;;
    b) BASE_URL="$OPTARG" ;;
    t) TIMEOUT="$OPTARG" ;;
    d) DEBUG=1 ;;
    D) AUTO_DL=1 ;;
    h)
       echo "Usage: $0 [-s START] [-e END] [-b BASE_URL] [-t TIMEOUT] [-d debug] [-D download]"
       exit 0
       ;;
  esac
done

mkdir -p "$OUT_HTML_DIR"
[[ "$AUTO_DL" -eq 1 ]] && mkdir -p "$PCAP_DIR"

HOST=$(printf '%s' "$BASE_URL" | sed -E 's|(https?://[^/]+).*|\1|')

ids_with_packets=()

echo "[*] Scanning ${BASE_URL%/}/$START → $END (timeout=$TIMEOUT s)"

for (( id=START; id<=END; id++ )); do
  URL="${BASE_URL%/}/$id"
  echo -n "[*] $id ... "

  html=$(curl -sS -L --max-time "$TIMEOUT" "$URL")
  rc=$?
  if [[ $rc -ne 0 ]]; then
    echo "curl-failed (rc=$rc)"
    continue
  fi
  [[ -z "$html" ]] && { echo "empty"; continue; }

  # Extract packets: works for <div> or <td>
  packets=$(printf '%s' "$html" | perl -0777 -ne '
    # Match "Number of Packets" followed by sibling <div> or <td>
    if (/Number of Packets\s*<\/[^>]+>\s*<[^>]+>\s*([0-9,]+)/is) {
      $n=$1; $n=~s/,//g; print $n; exit;
    }
    if (/Number of Packets.*?([0-9,]+)/is) {
      $n=$1; $n=~s/,//g; print $n; exit;
    }
  ')

  if [[ -n "$packets" && "$packets" -gt 0 ]]; then
    echo "[+] $packets packets"
    ids_with_packets+=("$id")
    printf '%s' "$html" > "$OUT_HTML_DIR/$id.html"

    if [[ "$AUTO_DL" -eq 1 ]]; then
      # Try to extract a /download link
      dlpath=$(printf '%s' "$html" | grep -oP 'href=["'\''][^"'\''>]*download[^"'\''>]*["'\'']' | head -n1 | grep -oP 'download[^"'\''>]*')
      [[ -z "$dlpath" ]] && dlpath="/download/$id"

      # Build full URL
      [[ "$dlpath" =~ ^https?:// ]] && dlurl="$dlpath" || dlurl="${HOST%/}/${dlpath#/}"

      echo "    -> downloading $dlurl"
      curl -sS -L --max-time "$TIMEOUT" -o "$PCAP_DIR/$id.pcap" "$dlurl" || echo "    (download failed)"
    fi
  else
    echo "no packet info"
    if [[ "$DEBUG" -eq 1 ]]; then
      echo "----- snippet for $id -----"
      printf '%.400s\n' "$html"
      echo "---------------------------"
    fi
  fi
done

echo
echo "[*] Scan complete."
if [[ ${#ids_with_packets[@]} -eq 0 ]]; then
  echo "[!] No IDs with packets found."
else
  echo "[*] IDs with packet data:"
  printf '%s\n' "${ids_with_packets[@]}"
fi
