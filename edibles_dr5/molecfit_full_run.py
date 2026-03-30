from edibles_dr5 import paths
import os
from edibles_dr5 import molecfit_tac_header
from edibles_dr5.io import read_spec
from edibles_dr5 import transformations
from pathlib import Path
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from importlib.resources import files


def main():
    obs_list = pd.read_csv(files('edibles_dr5') / 'supporting_data/obs_names.csv')

    molecfit_par_path = files('edibles_dr5') / 'molecfit/EDR5_loop.par'
    mol_bands_path = files('edibles_dr5') / 'molecfit/molecular_bands.csv'
    mol_bands = pd.read_csv(mol_bands_path)
    print(mol_bands)

    include_path = files('edibles_dr5') / 'molecfit/include.dat'
    include_list = np.genfromtxt(include_path)
    print(include_list)

    spec_dir = paths.edr5_orders_dir
    molecfit_dir = files('edibles_dr5') / 'tmp/molecfit_calc'
    molecfit_dir.mkdir(exist_ok=True, parents=True)
    os.chdir(molecfit_dir)

    # iterate through inclusion regions
    settings = ['346nm_blue', '437nm_blue', '564nm_redl', '564nm_redu', '860nm_redl', '860nm_redu']
    orders = list(range(1, 40))
    # settings = ['564nm_redu']
    # orders = [2]

    missed_settings = []

    spec_list = list(spec_dir.rglob('*.fits'))

    # spec_list = [item for item in spec_list if item.match('*HD183143*')]

    for setting in settings:
        for order in orders:
            # skip_iter = False
            # Filter file list for settings
            file_list = [item for item in spec_list if item.match(f'*{setting}_O{order}.fits')]
            # print(file_list)
            if len(file_list) == 0:
                # print('nothing')
                continue
            
            const_fit = False
            for spec_path in file_list:
                spec = read_spec(spec_path)
                spec[0] = transformations.angstrom_air_to_vac(spec[0]) / 10000

                include_order = []
                for ir in include_list:
                    if min(spec[0]) < ir[0] < max(spec[0]) and min(spec[0]) < ir[1] < max(spec[0]):
                        print(ir)
                        include_order.append(ir)
                
                if len(include_order) < 3:
                    const_fit = True
                    # break

                # Save inclusion ranges to file
                np.savetxt(molecfit_dir / 'include.dat', include_order, fmt='%.8f')

                molec_order = []
                fit_molec_order = []
                rel_col_order = []
                for _, row in mol_bands.iterrows():
                    # print(row)
                    if row['x_min'] < min(spec[0]) < row['x_max'] or row['x_min'] < max(spec[0]) < row['x_max']:
                        molec_order.append(row['species'])
                        fit_molec_order.append(row['fit_molec'])
                        rel_col_order.append(row['rel_col'])

                if len(molec_order) == 0:
                    missed_settings.append([setting, order, min(spec[0]), max(spec[0])])
                    pd.DataFrame(missed_settings).to_excel(files('edibles_dr5') / 'tmp/molecfit_calc/missed_settings.xlsx')
                    break

                if const_fit:
                    rpar_name = files("edibles_dr5") / "molecfit/rpar" / spec_path.name.replace(".fits", ".rpar")
                    rpar_neighbour = Path(str(rpar_name).replace(f'O{order}', f'O{order+2}'))
                    if not rpar_neighbour.exists():
                        rpar_neighbour = Path(str(rpar_name).replace(f'O{order}', f'O{order-2}'))
                        if not rpar_neighbour.exists():
                            break

                    with rpar_neighbour.open() as f:
                        n_lines = f.readlines()
                        # get column densities from neighbouring rpar
                        molec_list = n_lines[81]


                # load the molecfit parameter file
                with molecfit_par_path.open() as f:
                    lines = f.readlines()

                # modify lines
                lines[4] = f'user_workdir: {molecfit_dir}\n'
                lines[9] = f'filename: {spec_path}\n'
                if const_fit:
                    lines[81] = molec_list
                else:
                    lines[81] = 'list_molec: ' + ' '.join(molec_order) + '\n'

                if const_fit:
                    fit_bools = ['0' for _ in fit_molec_order]    
                else:
                    fit_bools = [f'{item:.0f}' for item in fit_molec_order]            
                   
                lines[84] = 'fit_molec: ' + ' '.join(fit_bools) + '\n'

                rel_col_strings = [f'{item:.2f}' for item in rel_col_order]            
                lines[88] = 'relcol: ' + ' '.join(rel_col_strings) + '\n'

                wlc_n = np.min([len(include_order) - 1, 2])
                lines[150] = f'wlc_n: {wlc_n}' + '\n'

                if setting in ['564nm_redl', '564nm_redu', '860nm_redl', '860nm_redu']:
                    lines[245] = f'slitw_key: ESO INS SLIT3 WID\n'
                elif setting in ['346nm_blue', '437nm_blue']:
                    lines[245] = f'slitw_key: ESO INS SLIT2 WID\n'

                if const_fit:
                    lines[136] = 'fit_wlc: 0\n'


                # save the modified atlas command file
                with open(molecfit_par_path, 'w') as f:
                    f.writelines(lines)


                # Do telluric correction
                os.system(paths.molecfit_bin / f'molecfit {molecfit_par_path}')
                os.system(paths.molecfit_bin / f'calctrans {molecfit_par_path}')

                # rewrite header and save corrected spectrum to tell_corr directory
                molecfit_tac_header.main(setting, molecfit_dir / 'output', spec_name=spec_path.name)

                # copy rpar file
                os.system(f'cp {molecfit_dir / "output/molecfit_expert_fit.rpar"} {files("edibles_dr5") / "molecfit/rpar" / spec_path.name.replace(".fits", ".rpar")}')


if __name__ == '__main__':
    main()
