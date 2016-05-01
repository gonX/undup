#!/bin/bash

FILELIST=()
declare -A FILESIZES CHECKSUMS 

scandir() {
	DIR="$1"
	echo "Scanning $DIR"

	for i in ${DIR}/*; do
		if [ -d "$i" ]; then
			scandir "$i"
		elif [ -f "$i" ]; then
			#echo "Found file: $i" # very verbose!
			FILELIST+=("$i")
		fi
	done
}

for d in "$@"; do
	if [ ! -d "$d" ]; then
		echo "Not a directory: $d"
		continue
	fi

	scandir "$d"
done

POTENTIALLY_DUPLICATE_FILE_COUNT=0
for f in "${FILELIST[@]}"; do
	SIZE="$(stat -c%s "$f")"
	if [ -z "${FILESIZES[$SIZE]}" ]; then
		FILESIZES[$SIZE]="$f"
	else
		((POTENTIALLY_DUPLICATE_FILE_COUNT++))
		FILESIZES[$SIZE]="$(echo -ne "${FILESIZES[$SIZE]}\n$f")"
	fi
done

echo "${#FILESIZES[@]} different file sizes found, creating $POTENTIALLY_DUPLICATE_FILE_COUNT potential duplicates"

HAS_SIZE_DUPLICATE=0
for s in "${!FILESIZES[@]}"; do
	FILECOUNT="$(wc -l <<< "${FILESIZES[$s]}")"
	if [ "$FILECOUNT" -gt 1 ]; then
		for i in $(seq 1 $FILECOUNT); do
			((HAS_SIZE_DUPLICATE++))
			CURRENT="$(awk "{ if ( NR == $i ) print }" <<< "${FILESIZES[$s]}")"
			CHECKSUM="$(sha256sum -b "$CURRENT" | awk '{ print $1 }')"
			if [ -z "${CHECKSUMS[$CHECKSUM]}" ]; then
				CHECKSUMS[$CHECKSUM]="$CURRENT"
			else
				CHECKSUMS[$CHECKSUM]="$(echo -ne "${CHECKSUMS[$CHECKSUM]}\n$CURRENT")"
			fi
		done
	fi
done
echo "${HAS_SIZE_DUPLICATE} files had size collissions, creating ${#CHECKSUMS[@]} unique checksums"

HAS_REAL_DUPLICATE=0
for c in "${!CHECKSUMS[@]}"; do
	FILECOUNT="$(wc -l <<< "${CHECKSUMS[$c]}")"
	if [ "$FILECOUNT" -gt 1 ]; then
		for i in $(seq 1 $FILECOUNT); do
            unset MATCHFOUND
			NUM_OF_FILES_TO_CHECK=$((FILECOUNT - i))
			CURRENT="$(awk "{ if ( NR == $i ) print }" <<< "${CHECKSUMS[$c]}")" 
			for y in $(seq 1 $NUM_OF_FILES_TO_CHECK); do
				NEXT="$(awk "{ if ( NR == $i + $y ) print }" <<< "${CHECKSUMS[$c]}")"
				diff "$CURRENT" "$NEXT" >/dev/null
				if [ $? -eq 0 ]; then #match
                    if [ -z "$MATCHFOUND" ]; then
                        MATCHFOUND=y 
                        ((HAS_REAL_DUPLICATE++))
                    fi 
                    ((HAS_REAL_DUPLICATE++))
					echo "'$NEXT' was found to match with '$CURRENT'!"
				fi
			done
		done
	fi
done

echo "Stats:"
echo "${#FILELIST[@]} files found"
echo "${#FILESIZES[@]} unique file sizes"
echo "out of which, ${#CHECKSUMS[@]} unique checksums existed"
echo "Total: $HAS_REAL_DUPLICATE duplicate files"
