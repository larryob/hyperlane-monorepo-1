#!/usr/bin/env tsx
import * as fs from 'fs';
import * as path from 'path';
import { fileURLToPath } from 'url';

interface FunctionSignature {
  name: string;
  signature: string;
  isView: boolean;
  isPure: boolean;
}

interface ContractInfo {
  name: string;
  filePath: string;
  functions: FunctionSignature[];
  events: string[];
  errors: string[];
  imports: Set<string>;
}

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const CONTRACTS_DIR = path.join(__dirname, '..', 'contracts');
const INTERFACES_DIR = path.join(__dirname, '..', 'contracts', 'interfaces');

/**
 * Recursively find all Solidity files
 */
function findSolidityFiles(dir: string): string[] {
  const files: string[] = [];
  const entries = fs.readdirSync(dir, { withFileTypes: true });

  for (const entry of entries) {
    const fullPath = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      // Skip interfaces, test, and mock directories
      if (
        !entry.name.includes('interface') &&
        entry.name !== 'test' &&
        entry.name !== 'mock'
      ) {
        files.push(...findSolidityFiles(fullPath));
      }
    } else if (entry.isFile() && entry.name.endsWith('.sol')) {
      // Skip files that are already interfaces (start with I)
      if (!entry.name.startsWith('I') && !entry.name.includes('Interface')) {
        files.push(fullPath);
      }
    }
  }

  return files;
}

/**
 * Extract contract information from a Solidity file
 */
function extractContractInfo(filePath: string): ContractInfo | null {
  const content = fs.readFileSync(filePath, 'utf-8');

  // Extract contract name - look for contract, abstract contract
  const contractMatch = content.match(/(?:abstract\s+)?contract\s+(\w+)/);
  if (!contractMatch) {
    return null; // Not a contract (might be a library or interface)
  }

  const contractName = contractMatch[1];
  const functions: FunctionSignature[] = [];
  const events: string[] = [];
  const errors: string[] = [];
  const imports = new Set<string>();

  // Extract imports for interface types
  const importMatches = content.matchAll(
    /import\s+(?:\{[^}]+\}|[^;]+)\s+from\s+["']([^"']+)["']/g,
  );
  for (const match of importMatches) {
    const importPath = match[1];
    // Only keep interface imports
    if (importPath.includes('interface') || importPath.includes('/I')) {
      imports.add(importPath);
    }
  }

  // Extract specific interface imports
  const interfaceImportMatches = content.matchAll(
    /import\s+\{([^}]+)\}\s+from/g,
  );
  for (const match of interfaceImportMatches) {
    const importedTypes = match[1].split(',').map((t) => t.trim());
    for (const type of importedTypes) {
      if (type.startsWith('I') || type.includes('Interface')) {
        const cleanType = type.replace(/\s+as\s+\w+/, '');
        imports.add(cleanType);
      }
    }
  }

  // Extract events
  const eventMatches = content.matchAll(/event\s+(\w+)\s*\([^)]*\)\s*;/g);
  for (const match of eventMatches) {
    events.push(match[0].trim());
  }

  // Extract errors
  const errorMatches = content.matchAll(/error\s+(\w+)\s*\([^)]*\)\s*;/g);
  for (const match of errorMatches) {
    errors.push(match[0].trim());
  }

  // Extract public and external functions
  // This regex looks for function definitions with public or external visibility
  const functionRegex =
    /function\s+(\w+)\s*\([^)]*\)[^;{]*(?:external|public)[^;{]*(?:returns\s*\([^)]*\))?\s*(?:;|{)/g;

  let match;
  while ((match = functionRegex.exec(content)) !== null) {
    const functionStart = match.index;
    const functionName = match[1];

    // Extract the full function signature including modifiers
    let braceCount = 0;
    let endIndex = match.index + match[0].length;

    if (match[0].includes('{')) {
      braceCount = 1;
      for (let i = endIndex; i < content.length && braceCount > 0; i++) {
        if (content[i] === '{') braceCount++;
        if (content[i] === '}') braceCount--;
        endIndex = i + 1;
      }
    }

    // Get the function signature up to the opening brace or semicolon
    const fullMatch = content.substring(functionStart, endIndex);
    let signature = fullMatch;

    // Clean up the signature - remove function body and keep only declaration
    if (signature.includes('{')) {
      signature = signature.substring(0, signature.indexOf('{')).trim();
    }

    // Check if it's external or public
    if (!signature.includes('external') && !signature.includes('public')) {
      continue;
    }

    // Convert to interface format (all functions in interfaces are external by default)
    signature = signature.replace(/\bpublic\b/, 'external');

    // Remove modifiers that aren't part of the interface
    signature = signature.replace(
      /\b(payable|nonReentrant|onlyOwner|override\([^)]*\))\b/g,
      (match) => {
        // Keep payable, remove others
        return match === 'payable' ? match : '';
      },
    );

    // Clean up whitespace
    signature = signature.replace(/\s+/g, ' ').trim();

    // Ensure it ends with semicolon
    if (!signature.endsWith(';')) {
      signature += ';';
    }

    const isView = signature.includes('view');
    const isPure = signature.includes('pure');

    functions.push({
      name: functionName,
      signature,
      isView,
      isPure,
    });
  }

  return {
    name: contractName,
    filePath,
    functions,
    events,
    errors,
    imports,
  };
}

/**
 * Generate interface file content
 */
function generateInterface(contractInfo: ContractInfo): string {
  const interfaceName = `I${contractInfo.name}`;
  const lines: string[] = [];

  // Add SPDX license
  lines.push('// SPDX-License-Identifier: MIT OR Apache-2.0');
  lines.push('pragma solidity >=0.8.0;');
  lines.push('');

  // Add imports for interface types
  if (contractInfo.imports.size > 0) {
    // Organize imports by path
    const importMap = new Map<string, Set<string>>();

    // Try to extract import statements from original file
    const content = fs.readFileSync(contractInfo.filePath, 'utf-8');
    const importMatches = content.matchAll(
      /import\s+\{([^}]+)\}\s+from\s+["']([^"']+)["']/g,
    );

    for (const match of importMatches) {
      const types = match[1].split(',').map((t) => t.trim());
      const importPath = match[2];

      for (const type of types) {
        const cleanType = type.replace(/\s+as\s+.*/, '').trim();
        if (cleanType.startsWith('I') || importPath.includes('interface')) {
          if (!importMap.has(importPath)) {
            importMap.set(importPath, new Set());
          }
          importMap.get(importPath)!.add(cleanType);
        }
      }
    }

    // Add organized imports
    for (const [importPath, types] of importMap) {
      if (types.size > 0) {
        lines.push(
          `import {${Array.from(types).join(', ')}} from "${importPath}";`,
        );
      }
    }

    if (importMap.size > 0) {
      lines.push('');
    }
  }

  // Start interface definition
  lines.push(`interface ${interfaceName} {`);

  // Add events
  if (contractInfo.events.length > 0) {
    lines.push('    // ============ Events ============');
    for (const event of contractInfo.events) {
      lines.push(`    ${event}`);
    }
    lines.push('');
  }

  // Add errors
  if (contractInfo.errors.length > 0) {
    lines.push('    // ============ Errors ============');
    for (const error of contractInfo.errors) {
      lines.push(`    ${error}`);
    }
    lines.push('');
  }

  // Add functions
  if (contractInfo.functions.length > 0) {
    lines.push('    // ============ Functions ============');
    for (const func of contractInfo.functions) {
      lines.push(`    ${func.signature}`);
    }
  }

  lines.push('}');
  lines.push('');

  return lines.join('\n');
}

/**
 * Main function
 */
function main() {
  console.log('🔍 Finding Solidity contract files...');
  const solidityFiles = findSolidityFiles(CONTRACTS_DIR);
  console.log(`Found ${solidityFiles.length} contract files`);

  // Ensure interfaces directory exists
  if (!fs.existsSync(INTERFACES_DIR)) {
    fs.mkdirSync(INTERFACES_DIR, { recursive: true });
  }

  const generatedDir = path.join(INTERFACES_DIR, 'generated');
  if (!fs.existsSync(generatedDir)) {
    fs.mkdirSync(generatedDir, { recursive: true });
  }

  let successCount = 0;
  let skipCount = 0;

  for (const filePath of solidityFiles) {
    try {
      const contractInfo = extractContractInfo(filePath);

      if (!contractInfo) {
        skipCount++;
        continue;
      }

      // Skip if no public/external functions
      if (
        contractInfo.functions.length === 0 &&
        contractInfo.events.length === 0 &&
        contractInfo.errors.length === 0
      ) {
        console.log(`⏭️  Skipping ${contractInfo.name} (no public interface)`);
        skipCount++;
        continue;
      }

      const interfaceContent = generateInterface(contractInfo);
      const interfaceName = `I${contractInfo.name}`;
      const outputPath = path.join(generatedDir, `${interfaceName}.sol`);

      fs.writeFileSync(outputPath, interfaceContent);
      console.log(`✅ Generated ${interfaceName}.sol`);
      successCount++;
    } catch (error) {
      console.error(`❌ Error processing ${filePath}:`, error);
    }
  }

  console.log('');
  console.log('📊 Summary:');
  console.log(`  ✅ Generated: ${successCount} interfaces`);
  console.log(`  ⏭️  Skipped: ${skipCount} files`);
  console.log(`  📁 Output: ${generatedDir}`);
}

main();
