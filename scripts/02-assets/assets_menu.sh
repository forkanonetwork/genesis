#!/usr/bin/env bash

### Colors ##
ESC=$(printf '\033') RESET="${ESC}[0m" BLACK="${ESC}[30m" RED="${ESC}[31m"
GREEN="${ESC}[32m" YELLOW="${ESC}[33m" BLUE="${ESC}[34m" MAGENTA="${ESC}[35m"
CYAN="${ESC}[36m" WHITE="${ESC}[37m" DEFAULT="${ESC}[39m"

### Color Functions ##

greenprint() { printf "${GREEN}%s${RESET}\n" "$1"; }
blueprint() { printf "${BLUE}%s${RESET}\n" "$1"; }
redprint() { printf "${RED}%s${RESET}\n" "$1"; }
yellowprint() { printf "${YELLOW}%s${RESET}\n" "$1"; }
magentaprint() { printf "${MAGENTA}%s${RESET}\n" "$1"; }
cyanprint() { printf "${CYAN}%s${RESET}\n" "$1"; }
fn_goodafternoon() { echo; echo "Good afternoon."; }
fn_goodmorning() { echo; echo "Good morning."; }
fn_bye() { echo "Bye bye."; exit 0; }
fn_fail() { echo "Wrong option." exit 1; }

# MENU_NAMES=
# Show vars (env, sock, etcétera)
# Check Rewards
# Check Slot Leadership
# Check KES
# Operational:
    # Renew KES
    # Open gLiveView
    # Run something
# Tokens
    # Assets Menu
    # NFT Menu
# Address:
    # SHOW Destination Address
    # SET Destination Address


sub_submenu() {
clear
tokenamount=12123123123
if [ $tokenamount -eq 0 ]; then
    TOKEN_AMOUNT="(not set)"
else
    TOKEN_AMOUNT="${tokenamount} assets to mint"
fi
    echo -n "
$(yellowprint 'TOKEN-MENU')
$(greenprint '1)') TOKEN AMOUNT: ${TOKEN_AMOUNT}
$(greenprint '2)') GOOD
$(blueprint '3)') Go Back to SUBMENU
$(magentaprint '4)') Go Back to MAIN MENU
$(redprint '0)') Exit
Choose an option:  "
    read -r ans
    case $ans in
    1)
        fn_goodmorning
        sub_submenu
        ;;
    2)
        fn_goodafternoon
        sub_submenu
        ;;
    3)
        submenu
        ;;
    4)
        mainmenu
        ;;
    0)
        fn_bye
        ;;
    *)
        fn_fail
        ;;
    esac
}

submenu() {
clear
    echo -n "
$(blueprint 'CMD1 SUBMENU')
$(greenprint '1)') SUBCMD1
$(magentaprint '2)') Go Back to Main Menu
$(redprint '0)') Exit
Choose an option:  "
    read -r ans
    case $ans in
    1)
        sub_submenu
        submenu
        ;;
    2)
        menu
        ;;
    0)
        fn_bye
        ;;
    *)
        fn_fail
        ;;
    esac
}

mainmenu() {
clear
    echo -n "
$(magentaprint 'MAIN MENU')
$(greenprint '1)') CMD1
$(redprint '0)') Exit
Choose an option:  "
    read -r ans
    case $ans in
    1)
        submenu
        mainmenu
        ;;
    0)
        fn_bye
        ;;
    *)
        fn_fail
        ;;
    esac
}

mainmenu
