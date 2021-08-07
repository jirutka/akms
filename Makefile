PROGNAME      := akms

prefix        := /usr/local
datarootdir   := $(prefix)/share
libexecdir    := $(prefix)/libexec
localstatedir := /var
mandir        := $(prefix)/share/man
sbindir       := $(prefix)/sbin
sysconfdir    := /etc

STATE_DIR     := $(localstatedir)/lib/$(PROGNAME)
KERNEL_HOOKS_DIR := $(datarootdir)/kernel-hooks.d

MAN_FILES     := $(basename $(wildcard *.[1-9].adoc))

ASCIIDOCTOR   := asciidoctor
INSTALL       := install
GIT           := git
SED           := sed

MAKEFILE_PATH  = $(lastword $(MAKEFILE_LIST))


#: Print list of targets (the default target).
help:
	@printf '%s\n\n' 'List of targets:'
	@$(SED) -En '/^#:.*/{ N; s/^#: (.*)\n([A-Za-z0-9_-]+).*/\2 \1/p }' $(MAKEFILE_PATH) \
		| while read label desc; do printf '%-15s %s\n' "$$label" "$$desc"; done

#: Build sources.
build: man

#: Convert man pages.
man: $(MAN_FILES)

#: Remove generated files.
clean:
	rm -f ./*.[1-9]

#: Install into $DESTDIR.
install: install-other install-man

#: Install everything except the man pages into $DESTDIR.
install-other:
	$(INSTALL) -D -m755 akms "$(DESTDIR)$(sbindir)/$(PROGNAME)"
	$(SED) -i \
		-e "s|/usr/libexec/akms|$(libexecdir)/$(PROGNAME)|" \
		-e "s|/var/lib/akms|$(STATE_DIR)|" \
		-e "s|/etc/akms\.conf|$(sysconfdir)/$(PROGNAME).conf|" \
		"$(DESTDIR)$(sbindir)/$(PROGNAME)"
	$(INSTALL) -D -m755 akms-build "$(DESTDIR)$(libexecdir)/$(PROGNAME)/akms-build"
	$(INSTALL) -D -m644 akms.conf "$(DESTDIR)$(sysconfdir)/$(PROGNAME).conf"
	$(INSTALL) -D -m755 akms.kernel-hook "$(DESTDIR)$(KERNEL_HOOKS_DIR)/$(PROGNAME).hook"
	$(INSTALL) -d -m755 "$(DESTDIR)$(STATE_DIR)"

#: Install man pages into $DESTDIR/$mandir/man[1-9]/.
install-man: man
	$(INSTALL) -D -m644 -t $(DESTDIR)$(mandir)/man5/ $(filter %.5,$(MAN_FILES))

#: Uninstall from $DESTDIR.
uninstall:
	rm -f "$(DESTDIR)$(sbindir)/$(PROGNAME)"
	rm -Rf "$(DESTDIR)$(libexecdir)/$(PROGNAME)"
	rm -f "$(DESTDIR)$(sysconfdir)/$(PROGNAME).conf"
	rm -f "$(DESTDIR)$(KERNEL_HOOKS_DIR)/$(PROGNAME).hook"
	rmdir "$(DESTDIR)$(STATE_DIR)" || true

#: Update version in the script and README.adoc to $VERSION.
bump-version:
	test -n "$(VERSION)"  # $$VERSION
	$(SED) -E -i "s/^(readonly VERSION)=.*/\1='$(VERSION)'/" $(PROGNAME)
	$(SED) -E -i "s/^(:version:).*/\1 $(VERSION)/" README.adoc

#: Bump version to $VERSION, create release commit and tag.
release: .check-git-clean | bump-version
	test -n "$(VERSION)"  # $$VERSION
	$(GIT) add .
	$(GIT) commit -m "Release version $(VERSION)"
	$(GIT) tag -s v$(VERSION) -m v$(VERSION)


.check-git-clean:
	@test -z "$(shell $(GIT) status --porcelain)" \
		|| { echo 'You have uncommitted changes!' >&2; exit 1; }

.PHONY: help man clean install uninstall bump-version release .check-git-clean


%.1: %.1.adoc
	$(ASCIIDOCTOR) -b manpage -o $@ $<

%.5: %.5.adoc
	$(ASCIIDOCTOR) -b manpage -o $@ $<
