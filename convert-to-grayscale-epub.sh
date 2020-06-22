#!/bin/bash
set -eE

TMPDIR="$(mktemp -d "${0##*/}.XXXXXX")"

book="$1"

for f in "$book "*".pdf"; do
	part="${f#$book }"
	part="${part%.pdf}"
	part="${part%% - *}"

	# Extract the scans
	pdfimages -all "$f" "$TMPDIR/$book$part"

	# Generate the output pages
	pushd "$TMPDIR" > /dev/null
	pages=()
	for i in "$book$part"*".jpg"; do

		# Put the pages horizontally for easier manipulation
		mogrify -colorspace Gray -rotate 270 "$i"

		# Generate tiles to optimize compression (TODO)
#		size="$(identify "$i")"
#		size="${size#$i JPEG }"
#		size="${size%% *}"
#		w="${size%%x*}"
#		tw="$((w/10))"
#		if [ "$((tw*10))" -lt "$w" ]; then
#			tw="$((tw+1))"
#		fi
#		for t in {0..9}; do
#			it="${i%.jpg}_$t.jpg"
#			gm convert "$i" -crop "${tw}x100%" "$it"
#			mogrify -rotate 90 "$it"
#		done

		# Adapt the pages to the e-book screens by cutting pages in two
		il="${i%.jpg}_l.jpg"
		ir="${i%.jpg}_r.jpg"
		convert "$i" -gravity West -crop 70%x100%+0+0 "$il"
		convert "$i" -gravity East -crop 70%x100%+0+0 "$ir"

		# Put the resulting pages back in vertical format
		mogrify -rotate 90 "$il"
		mogrify -rotate 90 "$ir"

		# Add them to the output pages
		pages+=("$il" "$ir")
	done

	# Generate a grayscale PDF version
	img2pdf -o "$book$part.pdf" "${pages[@]}"

	# Generate an EPUB version via Markdown
#	for i in "${pages[@]}"; do
#		echo "![$i]($i)"
#	done > "$book$part.md"
#	ebook-convert "$book$part.md" "$book$part.epub" --formatting-type markdown

	# Generate an EPUB version via ComicBook
#	zip -9 -r "$book$part.cbz" "${pages[@]}"
#	ebook-convert "$book$part.cbz" "$book$part.epub" --despeckle --disable-trim --keep-aspect-ratio

	popd > /dev/null

	# Save the resulting files
	mv "$TMPDIR/$book$part.pdf" "${f%.pdf}.ebook.pdf"
#	mv "$TMPDIR/$book$part.cbz" "${f%.pdf}.ebook.cbz"
#	mv "$TMPDIR/$book$part.epub" "${f%.pdf}.ebook.epub"
done

# Cleanup
rm -r "$TMPDIR"

