#!/usr/bin/env bash
# #################
#
# Bash script to run the test suite against the Vagrant environment.
#
# version: 1.0
#
# usage:
#
#   bash vagrant.sh
#
#   # in case you want to use one of tox virtualenvs
#
#   bash vagrant.sh --virtualenv $PWD/.tox/py27-ansible184 --virtualenv-name py27-ansible184
#   # or
#   bash vagrant.sh --python 27 --ansible 184
#
# author(s):
#   - Pedro Salgado <steenzout@ymail.com>
#
# #################

DIR="$(dirname "$0")"

cd $DIR

source ${DIR}/environment.sh

# The filename of the Ansible playbook to be used on the test.
# NOTE: PLAYBOOK must be the same value as defined in the Vagrantfile.
PLAYBOOK="${DIR}/vagrant.yml"

# A default inventory file is automatically generated by Vagrant @
#   INVENTORY=${DIR}/.vagrant/provisioners/ansible/inventory/vagrant_ansible_inventory


while [[ $# > 1 ]]
do
key="$1"

    case $key in

        --python)
        # The Python version to be used on the test.
        # NOTE: PYTHON_VERSION must be set to a Python version defined in tox.
        PYTHON_VERSION="$2"
        shift;;

        --ansible)
        # The Ansible version to be used on the test.
        # ANSIBLE_VERSION must be set to a Ansible version defined in tox.
        ANSIBLE_VERSION="$2"
        shift;;

        --virtualenv-name)
        # The tox virtualenv name
        VIRTUALENV_NAME="$2"
        shift;;

        --virtualenv)
        # The virtualenv directory to be used on the test.
        VIRTUALENV="$2"
        shift;;

        *)
        # unknown option
        ;;

    esac
    shift
done

DIR=$(dirname "$0")

if [[ ! -z ${PYTHON_VERSION} ]] && [[ ! -z ${ANSIBLE_VERSION} ]]; then
    echo '[INFO] loading Python / Ansible virtualenv...'
    VIRTUALENV="${DIR}/../.tox/py${PYTHON_VERSION}-ansible${ANSIBLE_VERSION}"
    VIRTUALENV_NAME="py${PYTHON_VERSION}-ansible${ANSIBLE_VERSION}"
fi

source ${VIRTUALENV}/bin/activate


. install_role_dependencies.sh


for box_yml in ${DIR}/host_vars/*.yml
do
    filename=$(basename "$box_yml")
    box=${filename%.*}

    echo "[INFO] preparing ${box}..."
    vagrant up ${box}

    # force tests to be run against this Vagrant box
    INVENTORY="${box},"

    . test_idempotence.sh

    echo "[INFO] destroying ${box}..."
    #vagrant destroy -f $box
done
