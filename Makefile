#!/usr/bin/make -f

draft = draft-protected-headers
OUTPUT = $(draft).txt $(draft).html $(draft).xml

all: $(OUTPUT)

%.xml: %.md
	kramdown-rfc2629 < $< > $@

%.html: %.xml
	xml2rfc $< --html --v3

%.txt: %.xml
	xml2rfc $< --text --v3

clean:
	-rm -rf $(OUTPUT) .refcache/ metadata.min.js

.PHONY: clean all
