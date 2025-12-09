"""
Testing different parameters for background subtraction.
"""
from edibles_dr5 import paths
import os
from edibles_dr5.esorex import extract_with_error_average

edibles_raw_dir = paths.edr5_dir / 'EDIBLES_raw'
tasks = ['uves_cal_mflat', 'uves_cal_response.reduce', 'uves_obs_scired.reduce']

# parameter_range = 
product_name = 'radius_y_5'

out_dir = paths.edr5_dir / f'troubleshooting_backsub/{product_name}'

out_dir.mkdir(exist_ok=True, parents=True)

out_str = (f'{paths.edps_dir / "bin/python3"} {paths.edps_dir / "bin/edps"} '
           f'-w uves.uves_wkf '
           f'-i {edibles_raw_dir} '
           f'-o {out_dir} '
           f'-rp uves_obs_scired.reduce radiusy 5'
           )

os.system(out_str)

print(out_str)

extract_with_error_average.main(output_dir_online=out_dir, rps='--reduce.backsub.radiusy=5 ')


