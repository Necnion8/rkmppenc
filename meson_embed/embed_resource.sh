#!/bin/bash
# embed_resource.sh - バイナリリソースを.oファイルに変換
#
# Usage: embed_resource.sh <input_file> <output_file> <symbol_name>

set -e

INPUT="$1"
OUTPUT="$2"
SYMBOL_BASE="$3"

if [ -z "$INPUT" ] || [ -z "$OUTPUT" ] || [ -z "$SYMBOL_BASE" ]; then
    echo "Usage: $0 <input_file> <output_file> <symbol_name>" >&2
    exit 1
fi

OUTPUT=$(realpath -m "$OUTPUT")
WORKDIR=$(mktemp -d)

cleanup() {
    rm -rf "$WORKDIR"
}
trap cleanup EXIT

TMPFILE="${WORKDIR}/${SYMBOL_BASE}"
cp "$INPUT" "$TMPFILE"

case "$(uname -m)" in
    aarch64|arm64)
        ELF_ARCH="elf64-littleaarch64"
        BIN_ARCH="aarch64"
        ;;
    x86_64|amd64)
        ELF_ARCH="elf64-x86-64"
        BIN_ARCH="i386:x86-64"
        ;;
    *)
        echo "Unsupported architecture: $(uname -m)" >&2
        exit 1
        ;;
esac

cd "$WORKDIR"
objcopy -I binary -O "$ELF_ARCH" -B "$BIN_ARCH" "$SYMBOL_BASE" "$OUTPUT"
