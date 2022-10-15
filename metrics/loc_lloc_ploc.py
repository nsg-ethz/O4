"""
compute loc, lloc, levenshtein distance;
get normalized files without macro expansion
"""
import re
import time
from typing import List, Tuple

import numpy as np

from leven import levenshtein

# ####################################################
# constants
# ####################################################

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# don't expand macros, otherwise same
# preprocessing (as described in report)
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

RAW_P4_FILES = [
    '../examples/v1model/heavy_hitter.p4',
    '../examples/v1model/cm_sketch.p4',
    '../examples/v1model/loss_detection.p4',
    '../examples/tna/aes_oneround.p4',
    '../examples/tna/conquest.p4',
    '../examples/tna/ddos_aid.p4'
]


FILES = [
    ("../examples/v1model/heavy_hitter_normalized_wo_macro_exp__2022_09_22__19_50_33.p4",
     "../examples/v1model/heavy_hitter.o4"),
    ("../examples/v1model/cm_sketch_normalized_wo_macro_exp__2022_09_22__19_50_33.p4",
     "../examples/v1model/cm_sketch.o4"),
    ("../examples/v1model/loss_detection_normalized_wo_macro_exp__2022_09_22__19_50_33.p4",
     "../examples/v1model/loss_detection.o4"),
    ("../examples/tna/aes_oneround_normalized_wo_macro_exp__2022_09_22__19_50_33.p4",
     "../examples/tna/aes_oneround.o4"),
    ("../examples/tna/conquest_normalized_wo_macro_exp__2022_09_22__19_50_33.p4",
     "../examples/tna/conquest.o4"),
    ("../examples/tna/ddos_aid_normalized_wo_macro_exp__2022_09_22__19_50_33.p4",
     "../examples/tna/ddos_aid.o4"),
]

OPTIONS = {
    "levenshtein_threshold": 1,
    "remove_comments": True,
    "remove_lines_only_containing_braces": True,
    "normalize_whitespaces": True,
    "debug": False,
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# old (for results with macro expansion)
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# FILES = [
#     ("../examples/v1model/heavy_hitter_normalized.p4",
#      "../examples/v1model/heavy_hitter.o4"),
#     ("../examples/v1model/cm_sketch_normalized.p4",
#      "../examples/v1model/cm_sketch.o4"),
#     ("../examples/v1model/loss_detection_normalized.p4",
#      "../examples/v1model/loss_detection.o4"),
#     ("../examples/tna/aes_oneround_normalized.p4",
#      "../examples/tna/aes_oneround.o4"),
#     ("../examples/tna/conquest_normalized.p4",
#      "../examples/tna/conquest.o4"),
#     ("../examples/tna/ddos_aid_normalized.p4",
#      "../examples/tna/ddos_aid.o4"),
# ]

# OPTIONS = {
#     "levenshtein_threshold": 1,
#     "debug": False,
# }


def _remove_comments(source: str) -> str:
    source = re.sub(r"/(?:\*.*?\*/|/[^\n]*)", "", source, flags=re.DOTALL)
    return source


def _remove_line_breaks_in_round_brackets(source: str) -> str:
    lines = source.split("\n")
    lines_dict = {i: line for (i, line) in enumerate(lines)}

    round_bracket_opened = [1 if ("(" in l) else 0 for l in lines]
    round_bracket_closed = [1 if (")" in l) else 0 for l in lines]
    start_indices = np.where(round_bracket_opened)[0]
    stop_indices = np.where(round_bracket_closed)[0]

    for start, stop in zip(start_indices, stop_indices):
        merge_lines = []
        for i in range(start, stop + 1):
            merge_lines.append(lines[i].replace("  ", ""))
            del lines_dict[i]
        new_line = " ".join(merge_lines)
        lines_dict[stop] = new_line

    sorted_lines = [b for (a, b) in sorted(lines_dict.items())]
    return "\n".join(sorted_lines)


def _get_ts() -> str:
    return str(time.strftime("%Y_%m_%d__%H_%M_%S"))


def advanced_preprocessing(source: str) -> Tuple[List[str], List[str]]:
    original_source = source

    # Remove headers (only detects top-level headers)
    if OPTIONS.get("remove_headers", True):
        source = re.sub(r"^header\s+\S+\s*{.*?}", "", source, flags=re.DOTALL | re.MULTILINE)

    # Remove parsers (only detects top-level parser and requires the closing bracket of the parser body
    # to be on a separate line, e.g. as done by the p4c pretty printer)
    if OPTIONS.get("remove_parsers", True):
        source = re.sub(r"^parser\s+\S+\s*(?:\(.*?\)\s*){1,2}{.*?^}", "", source, flags=re.DOTALL | re.MULTILINE)

    return simple_preprocessing(original_source), simple_preprocessing(source)


def simple_preprocessing(source: str) -> List[str]:
    # Remove comments
    if OPTIONS.get("remove_comments", True):
        source = _remove_comments(source=source)

    # Split source into lines
    source_lines = []
    for line in source.split("\n"):
        if OPTIONS.get("normalize_whitespaces", True):
            # Remove leading and trailing whitespaces
            line = line.strip()
            # Normalize other whitespaces to single space
            line = re.sub(r"\s+", " ", line)

        # Remove lines only containing a single closing brace
        if OPTIONS.get("remove_lines_only_containing_braces", True):
            line = re.sub(r"}", "", line)

        # Remove empty lines
        if line:
            source_lines.append(line)

    return source_lines


def normalize_code_without_macro_expansion(source: str) -> str:
    return _remove_comments(source)


def levenshtein_ploc(source_lines: List[str]) -> float:
    loc = len(source_lines)
    duplicate_loc = 0

    # Compare lines of code with each other, using the Levenshtein distance
    for i, x in enumerate(source_lines):
        for y in source_lines[i + 1:]:
            if levenshtein(x, y) <= OPTIONS.get("levenshtein_threshold", 1):
                if OPTIONS.get("debug", False):
                    print(f"Duplicate found: \"{x}\" --- \"{y}\"")
                duplicate_loc += 1
                break

    return duplicate_loc / loc * 100


def compute_diff(lst: List) -> float:
    return (lst[0] - lst[1]) / lst[0] * 100


def main():
    """
    compute LOC, LLOC and levenshtein distance for the input files at the top of this script
    :return:
    """
    loc_diffs = []
    lloc_diffs = []
    ploc_diffs = []
    for file_tuple in FILES:
        locs = []
        llocs = []
        plocs = []
        for file in file_tuple:
            with open(file) as f:
                simple_lines, advanced_lines = advanced_preprocessing(f.read())
                # TODO store these lines, name them as: without macro expansion
                # (or: not necessary because halstead already takes care of preprocessing as well?)
                # TODO run the halstead metric on those files
                loc = len(simple_lines)
                lloc = len(advanced_lines)
                ploc = levenshtein_ploc(simple_lines)
                print(f"LOC: {str(loc).rjust(4)}, "
                      f"LLOC: {str(lloc).rjust(4)}, "
                      f"%LOC: {f'{ploc:.1f}'.rjust(4)} "
                      f"for file {file}")
                locs.append(loc)
                llocs.append(lloc)
                plocs.append(ploc)

        loc_diff = compute_diff(locs)
        lloc_diff = compute_diff(llocs)
        ploc_diff = compute_diff(plocs)
        print(f"LOC: {f'{loc_diff:.1f}'.rjust(4)}, "
              f"LLOC: {f'{lloc_diff:.1f}'.rjust(4)}, "
              f"%LOC: {f'{ploc_diff:.1f}'.rjust(4)} percent reduction")
        loc_diffs.append(loc_diff)
        lloc_diffs.append(lloc_diff)
        ploc_diffs.append(ploc_diff)
        print("---")
    print(f"LOC: {f'{sum(loc_diffs) / len(loc_diffs):.1f}'.rjust(4)}, "
          f"LLOC: {f'{sum(lloc_diffs) / len(lloc_diffs):.1f}'.rjust(4)}, "
          f"%LOC: {f'{sum(ploc_diffs) / len(ploc_diffs):.1f}'.rjust(4)} percent average reduction")


def get_normalized_without_macro_exp_p4_files():
    """
    get the equivalent of the current normalized files, but without macro expansion
    :return:
    """

    # get timestamp for filenames
    ts = _get_ts()

    # iterate over all p4 files
    for p4_file in RAW_P4_FILES:  # type: str

        # read p4 file
        with open(p4_file, 'r') as f:
            content = f.read()

        # normalize w/o macro expansion
        new_content = _remove_comments(content)
        new_content = _remove_line_breaks_in_round_brackets(source=new_content)

        # store the adapted file
        new_file_name = p4_file.replace(".p4", f"_normalized_wo_macro_exp__{ts}.p4")
        print(new_file_name)
        with open(new_file_name, 'w') as f:
            f.write(new_content)


if __name__ == "__main__":
    main()
    # get_normalized_without_macro_exp_p4_files()
