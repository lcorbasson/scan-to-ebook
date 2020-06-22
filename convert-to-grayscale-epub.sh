#!/bin/bash
set -eE

TMPDIR="$(mktemp -d "${0##*/}.XXXXXX")"

book="$1"

for f in "$book "*".pdf"; do
	part="${f#$book }"
	part="${part%.pdf}"
	part="${part%% - *}"
	pdfimages -all "$f" "$TMPDIR/$book$part"
	pushd "$TMPDIR" > /dev/null
	for i in "$book$part"*".jpg"; do
		mogrify -colorspace Gray -rotate 270 "$i"
		il="${i%.jpg}_l.jpg"
		ir="${i%.jpg}_r.jpg"
		convert "$i" -gravity West -crop 70%x100%+0+0 "$il"
		convert "$i" -gravity East -crop 70%x100%+0+0 "$ir"
		mogrify -rotate 90 "$il"
		mogrify -rotate 90 "$ir"
#		echo "![$il]($il)" >> "$book$part.md"
#		echo "![$ir]($ir)" >> "$book$part.md"
	done
#	ebook-convert "$book$part.md" "$book$part.epub" --formatting-type markdown
	zip -9 -r "$book$part.cbz" "$book$part"*"_l.jpg" "$book$part"*"_r.jpg"
	ebook-convert "$book$part.cbz" "$book$part.epub" --despeckle --disable-trim --keep-aspect-ratio
	popd > /dev/null
	mv "$TMPDIR/$book$part.cbz" "${f%.pdf}.cbz"
	mv "$TMPDIR/$book$part.epub" "${f%.pdf}.epub"
done
#rm -r "$TMPDIR"

