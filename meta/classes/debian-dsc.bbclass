# Original source:
# https://github.com/alexbluesman/bitbake-dsc/blob/master/meta/classes/debian-dsc.bbclass
# Copyright (C) 2018 Alexander Smirnov

do_unpack_deb_src() {
  cd ${WORKDIR}
  dpkg-source -x ${PN}_${PV}.dsc
}
addtask unpack_deb_src after do_fetch before do_build

python __anonymous() {

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
    bb.plain("dsc_file: " + dsc_file)
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
                line = file.readline()
                while line and line.startswith(' '):
                    f = line.split()[2]
                    files.append(repo + f + ";unpack=0;")
                    line = file.readline()
                break
            line = file.readline()
        file.close()

    src_uri = d.getVar('SRC_URI', True) or ""
    bb.plain("SRC_URI: " + src_uri)
    files.append(repo + dsc_file + ";unpack=0;")
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
    fetcher.unpack(rootdir)
}
