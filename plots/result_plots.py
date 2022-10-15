import matplotlib.pyplot as plt

fontsize = 15
marker = "o"
markersize = 8

# LOC/LLOC Reduction vs. P4 LOC
p4_loc = [123, 125, 285, 443, 630, 1352]
loc_diff = [8.1, 28.8, 36.5, 54.6, 57.0, 80.0]
lloc_diff = [8.1, 32.9, 40.4, 60.7, 63.0, 83.3]

plt.figure(figsize=(7, 3))
plt.plot(p4_loc, loc_diff, marker=marker, linestyle="None", label="LOC", markersize=markersize)
#plt.plot(p4_loc, lloc_diff, marker=marker, linestyle="None", label="LLOC", markersize=markersize)
plt.xticks([0, 250, 500, 750, 1000, 1250, 1500], fontsize=fontsize)
plt.yticks([0, 20, 40, 60, 80, 100], fontsize=fontsize)
#plt.title("LOC/LLOC Reduction vs. P4 LOC", fontsize=fontsize)
plt.xlabel("P4 Lines Of Code", fontsize=fontsize)
plt.ylabel("Reduction in LOC (%)", fontsize=fontsize)
plt.legend(fontsize=fontsize - 2).remove()
ax = plt.gca()
ax.spines['right'].set_color('none')
ax.spines['top'].set_color('none')
plt.tight_layout()
plt.savefig("results-loc-lloc-reduction.pdf")
plt.show()

# O4 Compilation Time vs. O4 LOC
o4_loc_ddos = [270, 878, 1638, 2398, 3310, 4070]
t_total_ddos = [2.9, 8.8, 17.1, 25.2, 33.4, 43.5]
t_front_ddos = [0.43, 1.60, 3.10, 4.93, 7.43, 9.25]
t_back_ddos = [1.68, 6.38, 13.12, 20.89, 26.97, 33.29]

plt.figure(figsize=(7, 5))
plt.plot(o4_loc_ddos, t_total_ddos, marker=marker, linestyle="None", label="Total", markersize=markersize)
plt.plot(o4_loc_ddos, t_back_ddos, marker=marker, linestyle="None", label="Back End", markersize=markersize)
plt.plot(o4_loc_ddos, t_front_ddos, marker=marker, linestyle="None", label="Front End", markersize=markersize)
plt.xticks([0, 1000, 2000, 3000, 4000], fontsize=fontsize)
plt.yticks([0, 10, 20, 30, 40, 50], fontsize=fontsize)
plt.title("O4 Compilation Time vs. O4 LOC", fontsize=fontsize)
plt.xlabel("O4 LOC", fontsize=fontsize)
plt.ylabel("O4 Compilation Time (s)", fontsize=fontsize)
plt.legend(fontsize=fontsize - 2)

plt.tight_layout()
plt.savefig("results-compilation-time-loc.pdf")
plt.show()
