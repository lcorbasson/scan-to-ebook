#!/bin/bash
set -eE

if [ $# -lt 1 ]; then
	echo "Usage: $0 BOOK_ROOT" >&2
	exit 1
fi
book="$1"

for f in "$book "*".pdf"; do
	if [ "${f%.ebook.pdf}" != "$f" ]; then
		continue
	fi

	# Extract the part number from the file name
	part="${f#$book }"
	part="${part%.pdf}"
	part="${part%% - *}"
	part="${part%% – *}"
	echo "Working on $book, part $part:"

	# Create a temp dir
	tmpdir="$(mktemp -d "${0##*/}.$book$part.XXXXXX")"

	# Extract the scans
	pdfimages -all "$f" "$tmpdir/$book$part"

	# Generate the output pages
	pushd "$tmpdir" > /dev/null
	pages=()
	for i in "$book$part"*".jpg"; do
		echo " - page $i"

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
#			jpegoptim -q -s "$it"
#		done

		# Adapt the pages to the e-book screens by cutting pages in two
		il="${i%.jpg}_l.jpg"
		ir="${i%.jpg}_r.jpg"
		convert "$i" -gravity West -crop 70%x100%+0+0 "$il"
		convert "$i" -gravity East -crop 70%x100%+0+0 "$ir"

		# Optimize JPEGs
		jpegoptim -q -s "$i" "$il" "$ir"

		# Add them to the output pages
		pages+=("$il" "$ir")
	done

	# Generate a grayscale PDF version
	echo " - assembling the PDF e-book"
	img2pdf --output "$book$part.pdf" "${pages[@]}"
	# OCR it
	ocrmypdf -q --language deu+fra+nld+eng --output-type pdf --sidecar --deskew --clean "$book$part.pdf" "$book$part.ocr.pdf"
	ghostscript -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dPDFSETTINGS=/printer -dNOPAUSE -dQUIET -dBATCH -sOutputFile="$book$part.ebook.pdf" "$book$part.ocr.pdf"

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
	mv "$tmpdir/$book$part.ebook.pdf" "${f%.pdf}.ebook.pdf"
#	mv "$tmpdir/$book$part.cbz" "${f%.pdf}.ebook.cbz"
#	mv "$tmpdir/$book$part.epub" "${f%.pdf}.ebook.epub"

	# Cleanup
	rm -r "$tmpdir"
	echo
done

