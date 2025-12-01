# Solidity Named Arguments Converter

A tool to automatically convert Solidity function calls from positional arguments to named arguments syntax.

## Overview

This tool helps refactor Solidity code to use [named parameters](https://docs.soliditylang.org/en/latest/control-structures.html#function-calls-with-named-parameters) for better code readability.

**Before:**
```solidity
mailbox.dispatch(
    destinationDomain,
    recipientAddress,
    messageBody,
    metadata,
    hook
);
```

**After:**
```solidity
mailbox.dispatch({
    destinationDomain: destinationDomain,
    recipientAddress: recipientAddress,
    messageBody: messageBody,
    metadata: metadata,
    hook: hook
});
```

## Features

- **Automatic resolution**: Finds function definitions in the same codebase
- **Manual mappings**: Support for external contracts (OpenZeppelin, etc.) via JSON config
- **Safe transformation**: Creates backups before modifying files
- **Dry-run mode**: Preview changes without modifying files
- **Configurable threshold**: Set minimum number of arguments to trigger conversion

## Installation

```bash
cd tools/solidity-named-args
npm install
```

## Usage

### 1. Analyze your codebase

First, analyze your Solidity files to see what needs to be converted:

```bash
node src/analyzer.js "../../solidity/contracts/**/*.sol"
```

This will:
- Show statistics on function calls
- List resolved calls (can be auto-converted)
- List unresolved calls (need manual mapping)
- Generate `unresolved-calls.json` for review

### 2. Add manual mappings (if needed)

For unresolved function calls (external contracts), add entries to `function-signatures.json`:

```json
{
  "YourContract.yourFunction": {
    "params": ["param1", "param2", "param3", "param4"],
    "description": "Optional description"
  }
}
```

### 3. Convert files

**Dry run** (preview without changes):
```bash
node src/converter.js --dry-run "../../solidity/contracts/**/*.sol"
```

**Actual conversion**:
```bash
node src/converter.js "../../solidity/contracts/**/*.sol"
```

This will:
- Create `.bak` backup files
- Convert function calls to named arguments
- Report conversion statistics

### 4. Review and test

```bash
# Review changes
git diff

# Run tests to ensure nothing broke
cd ../../solidity
yarn test

# If all looks good, commit
git add .
git commit -m "refactor: convert function calls to named arguments"

# Clean up backup files
find . -name "*.bak" -delete
```

## Options

### Analyzer Options

```bash
node src/analyzer.js [options] <file-pattern> [<file-pattern> ...]

Examples:
  node src/analyzer.js "contracts/**/*.sol"
  node src/analyzer.js contracts/Mailbox.sol contracts/Router.sol
```

### Converter Options

```bash
node src/converter.js [options] <file-pattern> [<file-pattern> ...]

Options:
  --dry-run              Preview changes without modifying files
  --min-args <n>         Minimum arguments to trigger conversion (default: 4)
  --mapping <file>       Path to function signatures JSON file
  --help                 Show help

Examples:
  # Preview conversion on all contracts
  node src/converter.js --dry-run "../../solidity/contracts/**/*.sol"

  # Convert single file
  node src/converter.js contracts/Mailbox.sol

  # Convert with lower threshold (3+ args)
  node src/converter.js --min-args 3 "contracts/**/*.sol"

  # Use custom mapping file
  node src/converter.js --mapping custom-mappings.json "contracts/**/*.sol"
```

## How It Works

### 1. Parsing
Uses `@solidity-parser/parser` to parse Solidity files into an Abstract Syntax Tree (AST).

### 2. Analysis
- **Extracts function definitions**: Builds a symbol table of all functions with their parameter names
- **Finds function calls**: Identifies all function calls with positional arguments
- **Resolves calls**: Matches calls to definitions by name and argument count

### 3. Transformation
- **Filters by threshold**: Only converts calls with ≥ N arguments (default: 4)
- **Formats named calls**: Converts `func(a, b, c, d)` to `func({p1: a, p2: b, p3: c, p4: d})`
- **Preserves formatting**: Uses single-line for short calls, multi-line for long calls
- **Applies changes**: Modifies source files (with backups)

### Resolution Strategy

The tool tries to resolve function parameter names in this order:

1. **Local functions**: Functions defined in the same file
2. **Symbol table**: Functions defined in other analyzed files
3. **Manual mappings**: External functions in `function-signatures.json`

### Edge Cases Handled

- ✅ Function overloading (matches by argument count)
- ✅ Member access calls (`obj.func()`)
- ✅ Inherited functions (if parent contract is analyzed)
- ✅ Multi-line function calls
- ✅ Nested function calls as arguments
- ✅ Already using named arguments (skipped)
- ✅ `abi.*` calls (skipped, as per solhint rule)
- ⚠️ Generic types/templates (needs manual mapping)
- ⚠️ External contracts not in codebase (needs manual mapping)

## Integration with solhint

After conversion, enable the solhint rule to enforce named parameters going forward:

```json
// .solhint.json
{
  "rules": {
    "func-named-parameters": ["error", 4]
  }
}
```

This will enforce that all function calls with 4+ arguments use named parameters.

## Troubleshooting

### "Could not extract source for call"
The parser couldn't determine the exact source text. Check if:
- The Solidity file has syntax errors
- The function call is very complex or unusual

**Solution**: Add a manual mapping or fix the call manually.

### "No matching overload found"
The function definition has a different number of parameters than the call.

**Solution**: Check for:
- Incorrect function name
- Missing/extra arguments in the call
- Need to add manual mapping with correct parameter count

### Conversion breaks compilation
This is rare but can happen with:
- Very complex macro-like patterns
- Non-standard Solidity syntax

**Solution**:
- Revert the file: `cp file.sol.bak file.sol`
- Add the function to an exclusion list (feature TODO)
- Fix manually

## Limitations

1. **Type inference**: Cannot resolve parameter names from:
   - External contracts without source
   - Complex inheritance chains not in the analyzed files
   - Dynamic dispatch (e.g., through interfaces with multiple implementations)

2. **Formatting**: The tool uses simple formatting rules. You may want to run `prettier` afterward:
   ```bash
   yarn prettier --write "contracts/**/*.sol"
   ```

3. **Testing**: Always review changes and run tests before committing.

## Example Workflow

```bash
# Step 1: Analyze the codebase
cd tools/solidity-named-args
npm install
node src/analyzer.js "../../solidity/contracts/**/*.sol"

# Step 2: Review unresolved-calls.json and add to function-signatures.json

# Step 3: Dry run on a subset
node src/converter.js --dry-run "../../solidity/contracts/Mailbox.sol"

# Step 4: If it looks good, convert for real
node src/converter.js "../../solidity/contracts/Mailbox.sol"

# Step 5: Test
cd ../../solidity
yarn test:forge
yarn test:hardhat

# Step 6: Review changes
git diff

# Step 7: Format with prettier
yarn prettier --write contracts/**/*.sol

# Step 8: Convert remaining files
cd ../tools/solidity-named-args
node src/converter.js "../../solidity/contracts/**/*.sol"

# Step 9: Final test
cd ../../solidity
yarn test

# Step 10: Commit
git add .
git commit -m "refactor: convert function calls to named arguments"
```

## Contributing

To improve the tool:

1. **Add more manual mappings**: Contribute commonly-used external functions to `function-signatures.json`
2. **Improve resolution**: Enhance the analyzer to handle more edge cases
3. **Better formatting**: Improve the formatting logic for better readability
4. **Exclusion list**: Add ability to exclude certain functions from conversion

## License

Apache-2.0 (same as Hyperlane monorepo)
