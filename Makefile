#!/usr/bin/make -f

draft = draft-protected-headers
OUTPUT = $(draft).txt $(draft).html $(draft).xml

all: $(OUTPUT)

%.xml: %.md
	kramdown-rfc2629 < $< > $@

%.html: %.xml
	xml2rfc $< --html

%.txt: %.xml
	xml2rfc $< --text

clean:
	-rm -rf $(OUTPUT) .refcache/

.PHONY: clean all
