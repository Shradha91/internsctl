#!/usr/bin/env sh

VERSION="v0.1.0"

show_version() {
    echo "Version: $VERSION"
}

show_help() {
    echo "Usage: internsctl [OPTIONS] COMMAND"
    echo ""
    echo "Options:"
    echo "  -v, --version                          Show the version"
    echo "  -h, --help                             Show this help message"
    echo ""
    echo "Commands:"
    echo "  cpu getinfo                            Get CPU information using lscpu"
    echo "  memory getinfo                         Get memory information using free"
    echo "  user create <username>                 Create a new user with a corresponding home directory"
    echo "  user list [--sudo-only]                List all regular users on the Linux server [with sudo permissions]"
    echo "  file getinfo [OPTIONS] <filename>      Get information about a specific file"
    echo ""
    echo "File Getinfo Options:"
    echo "  -s, --size                             Print only the size"
    echo "  -p, --permissions                      Print only file permissions"
    echo "  -o, --owner                            Print only the file owner"
    echo "  -m, --last-modified                    Print last modified date"
}

get_cpu_info() {
    lscpu
}

get_memory_info() {
    free -h
}

create_user() {
    username="$1"
    if [ -z "$username" ]; then
        echo "Error: Missing username. Please provide a username."
        exit 1
    fi

  # Check if the user already exists
  if id "$username" &>/dev/null; then
      echo "Error: User '$username' already exists."
      exit 1
  fi

  # Create user with home directory
  sudo useradd -m "$username"
  echo "User '$username' created with home directory."
}

list_users() {
    if [[ "$1" == "--sudo-only" ]]; then
        awk -F':' '/^sudo/{print $4}' /etc/group | tr ',' '\n'
    else
        awk -F':' '($3>=1000 && $3!=65534){print $1}' /etc/passwd
    fi
}

get_file_info() {
    local filename="$1"
    local size_option=0
    local permissions_option=0
    local owner_option=0
    local last_modified_option=0

    shift

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -s|--size)
                size_option=1
                ;;
            -p|--permissions)
                permissions_option=1
                ;;
            -o|--owner)
                owner_option=1
                ;;
            -m|--last-modified)
                last_modified_option=1
                ;;
            *)
                echo "Error: Invalid option '$1' for file getinfo."
                exit 1
                ;;
        esac
        shift
    done

    if [ -z "$filename" ]; then
        echo "Error: Missing filename. Please provide a filename."
        exit 1
    fi

    if [ ! -e "$filename" ]; then
        echo "Error: File '$filename' does not exist."
        exit 1
    fi


    if [ $size_option -eq 1 ]; then
        local file_size=$(stat -c "Size (B): %s" "$filename")
        echo "$file_size"
    elif [ $permissions_option -eq 1 ]; then
        local perms=$(stat -c "Access: %A" "$filename")
        echo "$perms"
    elif [ $owner_option -eq 1 ]; then
        local owner=$(stat -c "Owner: %U" "$filename")
        echo "$owner"
    elif [ $last_modified_option -eq 1 ]; then
        local modify=$(stat -c "Modify: %y" "$filename")
        echo "$modify"
    else
        local file_stat=$(stat -c "File: %n\nAccess: %A\nSize (B): %s\nOwner: %U\nModify: %y" "$filename")
        printf "$file_stat"
    fi
}

case "$1" in
    -v|--version)
        show_version
        ;;
    -h|--help)
        show_help
        ;;
    cpu)
        case "$2" in
            getinfo)
                get_cpu_info
                ;;
            *)
                echo "Invalid command. Please use 'internsctl --help' for usage."
                exit 1
                ;;
        esac
        ;;
    memory)
        case "$2" in
            getinfo)
                get_memory_info
                ;;
            *)
                echo "Invalid command. Please use 'internsctl --help' for usage."
                exit 1
                ;;
        esac
        ;;
    user)
        case "$2" in
            create)
                create_user "$3"
                ;;
            list)
                list_users "$3"
                ;;
            *)
                echo "Invalid command. Please use 'internsctl --help' for usage."
                exit 1
                ;;
        esac
        ;;
    file)
        case "$2" in
            getinfo)
                shift
                shift
                get_file_info "$@"
                ;;
            *)
                echo "Invalid command. Please use 'internsctl --help' for usage."
                exit 1
                ;;
        esac
        ;;
    *)
        echo "Invalid command. Please use 'internsctl --help' for usage."
        exit 1
        ;;
esac

