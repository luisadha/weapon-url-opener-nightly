#!/bin/bash

# Sangat cepat rata-rata 24 ms.
## 📝 Changelog - v2.2.5 (2025-06-23)

### ✨ New Features
# - Revamped the UI for a more intuitive and cleaner experience.
# - Added automatic language detection for English and Indonesian.
# - Added support for file previews using `bat` with syntax highlighting (without line numbers).

### 🛠️ Fixes
# - Fixed a bug where nothing was selected and no valid fallback was triggered.
# - Improved **In Use** label behavior for better context awareness and clarity.

#!/usr/bin/env bash

DEBUG=0
lang=""
BASE="$HOME/.local/state/wuo/"
CACHE="$HOME/.local/state/wuo/lang"
STATE="$HOME/.local/state/wuo/lang.auto"
mkdir -p "$BASE"
debug_log() {  
  if [ "$DEBUG" -eq 1 ]; then  
    printf "[DEBUG] $*" >&2;
  fi 
}
normal_log() {
  if [ "$DEBUG" -eq 0 ]; then 
    echo -ne "$*"
  fi 
}


# 🔍 Deteksi opsi
if [[ $# -eq 0 ]]; then
  lang="auto"
fi
for arg in "$@"; do
  case $arg in
    --debug)
      DEBUG=1
      shift
      ;;
    --lang=*)
      LANG_ARG="${arg#--lang=}"
      if [[ "$LANG_ARG" == "auto" ]]; then
         termux-tts-engines | yq -o t | cut -f1,3 --complement | xargs | awk '{print $2}' > ~/.local/state/wuo/lang; touch ~/.local/state/wuo/lang.auto; lang="auto"
      elif [[ "$LANG_ARG" == "id" ]]; then  
           echo "Pengenalan" > ~/.local/state/wuo/lang; lang="id"
      elif [[ "$LANG_ARG" == "en" ]]; then 
           echo "Speech" > ~/.local/state/wuo/lang; lang="en"
      else echo "undefined"; exit 3; fi
        shift
      ;;
  esac
done

if [[ -z "$lang" && -f "$CACHE" && ! -f "$STATE" ]]; then
  case "$(cat "$CACHE")" in
    Pengenalan) lang="id" ;;
    Speech)     lang="en" ;;
  esac
fi
debug_log "Detection language: $lang\n"

if [ ! -f "$STATE" ]; then
  debug_log "Detection language: auto\n"
fi 


# Map Bahasa Indonesia
declare -A map_id=(
  [choosed_n]='Tidak memilih'
  [info_c]='Keluar dari skrip ini'
  [info_e]='Keluar'
  [banner]='WUO adalah alat penyedia termux-url-opener'
  [prompt_s]='Pilih senjata utamamu:'
  [toogle_u]='Digunakan'
  [choosed_y]='Kamu memilih'
  [info_s]='Sebagai senjata utamamu'
)

# Map Bahasa Inggris
declare -A map_en=(
  [choosed_n]='Not choosed yet'
  [info_c]='Program close'
  [info_e]='Exit'
  [banner]='WUO is termux-url-opener provider tools'
  [prompt_s]='Choose your main weapon:'
  [toogle_u]='In Use:'
  [choosed_y]='You choosed'
  [info_s]='as your primary weapon'
)

# Fungsi untuk ambil string berdasarkan key
trmap() {
  locale="$(cat $CACHE)";
  case "$locale" in
    Pengenalan) lang="id" ;;
    Speech)     lang="en" ;;
    *)          lang="en" ;;  # fallback default
   esac
debug_log "Query detected: $locale\n"

  case "$lang" in
    id) echo "${map_id[$1]}" ;;
    en) echo "${map_en[$1]}" ;;
    *) echo "Unknown language" ;;
  esac
  debug_log "Mapped language: $lang\n"
}

# Masuk ke folder koleksi
debug_log "Entering dir: " && pushd ~/bin
# Tambahkan dekripsi untuk opsi Exit
echo "$(trmap info_c)" > ~/bin/EXIT
__banner__="$(trmap banner)"

# Hitung skrip provider
count_plugin=$(ls ~/bin/*.sh| wc -l)
# Hitung hash dari termux-url-opener
ref_hash=$(md5sum ~/bin/termux-url-opener 2>/dev/null | awk '{print $1}')

# Ambil semua file .sh dalam urutan waktu
IFS=$'\n' read -d '' -r -a file_list < <(\ls -Art ~/bin/*.sh)

# Ambil hanya nama file-nya
IFS=$'\n' read -d '' -r -a file_list < <(printf "%s\n" "${file_list[@]}" | xargs -n1 basename)

# Tambahkan Opsi EXIT di akhir
file_list+=("EXIT")

# Cari file yang sedang 'in use' (hash sama dengan termux-url-opener)
toggle=""
for file in "${file_list[@]}"; do
  [[ "$file" == "EXIT" ]] && continue
  file_hash=$(md5sum ~/bin/"$file" 2>/dev/null | awk '{print $1}')
  if [[ "$file_hash" == "$ref_hash" ]]; then
    toggle="${file%.*}";
    break
  fi
done
# Siapkan header jika ada file yang in use
if [[ -n "$toggle" ]]; then
  fzf_header="$__banner__"
  current="$toggle"
else
  fzf_header="$__banner__"
  current="$toggle"
fi
# Cache biar cepat
c_y="$(trmap choosed_y )"; 
i_s="$(trmap info_s)";
inuse="$(trmap toogle_u)";
pr="$(trmap prompt_s)";
no_input="$(trmap choosed_n)";
eof="$(trmap info_e)";

# Tampilan
weapon=$(printf '%s\n' "${file_list[@]}" | while read -r f; do
    base="${f%.*}"
    printf "%s\t%s\n" "$f" "$base"
  done | fzf --prompt="$pr " \
  --height=50% \
  --layout=reverse \
  --border \
  --info=inline-right \
  --pointer='👉' \
  --ellipsis='+'\
  --color=border:cyan \
  --no-separator \
  --header-lines=0 \
  --input-border='sharp' \
  --header="$fzf_header" \
  --header-border="bold" \
  --list-border="vertical" \
  --header-first \
  --input-label="[ $inuse $current ]"\
  --highlight-line \
  --preview='bat --color=always --style=plain --paging=never --theme OneHalfDark {1}' \
  --with-nth=2 \
  --delimiter=$'\t' \
  --exit-0 | cut -f1) 

# Jika tidak memilih apa-apa, keluar
if [[ "$weapon" == "" ]]; then
  echo $no_input
  exit 2
fi
# Jika pilih EXIT
if [[ "$weapon" == "EXIT" ]]; then
  echo $eof
  exit 1
fi
rep="$(basename "$weapon")";
# Jalankan aksi
normal_log "$c_y" "$rep" "$i_s"
debug_log "Your Reply: $weapon\n"
sleep 0.1;
cp -f ~/bin/"$weapon" ~/bin/termux-url-opener
start=$(date +%s%N)
debug_log "Leaving dir.. " && cd "$OLDPWD" && printf "\n" # kode yang ingin diukur
end=$(date +%s%N)
#DEBUG 
debug_log "Time Elapsed: $(( (end - start)/1000000 )) ms\n"
