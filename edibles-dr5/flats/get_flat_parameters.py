"""
Getting the flat parameters to query flats from ESO archive for super flat.
"""
from pathlib import Path
from astropy.io import fits

flat_dir = Path('/home/alex/EDPS_data/UVES/flat')
flat_dir = Path("/home/alex/Downloads/archive(4)")
flat_list = flat_dir.rglob('*.fits')

for file in flat_list:
    with fits.open(file) as f:
        hdr = f[0].header

    if hdr.get('object') != "LAMP,FLAT":
        # if hdr.get('object') != "HD170740":
        continue
    try:
        wave_setting = hdr['ESO INS GRAT1 WLEN']
        grat_n = '1'
    except KeyError:
        wave_setting = hdr['ESO INS GRAT2 WLEN']
        grat_n = '2'

    try:
        filter_name = hdr['ESO INS FILT2 NAME']
        filter_n = '2'
    except KeyError:
        filter_name = hdr['ESO INS FILT3 NAME']
        filter_n = '3'

    print('ESO TPL ID', hdr['ESO TPL ID'])
    print(f'ESO INS GRAT{grat_n} WLEN: ', wave_setting)
    print('ESO DET WIN1 UIT1: ', hdr['ESO DET WIN1 UIT1'])
    print(f'ESO INS GRAT{grat_n} NAME: ', hdr[f'ESO INS GRAT{grat_n} NAME'])
    print('ESO INS SLIT1 NAME: ', hdr['ESO INS SLIT1 NAME'])
    print(f'ESO INS SLIT{filter_n} WID: ', hdr[f'ESO INS SLIT{filter_n} WID'])
    # print('ESO PRO CATG: ', hdr['ESO PRO CATG'])
    # print('ESO DET READ MODE: ', hdr['ESO DET READ MODE'])
    # print('EXPTIME: ', hdr["EXPTIME"])
    # print('ESO INS MODE: ', hdr['ESO INS MODE'])
    print(f'ESO INS FILT{filter_n} NAME: ', filter_name)
    print('')
