# Qek — WebAssembly build via Emscripten
# Requires: emcc (Emscripten SDK), python3
#
# Usage:
#   make          — build game.wasm + game.js into www/
#   make run      — build then start Python server
#   make clean    — remove build artifacts
#   make watch    — rebuild on source change (requires inotifywait)

CC      := emcc
SRCDIR  := client
WWWDIR  := www
OBJDIR  := build

SRCS := \
	$(SRCDIR)/main.c          \
	$(SRCDIR)/octree.c        \
	$(SRCDIR)/octree_render.c \
	$(SRCDIR)/octree_stl.c    \
	$(SRCDIR)/cmap.c          \
	$(SRCDIR)/physics.c       \
	$(SRCDIR)/renderer.c      \
	$(SRCDIR)/net.c           \
	$(SRCDIR)/input.c         \
	$(SRCDIR)/editor.c        \
	$(SRCDIR)/console.c

CFLAGS := \
	-O2 \
	-Wall \
	-Wextra \
	-I$(SRCDIR) \
	-DEMSCRIPTEN

EMFLAGS := \
	-s WASM=1 \
	-s USE_WEBGL2=0 \
	-s LEGACY_GL_EMULATION=0 \
	-s FULL_ES2=1 \
	-s USE_PTHREADS=0 \
	-s ALLOW_MEMORY_GROWTH=1 \
	-s INITIAL_MEMORY=134217728 \
	-s EXPORTED_FUNCTIONS='["_main","_net_connect_js","_malloc","_free","_input_set_pointer_locked"]' \
	-s EXPORTED_RUNTIME_METHODS='["allocateUTF8","ccall","cwrap"]' \
	-s NO_EXIT_RUNTIME=1 \
	-s MODULARIZE=0 \
	-s ENVIRONMENT=web \
	--js-library $(SRCDIR)/library_ws_stub.js \
	-lGL \
	-lwebsocket.js \
	-lm

# Debug build overrides
DEBUG_FLAGS := -O0 -g4 -s ASSERTIONS=2 -s SAFE_HEAP=1 -DDEBUG

OUT_JS   := $(WWWDIR)/game.js
OUT_WASM := $(WWWDIR)/game.wasm

.PHONY: all run clean debug watch

all: $(WWWDIR) $(OUT_JS)

$(WWWDIR):
	mkdir -p $(WWWDIR)

HDRS := $(wildcard $(SRCDIR)/*.h)

$(OUT_JS): $(SRCS) $(HDRS) | $(WWWDIR)
	$(CC) $(CFLAGS) $(EMFLAGS) $(SRCS) -o $(OUT_JS)
	@echo "Build complete → $(OUT_JS) + $(OUT_WASM)"

debug:
	$(CC) $(CFLAGS) $(DEBUG_FLAGS) $(EMFLAGS) $(SRCS) -o $(OUT_JS)

run: all
	cd server && python3 server.py

clean:
	rm -f $(OUT_JS) $(OUT_WASM) $(WWWDIR)/game.wasm.map

watch:
	@echo "Watching for changes..."
	while inotifywait -e modify $(SRCDIR)/*.c $(SRCDIR)/*.h 2>/dev/null; do \
		$(MAKE) all; \
	done
