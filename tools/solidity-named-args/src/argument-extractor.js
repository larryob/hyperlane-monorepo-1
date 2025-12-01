/**
 * Extract argument text from source code, handling nested structures
 *
 * The solidity-parser's range/loc doesn't always capture complete expressions
 * (e.g., closing parentheses), so we need to manually extract and balance.
 */

/**
 * Extract arguments from a function call by parsing the source manually
 */
export function extractArgumentsFromCall(callNode, sourceCode) {
  // Get the entire call text
  const callStart = callNode.loc.start;
  const callEnd = callNode.loc.end;

  // Find the opening parenthesis of the arguments list
  const lines = sourceCode.split('\n');
  let pos = { line: callStart.line - 1, column: callStart.column };

  // Find the '(' that starts arguments
  let found = false;
  let searchText = '';

  while (pos.line < lines.length) {
    const line = lines[pos.line];
    const searchStart = pos.column;

    for (let col = searchStart; col < line.length; col++) {
      const ch = line[col];
      searchText += ch;

      if (ch === '(') {
        // Found the opening paren
        pos.column = col + 1;
        found = true;
        break;
      }
    }

    if (found) break;

    pos.line++;
    pos.column = 0;
  }

  if (!found) {
    throw new Error('Could not find opening parenthesis for function call');
  }

  // Now extract arguments by balancing parentheses, brackets, and braces
  const argTexts = [];
  let currentArg = '';
  let depth = { paren: 0, bracket: 0, brace: 0, quote: null };
  let startPos = { ...pos };

  while (pos.line < lines.length) {
    const line = lines[pos.line];

    for (let col = pos.column; col < line.length; col++) {
      const ch = line[col];
      const nextCh = col + 1 < line.length ? line[col + 1] : null;

      // Handle string literals
      if (depth.quote) {
        currentArg += ch;
        if (ch === depth.quote && (col === 0 || line[col - 1] !== '\\')) {
          depth.quote = null;
        }
        continue;
      }

      if (ch === '"' || ch === "'") {
        depth.quote = ch;
        currentArg += ch;
        continue;
      }

      // Handle comment start (skip)
      if (ch === '/' && nextCh === '/') {
        // Line comment - skip rest of line
        break;
      }

      if (ch === '/' && nextCh === '*') {
        // Block comment - skip until */
        // (simplified: doesn't handle multi-line comments perfectly)
        currentArg += ' ';
        col++;
        continue;
      }

      // Track nesting depth
      if (ch === '(') depth.paren++;
      else if (ch === ')') depth.paren--;
      else if (ch === '[') depth.bracket++;
      else if (ch === ']') depth.bracket--;
      else if (ch === '{') depth.brace++;
      else if (ch === '}') depth.brace--;

      // Check if we're at a separator or end
      if (depth.paren === -1) {
        // Found closing paren - end of arguments
        argTexts.push(currentArg.trim());
        return argTexts.filter(a => a.length > 0);
      } else if (ch === ',' && depth.paren === 0 && depth.bracket === 0 && depth.brace === 0) {
        // Found argument separator at top level
        argTexts.push(currentArg.trim());
        currentArg = '';
      } else {
        currentArg += ch;
      }
    }

    // Move to next line
    pos.line++;
    pos.column = 0;
    if (currentArg.length > 0) {
      currentArg += ' '; // Add space between lines
    }
  }

  throw new Error('Could not find closing parenthesis for function call');
}

/**
 * Simple fallback: try to extract arguments by looking at the call node's location
 */
export function extractArgumentsSimple(callNode, sourceCode) {
  const argTexts = [];

  for (const argNode of callNode.arguments) {
    if (argNode.range) {
      // Use range if available (most reliable)
      let text = sourceCode.substring(argNode.range[0], argNode.range[1]);

      // Manually check if we need to add closing delimiters
      // Count opening vs closing parens/brackets/braces
      const open = {
        paren: (text.match(/\(/g) || []).length,
        bracket: (text.match(/\[/g) || []).length,
        brace: (text.match(/\{/g) || []).length
      };
      const close = {
        paren: (text.match(/\)/g) || []).length,
        bracket: (text.match(/\]/g) || []).length,
        brace: (text.match(/\}/g) || []).length
      };

      // If unbalanced, try to find the closing delimiter in source
      if (open.paren > close.paren || open.bracket > close.bracket || open.brace > close.brace) {
        // Look ahead in source for closing delimiters
        let pos = argNode.range[1];
        let depth = {
          paren: open.paren - close.paren,
          bracket: open.bracket - close.bracket,
          brace: open.brace - close.brace
        };

        while (pos < sourceCode.length && (depth.paren > 0 || depth.bracket > 0 || depth.brace > 0)) {
          const ch = sourceCode[pos];
          text += ch;

          if (ch === '(') depth.paren++;
          else if (ch === ')') depth.paren--;
          else if (ch === '[') depth.bracket++;
          else if (ch === ']') depth.bracket--;
          else if (ch === '{') depth.brace++;
          else if (ch === '}') depth.brace--;

          pos++;

          // Safety: don't go too far
          if (pos - argNode.range[1] > 1000) break;
        }
      }

      argTexts.push(text);
    } else {
      // Fallback: reconstruct from AST
      argTexts.push(reconstructArgument(argNode));
    }
  }

  return argTexts;
}

/**
 * Reconstruct argument text from AST node
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
    case 'UnaryOperation':
      return node.isPrefix
        ? `${node.operator}${reconstructArgument(node.subExpression)}`
        : `${reconstructArgument(node.subExpression)}${node.operator}`;
    case 'TupleExpression':
      const tupleArgs = node.components.map(reconstructArgument).join(', ');
      return `(${tupleArgs})`;
    default:
      return '...'; // Complex expression
  }
}
