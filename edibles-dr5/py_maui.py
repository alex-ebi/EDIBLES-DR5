"""
This is a GUI for fitting spectra to observations.
"""
import matplotlib.pyplot as plt
import matplotlib
from sklearn.decomposition import PCA
from sklearn.gaussian_process import GaussianProcessRegressor, kernels
import tkinter as tk
from tkinter import ttk
from matplotlib.backends.backend_tkagg import FigureCanvasTkAgg, NavigationToolbar2Tk


def train_pca_gpr(flux_list, param_list, snr=100):
    """
    Trains an interpolation model on training set of spectra.
    1. Performs Principal Component Analysis (PCA).
    2. Gaussian Process Recession on PCA eigenvalues.

    Parameters
    ----------
    flux_list : np.array
        2-D array of flux values (np.array([flux1, flux2, ...])).
    param_list : np.array
        2-D array of parameter values (np.array([param1, param2, ...])).
    snr : float
        S/N of observed spectrum.

    Returns
    -------
    interpol_function(parameter)
        Function which returns a spectrum corresponding to a set of parameters.
    """

    # instance of PCA model
    pca = PCA(n_components=0.99999)
    pca.fit(flux_list)

    # apply mapping to sets
    train_img_pca = pca.transform(flux_list)

    kernel = kernels.RationalQuadratic(length_scale=2, alpha=1.5, length_scale_bounds='fixed', alpha_bounds='fixed')

    gpr = GaussianProcessRegressor(normalize_y=True, n_restarts_optimizer=5, alpha=1 / snr, kernel=kernel)
    gpr.fit(param_list, train_img_pca)  # training

    # Define interpolation function.
    def interpol_function(param):
        return pca.inverse_transform(gpr.predict(param))

    return interpol_function


def viewer_gui():
    """
    Provides a GUI for comparing model spectra to observations.
    """
    # Make sure that we are using Tk
    matplotlib.use('TkAgg')

    f, ax = plt.subplots(figsize=[10, 20])

    # TKinter GUI--------------------------
    # get dimension of plot
    fig_dimension_px = f.bbox.get_points()
    root = tk.Tk()
    root.geometry(f'{int(fig_dimension_px[1][0] + 20)}x1000')

    root.rowconfigure(0, weight=20)
    root.rowconfigure(1, weight=1)

    # main frame
    main_frame = tk.Frame(root, bg='white')
    main_frame.pack(fill='both', expand=1)

    # create canvas
    my_canvas = tk.Canvas(main_frame, bg='white')
    my_canvas.pack(side='left', fill='both', expand=1)

    # Add scrollbar
    my_scrollbar = ttk.Scrollbar(main_frame, orient='vertical', command=my_canvas.yview)
    my_scrollbar.pack(side='right', fill='y')

    # configure canvas
    my_canvas.configure(yscrollcommand=my_scrollbar.set)
    my_canvas.bind('<Configure>', lambda e: my_canvas.configure(scrollregion=my_canvas.bbox('all')))

    # create another frame in canvas
    second_frame = tk.Frame(my_canvas, bg='white')
    second_frame.pack(expand=True, fill='x')

    # add new frame to window in canvas
    my_canvas.create_window((0, 0), window=second_frame, anchor='nw')

    # connect plot to second frame
    second_canvas = FigureCanvasTkAgg(f, master=second_frame)
    second_canvas.get_tk_widget().pack(side='top', expand=True, fill='x')

    # resize second canvas
    second_canvas.get_tk_widget().configure(scrollregion=my_canvas.bbox('all'), bg='blue')

    # create toolbar
    toolbar = NavigationToolbar2Tk(second_canvas, my_canvas, pack_toolbar=0)
    toolbar.update()
    toolbar.pack(side='bottom', fill='x')

    # Text box to enter new parameters
    # show a label
    label = tk.Label(my_canvas, text='Parameter text box')
    label.pack(side='left', anchor='s')

    text_box = tk.Entry(my_canvas)
    # text_box.bind("<Return>", lambda x: update_model_flux(text_box.get()))
    text_box.pack(side='left', anchor='s')

    root.mainloop()
