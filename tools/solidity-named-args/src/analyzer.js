#!/usr/bin/env node

/**
 * Analyzer: Finds function definitions and calls in Solidity files
 *
 * This module parses Solidity files and extracts:
 * 1. Function definitions with parameter names
 * 2. Function calls with their arguments
 */

import parser from '@solidity-parser/parser';
import fs from 'fs';
import path from 'path';

/**
 * Extract all function definitions from an AST
 */
export function extractFunctionDefinitions(ast, filePath = '') {
  const functions = new Map();

  parser.visit(ast, {
    FunctionDefinition(node) {
      if (!node.name) return; // Skip constructor/fallback/receive

      const paramNames = node.parameters.map(param => param.name || '_unnamed');
      const key = node.name;

      // Store function signature
      if (!functions.has(key)) {
        functions.set(key, []);
      }

      functions.get(key).push({
        name: node.name,
        paramNames,
        paramCount: paramNames.length,
        visibility: node.visibility,
        isConstructor: node.isConstructor,
        file: filePath,
        loc: node.loc
      });
    },

    ModifierDefinition(node) {
      const paramNames = node.parameters.map(param => param.name || '_unnamed');
      const key = node.name;

      if (!functions.has(key)) {
        functions.set(key, []);
      }

      functions.get(key).push({
        name: node.name,
        paramNames,
        paramCount: paramNames.length,
        isModifier: true,
        file: filePath,
        loc: node.loc
      });
    }
  });

  return functions;
}

/**
 * Extract all function calls from an AST
 */
export function extractFunctionCalls(ast, sourceCode, filePath = '') {
  const calls = [];

  parser.visit(ast, {
    FunctionCall(node) {
      // Skip calls that already use named arguments
      if (node.names && node.names.length > 0) {
        return;
      }

      // Skip if no arguments
      if (!node.arguments || node.arguments.length === 0) {
        return;
      }

      // Determine the function name
      let functionName = null;
      let fullExpression = null;

      if (node.expression.type === 'Identifier') {
        functionName = node.expression.name;
        fullExpression = functionName;
      } else if (node.expression.type === 'MemberAccess') {
        functionName = node.expression.memberName;
        // For member access like obj.func(), store as "Type.func" or "obj.func"
        if (node.expression.expression.type === 'Identifier') {
          const base = node.expression.expression.name;
          fullExpression = `${base}.${functionName}`;
        } else {
          fullExpression = functionName;
        }
      }

      if (!functionName) return;

      // Skip abi.* calls (as per solhint rule)
      if (fullExpression && fullExpression.startsWith('abi.')) {
        return;
      }

      // Extract the source text for this call
      let sourceText = null;
      if (node.loc && sourceCode) {
        sourceText = extractSourceText(sourceCode, node.loc);
      }

      calls.push({
        functionName,
        fullExpression,
        argumentCount: node.arguments.length,
        arguments: node.arguments,
        loc: node.loc,
        sourceText,
        file: filePath,
        node
      });
    }
  });

  return calls;
}

/**
 * Extract source text from location information
 */
function extractSourceText(sourceCode, loc) {
  if (!loc || !loc.start || !loc.end) return null;

  const lines = sourceCode.split('\n');
  const startLine = loc.start.line - 1;
  const endLine = loc.end.line - 1;
  const startCol = loc.start.column;
  const endCol = loc.end.column + 1; // end column is inclusive

  if (startLine === endLine) {
    return lines[startLine].substring(startCol, endCol);
  }

  // Multi-line call
  let text = lines[startLine].substring(startCol) + '\n';
  for (let i = startLine + 1; i < endLine; i++) {
    text += lines[i] + '\n';
  }
  text += lines[endLine].substring(0, endCol);

  return text;
}

/**
 * Build a symbol table from multiple files
 */
export function buildSymbolTable(files) {
  const symbolTable = new Map();

  for (const file of files) {
    try {
      const source = fs.readFileSync(file, 'utf-8');
      const ast = parser.parse(source, { loc: true, range: true });
      const functions = extractFunctionDefinitions(ast, file);

      // Merge into global symbol table
      for (const [name, definitions] of functions) {
        if (!symbolTable.has(name)) {
          symbolTable.set(name, []);
        }
        symbolTable.get(name).push(...definitions);
      }
    } catch (error) {
      console.error(`Error parsing ${file}:`, error.message);
    }
  }

  return symbolTable;
}

/**
 * Analyze a single file
 */
export function analyzeFile(filePath, symbolTable = null) {
  const source = fs.readFileSync(filePath, 'utf-8');
  const ast = parser.parse(source, { loc: true, range: true });

  const localFunctions = extractFunctionDefinitions(ast, filePath);
  const calls = extractFunctionCalls(ast, source, filePath);

  // Try to resolve each call
  const results = {
    file: filePath,
    totalCalls: calls.length,
    resolvedCalls: [],
    unresolvedCalls: []
  };

  for (const call of calls) {
    // Try local functions first
    let resolved = localFunctions.get(call.functionName);

    // Then try symbol table
    if (!resolved && symbolTable) {
      resolved = symbolTable.get(call.functionName);
    }

    // Find matching overload by argument count
    let match = null;
    if (resolved) {
      match = resolved.find(def => def.paramCount === call.argumentCount);
    }

    if (match) {
      results.resolvedCalls.push({
        ...call,
        paramNames: match.paramNames,
        definedIn: match.file
      });
    } else {
      results.unresolvedCalls.push(call);
    }
  }

  return results;
}

/**
 * Generate a report of function calls that need conversion
 */
export function generateReport(files, minArgs = 4) {
  console.log('Building symbol table...');
  const symbolTable = buildSymbolTable(files);
  console.log(`Found ${symbolTable.size} unique function names across all files\n`);

  const report = {
    totalFiles: files.length,
    totalCalls: 0,
    callsNeedingConversion: 0,
    resolvedCalls: 0,
    unresolvedCalls: 0,
    byFile: []
  };

  for (const file of files) {
    console.log(`Analyzing ${path.basename(file)}...`);
    const analysis = analyzeFile(file, symbolTable);

    // Filter by minimum arguments
    const needsConversion = {
      resolved: analysis.resolvedCalls.filter(c => c.argumentCount >= minArgs),
      unresolved: analysis.unresolvedCalls.filter(c => c.argumentCount >= minArgs)
    };

    report.totalCalls += analysis.totalCalls;
    report.callsNeedingConversion += needsConversion.resolved.length + needsConversion.unresolved.length;
    report.resolvedCalls += needsConversion.resolved.length;
    report.unresolvedCalls += needsConversion.unresolved.length;

    if (needsConversion.resolved.length > 0 || needsConversion.unresolved.length > 0) {
      report.byFile.push({
        file,
        ...needsConversion
      });
    }
  }

  return report;
}

/**
 * CLI entry point
 */
if (import.meta.url === `file://${process.argv[1]}`) {
  const args = process.argv.slice(2);

  if (args.length === 0) {
    console.log('Usage: node analyzer.js <solidity-file> [<solidity-file> ...]');
    console.log('       node analyzer.js "contracts/**/*.sol"');
    process.exit(1);
  }

  const { globSync } = await import('glob');
  const files = [];
  for (const arg of args) {
    if (arg.includes('*')) {
      files.push(...globSync(arg));
    } else {
      files.push(arg);
    }
  }

  const report = generateReport(files, 4);

  console.log('\n' + '='.repeat(80));
  console.log('ANALYSIS REPORT');
  console.log('='.repeat(80));
  console.log(`Total files analyzed: ${report.totalFiles}`);
  console.log(`Total function calls found: ${report.totalCalls}`);
  console.log(`Calls needing conversion (≥4 args): ${report.callsNeedingConversion}`);
  console.log(`  - Resolved (can auto-convert): ${report.resolvedCalls}`);
  console.log(`  - Unresolved (need manual mapping): ${report.unresolvedCalls}`);
  console.log('='.repeat(80));

  console.log('\nDetails by file:');
  for (const fileReport of report.byFile) {
    console.log(`\n${path.basename(fileReport.file)}:`);

    if (fileReport.resolved.length > 0) {
      console.log(`  Resolved calls (${fileReport.resolved.length}):`);
      for (const call of fileReport.resolved.slice(0, 3)) {
        console.log(`    - ${call.fullExpression || call.functionName}(${call.argumentCount} args) at line ${call.loc.start.line}`);
      }
      if (fileReport.resolved.length > 3) {
        console.log(`    ... and ${fileReport.resolved.length - 3} more`);
      }
    }

    if (fileReport.unresolved.length > 0) {
      console.log(`  Unresolved calls (${fileReport.unresolved.length}):`);
      for (const call of fileReport.unresolved.slice(0, 3)) {
        console.log(`    - ${call.fullExpression || call.functionName}(${call.argumentCount} args) at line ${call.loc.start.line}`);
      }
      if (fileReport.unresolved.length > 3) {
        console.log(`    ... and ${fileReport.unresolved.length - 3} more`);
      }
    }
  }

  // Export unresolved calls for manual mapping
  if (report.unresolvedCalls > 0) {
    const unresolvedList = [];
    for (const fileReport of report.byFile) {
      for (const call of fileReport.unresolved) {
        unresolvedList.push({
          function: call.fullExpression || call.functionName,
          argumentCount: call.argumentCount,
          file: path.basename(call.file),
          line: call.loc.start.line
        });
      }
    }

    const outputFile = 'unresolved-calls.json';
    fs.writeFileSync(outputFile, JSON.stringify(unresolvedList, null, 2));
    console.log(`\n✓ Unresolved calls exported to ${outputFile}`);
    console.log('  You can create manual mappings for these in function-signatures.json');
  }
}
