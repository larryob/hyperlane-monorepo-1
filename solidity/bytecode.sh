#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_ARG=${1:-bytecode}
if [[ "$OUTPUT_ARG" = /* ]]; then
    OUTPUT_PATH="$OUTPUT_ARG"
else
    OUTPUT_PATH="$SCRIPT_DIR/$OUTPUT_ARG"
fi
EXCLUDE="test|mock|interfaces|libs|upgrade|README|Abstract|Static|LayerZero|PolygonPos|Portal"

pushd "$SCRIPT_DIR" > /dev/null

IFS=$'\n'
CONTRACT_FILES=($(find ./contracts -type f))
unset IFS

echo "Generating bytecode dumps in $OUTPUT_PATH"
mkdir -p "$OUTPUT_PATH"

for file in "${CONTRACT_FILES[@]}"; do
    if [[ $file =~ .*($EXCLUDE).* ]]; then
        continue
    fi

    if [[ ! "$file" =~ \.sol$ ]]; then
        continue
    fi

    contracts=$(grep -o '^contract [A-Za-z0-9_][A-Za-z0-9_]*' "$file" | sed 's/^contract //')

    if [ -z "$contracts" ]; then
        continue
    fi

    for contract in $contracts; do
        echo "Dumping bytecode for $contract"
        {
            echo "## Creation bytecode"
            forge inspect "$contract" bytecode
            echo ""
            echo "## Deployed bytecode"
            forge inspect "$contract" deployedBytecode
        } > "$OUTPUT_PATH/$contract.bytecode.txt"
    done
done

popd > /dev/null
