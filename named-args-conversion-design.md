# Solidity Named Arguments Conversion - Design Document

## Overview

This document outlines a solution for automatically converting Solidity function calls to use named arguments syntax as specified in the [Solidity documentation](https://docs.soliditylang.org/en/latest/control-structures.html#function-calls-with-named-parameters).

## Background

### Current State
- The Hyperlane monorepo has ~150+ Solidity contracts
- Function calls currently use positional arguments: `dispatch(domain, recipient, body, metadata, hook)`
- solhint is already configured with the `func-named-parameters` rule (default: flags calls with 4+ unnamed args)

### Desired State
Convert function calls to named syntax:
```solidity
dispatch({
    destinationDomain: domain,
    recipientAddress: recipient,
    messageBody: body,
    metadata: metadata,
    hook: hook
})
```

## Key Challenge: Parameter Name Resolution

The main challenge is **mapping function calls to their definitions** to obtain parameter names. Consider:

```solidity
// Call site (in ContractA.sol)
mailbox.dispatch(domain, recipient, body);

// Definition could be in:
// 1. Same file
// 2. Parent contract (via inheritance)
// 3. Interface file (IMailbox.sol)
// 4. External contract
// 5. Library
```

## Proposed Solutions (3 Approaches)

### Option A: Manual Annotation + Simple Transform (RECOMMENDED FOR POC)

**Approach**: Create a mapping file that developers maintain with function signatures, then use simple text replacement.

**Pros**:
- Simple implementation (~200 lines of code)
- Fast execution
- No complex dependency resolution
- Developers can review and approve mappings
- Works for external contracts where source isn't available

**Cons**:
- Requires manual curation of function signature mappings
- Need to update mappings when function signatures change

**Implementation**:
```javascript
// function-signatures.json
{
  "Mailbox.dispatch": {
    "params": ["destinationDomain", "recipientAddress", "messageBody", "metadata", "hook"],
    "minParams": 3  // Has overloads with 3, 4, or 5 params
  },
  "Message.formatMessage": {
    "params": ["version", "nonce", "localDomain", "sender", "destinationDomain", "recipient", "body"]
  }
}
```

### Option B: AST-Based with Local Resolution

**Approach**: Parse all Solidity files, build a symbol table of function definitions, and match calls to definitions within the same codebase.

**Pros**:
- Automated for internal functions
- Accurate parameter names
- Can handle inheritance within the codebase

**Cons**:
- Cannot resolve external contracts (OpenZeppelin, etc.)
- Complex import resolution
- Slower processing
- May miss functions defined in other packages

**Implementation Complexity**: ~1000+ lines of code

### Option C: Full Type Resolution with Foundry/Hardhat

**Approach**: Use existing compiler artifacts and type information from Foundry/Hardhat builds.

**Pros**:
- Complete type information
- Handles all imports and dependencies
- Accurate resolution

**Cons**:
- Very complex implementation
- Requires successful compilation
- Dependent on build artifacts
- Slower processing

**Implementation Complexity**: ~2000+ lines of code

## Recommended Approach: Hybrid Strategy

Combine multiple approaches for practical results:

### Phase 1: Local + Manual (Immediate Value)
1. Use AST parsing to find all function calls with 4+ unnamed parameters
2. For each call, attempt to resolve definition in same file or via simple import
3. For unresolved calls, output to a manual mapping file for developer input
4. Apply transformations using resolved + manual mappings

### Phase 2: Enhanced Resolution (Future)
1. Integrate with Foundry's AST output for better symbol resolution
2. Build import graph for cross-file resolution
3. Cache results to speed up subsequent runs

## Implementation Plan

### Tool Architecture

```
solidity-named-args-converter/
├── src/
│   ├── parser.js           # Parse Solidity to AST using @solidity-parser/parser
│   ├── analyzer.js         # Find function calls, build symbol table
│   ├── resolver.js         # Resolve function definitions
│   ├── transformer.js      # Transform calls to named syntax
│   ├── writer.js           # Write modified source back
│   └── index.js           # CLI entry point
├── mappings/
│   ├── auto-detected.json  # Auto-detected function signatures
│   └── manual.json         # Manual overrides/external functions
├── package.json
└── README.md
```

### Core Algorithm

```javascript
// Pseudo-code
function convertToNamedArgs(sourceFile) {
  // 1. Parse source
  const ast = parser.parse(sourceFile);

  // 2. Build local symbol table
  const localFunctions = extractFunctionDefinitions(ast);

  // 3. Find function calls
  const calls = findFunctionCalls(ast);

  // 4. Resolve each call
  const transformations = [];
  for (const call of calls) {
    // Skip if already using named args
    if (call.names.length > 0) continue;

    // Skip if fewer than threshold args
    if (call.arguments.length < MIN_ARGS) continue;

    // Try to resolve parameter names
    let paramNames = localFunctions[call.name];
    if (!paramNames) {
      paramNames = loadFromManualMappings(call);
    }

    if (paramNames) {
      transformations.push({
        location: call.location,
        original: call.text,
        replacement: formatNamedCall(call, paramNames)
      });
    } else {
      // Output for manual mapping
      logUnresolved(call);
    }
  }

  // 5. Apply transformations (back to front to preserve positions)
  const modifiedSource = applyTransformations(sourceFile, transformations);

  return modifiedSource;
}
```

### Handling Edge Cases

1. **Function Overloading**: Match by argument count
2. **Inherited Functions**: Build inheritance tree, search parent contracts
3. **Interface Functions**: Parse interface files from imports
4. **External Libraries**: Use manual mappings
5. **Member Access** (e.g., `obj.func()`): Track object type
6. **Constructor Calls**: Use contract constructor signature
7. **Modifier Calls**: Usually don't need conversion (fewer params)

## Alternative: solhint Auto-Fix Plugin

Instead of a standalone tool, we could extend solhint with an auto-fix capability:

```javascript
// In solhint-plugin-hyperlane/index.js
class FunctionNamedParametersAutoFix extends BaseChecker {
  FunctionCall(node) {
    if (shouldConvert(node)) {
      const paramNames = resolveParameterNames(node);
      if (paramNames) {
        this.reporter.error(node, ruleId, message, {
          fix: (fixer) => fixer.replaceText(node, formatNamedCall(node, paramNames))
        });
      }
    }
  }
}
```

**Pros**: Integrates with existing tooling, familiar to devs
**Cons**: solhint auto-fix is less mature than ESLint's

## Testing Strategy

1. **Unit Tests**: Test individual components (parser, resolver, transformer)
2. **Integration Tests**: Test on sample Solidity contracts
3. **Regression Tests**: Run on subset of Hyperlane contracts, verify:
   - Code still compiles
   - Tests still pass
   - Gas costs unchanged
4. **Manual Review**: Diff the changes before committing

## Rollout Plan

1. **Create POC tool** (Phase 1 approach)
2. **Test on 5-10 sample contracts** manually
3. **Generate manual mapping file** for common external functions
4. **Run on full codebase**, generate unresolved list
5. **Developer review** of unresolved calls, update manual mappings
6. **Apply transformations** to all contracts
7. **Enable solhint rule** (`func-named-parameters: error`) to enforce going forward
8. **CI Integration**: Fail builds on unnamed parameter usage

## Open Questions

1. Should we convert ALL function calls or only those with 4+ parameters?
   - **Recommendation**: Start with 4+ (matches solhint default), can lower threshold later

2. How to handle very long parameter lists (wrapping/formatting)?
   - **Recommendation**: Use prettier for formatting after conversion

3. Should we convert internal function calls or only external ones?
   - **Recommendation**: Convert all to maintain consistency

4. What about library function calls (e.g., `Message.formatMessage()`)?
   - **Recommendation**: Include in manual mappings

## Timeline Estimate

- **POC Tool (Phase 1)**: 2-3 days
- **Manual Mappings**: 1 day (parallel)
- **Testing & Refinement**: 1-2 days
- **Full Codebase Conversion**: 1 day
- **Review & Cleanup**: 1 day

**Total**: ~1 week for complete conversion

## Next Steps

1. Get stakeholder approval on approach
2. Create function-signatures.json with common Hyperlane functions
3. Build POC converter tool
4. Test on sample contracts (Mailbox, Router, Token contracts)
5. Iterate based on results
