CASK = cask
EMACS = emacs
EMACSFLAGS =

export EMACS

SRCS = puppet-mode.el
OBJS = $(SRCS:.el=.elc)

.PHONY: compile clean

compile: $(OBJS)

clean:
	rm -f $(OBJS)

%.elc : %.el $(PKGDIR)
	$(CASK) exec $(EMACS) -Q --batch $(EMACSFLAGS) -f batch-byte-compile $<
