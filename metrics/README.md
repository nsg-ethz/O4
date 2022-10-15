# Metrics

## LOC, LLOC and %LOC

To compute the LOC, LLOC and %LOC for P4/O4 program pairs, you can use the `loc_lloc_ploc.py` Python script.

The `FILES` constant allows to specify the P4/O4 program pairs that will be analyzed. By default, the script will
compute the metrics for our example files in `code/examples`.

The `OPTIONS` constant allows to configure the script. One can e.g. configure the `levenshtein_threshold`.

**Important**: Make sure you have the Python requirements in `code/requirements.txt` installed, before running the
script.

## Halstead Metrics

The Halstead metrics are implemented as Racket DSLs.

Assuming you have Racket and the `o4` package already installed, you can install the `halstead` package from the
repository root:

```
raco pkg install code/metrics/halstead
```

Now you should be able to compute the Halstead metrics for any O4 file by adding the following line at the top of the
file:

```
#lang halstead/o4
```

and running:

```
racket path/to/file
```

For a P4 file, simply use the `halstead/p4` DSL instead.

## Compile Times

You can use the `timing_script.sh` shell script to run timing measurements on our example files in `code/examples`.
