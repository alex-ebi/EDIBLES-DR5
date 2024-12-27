from pathlib import Path


def recursive_listdir(root_path: str, endswith: str) -> list:
    """
    Returns list of all files in a directory, which end with a specified string.
    The returned list of paths consists of pathlib.Path's.
    They can be easily converted to strings, but have some useful methods.

    Parameters
    ----------
    root_path : str
        Path of main directory for file-search.

    endswith : str
        Specified string ending.

    Returns
    -------
    list(pathlib.Path)
        list of pathlib.Path's
    """
    root_path = Path(root_path)  # convert root path to a Path object
    list_dir = list(root_path.glob(f'**/*{endswith}'))

    return list_dir
