#!/usr/bin/env node

/**
 * Converter: Transforms Solidity function calls to use named arguments
 *
 * This module takes the analysis results and applies transformations to convert
 * positional arguments to named arguments.
 */

import parser from '@solidity-parser/parser';
import fs from 'fs';
import path from 'path';
import { analyzeFile, buildSymbolTable } from './analyzer.js';
import { extractArgumentsSimple } from './argument-extractor.js';

/**
 * Load manual function signatures from a JSON file
 */
export function loadManualSignatures(mappingFile) {
  if (!fs.existsSync(mappingFile)) {
    return new Map();
  }

  const content = fs.readFileSync(mappingFile, 'utf-8');
  const json = JSON.parse(content);

  const signatures = new Map();
  for (const [key, value] of Object.entries(json)) {
    signatures.set(key, value);
  }

  return signatures;
}

/**
 * Format a function call with named arguments
 */
export function formatNamedCall(call, paramNames, sourceCode) {
  // Extract the function expression part (before the arguments)
  let functionExpr = call.fullExpression || call.functionName;

  // Build the named arguments
  // Use improved argument extraction that handles nesting
  let argTexts;
  try {
    argTexts = extractArgumentsSimple(call.node, sourceCode);
  } catch (error) {
    console.warn(`Warning: Could not extract arguments, using fallback`);
    argTexts = call.arguments.map(reconstructArgument);
  }

  const namedArgs = [];
  for (let i = 0; i < call.argumentCount; i++) {
    const paramName = paramNames[i] || `_param${i}`;
    const argText = argTexts[i] || reconstructArgument(call.arguments[i]);
    namedArgs.push(`${paramName}: ${argText}`);
  }

  // Format the call
  // For short calls (1-2 args or total length < 80), use single line
  const singleLine = `${functionExpr}({${namedArgs.join(', ')}})`;

  if (namedArgs.length <= 2 || singleLine.length < 80) {
    return singleLine;
  }

  // For longer calls, use multi-line format
  const indent = '    '; // 4 spaces
  const formattedArgs = namedArgs.map(arg => `${indent}${arg}`).join(',\n');

  return `${functionExpr}({\n${formattedArgs}\n})`;
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
  // Note: loc.end.column appears to be exclusive (points after last char)
  const endCol = loc.end.column;

  if (startLine === endLine) {
    return lines[startLine].substring(startCol, endCol);
  }

  // Multi-line argument
  let text = lines[startLine].substring(startCol);
  for (let i = startLine + 1; i < endLine; i++) {
    text += '\n' + lines[i];
  }
  text += '\n' + lines[endLine].substring(0, endCol);

  return text;
}

/**
 * Reconstruct argument text from AST node (fallback)
 */
function reconstructArgument(node) {
  if (!node) return '_';

  switch (node.type) {
    case 'Identifier':
      return node.name;
    case 'NumberLiteral':
      return node.number;
    case 'BooleanLiteral':
      return node.value ? 'true' : 'false';
    case 'StringLiteral':
      return `"${node.value}"`;
    case 'MemberAccess':
      return `${reconstructArgument(node.expression)}.${node.memberName}`;
    case 'FunctionCall':
      const args = node.arguments.map(reconstructArgument).join(', ');
      return `${reconstructArgument(node.expression)}(${args})`;
    case 'BinaryOperation':
      return `${reconstructArgument(node.left)} ${node.operator} ${reconstructArgument(node.right)}`;
    case 'IndexAccess':
      return `${reconstructArgument(node.base)}[${reconstructArgument(node.index)}]`;
    default:
      return '...'; // Complex expression
  }
}

/**
 * Convert a single file
 */
export function convertFile(
  filePath,
  symbolTable,
  manualSignatures,
  options = {}
) {
  const {
    minArgs = 4,
    dryRun = false,
    backup = true
  } = options;

  console.log(`\nConverting ${path.basename(filePath)}...`);

  const source = fs.readFileSync(filePath, 'utf-8');
  const analysis = analyzeFile(filePath, symbolTable);

  // Filter calls that need conversion
  const toConvert = analysis.resolvedCalls.filter(c => c.argumentCount >= minArgs);

  // Try to resolve unresolved calls with manual signatures
  for (const call of analysis.unresolvedCalls) {
    if (call.argumentCount < minArgs) continue;

    const key = call.fullExpression || call.functionName;
    if (manualSignatures.has(key)) {
      const sig = manualSignatures.get(key);
      if (sig.params && sig.params.length === call.argumentCount) {
        toConvert.push({
          ...call,
          paramNames: sig.params,
          definedIn: 'manual-mapping'
        });
      }
    }
  }

  if (toConvert.length === 0) {
    console.log('  No function calls to convert.');
    return { file: filePath, converted: 0 };
  }

  console.log(`  Found ${toConvert.length} calls to convert`);

  // Sort by location (reverse order) so we can apply transformations back-to-front
  toConvert.sort((a, b) => {
    if (a.loc.start.line !== b.loc.start.line) {
      return b.loc.start.line - a.loc.start.line;
    }
    return b.loc.start.column - a.loc.start.column;
  });

  // Apply transformations
  let modifiedSource = source;
  const transformations = [];

  for (const call of toConvert) {
    try {
      const replacement = formatNamedCall(call, call.paramNames, source);
      const original = call.sourceText || extractSourceText(source, call.loc);

      if (!original) {
        console.warn(`  ⚠ Could not extract source for call at line ${call.loc.start.line}`);
        continue;
      }

      // Replace in source
      const beforeLength = modifiedSource.length;
      modifiedSource = replaceAtLocation(modifiedSource, call.loc, original, replacement);
      const afterLength = modifiedSource.length;

      transformations.push({
        line: call.loc.start.line,
        function: call.fullExpression || call.functionName,
        original: original.substring(0, 50) + (original.length > 50 ? '...' : ''),
        replacement: replacement.substring(0, 50) + (replacement.length > 50 ? '...' : '')
      });

      console.log(`  ✓ Line ${call.loc.start.line}: ${call.fullExpression || call.functionName}`);
    } catch (error) {
      console.error(`  ✗ Error converting call at line ${call.loc.start.line}:`, error.message);
    }
  }

  if (!dryRun && transformations.length > 0) {
    // Create backup
    if (backup) {
      fs.writeFileSync(filePath + '.bak', source);
    }

    // Write modified source
    fs.writeFileSync(filePath, modifiedSource);
    console.log(`  ✓ Written ${transformations.length} transformations to ${path.basename(filePath)}`);

    if (backup) {
      console.log(`  ✓ Backup saved to ${path.basename(filePath)}.bak`);
    }
  }

  return {
    file: filePath,
    converted: transformations.length,
    transformations
  };
}

/**
 * Replace text at a specific location in source code
 */
function replaceAtLocation(source, loc, original, replacement) {
  const lines = source.split('\n');
  const startLine = loc.start.line - 1;
  const endLine = loc.end.line - 1;
  const startCol = loc.start.column;
  const endCol = loc.end.column + 1;

  if (startLine === endLine) {
    // Single line replacement
    const line = lines[startLine];
    lines[startLine] = line.substring(0, startCol) + replacement + line.substring(endCol);
  } else {
    // Multi-line replacement - replace with single line
    const firstLine = lines[startLine].substring(0, startCol);
    const lastLine = lines[endLine].substring(endCol);

    lines[startLine] = firstLine + replacement + lastLine;
    lines.splice(startLine + 1, endLine - startLine);
  }

  return lines.join('\n');
}

/**
 * Convert multiple files
 */
export function convertFiles(files, options = {}) {
  const {
    minArgs = 4,
    dryRun = false,
    backup = true,
    mappingFile = 'function-signatures.json'
  } = options;

  console.log('Building symbol table from all files...');
  const symbolTable = buildSymbolTable(files);

  console.log('Loading manual function signatures...');
  const manualSignatures = loadManualSignatures(mappingFile);
  console.log(`Loaded ${manualSignatures.size} manual signatures`);

  const results = [];
  let totalConverted = 0;

  for (const file of files) {
    try {
      const result = convertFile(file, symbolTable, manualSignatures, {
        minArgs,
        dryRun,
        backup
      });
      results.push(result);
      totalConverted += result.converted;
    } catch (error) {
      console.error(`Error processing ${file}:`, error.message);
    }
  }

  console.log('\n' + '='.repeat(80));
  console.log('CONVERSION SUMMARY');
  console.log('='.repeat(80));
  console.log(`Total files processed: ${files.length}`);
  console.log(`Total function calls converted: ${totalConverted}`);

  if (dryRun) {
    console.log('\n⚠ DRY RUN - No files were modified');
  }

  console.log('='.repeat(80));

  return results;
}

/**
 * CLI entry point
 */
if (import.meta.url === `file://${process.argv[1]}`) {
  const args = process.argv.slice(2);

  let dryRun = false;
  let minArgs = 4;
  let mappingFile = 'function-signatures.json';
  const files = [];

  // Parse arguments
  for (let i = 0; i < args.length; i++) {
    const arg = args[i];
    if (arg === '--dry-run') {
      dryRun = true;
    } else if (arg === '--min-args') {
      minArgs = parseInt(args[++i], 10);
    } else if (arg === '--mapping') {
      mappingFile = args[++i];
    } else if (arg === '--help') {
      console.log('Usage: node converter.js [options] <file-pattern> [<file-pattern> ...]');
      console.log('');
      console.log('Options:');
      console.log('  --dry-run              Show what would be converted without modifying files');
      console.log('  --min-args <n>         Minimum number of arguments to trigger conversion (default: 4)');
      console.log('  --mapping <file>       Path to function signatures JSON file (default: function-signatures.json)');
      console.log('');
      console.log('Examples:');
      console.log('  node converter.js --dry-run "contracts/**/*.sol"');
      console.log('  node converter.js --min-args 3 contracts/Mailbox.sol');
      process.exit(0);
    } else {
      files.push(arg);
    }
  }

  if (files.length === 0) {
    console.log('Usage: node converter.js [--dry-run] [--min-args N] <file> [<file> ...]');
    console.log('Run with --help for more options');
    process.exit(1);
  }

  const { globSync } = await import('glob');
  const expandedFiles = [];
  for (const pattern of files) {
    if (pattern.includes('*')) {
      expandedFiles.push(...globSync(pattern));
    } else {
      expandedFiles.push(pattern);
    }
  }

  console.log(`Processing ${expandedFiles.length} files...`);
  console.log(`Minimum arguments for conversion: ${minArgs}`);
  console.log(`Dry run: ${dryRun}\n`);

  convertFiles(expandedFiles, { minArgs, dryRun, mappingFile });
}
