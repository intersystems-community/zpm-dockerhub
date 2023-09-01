def ipm(cmd, *args):
    """
    Executes shell command with IPM:

    Parameters
    ----------
    cmd : str
        The command to execute

    Examples
    --------
    `ipm('help')`
    `ipm('load /home/irisowner/dev -v')`
    `ipm('install webterminal')`
    """

    import multiprocessing

    def shell(cmd, status):
        import iris

        status.put(True)

        res = iris.cls("%ZPM.PackageManager").Shell(cmd)
        print('')
        if res != 1:
            status.get()
            status.put(False)

    manager = multiprocessing.Manager()
    status = manager.Queue()
    process = multiprocessing.Process(
        target=shell,
        args=(
            cmd,
            status,
        ),
    )
    process.start()
    process.join()
    return status.get()
