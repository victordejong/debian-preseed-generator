# debian-preseed-generator

This project exists to provide a miminum configuration for a full Debian installation with sane defaults used where relevant.

## Howto

1. Clone this project:
```bash
git clone https://gitlab.com/victordejong/debian-preseed-generator
cd debian-preseed-generator
```
2. Fill the `vars` file with the correct variables

2. To render the preseed file and make it available over HTTP, run this command from this repository:

```bash
./deploy.sh

# Or, if you only want to render the template without hosting it
./deploy.sh build
```
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
Or copy the generated `preseed.cfg` file to another location and run `python3 -m http.server` from there.

3. Add the following to the `linux` GRUB entry BEFORE the dashes (`---`):
```text
linux   [...] auto=true hostname=[HOSTNAME] domain=[EXAMPLE.COM] url=http://WEBHOST:PORT/preseed.cfg
```
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
The domain part is not necessary and may be left empty `domain=`.

## Supported OS'

This preseed works on the following OS':

 - Debian 12 Bookworm