# debian-preseed-generator

This project exists to provide a miminum configuration for a full Debian installation with sane defaults used where relevant.

The preseed installs to a singe disk with LVM and uses a simple static networking setup or DHCP. The default user/pass is `jan/Welkom123!@#`, with the same password for the root user.

`sudo` and `ssh-server` are installed by default.
## Requirements

- `python3`
- `python3-venv`
- `bash`
- (Optional) `grub` toolset (for generating a grub password with `grub-mkpasswd-pbkdf2`)

## Howto

1. Clone this project:
```bash
git clone https://gitlab.com/victordejong/debian-preseed-generator
cd debian-preseed-generator
```
2. (Optional) 2 files can be used to automatically provide answers for the template. `vars` can be used and is the file `deploy.sh` writes to to save answers you provided manually for future use. `vars.custom` fulfills the same function as `vars`, but takes precedence and will never be written to by the `deploy.sh` script. For any missing option the default value will be used, see [Default values](#default-values).

3. To render the preseed file and make it available over HTTP, run this command from this repository:

```bash
./deploy.sh
```
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
For more options, see `./deploy help` 

4. Add the following to the Debian Installer `linux` GRUB entry BEFORE the dashes (`---`):
```text
linux   [...] auto=true hostname=[HOSTNAME] domain=[EXAMPLE.COM] url=http://WEBHOST:PORT/preseed.cfg
```

> [!WARNING]
> When starting the installer, the preseed file is configured as such to overwrite all data on the target disk if there is any, without prompting the user!

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
The domain part is not necessary and may be left empty `domain=`.

## Default values

Currently, the following default values are active.
```bash
# Unset static network configuration enables DHCP in the preseed file
DEBINSTALL_NET_IP=
DEBINSTALL_NET_MASK=
DEBINSTALL_NET_GW=
DEBINSTALL_NET_NS=

DEBINSTALL_MACHINE_HOSTNAME='debian'
DEBINSTALL_DOMAIN='example.org'
DEBINSTALL_EXTRA_PACKAGES='sudo htop build-essential'

DEBINSTALL_BOOTDISK='/dev/sda'

# Timezone and country are for the Netherlands
DEBINSTALL_COUNTRY='nl'
DEBINSTALL_TIMEZONE='Europe/Amsterdam'

DEBINSTALL_FULL_USERNAME='Jan Modaal'
# Both passwords are 'Welkom123!@#'
DEBINSTALL_USER_PASS='$6$KGtfj9Pk5Bf0lXxe$UbreL0Kpk3XymAhXwhlIx0DhS9PqbQWtjcrAq8sTBUi/kf4nyl.WgRzEyaSd7HtSvdqHmXS5JZk0G.zvS1YeF0'
DEBINSTALL_GRUB_PASS='grub.pbkdf2.sha512.10000.D653BB7638769417A9A6A35F5E6ACFEB1DDD6C28321581AB800A02278255AF36CEDDA55919D197992590127DEA20957A9A593E8615CDA1729EC30FB76FB85962.906A00F5C102E490C2D61570390F272E7B450466CE6C71D923C4792FD2CAE25D862E6A7915DD3F90669087CFFF2FC2E72BFF95257E7C741893D4D241F0002DB7'
```

An example static networking configuration:
```bash
DEBINSTALL_NET_IP=10.0.0.2
DEBINSTALL_NET_MASK=255.255.255.0
DEBINSTALL_NET_GW=10.0.0.1
DEBINSTALL_NET_NS=1.1.1.1
```

The `DEBINSTALL_USER_PASS` can be generated as follows:
```bash
openssl passwd -6 [PASSWORD]
```

The `DEBINSTALL_GRUB_PASS` can be generated using the `grub-mkpasswd-pbkdf2` tool, which is usually shipped with the relevant `grub2` package for your system.

## Supported OS'

This preseed has been tested on the following OS':

 - Debian 11 Bullseye
 - Debian 12 Bookworm
 - Debian 13 Trixie RC2

Other version might also work, but are not guaranteed.
