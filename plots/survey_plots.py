from textwrap import wrap

import matplotlib.pyplot as plt
import pandas as pd

df = pd.read_csv("survey.csv")
fontsize = 15

# Clone Pain Points
labels = [1, 2, 3, 4, 5]

plt.figure(figsize=(15, 4.5))
for index, column in enumerate([2, 3, 4], 1):
    s = df.iloc[:, column]
    counts = [s[s == label].count() for label in labels]

    plt.subplot(1, 3, index)
    plt.bar(labels, counts, align="center")
    plt.xticks(labels, fontsize=fontsize)
    plt.yticks([0, 2, 4, 6, 8, 10, 12, 14], fontsize=fontsize)
    plt.title("\n".join(wrap(s.name, 40)), fontsize=fontsize)
    if index == 2:
        plt.xlabel("Rating (1=no issue at all, 5=very annoying)", fontsize=fontsize)
    if index == 1:
        plt.ylabel("Number of Answers", fontsize=fontsize)
    plt.text(0.7, 12.2, f"n={s[s.isna() == False].count()}", fontsize=fontsize)

plt.tight_layout()
plt.savefig("survey-results-clone-pain-points.pdf")
plt.show()

# Clone Workarounds
labels = ["I manually copy and paste code from one project to another",
          "I use preprocessor macros",
          "I use templating in a different programming language",
          "I designed my own programming language/pre-processor"]
s = df.iloc[:, 7]
counts = [s[s.str.contains(label).fillna(False)].count() for label in labels]

plt.figure(figsize=(9, 4.5))
plt.barh(["\n".join(wrap(label, 30)) for label in labels], counts, align="center")
plt.xticks([0, 5, 10, 15, 20, 25], fontsize=fontsize)
plt.yticks(["\n".join(wrap(label, 30)) for label in labels], fontsize=fontsize)
plt.title("\n".join(wrap(s.name, 40)), fontsize=fontsize)
plt.xlabel("Number of Answers (multiple answers allowed)", fontsize=fontsize)
plt.text(21.1, 3.1, f"n={s[s.isna() == False].count()}", fontsize=fontsize)

plt.tight_layout()
plt.savefig("survey-results-clone-workarounds.pdf")
plt.show()

# Clone Proposals
labels = [1, 2, 3, 4, 5]

plt.figure(figsize=(15, 4.5))
for index, column in enumerate([9, 10, 12], 1):
    s = df.iloc[:, column]
    counts = [s[s == label].count() for label in labels]

    plt.subplot(1, 3, index)
    plt.bar(labels, counts, align="center")
    plt.xticks(labels, fontsize=fontsize)
    plt.yticks([0, 2, 4, 6, 8, 10], fontsize=fontsize)
    plt.title("\n".join(wrap(s.name, 40)), fontsize=fontsize)
    if index == 2:
        plt.xlabel("Rating (1=there is no need, 5=would make life easier)", fontsize=fontsize)
    if index == 1:
        plt.ylabel("Number of Answers", fontsize=fontsize)
    plt.text(0.7, 8.7, f"n={s[s.isna() == False].count()}", fontsize=fontsize)

plt.tight_layout()
plt.savefig("survey-results-clone-proposals.pdf")
plt.show()

# Other Proposals
labels = [1, 2, 3, 4, 5]

plt.figure(figsize=(15, 4.5))
for index, column in enumerate([13, 11, 14], 1):
    s = df.iloc[:, column]
    counts = [s[s == label].count() for label in labels]

    plt.subplot(1, 3, index)
    plt.bar(labels, counts, align="center")
    plt.xticks(labels, fontsize=fontsize)
    plt.yticks([0, 2, 4, 6, 8, 10, 12, 14], fontsize=fontsize)
    plt.title("\n".join(wrap(s.name, 40)), fontsize=fontsize)
    if index == 2:
        plt.xlabel("Rating (1=there is no need, 5=would make life easier)", fontsize=fontsize)
    if index == 1:
        plt.ylabel("Number of Answers", fontsize=fontsize)
    plt.text(0.7, 12.2, f"n={s[s.isna() == False].count()}", fontsize=fontsize)

plt.tight_layout()
plt.savefig("survey-results-other-proposals.pdf")
plt.show()

# Baseline Questions
labels = [1, 2, 3, 4, 5]

plt.figure(figsize=(10, 4.5))
for index, column in enumerate([1, 8], 1):
    s = df.iloc[:, column]
    counts = [s[s == label].count() for label in labels]

    plt.subplot(1, 2, index)
    plt.bar(labels, counts, align="center")
    plt.xticks(labels, fontsize=fontsize)
    plt.yticks([0, 3, 6, 9, 12, 15, 18], fontsize=fontsize)
    plt.title("\n".join(wrap(s.name, 40)), fontsize=fontsize)
    if index == 1:
        plt.xlabel("Rating (1=not at all, 5=it is perfect)", fontsize=fontsize)
        plt.ylabel("Number of Answers", fontsize=fontsize)
    if index == 2:
        plt.xlabel("Rating (1=beginner, 5=expert)", fontsize=fontsize)
    plt.text(0.7, 15.8, f"n={s[s.isna() == False].count()}", fontsize=fontsize)

plt.tight_layout()
plt.savefig("survey-results-baseline-questions.pdf")
plt.show()
