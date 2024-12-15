# Reverse Polish Notation (RPN) Calculator in Assembly

This project implements a Reverse Polish Notation (RPN) calculator in x86-64 assembly language using the **flat assembler (FASM)**. The calculator supports basic arithmetic operations and is designed as a command-line utility, reading input from standard input (stdin) and outputting results to standard output (stdout). The project showcases low-level programming techniques, including stack manipulation, string parsing, and static memory management in assembly.

## Features

### Completed Features
- **Basic Arithmetic Operations**:
  - Addition (`+`)
  - Subtraction (`-`)
  - Multiplication (`*`)
  - Division (`/`)
- **Input Handling**:
  - Tokenization of input strings
  - Parsing of integers
  - Operator precedence and stack-based evaluation
- **Output Handling**:
  - Printing integers
  - Clear and formatted error messages
- **Error Handling**:
  - Detection of unknown tokens
  - Prevention of stack overflow
  - Detection of bad or missing input

### Current Limitations
- **Parenthesis Handling**: The current implementation does not support expressions with parenthesis, such as `((1 + 2) * 3)`.
- **Floating-Point Operations**: Operations on floating-point numbers are not supported; only integers are handled.
- **Negative Numbers**: Negative numbers are not supported in the current implementation.

## Structure

The program is structured into the following components:

### 1. **Macros**
- Simplify common operations like syscalls, string handling, and stack operations.
- Provide reusable building blocks for system-level tasks.

### 2. **Main Operations**
- **Arithmetic Operations**: Implemented as callable subroutines (`op_add`, `op_sub`, `op_mul`, `op_div`).
- **Tokenization and Parsing**: Extracts numbers and operators from input strings and manages precedence.

### 3. **Error Handling**
- Detects and gracefully handles invalid input, stack overflows, and unsupported tokens.

### 4. **User Interface**
- Provides a command-line prompt for input.
- Outputs results with formatted colors and messages.
- Allows users to quit the program by typing `q`.

## Usage

1. Assemble the program using **FASM**:
   ```bash
   fasm calc.s
   ```
2. Run the calculator:
   ```bash
   ./calc
   ```
3. Enter expressions in natural Notation (e.g., `2*5+10`).
4. Quit the program by typing `q`.

## Example
```bash
> 2*5+6 = 16
> 3x4
Unknown token
> 3+2+
Bad input
> q
Goodbye!
```

## Error Messages
- **"Unknown token"**: Indicates that the input contained an unrecognized symbol.
- **"Bad input"**: Indicates that the input format is invalid.
- **"Operation stack overflow"**: Indicates that too many operations were stacked.

## TODO / Next Steps

1. **Parenthesis Handling**:
   - Implement functionality to parse and evaluate expressions with parenthesis for grouping operations.
   - Adjust the tokenization and operator precedence logic to account for parenthesis.

2. **Negative Numbers**:
   - Add support for negative numbers in the input expressions.
   - Update the tokenization and parsing logic to handle negative numbers correctly.
   - Update `putd` procedure to handle negative integers.

3. **Floating-Point Operations**:
   - Extend the calculator to support floating-point numbers.
   - Use x87 FPU instructions or SIMD registers (e.g., SSE or AVX).

4. **Additional Features**:
   - Add support for more advanced mathematical functions (e.g., power, modulus).
   - Enhance error reporting to include more detailed descriptions of input errors.

5. **Operation Availability**:
   - Expand the range of operations supported by the calculator, including bitwise operations, logical operations, and more advanced mathematical functions.


## Contributions
Contributions to improve the project are welcome. Feel free to open issues or submit pull requests.

## License

Feel free to use the code in this repository as you see fit. If you use this code in your projects, please provide attribution by linking back to this repository.
