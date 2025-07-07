#!/bin/bash
set -eo pipefail

# The default installation variables. The unset network components enable DHCP.
debinstall_defaults() {
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
    # shellcheck disable=SC2016
    DEBINSTALL_USER_PASS='$6$KGtfj9Pk5Bf0lXxe$UbreL0Kpk3XymAhXwhlIx0DhS9PqbQWtjcrAq8sTBUi/kf4nyl.WgRzEyaSd7HtSvdqHmXS5JZk0G.zvS1YeF0'
    DEBINSTALL_GRUB_PASS='grub.pbkdf2.sha512.10000.D653BB7638769417A9A6A35F5E6ACFEB1DDD6C28321581AB800A02278255AF36CEDDA55919D197992590127DEA20957A9A593E8615CDA1729EC30FB76FB85962.906A00F5C102E490C2D61570390F272E7B450466CE6C71D923C4792FD2CAE25D862E6A7915DD3F90669087CFFF2FC2E72BFF95257E7C741893D4D241F0002DB7'
}

ve() {
    local py=${1:-python3.8}
    local venv="${2:-./.venv}"

    local bin="${venv}/bin/activate"

    # If not already in virtualenv
    # $VIRTUAL_ENV is being set from $venv/bin/activate script
	  if [ -z "${VIRTUAL_ENV}" ]; then
        if [ ! -d "${venv}" ]; then
            echo "Creating and activating virtual environment ${venv}"
            ${py} -m venv "${venv}" --system-site-package
            echo "export PYTHON=${py}" >> "${bin}"    # overwrite ${python} on .zshenv
            # shellcheck disable=SC1090
            source "${bin}"
            echo "Upgrading pip"
        else
            echo "Virtual environment  ${venv} already exists, updating and activating..."
            # shellcheck disable=SC1090
            source "${bin}"
        fi
        ${py} -m pip install --upgrade pip
        pip install -U -r requirements.txt
    else
        echo "Already in a virtual environment!"
    fi
}

pretty_print() {
    NOCOL="\e[0m"
    LIGHT_YELLOW="\e[93m"

    echo -e "${LIGHT_YELLOW}${1}${NOCOL}"
}

host_content() {

pretty_print "Hosting content"
python3 -m http.server -d build

}

generate_user_config() {

    pretty_print """
    You will now be prompted for each configuration option. The default, which
    will be shown for each entry can be used by leaving the input blank.
    After the questionnaire the results will be written to ./vars
    """
    # Prompt the user for each generic variable, networking and password need
    # to be handled separately
    VAR_NAME_LIST=$(compgen -v | grep 'DEBINSTALL' | grep -vE '(NET)|(PASS)')
    for var_name in ${VAR_NAME_LIST}; do
        pretty_print "    Config option ${var_name} [Default=${!var_name}]"
        read -rp "    Value: " VAR_INPUT
        if [ -n "${VAR_INPUT}" ]; then
            export "${var_name}"="${VAR_INPUT}"
        fi
    done

    # Prompt user for networking choice. This has to be done a little bit
    # differently as there is no default value (the default is DHCP).
    # If the user wants a static IP, we loop over al NET variables and
    # handle them in a match-case structure.
    pretty_print """
    Config option static networking (y/n) [Default=n]
    If yes, you will be prompted for networking details"""
    read -rp "    Value: " VAR_INPUT
    if [ "${VAR_INPUT}" == 'y' ]; then
        VAR_NAME_LIST=$(compgen -v | grep 'DEBINSTALL' | grep 'NET')
        for var_name in ${VAR_NAME_LIST}; do
            case "${var_name}" in
                DEBINSTALL_NET_IP)
                    pretty_print "    Config option ${var_name} (Example: 10.0.0.2)"
                    read -rp "    Value: " "${var_name?}"
                    ;;
                DEBINSTALL_NET_MASK)
                    pretty_print "    Config option ${var_name} (Example: 255.255.255.0)"
                    read -rp "    Value: " "${var_name?}"
                    ;;
                DEBINSTALL_NET_GW|DEBINSTALL_NET_NS)
                    pretty_print "    Config option ${var_name} (Example: 10.0.0.1)"
                    read -rp "    Value: " "${var_name?}"
                    ;;
            esac
        done
    fi

    # Generate root, user and grub passwords from user input, if desired
    # Do some while-do stuff to get a validated password input
    pretty_print """
    Config option setting custom passwords (y/n) [Default=n]
    If choosing no (the default), the password will be 'Welkom123!@#'
    If yes, you will be prompted for a password"""
    read -rp "    Value: " VAR_INPUT
    if [ "${VAR_INPUT}" == 'y' ]; then
        pretty_print """
        Set the root, user and GRUB2 password. All 3 will be generated from the
        same value.
        If you require a different value for each, please use the answers file."""
        PASS_SUCCES=false
        while [ "${PASS_SUCCES}" = false ]; do
            read -srp "        Password: " PASS_INPUT
            echo
            read -srp "        Confirm password: " CONFIRM_PASS_INPUT
            echo
            if [ "${PASS_INPUT}" == "${CONFIRM_PASS_INPUT}" ]; then
                PASS_SUCCES=true
            else
                pretty_print "    Passwords provided do not match!"
            fi
        done

        DEBINSTALL_USER_PASS="$(openssl passwd -6 "${PASS_INPUT}")"
        # Hacky workaround for getting a GRUB2 password, as the
        # grub-mkpasswd-pbkdf2 is not really script friendly
        DEBINSTALL_GRUB_PASS="$(echo -e "${PASS_INPUT}\n${PASS_INPUT}" | grub-mkpasswd-pbkdf2 | awk '/grub.pbkdf/{print$NF}')"

    fi

    # Write the questionnaire to an answers file for (optional) future use
    declare | grep -E '^DEBINSTALL' > vars

}

render_template() {
    
    mkdir -p build

    pretty_print "Rendering template"
    jinja2 --strict -D ip="${DEBINSTALL_NET_IP}" -D mask="${DEBINSTALL_NET_MASK}" -D gw="${DEBINSTALL_NET_GW}" -D ns="${DEBINSTALL_NET_NS}" \
        -D hostname="${DEBINSTALL_MACHINE_HOSTNAME}" -D domain="${DEBINSTALL_DOMAIN}" -D disk="${DEBINSTALL_BOOTDISK}" -D country="${DEBINSTALL_COUNTRY}" \
        -D extra_pkgs="${DEBINSTALL_EXTRA_PACKAGES}" -D timezone="${DEBINSTALL_TIMEZONE}" -D username="${DEBINSTALL_FULL_USERNAME}" -D user_pass="${DEBINSTALL_USER_PASS}" \
        -D grub_pass="${DEBINSTALL_GRUB_PASS}" \
        preseed.cfg.j2 > build/preseed.cfg

    pretty_print "Build complete! Template may be found in ./build/preseed.cfg"
}

main() {
    ve python3 > /dev/null

    # Set all default variables
    debinstall_defaults

    # Load from vars file if exists, overriding defaults, else interactively prompt user
    if [ -f ./vars ]; then
        pretty_print "Variable answers file './vars' found"
        # shellcheck disable=SC1091
        source ./vars
    else
        pretty_print "No answers file found, starting user questionnaire"
        generate_user_config
    fi

    # Clean up previous build artefacts if present
    if [ -d build ]; then
        pretty_print "Removing existing build directory"
        rm -r build
    fi

    # Render the preseed template
    render_template    

    if [ "${1}" != "build" ]; then
        host_content
    fi

}

main "${@}"
