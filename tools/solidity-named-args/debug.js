import parser from '@solidity-parser/parser';
import fs from 'fs';

const source = fs.readFileSync('test-example.sol', 'utf-8');
const ast = parser.parse(source, { loc: true, range: true });

parser.visit(ast, {
  FunctionCall(node) {
    if (node.arguments && node.arguments.length > 0) {
      console.log('\n=== Function Call ===');

      let functionName = 'unknown';
      if (node.expression.type === 'Identifier') {
        functionName = node.expression.name;
      } else if (node.expression.type === 'MemberAccess') {
        functionName = node.expression.memberName;
      }

      console.log('Function:', functionName);
      console.log('Arguments:', node.arguments.length);
      console.log('Call location:', node.loc);

      // Show each argument
      node.arguments.forEach((arg, i) => {
        console.log(`\nArg ${i}:`, arg.type);
        console.log('  Location:', arg.loc);

        if (arg.range) {
          const argText = source.substring(arg.range[0], arg.range[1]);
          console.log('  Text (from range):', argText);
        }

        // Try manual extraction
        if (arg.loc) {
          const lines = source.split('\n');
          const startLine = arg.loc.start.line - 1;
          const endLine = arg.loc.end.line - 1;
          const startCol = arg.loc.start.column;
          const endCol = arg.loc.end.column;

          if (startLine === endLine) {
            const text = lines[startLine].substring(startCol, endCol);
            console.log('  Text (from loc):', text);
          }
        }
      });
    }
  }
});
