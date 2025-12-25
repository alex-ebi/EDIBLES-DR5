from astropy.io import fits
import paths


def main(setting, molecfit_dir, spec_name=None, spec_dir=paths.edr5_tell_corr_dir):

    spec_dir.mkdir(exist_ok=True, parents=True)
    molecfit_dir.mkdir(exist_ok=True, parents=True)    

    tac_file = molecfit_dir / 'molecfit_expert_tac.fits'
    fits_file = molecfit_dir / 'molecfit_expert.fits'

    hdul = fits.open(tac_file)
    hdul_2 = fits.open(fits_file)

    hdul[0].header = hdul_2[0].header

    # print(hdul[0].header)

    if spec_name is None:
        obj = hdul[0].header['OBJECT'].replace(' ', '')
        obs_date = hdul[0].header['DATE-OBS'][:10]
        spec_name = f'{obj}_{obs_date}_uves_{setting}_TAC.fits'

    target_path = spec_dir / spec_name

    hdul.writeto(target_path, overwrite=True)


if __name__ == '__main__':
    main()
