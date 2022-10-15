# Reducing P4 Language's Voluminosity <br> using Higher-Level Constructs

O4 is a domain-specific data-plane programming language, allowing to specify custom packet handling in programmable
network devices. It compiles to P4, and is therefore compatible with all state-of-the-art P4 targets. With O4 one can
write more concise software, reducing the required lines of code of up to 80% compared to an equivalent P4
implementation.

## Structure of the repo

```
code/
├── examples/               - P4/O4 Example Program
├── metrics/                - Implementations of Evaluation Metrics
├── o4/                     - O4 Compiler
├── p4include/
├── plots/              
│   ├── result_plots.py     - Evaluation Plots
│   ├── survey.csv          - Raw Survey Results
│   └── survey_plots.py     - Survey Plots
├── docker-compose.yml
├── README.md
└── requirements.txt        - Requirements for Python Scripts
```

## Technologies

The current O4 compiler runs with:

- P4-16 version: 1.2.2
- Racket version: 8.1 or higher

## Setup

To setup the O4 compiler, make sure you have Racket installed:

```
$ racket --version
Welcome to Racket v8.1 [cs].
```

Then install the `o4` package from the repository root:

```
raco pkg install code/o4
```

Now compile the given test file from the repository root to make sure everything works as expected:

```
$ racket code/o4/test.o4
Finished lexing and parsing of source in 0.006 seconds
Finished back end compilation in 0.112 seconds
Finished writing compilation output to file code/examples/o4_compilation_output.p4
```

**Optional:** The O4 compiler can directly invoke the P4 compiler after it has finished. To set this up, one has to
set `run_p4_compiler` to `true` and configure `p4_compiler_executable` and `p4_compiler_arguments`
in `config.json` accordingly.

For more information see [Invoking the P4 compiler](#invoking-the-p4-compiler).

## Usage

Make sure that you finished the [Setup](#setup) and have verified that the compiler works as expected.

An O4 source file has to start with `#lang o4` followed by a newline:

```
#lang o4

header header_t {
    bit<32>[4] values;
}

struct headers {
    header_t test_header;
}

control test_control(inout headers hdr) {
    factory test_factory (int index, bit<32> value) {
        action test_action () {
            hdr.test_header.values[index] = value;
        }
        return test_action;
    }

    apply {
        for (int i in [0, 1, 2, 3]) {
            test_factory(i, (bit<32>) i)();
        }
    }
}
```

To compile an O4 source file, run the O4 compiler from the repository root (otherwise the relative paths might not work
as intended):

```
$ racket path/from/repository/root/to/o4/source/file
```

### Invoking the P4 compiler

The O4 compiler allows to automatically invoke a subprocess after the compilation finished successfully. This can be
used to chain together the O4 and P4 compilers.

To turn this feature on, you have to set `run_p4_compiler` to `true` in the `config.json` file. In the same file you can
also specify which executable to run, with `p4_compiler_executable`. To pass any arguments to the call you can use
the `p4_compiler_arguments`.

We provide a docker-compose file that sets up a [p4c](https://github.com/p4lang/p4c) Docker container and maps all
required files into it, allowing to execute any p4c call with little setup required. If you point
the `p4_compiler_executable` to your local Docker executable, the pre-configured command in the config file will call
the p4c pretty-printer.

If you instead want to further compile the output of the O4 compiler onto a BMv2 target, you have to adapt the command
in the config file to match:

```
docker compose -f code/docker-compose.yml run --rm p4c --target bmv2 --arch v1model o4_compilation_output.p4
```

## Running Tests

The O4 compiler ships with a suite of over 230 test cases, which test many of the most important features of the
compiler implementation.

To run these test, first install the `o4` package as described in [Setup](#setup), then simply run:

```
raco test -p o4
```

## Reading the Code

To make a deep dive into the source code easier, we provide an overview of the most important components of the O4
compiler and their interactions. This section assumes some familiarity with Racket and the `#lang` functionality.

The `main.rkt` file is a good starting point for getting into the code, as it contains both the `read-syntax` procedure
and the `#%module-begin` macro of the O4 language. The main file also contains calls to the `parse` function of
the `brag` library, invoking the front end, using the tokenizer in `frontend/lexer-tokenizer.rkt` and the grammar
in `frontend/parser.rkt`, to tokenize and parse the input file. Furthermore, it contains the call to `o4-program`, the
entrypoint to the backend, with its binding given in `backend/o4-program.rkt`

The backend logic is split into individual sections that correspond to the commented sections in the O4 grammar. An
important part of the back end is the context data structure, which stores global information that is passed throughout
all predicates in the back end. The context is always required via the global `context.rkt`
file, which is done purely for convenience. The actual context logic is defined in the files in the `context/` folder.
If you decide to dig into the context logic, we recommend to start with the `context/base.rkt` file, as it contains the
main struct definitions and helper functions used throughout the context logic.

It might also make sense to have a look at the commonly used utility functions in `utils/util.rkt`, before diving into
the back end code.

### Tokenize-Only and Parse-Only Dialects

Additional to the O4 language, we provide two helper dialects that allow to investigate the output of the tokenizer and
parser respectively.

To invoke these dialects, simply change the `#lang` line in an O4 program to `#lang o4/utils/tokenize-only`
or `#lang o4/utils/parse-only` and run the file using the usual `racket` command.

## Current Compiler Limitations

The following is an overview of the current limitations of the O4 compiler:

- The architecture definition sub-language is not supported (extern-, error-, match-kind-, parser-type-, control-type-,
  package-type-declarations).
- Annotations are not supported (do not cause syntax errors, but are simply ignored).
- The `header_union`, `type`, `switch`, `this` and `abstract` keywords and their respective functionality are not
  supported.
- Valuesets are not supported.
- The ternary operator is not supported.
- Header stacks are not detected and will be treated as arrays (they will be expanded).
- Dot-prefixed variables are not fully supported.
- Tuple types are not fully supported.
- Only very basic type checking is performed (e.g. one can use incompatible types for factory parameters and arguments).
- Array types cannot be used in typedef declarations, as function return types, in specified enum declarations, in cast
  expressions, in type argument lists and as loop iterators.
- Factory bodies can only be instances of `action`, `table` and `extern` types.
- `for` loops can only loop over 1D arrays.

### Known Issues

- The procedures `set-variable`, `set-parameter`, `set-factory` and `set-factory-call` are missing error handlers.
- Certain usages of expression arrays allow for arrays with improper structure.
