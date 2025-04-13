from astropy.io import fits
import pandas as pd
from edibles_dr5 import edr5_functions, paths
from importlib.resources import files



def main(flat_dir):
    breakpoint_file = files('edibles_dr5') / 'supporting_data/breakpoints_4.csv'
    breakpoints = pd.read_csv(breakpoint_file, index_col=0)

    df = pd.DataFrame()
    for file in flat_dir.glob('*.fits'):
        with fits.open(file) as f:
            hdr = f[0].header

        if hdr['OBJECT'] == 'BIAS':
            continue

        # Get wavelength and path (red or blue) of flat
        wave, path = edr5_functions.get_wave_path(hdr)

        # Removing flats which have the wrong wavelength setting
        if wave not in [346.0, 437.0, 564.0, 860.0]:
            # print("NOT WHAT WE WANT!!!!!!!!!!!!!!!!!!!")
            # print(wave)
            # os.system(f'rm {file}')
            continue

        # print(hdr['MJD-OBS'])
        # print(hdr['DATE-OBS'])
        # print(hdr['OBJECT'])
        flat_bin = breakpoints['MJD'].searchsorted(hdr['MJD-OBS'])

        s = pd.Series([file.name, wave, hdr['ESO DPR TYPE'], hdr['DATE-OBS'], hdr['MJD-OBS'], flat_bin], index=['name', 'wave', 'ESO DPR TYPE', 'DATE-OBS', 'MJD-OBS', 'flat_bin'])
        df = pd.concat((df, s), axis=1, ignore_index=True)

    df = df.T.sort_values(by=['flat_bin', 'wave', 'MJD-OBS'])
    
    df.to_csv(files('edibles_dr5') / 'supporting_data/flat_list.csv')

    for i, _ in breakpoints.iloc[1:].iterrows():
        sub_df = df.loc[df['flat_bin'] == i]
        for setting in [346.0, 437.0, 564.0, 860.0]:
            ss_df = sub_df.loc[sub_df['wave'] == setting]
            print(i, setting,len(ss_df))



if __name__ == '__main__':
    print(paths.edr5_dir / 'calib_raw')
    main(paths.edr5_dir / 'calib_raw')
