# tmux-borrow — build & test Makefile.
# All tests run against a PRIVATE tmux server socket (`tum-test`), never the
# user's default server. Steps that do not need tmux (pure parsers) never call it.
#
# Quick start:
#   make help          list targets
#   make viability     run the R1 state-store viability test (title vs option)
#   make man           render man/*.md -> man/*.1 / *.5 (pandoc, or scripts/md2man.awk)
#   make test          run every step (PENDING steps print and pass)
#   make test-phase1   run one phase
#   make test-01-defs  run one step

TMUX_BIN          ?= tmux
SOCKET            ?= tum-test
TUM_TEST_SOCKET   := $(SOCKET)
export TUM_TEST_SOCKET

# install destinations (used by `make install`)
PREFIX            ?= /usr/local
BINDIR            ?= $(PREFIX)/bin
LIBDIR            ?= $(PREFIX)/lib/tum
DATADIR           ?= $(PREFIX)/share/tum
MANDIR1           ?= $(PREFIX)/share/man/man1
MANDIR5           ?= $(PREFIX)/share/man/man5

# manpages: man/<name>.<sec>.md  ->  man/<name>.<sec>  (strip the .md)
MAN_MD   := $(wildcard man/*.md)
MAN_ROFF := $(MAN_MD:.md=)

SHELL := /usr/bin/env bash
RUN   := bash t/run.sh

.PHONY: help server server-kill viability man install clean test \
        test-phase0 test-phase1 test-phase2 test-phase3 test-phase4 \
        test-phase5 test-phase6 test-phase7 \
        test-00-scaffold \
        test-01-defs test-02-state test-03-tmux \
        test-04-borrow-create test-05-borrow-reuse-host test-06-borrow-pool \
        test-07-new-owned test-08-borrow-noname test-09-input test-10-env \
        test-11-argv test-12-validate \
        test-13-flip-slot test-14-flip-context test-15-close test-16-geometry \
        test-17-push-pop test-18-import test-19-ls test-20-check \
        test-21-layout-parse test-22-layout-borrow test-23-layout-anchor test-24-layout-focus \
        test-25-chooser test-26-keymap test-27-status test-28-popup \
        test-29-completion test-30-edge

help:
	@echo "tmux-borrow make targets:"
	@echo "  make server         start the private tmux test server (socket $(SOCKET))"
	@echo "  make server-kill    stop it"
	@echo "  make viability      R1: state-store viability test (title vs pane-scope option)"
	@echo "  make man            render man/*.md -> man/*.1 / *.5 (pandoc, else scripts/md2man.awk)"
	@echo "  make install        install bin/tum, scripts/, and manpages (PREFIX=$(PREFIX))"
	@echo "  make test           run every step (PENDING steps print and pass)"
	@echo "  make test-phaseN    run a phase (N = 0..7)"
	@echo "  make test-NN-name   run one step (see steps below)"
	@echo ""
	@echo "Steps: 00-scaffold | 01-defs 02-state 03-tmux |"
	@echo "        04-borrow-create 05-borrow-reuse-host 06-borrow-pool 07-new-owned"
	@echo "        08-borrow-noname 09-input 10-env 11-argv 12-validate |"
	@echo "        13-flip-slot 14-flip-context 15-close 16-geometry |"
	@echo "        17-push-pop 18-import 19-ls 20-check |"
	@echo "        21-layout-parse 22-layout-borrow 23-layout-anchor 24-layout-focus |"
	@echo "        25-chooser 26-keymap 27-status 28-popup | 29-completion 30-edge"

server:
	@$(TMUX_BIN) -L $(SOCKET) -f /dev/null new-session -d -s __init 2>/dev/null || true
	@echo "test server up on socket $(SOCKET)"

server-kill:
	@-$(TMUX_BIN) -L $(SOCKET) kill-server 2>/dev/null || true
	@echo "test server stopped"

viability:
	@bash t/viability.sh

# --- individual steps -------------------------------------------------------
test-00-scaffold:            ; @$(RUN) 00-scaffold
test-01-defs:                ; @$(RUN) 01-defs
test-02-state:               ; @$(RUN) 02-state
test-03-tmux:                ; @$(RUN) 03-tmux
test-04-borrow-create:       ; @$(RUN) 04-borrow-create
test-05-borrow-reuse-host:   ; @$(RUN) 05-borrow-reuse-host
test-06-borrow-pool:         ; @$(RUN) 06-borrow-pool
test-07-new-owned:           ; @$(RUN) 07-new-owned
test-08-borrow-noname:       ; @$(RUN) 08-borrow-noname
test-09-input:               ; @$(RUN) 09-input
test-10-env:                 ; @$(RUN) 10-env
test-11-argv:                ; @$(RUN) 11-argv
test-12-validate:            ; @$(RUN) 12-validate
test-13-flip-slot:           ; @$(RUN) 13-flip-slot
test-14-flip-context:        ; @$(RUN) 14-flip-context
test-15-close:               ; @$(RUN) 15-close
test-16-geometry:            ; @$(RUN) 16-geometry
test-17-push-pop:            ; @$(RUN) 17-push-pop
test-18-import:              ; @$(RUN) 18-import
test-19-ls:                  ; @$(RUN) 19-ls
test-20-check:               ; @$(RUN) 20-check
test-21-layout-parse:        ; @$(RUN) 21-layout-parse
test-22-layout-borrow:       ; @$(RUN) 22-layout-borrow
test-23-layout-anchor:       ; @$(RUN) 23-layout-anchor
test-24-layout-focus:        ; @$(RUN) 24-layout-focus
test-25-chooser:             ; @$(RUN) 25-chooser
test-26-keymap:              ; @$(RUN) 26-keymap
test-27-status:              ; @$(RUN) 27-status
test-28-popup:               ; @$(RUN) 28-popup
test-29-completion:          ; @$(RUN) 29-completion
test-30-edge:                ; @$(RUN) 30-edge

# --- phases -----------------------------------------------------------------
test-phase0: test-00-scaffold
test-phase1: test-01-defs test-02-state test-03-tmux
test-phase2: test-04-borrow-create test-05-borrow-reuse-host test-06-borrow-pool \
             test-07-new-owned test-08-borrow-noname test-09-input test-10-env \
             test-11-argv test-12-validate
test-phase3: test-13-flip-slot test-14-flip-context test-15-close test-16-geometry
test-phase4: test-17-push-pop test-18-import test-19-ls test-20-check
test-phase5: test-21-layout-parse test-22-layout-borrow test-23-layout-anchor test-24-layout-focus
test-phase6: test-25-chooser test-26-keymap test-27-status test-28-popup
test-phase7: test-29-completion test-30-edge

test: test-phase0 test-phase1 test-phase2 test-phase3 test-phase4 \
      test-phase5 test-phase6 test-phase7
	@echo "all steps run (check output above for PENDING/PASS/FAIL)"

# --- manpages ---------------------------------------------------------------
# man/<name>.<sec>.md -> man/<name>.<sec>. pandoc first; awk fallback otherwise.
man: $(MAN_ROFF)
	@test -z "$(MAN_MD)" && echo "make man: no man/*.md sources yet (step 1.1+ writes them)" || true

man/%: man/%.md
	@if command -v pandoc >/dev/null 2>&1; then \
	  pandoc -s -t man -o $@ $<; \
	elif [ -f scripts/md2man.awk ]; then \
	  awk -f scripts/md2man.awk $< > $@; \
	else echo "make man: need pandoc or scripts/md2man.awk to render $<" >&2; exit 1; fi
	@echo "rendered $@"

# --- install ----------------------------------------------------------------
install: man
	install -D bin/tum $(DESTDIR)$(BINDIR)/tum
	install -D scripts/tum-chooser $(DESTDIR)$(LIBDIR)/tum-chooser
	install -D scripts/tum-bindings.conf $(DESTDIR)$(DATADIR)/tum-bindings.conf
	install -D scripts/tum-completion.bash $(DESTDIR)$(DATADIR)/tum-completion.bash
	@for f in man/*.1; do [ -f "$$f" ] && install -D "$$f" $(DESTDIR)$(MANDIR1)/$$(basename $$f); done
	@for f in man/*.5; do [ -f "$$f" ] && install -D "$$f" $(DESTDIR)$(MANDIR5)/$$(basename $$f); done
	@echo "installed tum to $(DESTDIR)$(BINDIR) (manpages to $(DESTDIR)$(MANDIR1) / $(DESTDIR)$(MANDIR5))"

clean: server-kill
	@rm -rf /tmp/tum-test-* 2>/dev/null || true
	@rm -f man/*.1 man/*.5 2>/dev/null || true
