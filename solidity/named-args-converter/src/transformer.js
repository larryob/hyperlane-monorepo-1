/**
 * Transformer - Converts Solidity function calls to named arguments syntax
 *
 * This module handles the actual transformation of function calls from:
 *   functionName(arg1, arg2, arg3)
 * to:
 *   functionName({param1: arg1, param2: arg2, param3: arg3})
 */
import parser from '@solidity-parser/parser';

/**
 * Get the function name from a function call expression
 */
function getFunctionName(expression) {
  if (!expression) return null;

  switch (expression.type) {
    case 'Identifier':
      return expression.name;
    case 'MemberAccess':
      return expression.memberName;
    case 'NewExpression':
      // Constructor call: new ContractName(...)
      if (
        expression.typeName &&
        expression.typeName.type === 'UserDefinedTypeName'
      ) {
        return 'constructor';
      }
      return null;
    default:
      return null;
  }
}

/**
 * Get the contract context from a member access expression
 */
function getContractContext(expression) {
  if (!expression) return null;

  if (expression.type === 'MemberAccess') {
    const base = expression.expression;
    if (base.type === 'Identifier') {
      return base.name;
    }
  }

  if (expression.type === 'NewExpression') {
    // Constructor call: new ContractName(...)
    if (
      expression.typeName &&
      expression.typeName.type === 'UserDefinedTypeName'
    ) {
      return expression.typeName.namePath;
    }
  }

  return null;
}

/**
 * Check if a function call should be skipped
 */
function shouldSkipCall(node, funcName) {
  // Skip if already using named arguments
  if (node.names && node.names.length > 0) {
    return true;
  }

  // Skip calls with no arguments
  if (!node.arguments || node.arguments.length === 0) {
    return true;
  }

  // Skip ABI calls
  if (node.expression && node.expression.type === 'MemberAccess') {
    const base = node.expression.expression;
    if (base && base.type === 'Identifier' && base.name === 'abi') {
      return true;
    }
  }

  // Skip type conversions (e.g., address(x), uint256(y))
  if (node.expression && node.expression.type === 'ElementaryTypeName') {
    return true;
  }

  // Skip type casting to user-defined types (e.g., IContract(address))
  if (node.expression && node.expression.type === 'Identifier') {
    // Heuristic: if the name starts with uppercase, it might be a type cast
    const firstChar = funcName?.charAt(0);
    if (
      firstChar &&
      firstChar === firstChar.toUpperCase() &&
      node.arguments.length === 1
    ) {
      // This could be a type conversion, but we need context to be sure
      // For now, we'll skip single-argument calls to identifiers starting with uppercase
      // This might miss some valid conversions, but it's safer
    }
  }

  // Built-in global functions that should not use named arguments
  // Note: These only apply to non-member-access calls
  const globalBuiltIns = new Set([
    'require',
    'revert',
    'assert',
    'keccak256',
    'sha256',
    'sha3',
    'ripemd160',
    'ecrecover',
    'addmod',
    'mulmod',
    'blockhash',
    'selfdestruct',
    'suicide',
    'gasleft',
  ]);

  // Check for direct calls to global built-ins
  if (node.expression && node.expression.type === 'Identifier') {
    if (globalBuiltIns.has(funcName)) {
      return true;
    }
  }

  // Built-in member functions (on elementary types like address, arrays, etc.)
  // Only skip these if called on elementary types, not user-defined types
  const memberBuiltIns = new Set([
    'push',
    'pop',
    'concat',
    'call',
    'delegatecall',
    'staticcall',
    'send',
    'transfer',
  ]);

  if (node.expression && node.expression.type === 'MemberAccess') {
    const base = node.expression.expression;

    // Check if calling on an elementary type or type conversion
    // e.g., address(x).transfer(...), payable(x).send(...)
    if (base.type === 'FunctionCall' && base.expression) {
      // Likely a type conversion like address(...), payable(...)
      if (base.expression.type === 'ElementaryTypeName') {
        if (memberBuiltIns.has(funcName)) {
          return true;
        }
      }
    }

    // Check for direct member access on msg, block, tx
    if (base.type === 'Identifier') {
      if (['msg', 'block', 'tx'].includes(base.name)) {
        return true;
      }
    }

    // For arrays (identified by IndexAccess), skip push/pop
    if (base.type === 'IndexAccess') {
      if (['push', 'pop'].includes(funcName)) {
        return true;
      }
    }
  }

  return false;
}

/**
 * Transformer class for converting function calls to named arguments
 */
export class Transformer {
  constructor(registry, options = {}) {
    this.registry = registry;
    this.options = {
      minArgs: options.minArgs || 1, // Minimum args to require named params
      dryRun: options.dryRun || false,
      verbose: options.verbose || false,
      ...options,
    };
    this.changes = [];
  }

  /**
   * Transform a Solidity source file
   */
  transform(source, filePath = null) {
    // Parse the source
    let ast;
    try {
      ast = parser.parse(source, {
        loc: true,
        range: true,
        tolerant: true,
      });
    } catch (error) {
      console.error(`Parse error in ${filePath || 'source'}:`, error.message);
      return { source, changes: [], errors: [error.message] };
    }

    // Collect all function calls that need transformation
    this.changes = [];
    this._collectCalls(ast, source, filePath);

    // Apply transformations in reverse order (to preserve positions)
    if (!this.options.dryRun && this.changes.length > 0) {
      source = this._applyChanges(source);
    }

    return {
      source,
      changes: this.changes,
      errors: [],
    };
  }

  /**
   * Collect all function calls that need transformation
   */
  _collectCalls(ast, source, filePath) {
    const self = this;
    let currentContract = null;

    // Track variable types within contracts for resolving member access
    this.variableTypes = new Map();

    parser.visit(ast, {
      ContractDefinition(node) {
        currentContract = node.name;
        // Reset variable types for each contract
        self.variableTypes = new Map();
      },
      'ContractDefinition:exit'() {
        currentContract = null;
        self.variableTypes = new Map();
      },
      StateVariableDeclaration(node) {
        // Track state variable types (e.g., IExternal ext;)
        if (node.variables) {
          for (const variable of node.variables) {
            if (variable.name && variable.typeName) {
              const typeName = self._getTypeName(variable.typeName);
              if (typeName) {
                self.variableTypes.set(variable.name, typeName);
              }
            }
          }
        }
      },
      VariableDeclarationStatement(node) {
        // Track local variable declarations
        if (node.variables) {
          for (const variable of node.variables) {
            if (variable && variable.name && variable.typeName) {
              const typeName = self._getTypeName(variable.typeName);
              if (typeName) {
                self.variableTypes.set(variable.name, typeName);
              }
            }
          }
        }
      },
      FunctionCall(node) {
        self._processFunctionCall(node, source, currentContract);
      },
    });
  }

  /**
   * Get the type name from a TypeName AST node
   */
  _getTypeName(typeName) {
    if (!typeName) return null;

    switch (typeName.type) {
      case 'ElementaryTypeName':
        return typeName.name;
      case 'UserDefinedTypeName':
        return typeName.namePath;
      case 'ArrayTypeName':
        return this._getTypeName(typeName.baseTypeName) + '[]';
      default:
        return null;
    }
  }

  /**
   * Process a single function call
   */
  _processFunctionCall(node, source, currentContract) {
    const funcName = getFunctionName(node.expression);

    // Skip if no function name or should be skipped
    if (!funcName || shouldSkipCall(node, funcName)) {
      return;
    }

    // Skip if fewer args than minimum
    if (node.arguments.length < this.options.minArgs) {
      return;
    }

    // Try to find the function definition
    let contractContext = getContractContext(node.expression);
    let funcDef = null;

    // For member access calls, try to resolve the type from state variables
    if (node.expression.type === 'MemberAccess') {
      const varName = node.expression.expression?.name;
      if (varName && this.variableTypes && this.variableTypes.has(varName)) {
        contractContext = this.variableTypes.get(varName);
      }
    }

    // Try specific contract first, then fallback
    if (contractContext) {
      funcDef = this.registry.lookupFunction(
        funcName,
        node.arguments.length,
        contractContext,
      );
    }

    // Fallback to current contract context
    if (!funcDef && currentContract) {
      funcDef = this.registry.lookupFunction(
        funcName,
        node.arguments.length,
        currentContract,
      );
    }

    // Global fallback
    if (!funcDef) {
      funcDef = this.registry.lookupFunction(
        funcName,
        node.arguments.length,
        null,
      );
    }

    // Also check events and errors (for emit and revert statements)
    const eventDef = this.registry.lookupEvent(funcName, node.arguments.length);
    const errorDef = this.registry.lookupError(funcName, node.arguments.length);

    const definition = funcDef || eventDef || errorDef;

    if (!definition) {
      if (this.options.verbose) {
        console.log(
          `No definition found for ${funcName}(${node.arguments.length} args) in context ${contractContext || currentContract || 'global'}`,
        );
      }
      return;
    }

    // Skip if ambiguous (multiple overloads match)
    if (definition.ambiguous) {
      if (this.options.verbose) {
        console.log(`Ambiguous function ${funcName} - skipping`);
      }
      return;
    }

    // Get parameter names
    const paramNames = definition.params.map((p) => p.name);

    // Skip if any parameter name is missing
    if (paramNames.some((n) => !n)) {
      if (this.options.verbose) {
        console.log(`Function ${funcName} has unnamed parameters - skipping`);
      }
      return;
    }

    // Skip if number of args doesn't match parameters
    if (node.arguments.length !== paramNames.length) {
      return;
    }

    // Create the transformation
    this._createChange(node, source, funcName, paramNames);
  }

  /**
   * Create a change record for a function call
   */
  _createChange(node, source, funcName, paramNames) {
    if (!node.range) return;

    // Find the opening parenthesis after the function name
    const callStart = node.range[0];
    const callEnd = node.range[1];

    // Get the original call text
    const originalText = source.substring(callStart, callEnd + 1);

    // Find where arguments start (after the opening parenthesis)
    const parenIndex = originalText.indexOf('(');
    if (parenIndex === -1) return;

    // Get the function expression part
    const funcExprEnd = callStart + parenIndex;
    const funcExpr = source.substring(callStart, funcExprEnd);

    // Build the named arguments
    const argTexts = node.arguments.map((arg, i) => {
      if (!arg.range) return null;
      const argText = source.substring(arg.range[0], arg.range[1] + 1);
      return `${paramNames[i]}: ${argText}`;
    });

    if (argTexts.some((t) => t === null)) return;

    // Determine if we should use single-line or multi-line format
    const totalLength = funcExpr.length + argTexts.join(', ').length + 4;
    const useMultiLine = totalLength > 100 || argTexts.length > 3;

    let newArgsText;
    if (useMultiLine) {
      // Detect indentation from original
      const lineStart = source.lastIndexOf('\n', callStart) + 1;
      const indent =
        source.substring(lineStart, callStart).match(/^\s*/)?.[0] || '';
      const innerIndent = indent + '    ';
      newArgsText = `({\n${innerIndent}${argTexts.join(',\n' + innerIndent)}\n${indent}})`;
    } else {
      newArgsText = `({${argTexts.join(', ')}})`;
    }

    const newText = funcExpr + newArgsText;

    this.changes.push({
      funcName,
      paramNames,
      start: callStart,
      end: callEnd + 1,
      original: originalText,
      replacement: newText,
      loc: node.loc,
    });
  }

  /**
   * Apply all collected changes to the source
   */
  _applyChanges(source) {
    // Sort changes by start position in reverse order
    const sortedChanges = [...this.changes].sort((a, b) => b.start - a.start);

    let result = source;
    for (const change of sortedChanges) {
      result =
        result.substring(0, change.start) +
        change.replacement +
        result.substring(change.end);
    }

    return result;
  }

  /**
   * Get a summary of changes
   */
  getSummary() {
    const byFunction = new Map();
    for (const change of this.changes) {
      const count = byFunction.get(change.funcName) || 0;
      byFunction.set(change.funcName, count + 1);
    }

    return {
      totalChanges: this.changes.length,
      byFunction: Object.fromEntries(byFunction),
    };
  }
}

export default Transformer;
