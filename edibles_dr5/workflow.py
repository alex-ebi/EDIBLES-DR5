#!/usr/bin/env python
# coding: utf-8

# # This is the workflow of my EDR5 reduction
# First, we download a collection of flats from the ESO archive WITH night logs!
# 
# ## Parameters:
# ### General:
# Night: 2017 01 01 .. 2017 12 31
# User defined input: LAMP,FLAT\
# Mode: ECHELLE\
# Slit: FREE
# 
# ### Setting specific:
# 346 nm setting:\
# TPL ID: UVES_dic1_cal_flatfree\
# (Exptime: 59 .. 60)\
# Filter bandpass: HER_5\
# Grating: CD#1
# 
# 437 nm setting:\
# TPL ID: UVES_dic2_cal_flatfree\
# (Exptime: 272 .. 273)\
# Filter bandpass: HER_5\
# Grating: CD#2
# 
# 564 nm setting:\
# TPL ID: UVES_dic1_cal_flatfree\
# (Exptime: 31 .. 32)\
# Filter bandpass: SHP700\
# Grating: CD#3
# 
# 860 nm setting:\
# TPL ID: UVES_dic2_cal_flatfree\
# (Exptime: 80 .. 81)\
# Filter bandpass: OG590\
# Grating: CD#4
# 
# Respective download scripts are supplied
# 
# 

# In[1]:


from pathlib import Path
import os
from edibles_dr5.paths import edr5_dir
from importlib.resources import files


# ## Download flats for super flats
# 

# In[11]:


flat_dir = edr5_dir / 'flat_raw'
download_script_dir = files('edibles_dr5') / 'supporting_data'

# Execute shell scripts
os.chdir(flat_dir)
# script_names = ['downloadScript_346nm.sh', 'downloadScript_437nm.sh', 'downloadScript_564nm.sh',
#                 'downloadScript_860nm.sh']
script_names = ['downloadScript_564nm.sh']
for script in script_names:
    os.system(f'source {download_script_dir / script}')
# Uncompress files
os.system('uncompress *.Z')


# ## Download BIAS for super BIAS
# It is possible that a lot of nise is introduced by noisy bias frames. This is why we make a super bias too.

# ## Download BIAS files for FLATS
# the downloaded flats are raw and need their respective bias files. Those are specified in the night logs.\
# (Note: Also download LAMP,ORDERDEF, bcause it is needed for reduction of master flats)

# In[ ]:


from edibles_dr5.flats import download_associated_bias_orderdef

download_associated_bias_orderdef.main(flat_dir)


# ## Make master biases with EDPS

# In[2]:


bias_dir = edr5_dir / 'bias'
# print(f'edps -w uves.uves_wkf -i {bias_dir} -t bias')
os.system(f'edps -w uves.uves_wkf -i {bias_dir} -t bias')


# ## Make master flats with EDPS

# In[3]:


print(f'edps -w uves.uves_wkf -i {flat_dir} -t flat')
# os.system(f'edps -w uves.uves_wkf -i {flat_dir} -t flat')


# ## Make super biases
# More master biases are created while making the master flats

# In[ ]:


from edibles_dr5.bias import make_superbias

make_superbias.main()


# ## Make super flats

# In[ ]:


from edibles_dr5.flats import make_superflat

make_superflat.main()


# ## Run EDPS reduction on object data

# In[ ]:


os.system(f'edps -w uves.uves_wkf -i {edr5_dir / "HD170740_07_05"}')


# ## Rerun reductions with superflats

# In[ ]:


from edibles_dr5.esorex import extract_with_error

extract_with_error.main()

