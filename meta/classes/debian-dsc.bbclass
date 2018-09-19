# Original source:
# https://github.com/alexbluesman/bitbake-dsc/blob/master/meta/classes/debian-dsc.bbclass
# Copyright (C) 2018 Alexander Smirnov

def get_deb_host_arch():
    import subprocess
    host_arch = subprocess.Popen("dpkg --print-architecture",
                                 shell=True,
                                 env=os.environ,
                                 stdout=subprocess.PIPE
                                ).stdout.read().decode('utf-8').strip()
    return host_arch

python __anonymous() {
    import subprocess


# Fetch .dsc package file
    dsc_uri = (d.getVar('DSC_URI', True) or "").split()
    if len(dsc_uri) == 0:
        return
    try:
        fetcher = bb.fetch2.Fetch(dsc_uri, d)
        fetcher.download()
    except bb.fetch2.BBFetchException as e:
        raise bb.build.FuncFailed(e)

    # Open .dsc file from downloads
    dl_dir = d.getVar('DL_DIR', True) or ""
    dsc_file = (dsc_uri[0].split(";")[0]).split("/")[-1]
    filepath = dl_dir + '/' + dsc_file
    repo = (dsc_uri[0].split(";")[0]).replace(dsc_file, "")
    files = []

    # Parse .dsc for the important fields
    with open(filepath, 'r') as file:
        line = file.readline()
        while line:
            # Get package version and export PV
            if line.startswith('Version:'):
                pv = line.split(": ")[-1].rstrip()
                d.setVar('PV', pv)
            elif line.startswith('Files:'):
                print("Files:")
                line = file.readline()
                while line and line.startswith(' '):
                    f = line.split()[2]
                    print("file_name: " + f)
                    files.append(repo + f + ";unpack=0;")
                    line = file.readline()
                break
            line = file.readline()
        file.close()
    src_uri = d.getVar('SRC_URI', True) or ""
    d.setVar('SRC_URI', src_uri + ' ' + ' '.join(files))
    src_uri = (d.getVar('SRC_URI', True) or "").split()


#    if len(src_uri) == 0:
#        return
#    try:
    fetcher = bb.fetch2.Fetch(src_uri, d)
    fetcher.download()
#    except bb.fetch2.BBFetchException as e:
#        raise bb.build.FuncFailed(e)

    rootdir = d.getVar('WORKDIR')
    bb.plain("rootdir: " + rootdir)
    fetcher.unpack(rootdir)

    host_arch = get_deb_host_arch()
    bb.plain("host_arch : "  + host_arch)
    subprocess.run(["dpkg", "--print-architecture"])
    bb.plain("dpkg --print-architectre completed")
#    subprocess.run(["dpkg-source", " -x", "hello_2.9-2+deb8u1.dsc"])
#    subprocess.run(["dpkg-source -x", " *.dsc"])

# TODO:
# 1. Get the name of tarball and set SRC_URI (lightweight dsc backend) => Done
# 2. Fetch tarball and derive 'debian/control' (full dsc backend)
# 3. Extract fetched tarball and setup source tree
}
