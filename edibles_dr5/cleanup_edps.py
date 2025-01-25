from edibles_dr5 import paths, edr5_functions


def main():
    edps_object_dir = paths.edr5_dir / 'EDPS/UVES/object'

    for sub_dir in edps_object_dir.iterdir():
        edr5_functions.cleanup_edps_subdir(sub_dir)


if __name__ == '__main__':
    main()
