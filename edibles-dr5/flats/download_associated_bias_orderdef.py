"""
Downloading associated bias frames of flat fields.
Also downloading orderdef files, because it is needed for the optimal flat reduction.
See UVES manual, Figure 5.10.
"""
from pathlib import Path
from astropy.io import fits
from edibles_DR5.workflow import edr5_functions
import urllib
import os


def associate_filter_name(wave):
    if wave in [346.0, 437.0]:
        filter_name = 'HER_5'
    elif wave == 564.0:
        filter_name = 'SHP700'
    elif wave == 860.0:
        filter_name = 'OG590'
    else:
        raise ValueError(f'Wave setting {wave} not recognized')

    return filter_name


def main(flat_dir):
    for file in flat_dir.glob('*.fits'):
        with fits.open(file) as f:
            hdr = f[0].header

        if hdr['OBJECT'] == 'BIAS':
            continue

        # Get wavelength and path (red or blue) of flat
        wave, path = edr5_functions.get_wave_path(hdr)

        # Removing flats which have the wrong wavelength setting
        if wave not in [346.0, 437.0, 564.0, 860.0]:
            print("NOT WHAT WE WANT!!!!!!!!!!!!!!!!!!!")
            print(wave)
            # os.system(f'rm {file}')
            continue

        # Removing files which have the wrong filter
        filter_name = edr5_functions.get_filter_name(hdr)
        my_filter_name = associate_filter_name(wave)

        if filter_name != my_filter_name:
            print("NOT WHAT WE WANT!!!!!!!!!!!!!!!!!!!")
            # os.system(f'rm {file}')
            continue

        night_log_file = Path(str(file).replace('.fits', '.NL.txt'))

        if night_log_file.is_file():
            with open(night_log_file, 'r') as f:
                lines = f.readlines()
            binning = True
            for line in lines:
                if line.startswith('CCD: ') and '/1x1/' in line:
                    binning = False
                elif line.startswith('CCD: ') and '/1x1/' not in line:
                    binning = True
                if f'{path.upper()}_BIAS' in line and not binning:  # Only downloading bias if it is taken for 1x1 binning.
                    bias_archive_name = line.split('\t')[1]
                    print(bias_archive_name)
                    if not (flat_dir / (bias_archive_name + '.fits')).is_file():
                        dp_id = bias_archive_name.replace('.fits', '')
                        download_url = f'http://archive.eso.org/datalink/links?ID=ivo://eso.org/ID?{dp_id}&eso_download=file'
                        print(f'Retrieving file {bias_archive_name}.fits')
                        urllib.request.urlretrieve(download_url, filename=flat_dir / (bias_archive_name + '.fits.Z'))
                        print(f'File {bias_archive_name}.fits downloaded')
                        os.system(f'uncompress {flat_dir / (bias_archive_name + ".fits.Z")}')
                if line.startswith('UVES_DIC') and '_ORDDEF' in line:
                    order_def_wave = float(line.split()[4])
                    order_def_filter = line.split()[5]
                    if (wave == order_def_wave) and (my_filter_name == order_def_filter):
                        orderdef_archive_name = line.split('\t')[1]
                        print(orderdef_archive_name)
                        if not (flat_dir / (orderdef_archive_name + '.fits')).is_file():
                            dp_id = orderdef_archive_name.replace('.fits', '')
                            download_url = f'http://archive.eso.org/datalink/links?ID=ivo://eso.org/ID?{dp_id}&eso_download=file'
                            print(f'Retrieving file {orderdef_archive_name}.fits')
                            urllib.request.urlretrieve(download_url,
                                                       filename=flat_dir / (orderdef_archive_name + '.fits.Z'))
                            print(f'File {orderdef_archive_name}.fits downloaded')
                            os.system(f'uncompress {flat_dir / (orderdef_archive_name + ".fits.Z")}')


if __name__ == '__main__':
    main(edr5_functions.edr5_dir / 'flat_2024_11_25')
