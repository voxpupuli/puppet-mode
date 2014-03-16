CASK = cask
EMACS = emacs
EMACSFLAGS =

export EMACS

PKGDIR := $(shell EMACS=$(EMACS) $(CASK) package-directory)

SRCS = puppet-mode.el
OBJS = $(SRCS:.el=.elc)

.PHONY: compile clean

compile: $(OBJS)

clean:
	rm -f $(OBJS)

%.elc : %.el $(PKGDIR)
	$(CASK) exec $(EMACS) -Q --batch $(EMACSFLAGS) -f batch-byte-compile $<

$(PKGDIR) : Cask
	$(CASK) install
	touch $(PKGDIR)
