CASK = cask
EMACS = emacs
EMACSFLAGS =

export EMACS

SRCS = puppet-mode.el
OBJECTS = $(SRCS:.el=.elc)

.PHONY: all

compile: $(OBJECTS)

%.elc : %.el $(PKGDIR)
	$(CASK) exec $(EMACS) -Q --batch $(EMACSFLAGS) -f batch-byte-compile $<
