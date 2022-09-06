# ubuntu-server-autoinstall-iso-creator
</p>
<p align="center">
    <a href="https://github.com/PaxJaromeMalues/ubuntu-server-autoinstall-iso-repacker/releases/latest">
        <img src="https://img.shields.io/badge/Version-1.0.0-green.svg" alt="Version">
    </a>
    <a href="https://github.com/PaxJaromeMalues/ubuntu-server-autoinstall-iso-repacker/issues">
        <img src="https://img.shields.io/github/issues-raw/PaxJaromeMalues/ubuntu-server-autoinstall-iso-repacker.svg?label=Issues" alt="Issues">
    </a>

This shell script repacks(!) an EFI and MBR bootable auto installation iso9660 container using a modified grub.cfg, custom user-data and meta-data files based on the latest (daily) Ubuntu 22.04.x LTS ISO.

Note, that using an entirely automated ISO outside AND INSIDE of testing environments can have fatal results for your project.
You will be notified of that once each use unless you alternate the script yourself.

Note as well, that Subiquity in itself still suffers from some rather annoying bugs.
Only use Cloud-init and Subiquity if you can handle those bugs or stick to a different autoinstallation method of your choice.

Report bugs and ideas for improvement of this script!!
</p>
