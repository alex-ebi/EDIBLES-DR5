from astro_scripts_uibk import pub_plot
import matplotlib.pyplot as plt


def test_pub_style_and_pub_ticks():
    f, ax = plt.subplots()

    pub_plot.pub_style_fig()
    pub_plot.pub_ticks(ax, .1, .2)
    ax.plot([1, 2])
    plt.show(block=False)
    plt.close(f)
