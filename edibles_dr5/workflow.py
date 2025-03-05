#!/usr/bin/env python
# coding: utf-8

# # This is the workflow of my EDR5 reduction
# First, we download a collection of flats from the ESO archive WITH night logs!
# 
# ## Parameters:
# ### General:
# Night: 2014 01 01 .. 2019 12 31
# User defined input: LAMP,FLAT\
# Mode: ECHELLE\
# Slit: FREE
# 
# ### Setting specific:
# 346 nm setting:\
# TPL ID: UVES_dic1_cal_flatfree\
# (Exptime: 20 .. 100000)\
# Filter bandpass: HER_5\
# Grating: CD#1
# 
# 437 nm setting:\
# TPL ID: UVES_dic2_cal_flatfree\
# (Exptime: 110 .. 100000)\
# Filter bandpass: HER_5\
# Grating: CD#2
# 
# 564 nm setting:\
# TPL ID: UVES_dic1_cal_flatfree\
# (Exptime: 14 .. 100000)\
# Filter bandpass: SHP700\
# Grating: CD#3
# 
# 860 nm setting:\
# TPL ID: UVES_dic2_cal_flatfree\
# (Exptime: 23 .. 100000)\
# Filter bandpass: OG590\
# Grating: CD#4
# 
# Respective download scripts are supplied
# 
# 

# In[2]:


import os
from edibles_dr5.paths import edr5_dir, edps_dir
from importlib.resources import files

edr5_dir.mkdir(exist_ok=True)
flat_dir = edr5_dir / 'calib_raw'


# ## Download flats for super flats
# 

# In[ ]:


flat_dir.mkdir(exist_ok=True)
download_script_dir = files('edibles_dr5') / 'supporting_data'

# Execute shell scripts
os.chdir(flat_dir)
script_names = ['downloadScript_346nm.sh', 'downloadScript_437nm.sh', 'downloadScript_564nm.sh',
                'downloadScript_860nm.sh']

for script in script_names:
    os.system(f'chmod u+x {download_script_dir / script}')
    os.system(f'{download_script_dir / script}')
    print(f'source {download_script_dir / script}')
# Uncompress files
os.system('uncompress *.Z')


# ## Download BIAS, ORDERDEF and FMTCHK files for FLATS
# The downloaded flats are raw and need their respective bias and orderdef files. Those are specified in the night logs.

# In[ ]:


from edibles_dr5.flats import download_associated_bias_orderdef

download_associated_bias_orderdef.main(flat_dir)


# ## Make master flats with EDPS

# In[ ]:


print(f'{edps_dir / "bin/python3"} {edps_dir / "bin/edps"} -w uves.uves_wkf -i {flat_dir} -t flat')

os.system(f'{edps_dir / "bin/python3"} {edps_dir / "bin/edps"} -w uves.uves_wkf -i {flat_dir} -t flat')


# ## Make super flats

# In[ ]:


from edibles_dr5.flats import make_superflat

make_superflat.main()


# # Download EDIBLES data

# In[ ]:


edibles_raw_dir = edr5_dir / 'EDIBLES_raw'
edibles_raw_dir.mkdir(exist_ok=True)

os.chdir(edibles_raw_dir)

os.system(f'chmod u+x {download_script_dir / "downloadScript_EDIBLES_sample.sh"}')
os.system(f'{download_script_dir / "downloadScript_EDIBLES_sample.sh"}')


# ## Run EDPS reduction on object data

# In[ ]:


os.system(f'{edps_dir / "bin/python3"} {edps_dir / "bin/edps"} -w uves.uves_wkf -i {edibles_raw_dir}')


# ## Rerun reductions with superflats

# In[ ]:


from edibles_dr5.esorex import extract_with_error_optimal, extract_with_error_average

extract_with_error_optimal.main()
extract_with_error_average.main()

