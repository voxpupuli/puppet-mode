EMACS = emacs
EMACSFLAGS =

SRCS = puppet-mode.el
OBJECTS = $(SRCS:.el=.elc)

.PHONY: all

compile: $(OBJECTS)

%.elc : %.el $(PKGDIR)
	$(EMACS) -Q --batch $(EMACSFLAGS) -f batch-byte-compile $<
